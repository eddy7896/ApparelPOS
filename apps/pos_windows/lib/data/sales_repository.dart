// Selling: a cashier-safe stock lookup and saving a bill in ONE transaction
// (garments marked sold, bill, lines, payments, bill serial, audit, outbox).
// Rules are in core_domain (priceLine, discountDecision, settle, BillNumber,
// the permission matrix). E-SALE-1, E-AUTHZ-1, E-OFFLINE-1, E-AUDIT-1.
//
// Nothing in this file reads cost: the cost table is `batch_lines`, and it is
// never selected here (a test reads this file's text to keep it so).
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';

/// Why a garment cannot go on a bill.
enum NotSellableReason { notFound, alreadySold, notInStock }

/// Thrown when a scanned barcode cannot be sold. [soldOnBill] names the bill
/// when it was already sold.
final class ArticleNotSellable implements Exception {
  ArticleNotSellable(this.barcode, this.reason, {this.soldOnBill});
  final String barcode;
  final NotSellableReason reason;
  final String? soldOnBill;
  @override
  String toString() =>
      'ArticleNotSellable: $barcode ${reason.name}'
      '${soldOnBill == null ? '' : ' (bill $soldOnBill)'}';
}

/// Thrown for a bill that is not well formed (empty, repeated barcode, bad
/// customer details).
final class InvalidBill implements Exception {
  InvalidBill(this.message);
  final String message;
  @override
  String toString() => 'InvalidBill: $message';
}

/// Thrown when a cashier's discount is over the limit; the manager's password
/// is needed (the prompt comes with the register screen, P2-4c).
final class DiscountNeedsManager implements Exception {
  DiscountNeedsManager(this.barcode);
  final String barcode;
  @override
  String toString() => 'DiscountNeedsManager: $barcode';
}

/// Thrown when the payments do not cover the bill.
final class BillNotPaid implements Exception {
  BillNotPaid(this.due);
  final Money due;
  @override
  String toString() => 'BillNotPaid: $due still due';
}

/// A garment as the counter sees it. There is no cost field, by design.
final class SaleItem {
  const SaleItem({
    required this.articleId,
    required this.barcode,
    required this.productName,
    required this.size,
    required this.color,
    required this.mrp,
    required this.status,
    this.soldOnBill,
  });
  final String articleId;
  final String barcode;
  final String productName;
  final String size;
  final String color;
  final Money mrp;
  final ArticleStatus status;
  final String? soldOnBill;
}

/// One garment to bill: its barcode, an optional markdown (manager or owner
/// only) and an optional cashier discount.
final class BillLineInput {
  const BillLineInput(this.barcode, {this.markdown, this.discount});
  final String barcode;
  final PriceCut? markdown;
  final PriceCut? discount;
}

final class SavedBillLine {
  const SavedBillLine({
    required this.barcode,
    required this.productName,
    required this.size,
    required this.color,
    required this.priced,
  });
  final String barcode;
  final String productName;
  final String size;
  final String color;
  final PricedLine priced;
}

/// A bill that was saved.
final class SavedBill {
  const SavedBill({
    required this.billId,
    required this.billNumber,
    required this.billedAt,
    required this.lines,
    required this.settlement,
  });
  final String billId;
  final BillNumber billNumber;
  final DateTime billedAt;
  final List<SavedBillLine> lines;
  final Settlement settlement;
  Money get total => settlement.total;
}

class SalesRepository {
  SalesRepository(
    this._db, {
    required String Function() newId,
    DateTime Function()? now,
  }) : _newId = newId,
       _now = now ?? (() => DateTime.now().toUtc()),
       _writer = AuditedWriter(_db, now: now, newId: newId);

  final AppDatabase _db;
  final String Function() _newId;
  final DateTime Function() _now;
  final AuditedWriter _writer;

  /// Looks up a garment by barcode for the counter. Needs
  /// `viewStockAndPrices`. Returns null for an unknown barcode.
  Future<SaleItem?> lookup({
    required Role? role,
    required String barcode,
  }) async {
    require(role, Permission.viewStockAndPrices);
    final row = await _find(barcode);
    return row?.item;
  }

