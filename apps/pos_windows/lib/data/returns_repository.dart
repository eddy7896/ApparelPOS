// Taking a garment back: look up what was sold, and save a return in ONE
// transaction (garments back in stock or marked damaged, the return, its lines,
// a credit note if that is how the refund is paid, audit, outbox). Rules are in
// core_domain (returnTiming, refundTotal, CreditNoteCode, the permission
// matrix). E-RETURN-1, E-AUDIT-1, E-AUTHZ-1. No cost is read here (a test reads
// this file's text to keep it so).
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';

/// What happens to a returned garment.
enum ReturnOutcome {
  restock('RESTOCK'),
  damaged('DAMAGED');

  const ReturnOutcome(this.dbValue);
  final String dbValue;
}

enum NotReturnableReason { notFound, notSold, alreadyReturned }

/// Thrown when a barcode cannot be returned.
final class GarmentNotReturnable implements Exception {
  GarmentNotReturnable(this.barcode, this.reason);
  final String barcode;
  final NotReturnableReason reason;
  @override
  String toString() => 'GarmentNotReturnable: $barcode ${reason.name}';
}

/// Thrown for a return that is not well formed.
final class InvalidReturn implements Exception {
  InvalidReturn(this.message);
  final String message;
  @override
  String toString() => 'InvalidReturn: $message';
}

/// Thrown when a return is outside the window and nobody approved it.
final class ReturnNeedsApproval implements Exception {
  ReturnNeedsApproval(this.barcode);
  final String barcode;
  @override
  String toString() => 'ReturnNeedsApproval: $barcode';
}

/// A sold garment that can be returned, with what it was sold for.
final class ReturnCandidate {
  const ReturnCandidate({
    required this.billLineId,
    required this.articleId,
    required this.barcode,
    required this.productName,
    required this.size,
    required this.color,
    required this.billNo,
    required this.soldAt,
    required this.netPrice,
    required this.timing,
  });
  final String billLineId;
  final String articleId;
  final String barcode;
  final String productName;
  final String size;
  final String color;
  final String billNo;
  final DateTime soldAt;

  /// What the customer paid for this garment, after markdown and discount.
  final Money netPrice;
  final ReturnTiming timing;
}

/// One garment to return, and what to do with it. A damaged garment needs a
/// note.
final class ReturnItemInput {
  const ReturnItemInput(this.barcode, this.outcome, {this.note});
  final String barcode;
  final ReturnOutcome outcome;
  final String? note;
}

/// A credit note that was issued.
final class IssuedCreditNote {
  const IssuedCreditNote({
    required this.id,
    required this.code,
    required this.amount,
    required this.issuedAt,
    required this.lastDay,
  });
  final String id;
  final String code;
  final Money amount;
  final DateTime issuedAt;
  final DateTime lastDay;
}

/// A return that was saved.
final class SavedReturn {
  const SavedReturn({
    required this.returnId,
    required this.refundMode,
    required this.total,
    required this.lines,
    this.creditNote,
  });
  final String returnId;
  final RefundMode refundMode;
  final Money total;
  final List<ReturnCandidate> lines;
  final IssuedCreditNote? creditNote;
}

