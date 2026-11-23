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
import 'shift_repository.dart';

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
    this.markdown,
  });
  final String articleId;
  final String barcode;
  final String productName;
  final String size;
  final String color;
  final Money mrp;
  final ArticleStatus status;
  final String? soldOnBill;

  /// The markdown the shop set ahead of time on this garment's style, if one is
  /// running today and leaves something to pay. The register shows it and the
  /// bill takes it; a marked-down garment takes no cashier discount.
  final PriceCut? markdown;
}

/// One garment to bill: its barcode, an optional markdown (manager or owner
/// only) and an optional cashier discount.
final class BillLineInput {
  const BillLineInput(this.barcode, {this.markdown, this.discount});
  final String barcode;
  final PriceCut? markdown;
  final PriceCut? discount;
}

/// A credit note as the counter sees it.
final class CreditNoteInfo {
  const CreditNoteInfo({
    required this.id,
    required this.code,
    required this.amount,
    required this.balance,
    required this.issuedAt,
    required this.lastDay,
    required this.valid,
  });
  final String id;
  final String code;

  /// What it was issued for.
  final Money amount;

  /// What is left on it (amount minus what bills have taken).
  final Money balance;
  final DateTime issuedAt;
  final DateTime lastDay;

  /// False once past its last day.
  final bool valid;

  /// True when it can pay something: not expired and money left.
  bool get usable => valid && balance.paise > 0;
}

/// Money to take off a credit note for this bill.
final class CreditNoteUseInput {
  const CreditNoteUseInput(this.code, this.amount);
  final String code;
  final Money amount;
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

  /// Looks up a credit note by its code. Needs `sell`. Null if there is none.
  Future<CreditNoteInfo?> lookupCreditNote({
    required Role? role,
    required String code,
  }) async {
    require(role, Permission.sell);
    return _creditNote(code);
  }

  Future<CreditNoteInfo?> _creditNote(String code) async {
    final rows = await _db
        .customSelect(
          'SELECT n.id AS id, n.amount_paise AS amount, n.issued_at AS issued_at, '
          'n.amount_paise - COALESCE((SELECT SUM(u.amount_paise) FROM credit_note_uses u '
          'WHERE u.credit_note_id = n.id), 0) AS balance '
          'FROM credit_notes n WHERE n.code = ?',
          variables: [Variable<String>(code)],
        )
        .get();
    if (rows.isEmpty) {
      return null;
    }
    final r = rows.single;
    final issuedAt = r.read<DateTime>('issued_at');
    return CreditNoteInfo(
      id: r.read<String>('id'),
      code: code,
      amount: Money(r.read<int>('amount')),
      balance: Money(r.read<int>('balance')),
      issuedAt: issuedAt,
      lastDay: creditNoteLastDay(issuedAt),
      valid: isCreditNoteValid(issuedAt, _now()),
    );
  }

  Future<_Found?> _find(String barcode) async {
    final rows = await _db
        .customSelect(
          'SELECT a.id AS id, a.barcode_value AS barcode, a.mrp_paise AS mrp, '
          'a.status AS status, p.name AS name, v.size AS size, v.color AS color, '
          'm.percent_bp AS mbp, m.amount_paise AS mamt '
          'FROM articles a '
          'JOIN variants v ON v.id = a.variant_id '
          'JOIN products p ON p.id = v.product_id '
          'LEFT JOIN style_markdowns m ON m.product_id = p.id AND m.ends_before > ? '
          'WHERE a.barcode_value = ?',
          variables: [Variable<DateTime>(_now()), Variable<String>(barcode)],
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
    final bp = r.read<int?>('mbp');
    final amt = r.read<int?>('mamt');
    final mrp = Money(r.read<int>('mrp'));
    final stored = bp != null
        ? PriceCut.percentBp(bp)
        : amt != null
        ? PriceCut.amount(Money(amt))
        : null;
    return _Found(
      SaleItem(
        articleId: r.read<String>('id'),
        barcode: r.read<String>('barcode'),
        productName: r.read<String>('name'),
        size: r.read<String>('size'),
        color: r.read<String>('color'),
        mrp: mrp,
        status: status,
        soldOnBill: billNo,
        markdown: effectiveMarkdown(stored, mrp),
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
    List<CreditNoteUseInput> creditNotes = const [],
  }) async {
    require(role, Permission.sell);
    if (payments.any((p) => p.mode == PaymentMode.creditNote)) {
      throw InvalidBill('pay by credit note through creditNotes, not payments');
    }
    final noteCodes = <String>{};
    for (final c in creditNotes) {
      if (!noteCodes.add(c.code)) {
        throw InvalidBill('credit note ${c.code} is used twice');
      }
      if (c.amount.paise <= 0) {
        throw InvalidBill('a credit note amount must be above zero');
      }
    }
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
            markdown: input.markdown ?? item.markdown,
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
        final usedNotes = <(CreditNoteInfo, Money)>[];
        for (final c in creditNotes) {
          final info = await _creditNote(c.code);
          if (info == null) {
            throw InvalidBill('credit note ${c.code} was not found');
          }
          if (!info.valid) {
            throw InvalidBill('credit note ${c.code} has expired');
          }
          if (c.amount > info.balance) {
            throw InvalidBill(
              'credit note ${c.code} has only ${formatRupees(info.balance)} left',
            );
          }
          usedNotes.add((info, c.amount));
        }
        final creditTotal = usedNotes.fold<Money>(
          Money.zero,
          (sum, u) => sum + u.$2,
        );
        final settlement = settle(total, [
          ...payments,
          if (creditTotal.paise > 0)
            Payment(PaymentMode.creditNote, creditTotal),
        ]);
        if (!settlement.isPaid) {
          throw BillNotPaid(settlement.due);
        }

        final shiftId = await requireOpenShiftId(_db, cashierId);
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
                shiftId: Value(shiftId),
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
        for (final e in settlement.byMode.entries) {
          await addDaybookRow(
            _db,
            id: _newId(),
            at: at,
            shiftId: shiftId,
            kind: 'SALE_${e.key.dbValue.toUpperCase()}',
            amountPaise: e.value.paise,
            refType: 'bill',
            refId: billId,
          );
        }
        for (final (info, amount) in usedNotes) {
          await _db
              .into(_db.creditNoteUses)
              .insert(
                CreditNoteUsesCompanion.insert(
                  id: _newId(),
                  creditNoteId: info.id,
                  billId: billId,
                  amountPaise: amount.paise,
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