  Future<_Found?> _find(String barcode) async {
    final rows = await _db
        .customSelect(
          'SELECT a.id AS id, a.barcode_value AS barcode, a.mrp_paise AS mrp, '
          'a.status AS status, p.name AS name, v.size AS size, v.color AS color '
          'FROM articles a '
          'JOIN variants v ON v.id = a.variant_id '
          'JOIN products p ON p.id = v.product_id '
          'WHERE a.barcode_value = ?',
          variables: [Variable<String>(barcode)],
        )
        .get();
    if (rows.isEmpty) {
      return null;
    }
    final r = rows.single;
    final status = ArticleStatus.fromDb(r.read<String>('status'));
    String? billNo;
    if (status == ArticleStatus.sold) {
      final b = await _db
          .customSelect(
            'SELECT b.bill_no AS no FROM bill_lines l '
            'JOIN bills b ON b.id = l.bill_id '
            'WHERE l.article_id = ? ORDER BY b.billed_at DESC LIMIT 1',
            variables: [Variable<String>(r.read<String>('id'))],
          )
          .get();
      billNo = b.isEmpty ? null : b.single.read<String>('no');
    }
    return _Found(
      SaleItem(
        articleId: r.read<String>('id'),
        barcode: r.read<String>('barcode'),
        productName: r.read<String>('name'),
        size: r.read<String>('size'),
        color: r.read<String>('color'),
        mrp: Money(r.read<int>('mrp')),
        status: status,
        soldOnBill: billNo,
      ),
    );
  }

  /// Saves a bill. Needs `sell`; a markdown needs `setMarkdown`. Throws
  /// [PermissionDenied], [InvalidBill], [ArticleNotSellable],
  /// [DiscountNeedsManager], [DiscountNotAllowed], [PriceCutTooLarge],
  /// [NonCashOverpayment] or [BillNotPaid]; on any failure nothing at all is
  /// saved (no garment is marked sold, no serial is used).
  Future<SavedBill> saveBill({
    required Role? role,
    required String cashierId,
    required List<BillLineInput> lines,
    required List<Payment> payments,
    String? customerName,
    String? customerPhone,
    int discountLimitBp = defaultCashierDiscountLimitBp,
    Role? discountApproverRole,
    String? discountApprovedBy,
  }) async {
    require(role, Permission.sell);
    if ((discountApproverRole == null) != (discountApprovedBy == null)) {
      throw ArgumentError(
        'give both discountApproverRole and discountApprovedBy, or neither',
      );
    }
    // A manager or owner who typed their password may approve a discount over
    // the cashier's limit. An approver without that right changes nothing.
    final decisionRole =
        can(discountApproverRole, Permission.overrideDiscountLimit)
        ? discountApproverRole
        : role;
    if (lines.isEmpty) {
      throw InvalidBill('a bill needs at least one garment');
    }
    final seen = <String>{};
    for (final l in lines) {
      if (!seen.add(l.barcode)) {
        throw InvalidBill('${l.barcode} is on the bill twice');
      }
      final markdown = l.markdown;
      if (markdown != null && !markdown.isZero) {
        require(role, Permission.setMarkdown);
      }
    }
    final name = _cleanName(customerName);
    final phone = _cleanPhone(customerPhone);

    final billId = _newId();
    final at = _now();
    final yearLabel = financialYearLabel(at);

    return _writer.run<SavedBill>(
      action: 'sale.bill',
      entityType: 'bill',
      entityId: billId,
      actor: cashierId,
      body: () async {
        final saved = <SavedBillLine>[];
        final articleIds = <String>[];
        for (final input in lines) {
          final found = await _find(input.barcode);
          if (found == null) {
            throw ArticleNotSellable(input.barcode, NotSellableReason.notFound);
          }
          final item = found.item;
          if (item.status == ArticleStatus.sold) {
            throw ArticleNotSellable(
              input.barcode,
              NotSellableReason.alreadySold,
              soldOnBill: item.soldOnBill,
            );
          }
          if (item.status != ArticleStatus.inStock) {
            throw ArticleNotSellable(
              input.barcode,
              NotSellableReason.notInStock,
            );
          }
          final discount = input.discount;
          if (discount != null) {
            final decision = discountDecision(
              decisionRole,
              discount,
              item.mrp,
              limitBp: discountLimitBp,
            );
            if (decision == DiscountDecision.denied) {
              throw PermissionDenied(role, Permission.giveDiscount);
            }
            if (decision == DiscountDecision.needsManagerOverride) {
              throw DiscountNeedsManager(input.barcode);
            }
          }
          final priced = priceLine(
            mrp: item.mrp,
            markdown: input.markdown,
            cashierDiscount: discount,
          );
          // The garment is marked sold only if it is still in stock right now.
          final changed =
              await (_db.update(_db.articles)..where(
                    (a) =>
                        a.id.equals(item.articleId) &
                        a.status.equals(ArticleStatus.inStock.dbValue),
                  ))
                  .write(
                    ArticlesCompanion(
                      status: Value(ArticleStatus.sold.dbValue),
                      updatedAt: Value(at),
                    ),
                  );
          if (changed != 1) {
            throw ArticleNotSellable(
              input.barcode,
              NotSellableReason.alreadySold,
            );
          }
          articleIds.add(item.articleId);
          saved.add(
            SavedBillLine(
              barcode: item.barcode,
              productName: item.productName,
              size: item.size,
              color: item.color,
              priced: priced,
            ),
          );
        }

        final total = saved.fold<Money>(
          Money.zero,
          (sum, l) => sum + l.priced.finalPrice,
        );
        final settlement = settle(total, payments);
        if (!settlement.isPaid) {
          throw BillNotPaid(settlement.due);
        }

        final counter = (await _db.select(_db.counters).get()).first;
        final counterNo = await _counterNo();
        final billNumber = await _nextBillNumber(
          counter.id,
          counterNo,
          yearLabel,
        );

        await _db
            .into(_db.bills)
            .insert(
              BillsCompanion.insert(
                id: billId,
                billNo: billNumber.format(),
                counterId: counter.id,
                cashierId: cashierId,
                customerName: Value(name),
                customerPhone: Value(phone),
                totalPaise: total.paise,
                changePaise: settlement.change.paise,
                billedAt: at,
                createdAt: at,
              ),
            );
        for (var i = 0; i < saved.length; i++) {
          final l = saved[i];
          await _db
              .into(_db.billLines)
              .insert(
                BillLinesCompanion.insert(
                  id: _newId(),
                  billId: billId,
                  articleId: articleIds[i],
                  barcodeValue: l.barcode,
                  productName: l.productName,
                  size: l.size,
                  color: l.color,
                  mrpPaise: l.priced.mrp.paise,
                  markdownPaise: l.priced.markdownAmount.paise,
                  discountPaise: l.priced.discountAmount.paise,
                  finalPaise: l.priced.finalPrice.paise,
                ),
              );
        }
        for (final e in settlement.byMode.entries) {
          await _db
              .into(_db.billPayments)
              .insert(
                BillPaymentsCompanion.insert(
                  id: _newId(),
                  billId: billId,
                  mode: e.key.dbValue,
                  amountPaise: e.value.paise,
                ),
              );
        }
        return SavedBill(
          billId: billId,
          billNumber: billNumber,
          billedAt: at,
          lines: saved,
          settlement: settlement,
        );
      },
      // No customer details and no cost in the audit or outbox details.
      details: {
        'garments': lines.length,
        'role': role?.dbValue,
        'discountApprovedBy': ?discountApprovedBy,
      },
    );
  }

