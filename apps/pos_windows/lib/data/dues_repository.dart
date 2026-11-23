// Pay later (udhaar), owner 2026-11-23: customers who owe money, bill by bill,
// taking a payment against what they owe, and writing a debt off. A bill is
// left unpaid by SalesRepository.saveBill (with a manager's or owner's
// approval); a return reduces what is owed on its bill (ReturnsRepository).
// The rules are in core_domain (dues_rules). Money taken goes in the daybook as
// DUES_CASH, DUES_UPI and DUES_CARD, so the drawer and the reports see it.
// Nothing here reads cost (E-AUTHZ-1). Rows are never edited (E-AUDIT-1).
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';
import 'shift_repository.dart';

/// Thrown when a payment or write-off is not well formed.
final class InvalidDues implements Exception {
  InvalidDues(this.message);
  final String message;
  @override
  String toString() => 'InvalidDues: $message';
}

/// Thrown when the customer owes nothing, or no such customer.
final class NothingOwed implements Exception {
  @override
  String toString() => 'NothingOwed';
}

/// What is still owed on one bill: the sum of its ledger rows.
Future<Money> billOutstanding(AppDatabase db, String billId) async {
  final r = await db
      .customSelect(
        'SELECT COALESCE(SUM(amount_paise), 0) AS v FROM dues_ledger WHERE bill_id = ?',
        variables: [Variable<String>(billId)],
      )
      .getSingle();
  return Money(r.read<int>('v'));
}

/// A customer and what they owe.
final class CustomerDues {
  const CustomerDues({
    required this.id,
    required this.name,
    required this.phone,
    required this.owed,
    required this.oldestBillAt,
    required this.billCount,
  });
  final String id;
  final String name;

  /// The phone key (the last 10 digits).
  final String phone;
  final Money owed;

  /// The oldest bill still owing, or null when nothing is owed.
  final DateTime? oldestBillAt;

  /// How many bills still owe something.
  final int billCount;
}

/// A bill with something still owed on it.
final class DueBillInfo {
  const DueBillInfo({
    required this.billId,
    required this.billNo,
    required this.billedAt,
    required this.total,
    required this.outstanding,
  });
  final String billId;
  final String billNo;
  final DateTime billedAt;
  final Money total;
  final Money outstanding;
}

/// One line of a customer's history.
final class DuesHistoryLine {
  const DuesHistoryLine({
    required this.at,
    required this.kind,
    required this.amount,
    required this.billNo,
    this.note,
  });
  final DateTime at;

  /// OWED, PAYMENT, RETURN_OFFSET or WRITE_OFF.
  final String kind;

  /// Positive adds to what is owed, negative takes off.
  final Money amount;
  final String billNo;
  final String? note;
}

/// A customer's page: what they owe bill by bill, and the history.
final class CustomerDetail {
  const CustomerDetail({
    required this.customer,
    required this.bills,
    required this.history,
  });
  final CustomerDues customer;

  /// Bills still owing, oldest first.
  final List<DueBillInfo> bills;

  /// Everything, newest first.
  final List<DuesHistoryLine> history;
}

/// What a payment did.
final class DuesPaymentResult {
  const DuesPaymentResult({
    required this.receiptId,
    required this.applied,
    required this.change,
    required this.remaining,
    required this.byMode,
  });
  final String receiptId;

  /// Taken off what the customer owes.
  final Money applied;

  /// Cash handed back.
  final Money change;

  /// Still owed after this payment.
  final Money remaining;
  final Map<PaymentMode, Money> byMode;
}