class ReturnsRepository {
  ReturnsRepository(
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

  /// Looks up a garment for return. Needs `takeReturn`. Returns null for an
  /// unknown barcode; throws [GarmentNotReturnable] if it was never sold or was
  /// already returned.
  Future<ReturnCandidate?> lookup({
    required Role? role,
    required String barcode,
    int windowDays = defaultReturnWindowDays,
  }) async {
    require(role, Permission.takeReturn);
    return _find(barcode, windowDays);
  }

  Future<ReturnCandidate?> _find(String barcode, int windowDays) async {
    final art = await _db
        .customSelect(
          'SELECT id, status FROM articles WHERE barcode_value = ?',
          variables: [Variable<String>(barcode)],
        )
        .get();
    if (art.isEmpty) {
      return null;
    }
    final articleId = art.single.read<String>('id');
    if (art.single.read<String>('status') != ArticleStatus.sold.dbValue) {
      // Back in stock or damaged after an earlier return, or never sold.
      final returned = await _db
          .customSelect(
            'SELECT 1 FROM return_lines WHERE article_id = ? LIMIT 1',
            variables: [Variable<String>(articleId)],
          )
          .get();
      throw GarmentNotReturnable(
        barcode,
        returned.isEmpty
            ? NotReturnableReason.notSold
            : NotReturnableReason.alreadyReturned,
      );
    }
    // The current sale is the bill line with no return yet (every earlier sale
    // of this garment was returned). Not "the latest by time": two bills can
    // fall in the same second.
    final rows = await _db
        .customSelect(
          'SELECT l.id AS line_id, l.product_name AS name, l.size AS size, '
          'l.color AS color, l.final_paise AS net, b.bill_no AS bill_no, '
          'b.billed_at AS billed_at '
          'FROM bill_lines l JOIN bills b ON b.id = l.bill_id '
          'WHERE l.article_id = ? '
          'AND NOT EXISTS (SELECT 1 FROM return_lines r WHERE r.bill_line_id = l.id) '
          'ORDER BY b.billed_at DESC LIMIT 1',
          variables: [Variable<String>(articleId)],
        )
        .get();
    if (rows.isEmpty) {
      throw GarmentNotReturnable(barcode, NotReturnableReason.notSold);
    }
    final r = rows.first;
    final soldAt = r.read<DateTime>('billed_at');
    return ReturnCandidate(
      billLineId: r.read<String>('line_id'),
      articleId: articleId,
      barcode: barcode,
      productName: r.read<String>('name'),
      size: r.read<String>('size'),
      color: r.read<String>('color'),
      billNo: r.read<String>('bill_no'),
      soldAt: soldAt,
      netPrice: Money(r.read<int>('net')),
      timing: returnTiming(
        soldAt,
        _now().isBefore(soldAt) ? soldAt : _now(),
        windowDays: windowDays,
      ),
    );
  }

  /// Saves a return. Needs `takeReturn`. A garment past the window needs a
  /// manager or owner: either [role] has `approveLateReturn`, or an approver
  /// (role and id together) who has it. Throws [PermissionDenied],
  /// [InvalidReturn], [GarmentNotReturnable] or [ReturnNeedsApproval]; on any
  /// failure nothing at all is saved.
  Future<SavedReturn> saveReturn({
    required Role? role,
    required String cashierId,
    required List<ReturnItemInput> items,
    required RefundMode refundMode,
    Role? approverRole,
    String? approvedBy,
    int windowDays = defaultReturnWindowDays,
  }) async {
    require(role, Permission.takeReturn);
    if ((approverRole == null) != (approvedBy == null)) {
      throw ArgumentError('give both approverRole and approvedBy, or neither');
    }
    if (items.isEmpty) {
      throw InvalidReturn('a return needs at least one garment');
    }
    final seen = <String>{};
    for (final i in items) {
      if (!seen.add(i.barcode)) {
        throw InvalidReturn('${i.barcode} is in the return twice');
      }
      if (i.outcome == ReturnOutcome.damaged &&
          (i.note == null || i.note!.trim().isEmpty)) {
        throw InvalidReturn('a damaged garment needs a short note');
      }
      if ((i.note?.trim().length ?? 0) > 200) {
        throw InvalidReturn('a note is longer than 200 characters');
      }
    }
    final approved =
        can(role, Permission.approveLateReturn) ||
        can(approverRole, Permission.approveLateReturn);
    final usedApprover =
        !can(role, Permission.approveLateReturn) &&
        can(approverRole, Permission.approveLateReturn);

    final returnId = _newId();
    final at = _now();

    return _writer.run<SavedReturn>(
      action: 'sale.return',
      entityType: 'return',
      entityId: returnId,
      actor: cashierId,
      body: () async {
        final lines = <ReturnCandidate>[];
        for (final i in items) {
          final found = await _find(i.barcode, windowDays);
          if (found == null) {
            throw GarmentNotReturnable(i.barcode, NotReturnableReason.notFound);
          }
          if (found.timing == ReturnTiming.needsApproval && !approved) {
            throw ReturnNeedsApproval(i.barcode);
          }
          lines.add(found);
        }
        final total = refundTotal([for (final l in lines) l.netPrice]);

        IssuedCreditNote? note;
        if (refundMode == RefundMode.creditNote) {
          note = await _issueCreditNote(total, cashierId, at);
        }

        await _db
            .into(_db.returns)
            .insert(
              ReturnsCompanion.insert(
                id: returnId,
                cashierId: cashierId,
                approvedBy: Value(usedApprover ? approvedBy : null),
                refundMode: refundMode.dbValue,
                creditNoteId: Value(note?.id),
                totalPaise: total.paise,
                returnedAt: at,
              ),
            );
        for (var k = 0; k < items.length; k++) {
          final l = lines[k];
          final input = items[k];
          final target = input.outcome == ReturnOutcome.restock
              ? ArticleStatus.inStock
              : ArticleStatus.damaged;
          // Only a garment that is still SOLD can come back.
          final changed =
              await (_db.update(_db.articles)..where(
                    (a) =>
                        a.id.equals(l.articleId) &
                        a.status.equals(ArticleStatus.sold.dbValue),
                  ))
                  .write(
                    ArticlesCompanion(
                      status: Value(target.dbValue),
                      updatedAt: Value(at),
                    ),
                  );
          if (changed != 1) {
            throw GarmentNotReturnable(l.barcode, NotReturnableReason.notSold);
          }
          await _db
              .into(_db.returnLines)
              .insert(
                ReturnLinesCompanion.insert(
                  id: _newId(),
                  returnId: returnId,
                  billLineId: l.billLineId,
                  articleId: l.articleId,
                  refundPaise: l.netPrice.paise,
                  outcome: input.outcome.dbValue,
                  note: Value(input.note?.trim()),
                ),
              );
        }
        return SavedReturn(
          returnId: returnId,
          refundMode: refundMode,
          total: total,
          lines: lines,
          creditNote: note,
        );
      },
      // No customer details, no note text and no cost in audit or outbox.
      details: {
        'garments': items.length,
        'refundMode': refundMode.dbValue,
        'role': role?.dbValue,
        'approvedBy': ?(usedApprover ? approvedBy : null),
      },
    );
  }

  Future<IssuedCreditNote> _issueCreditNote(
    Money amount,
    String cashierId,
    DateTime at,
  ) async {
    if (amount.paise <= 0) {
      throw InvalidReturn('a credit note needs an amount above zero');
    }
    final counter = (await _db.select(_db.counters).get()).first;
    final setting = await (_db.select(
      _db.appSettings,
    )..where((s) => s.name.equals('counter_no'))).getSingleOrNull();
    final counterNo = int.tryParse(setting?.value ?? '') ?? 1;
    final last = await _db
        .customSelect(
          'SELECT COALESCE(MAX(serial), 0) AS s FROM credit_notes WHERE counter_id = ?',
          variables: [Variable<String>(counter.id)],
        )
        .getSingle();
    final code = CreditNoteCode(
      counterNo: counterNo,
      serial: last.read<int>('s') + 1,
    );
    final id = _newId();
    await _db
        .into(_db.creditNotes)
        .insert(
          CreditNotesCompanion.insert(
            id: id,
            code: code.value,
            counterId: counter.id,
            serial: code.serial,
            amountPaise: amount.paise,
            issuedAt: at,
            issuedBy: cashierId,
          ),
        );
    return IssuedCreditNote(
      id: id,
      code: code.value,
      amount: amount,
      issuedAt: at,
      lastDay: creditNoteLastDay(at),
    );
  }
}