  /// This counter's number in bill numbers: setting `counter_no`, or 1 (one
  /// counter in release 1; per-counter settings come in release 2).
  Future<int> _counterNo() async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((s) => s.name.equals('counter_no'))).getSingleOrNull();
    return int.tryParse(row?.value ?? '') ?? 1;
  }

  Future<BillNumber> _nextBillNumber(
    String counterId,
    int counterNo,
    String yearLabel,
  ) async {
    final row =
        await (_db.select(_db.billSequences)..where(
              (s) =>
                  s.counterId.equals(counterId) & s.yearLabel.equals(yearLabel),
            ))
            .getSingleOrNull();
    final serial = (row?.lastSerial ?? 0) + 1;
    final number = BillNumber(
      yearLabel: yearLabel,
      counterNo: counterNo,
      serial: serial,
    );
    await _db
        .into(_db.billSequences)
        .insertOnConflictUpdate(
          BillSequencesCompanion.insert(
            counterId: counterId,
            yearLabel: yearLabel,
            lastSerial: serial,
          ),
        );
    return number;
  }

  static String? _cleanName(String? text) {
    final t = text?.trim() ?? '';
    if (t.isEmpty) {
      return null;
    }
    if (t.length > 80) {
      throw InvalidBill('the customer name is longer than 80 characters');
    }
    return t;
  }

  static String? _cleanPhone(String? text) {
    final t = text?.trim() ?? '';
    if (t.isEmpty) {
      return null;
    }
    final digits = t.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (!RegExp(r'^[0-9+\- ]+$').hasMatch(t) || digits < 7 || digits > 15) {
      throw InvalidBill('the phone number must have 7 to 15 digits');
    }
    return t;
  }
}

final class _Found {
  const _Found(this.item);
  final SaleItem item;
}