class DuesRepository {
  DuesRepository(
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

  static const _customerSql =
      'SELECT c.id AS id, c.name AS name, c.phone AS phone, '
      'COALESCE(SUM(l.amount_paise), 0) AS owed '
      'FROM customers c LEFT JOIN dues_ledger l ON l.customer_id = c.id ';

  /// Customers by what they owe, most first; with [onlyOwing] false, customers
  /// who owe nothing now are listed too. Needs `sell` (the counter takes the
  /// payments).
  Future<List<CustomerDues>> customers({
    required Role? role,
    bool onlyOwing = true,
  }) async {
    require(role, Permission.sell);
    final rows = await _db
        .customSelect(
          '$_customerSql GROUP BY c.id '
          '${onlyOwing ? 'HAVING owed > 0 ' : ''}'
          'ORDER BY owed DESC, c.name',
        )
        .get();
    final out = <CustomerDues>[];
    for (final r in rows) {
      out.add(await _toCustomer(r));
    }
    return out;
  }

  Future<CustomerDues> _toCustomer(QueryRow r) async {
    final id = r.read<String>('id');
    final bills = await _dueBills(id);
    return CustomerDues(
      id: id,
      name: r.read<String>('name'),
      phone: r.read<String>('phone'),
      owed: Money(r.read<int>('owed')),
      oldestBillAt: bills.isEmpty ? null : bills.first.billedAt,
      billCount: bills.length,
    );
  }

  /// Bills still owing for [customerId], oldest first.
  Future<List<DueBillInfo>> _dueBills(String customerId) async {
    final rows = await _db
        .customSelect(
          'SELECT b.id AS id, b.bill_no AS no, b.billed_at AS at, '
          'b.total_paise AS total, SUM(l.amount_paise) AS out '
          'FROM dues_ledger l JOIN bills b ON b.id = l.bill_id '
          'WHERE l.customer_id = ? GROUP BY b.id HAVING out > 0 '
          'ORDER BY b.billed_at, b.rowid',
          variables: [Variable<String>(customerId)],
        )
        .get();
    return [
      for (final r in rows)
        DueBillInfo(
          billId: r.read<String>('id'),
          billNo: r.read<String>('no'),
          billedAt: r.read<DateTime>('at').toUtc(),
          total: Money(r.read<int>('total')),
          outstanding: Money(r.read<int>('out')),
        ),
    ];
  }

  /// The customer with this phone (any way it is typed), or null. Needs `sell`.
  Future<CustomerDues?> findByPhone({
    required Role? role,
    required String phone,
  }) async {
    require(role, Permission.sell);
    final key = customerPhoneKey(phone);
    if (key == null) {
      return null;
    }
    final rows = await _db
        .customSelect(
          '$_customerSql WHERE c.phone = ? GROUP BY c.id',
          variables: [Variable<String>(key)],
        )
        .get();
    return rows.isEmpty ? null : _toCustomer(rows.single);
  }

  /// A customer's bills still owing and their history. Needs `sell`. Null for
  /// an unknown customer.
  Future<CustomerDetail?> detail({
    required Role? role,
    required String customerId,
  }) async {
    require(role, Permission.sell);
    final rows = await _db
        .customSelect(
          '$_customerSql WHERE c.id = ? GROUP BY c.id',
          variables: [Variable<String>(customerId)],
        )
        .get();
    if (rows.isEmpty) {
      return null;
    }
    final hist = await _db
        .customSelect(
          'SELECT l.at AS at, l.kind AS kind, l.amount_paise AS amt, '
          'b.bill_no AS no, l.note AS note '
          'FROM dues_ledger l JOIN bills b ON b.id = l.bill_id '
          'WHERE l.customer_id = ? ORDER BY l.at DESC, l.rowid DESC',
          variables: [Variable<String>(customerId)],
        )
        .get();
    return CustomerDetail(
      customer: await _toCustomer(rows.single),
      bills: await _dueBills(customerId),
      history: [
        for (final r in hist)
          DuesHistoryLine(
            at: r.read<DateTime>('at').toUtc(),
            kind: r.read<String>('kind'),
            amount: Money(r.read<int>('amt')),
            billNo: r.read<String>('no'),
            note: r.read<String?>('note'),
          ),
      ],
    );
  }

  /// Everything owed by everybody now. Needs `sell`.
  Future<Money> totalOwed({required Role? role}) async {
    require(role, Permission.sell);
    final r = await _db
        .customSelect(
          'SELECT COALESCE(SUM(amount_paise), 0) AS v FROM dues_ledger',
        )
        .getSingle();
    return Money(r.read<int>('v'));
  }

  /// Takes what the customer hands over (cash, UPI, card) off what they owe,
  /// the oldest bill first. Cash over what is owed is change; UPI and card may
  /// not be more than is owed. Needs `sell` and an open shift (the money goes
  /// into that shift's drawer and reports). Throws [PermissionDenied],
  /// [InvalidDues], [NothingOwed], [NonCashOverpayment] or [NoOpenShift]; on
  /// any failure nothing is saved.
  Future<DuesPaymentResult> receivePayment({
    required Role? role,
    required String userId,
    required String customerId,
    required List<Payment> payments,
  }) async {
    require(role, Permission.sell);
    if (payments.isEmpty) {
      throw InvalidDues('type how much the customer pays');
    }
    if (payments.any((p) => p.mode == PaymentMode.creditNote)) {
      throw InvalidDues('a credit note cannot pay what is owed');
    }
    final receiptId = _newId();
    final at = _now();
    return _writer.run<DuesPaymentResult>(
      action: 'dues.receive',
      entityType: 'dues_receipt',
      entityId: receiptId,
      actor: userId,
      body: () async {
        final bills = await _dueBills(customerId);
        final owed = _owedOn(bills);
        if (owed.paise <= 0) {
          throw NothingOwed();
        }
        final settlement = settle(owed, payments);
        final applied = owed - settlement.due;
        final shiftId = await requireOpenShiftId(_db, userId);
        Money mode(PaymentMode m) => settlement.byMode[m] ?? Money.zero;
        await _db
            .into(_db.duesReceipts)
            .insert(
              DuesReceiptsCompanion.insert(
                id: receiptId,
                customerId: customerId,
                at: at,
                shiftId: shiftId,
                receivedBy: userId,
                cashPaise: payments
                    .where((p) => p.mode == PaymentMode.cash)
                    .fold<int>(0, (a, p) => a + p.amount.paise),
                upiPaise: mode(PaymentMode.upi).paise,
                cardPaise: mode(PaymentMode.card).paise,
                changePaise: settlement.change.paise,
                appliedPaise: applied.paise,
              ),
            );
        for (final e in settlement.byMode.entries) {
          await addDaybookRow(
            _db,
            id: _newId(),
            at: at,
            shiftId: shiftId,
            kind: 'DUES_${e.key.dbValue.toUpperCase()}',
            amountPaise: e.value.paise,
            refType: 'dues',
            refId: receiptId,
          );
        }
        for (final share in allocateDues([
          for (final b in bills) DueBill(b.billId, b.outstanding),
        ], applied)) {
          await _db
              .into(_db.duesLedger)
              .insert(
                DuesLedgerCompanion.insert(
                  id: _newId(),
                  customerId: customerId,
                  billId: share.billId,
                  kind: 'PAYMENT',
                  amountPaise: -share.amount.paise,
                  receiptId: Value(receiptId),
                  at: at,
                  actorId: userId,
                ),
              );
        }
        return DuesPaymentResult(
          receiptId: receiptId,
          applied: applied,
          change: settlement.change,
          remaining: settlement.due,
          byMode: settlement.byMode,
        );
      },
      details: {'applied': payments.length, 'customerId': customerId},
    );
  }

  /// Closes [amount] of what the customer owes without being paid, the oldest
  /// bill first, with a reason. Owner only (`writeOffDebt`). Throws
  /// [PermissionDenied], [InvalidDues] or [NothingOwed].
  Future<void> writeOff({
    required Role? role,
    required String actorId,
    required String customerId,
    required Money amount,
    required String note,
  }) async {
    require(role, Permission.writeOffDebt);
    final reason = note.trim();
    if (reason.isEmpty) {
      throw InvalidDues('say why the debt is written off');
    }
    if (reason.length > 200) {
      throw InvalidDues('the reason is longer than 200 characters');
    }
    if (amount.paise <= 0) {
      throw InvalidDues('the amount must be above zero');
    }
    final at = _now();
    await _writer.run<void>(
      action: 'dues.writeoff',
      entityType: 'customer',
      entityId: customerId,
      actor: actorId,
      details: {'amountPaise': amount.paise},
      body: () async {
        final bills = await _dueBills(customerId);
        final owed = _owedOn(bills);
        if (owed.paise <= 0) {
          throw NothingOwed();
        }
        if (amount > owed) {
          throw InvalidDues('that is more than the customer owes');
        }
        for (final share in allocateDues([
          for (final b in bills) DueBill(b.billId, b.outstanding),
        ], amount)) {
          await _db
              .into(_db.duesLedger)
              .insert(
                DuesLedgerCompanion.insert(
                  id: _newId(),
                  customerId: customerId,
                  billId: share.billId,
                  kind: 'WRITE_OFF',
                  amountPaise: -share.amount.paise,
                  at: at,
                  actorId: actorId,
                  note: Value(reason),
                ),
              );
        }
      },
    );
  }

  static Money _owedOn(List<DueBillInfo> bills) =>
      bills.fold<Money>(Money.zero, (sum, b) => sum + b.outstanding);
}
