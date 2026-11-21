// Shifts and the blind cash close. A cashier opens a shift with the cash in the
// drawer (counted by notes and coins), sells and takes returns inside it, and
// ends it with a blind count: the close returns only a receipt, never the
// expected amount or the variance (E-SHIFT-1). The owner reads those through
// [closeReports], which needs the daybook permission. Rules are in core_domain
// (countCash, expectedCash, CashVariance, the permission matrix). Shift rows,
// close rows and daybook rows are never edited (E-AUDIT-1). No cost is read
// here.
import 'dart:convert';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';

/// Thrown when a sale, return or close needs an open shift and there is none.
final class NoOpenShift implements Exception {
  @override
  String toString() => 'NoOpenShift: open a shift first';
}

/// Thrown when a cashier already has an open shift.
final class ShiftAlreadyOpen implements Exception {
  ShiftAlreadyOpen(this.shiftId);
  final String shiftId;
  @override
  String toString() => 'ShiftAlreadyOpen: $shiftId';
}

/// An open shift as the counter sees it. There is no expected cash here.
final class ShiftInfo {
  const ShiftInfo({
    required this.id,
    required this.cashierId,
    required this.openedAt,
  });
  final String id;
  final String cashierId;
  final DateTime openedAt;
}

/// One closed shift for the owner.
final class ShiftCloseReport {
  const ShiftCloseReport({
    required this.shiftId,
    required this.cashierName,
    required this.openedAt,
    required this.closedAt,
    required this.opening,
    required this.expected,
    required this.counted,
    required this.variance,
  });
  final String shiftId;
  final String cashierName;
  final DateTime openedAt;
  final DateTime closedAt;
  final Money opening;
  final Money expected;
  final Money counted;
  final CashVariance variance;
}

/// The id of [userId]'s open shift, for sales and returns made inside it.
/// Throws [NoOpenShift] when there is none.
Future<String> requireOpenShiftId(AppDatabase db, String userId) async {
  final rows = await db
      .customSelect(
        'SELECT s.id AS id FROM shifts s WHERE s.cashier_id = ? '
        'AND NOT EXISTS (SELECT 1 FROM shift_closes c WHERE c.shift_id = s.id) '
        'ORDER BY s.opened_at DESC LIMIT 1',
        variables: [Variable<String>(userId)],
      )
      .get();
  if (rows.isEmpty) {
    throw NoOpenShift();
  }
  return rows.first.read<String>('id');
}

/// Writes one daybook row (call inside the sale or return transaction).
Future<void> addDaybookRow(
  AppDatabase db, {
  required String id,
  required DateTime at,
  required String shiftId,
  required String kind,
  required int amountPaise,
  required String refType,
  required String refId,
}) => db
    .into(db.daybook)
    .insert(
      DaybookCompanion.insert(
        id: id,
        at: at,
        shiftId: shiftId,
        kind: kind,
        amountPaise: amountPaise,
        refType: refType,
        refId: refId,
      ),
    );

String _countJson(Map<Denomination, int> counts) => jsonEncode({
  for (final e in counts.entries)
    if (e.value > 0) e.key.dbValue: e.value,
});

class ShiftRepository {
  ShiftRepository(
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

  /// The open shift of [userId] (one with no close row), or null.
  Future<ShiftInfo?> currentShift(String userId) async {
    final rows = await _db
        .customSelect(
          'SELECT s.id AS id, s.opened_at AS opened_at FROM shifts s '
          'WHERE s.cashier_id = ? '
          'AND NOT EXISTS (SELECT 1 FROM shift_closes c WHERE c.shift_id = s.id) '
          'ORDER BY s.opened_at DESC LIMIT 1',
          variables: [Variable<String>(userId)],
        )
        .get();
    if (rows.isEmpty) {
      return null;
    }
    return ShiftInfo(
      id: rows.first.read<String>('id'),
      cashierId: userId,
      openedAt: rows.first.read<DateTime>('opened_at').toUtc(),
    );
  }

  /// How many shifts are open right now (anyone's): a backup follows a close
  /// only when this is zero.
  Future<int> openShiftCount() async =>
      (await _db
              .customSelect(
                'SELECT COUNT(*) AS c FROM shifts s '
                'WHERE NOT EXISTS (SELECT 1 FROM shift_closes c WHERE c.shift_id = s.id)',
              )
              .getSingle())
          .read<int>('c');

  /// True when [userId] has an open shift that was opened on an earlier shop
  /// day (India time): it must be closed before selling (owner, 2026-11-21).
  Future<bool> hasStaleShift(String userId) async {
    final s = await currentShift(userId);
    if (s == null) {
      return false;
    }
    String day(DateTime d) {
      final l = d.toUtc().add(shopUtcOffset);
      return '${l.year}-${l.month}-${l.day}';
    }

    return day(s.openedAt) != day(_now());
  }

  /// Opens a shift with the drawer cash [counts]. Needs `sell` (anyone who
  /// sells). Throws [PermissionDenied], [ShiftAlreadyOpen] or [ArgumentError]
  /// (a bad count).
  Future<ShiftInfo> openShift({
    required Role? role,
    required String userId,
    required Map<Denomination, int> counts,
  }) async {
    require(role, Permission.sell);
    final opening = countCash(counts);
    final id = _newId();
    final at = _now();
    return _writer.run<ShiftInfo>(
      action: 'shift.open',
      entityType: 'shift',
      entityId: id,
      actor: userId,
      body: () async {
        final existing = await currentShift(userId);
        if (existing != null) {
          throw ShiftAlreadyOpen(existing.id);
        }
        final counter = (await _db.select(_db.counters).get()).first;
        await _db
            .into(_db.shifts)
            .insert(
              ShiftsCompanion.insert(
                id: id,
                cashierId: userId,
                counterId: counter.id,
                openedAt: at,
                openingPaise: opening.paise,
                openingCount: _countJson(counts),
              ),
            );
        return ShiftInfo(id: id, cashierId: userId, openedAt: at);
      },
      details: {'openingPaise': opening.paise},
    );
  }

  /// The blind close: counts the drawer, stores expected cash and the variance
  /// for the owner, and returns only a receipt. Needs `closeShift`. Throws
  /// [PermissionDenied], [NoOpenShift] or [ArgumentError] (a bad count).
  Future<ShiftCloseReceipt> closeShift({
    required Role? role,
    required String userId,
    required Map<Denomination, int> counts,
  }) async {
    require(role, Permission.closeShift);
    final counted = countCash(counts);
    final at = _now();
    final closeId = _newId();
    final shift = await currentShift(userId);
    if (shift == null) {
      throw NoOpenShift();
    }
    return _writer.run<ShiftCloseReceipt>(
      action: 'shift.close',
      entityType: 'shift',
      entityId: shift.id,
      actor: userId,
      body: () async {
        final fresh = await currentShift(userId);
        if (fresh == null || fresh.id != shift.id) {
          throw NoOpenShift();
        }
        final opening = Money(
          (await _db
                  .customSelect(
                    'SELECT opening_paise AS p FROM shifts WHERE id = ?',
                    variables: [Variable<String>(shift.id)],
                  )
                  .getSingle())
              .read<int>('p'),
        );
        Future<int> sum(String kind) async =>
            (await _db
                    .customSelect(
                      'SELECT COALESCE(SUM(amount_paise), 0) AS s FROM daybook '
                      'WHERE shift_id = ? AND kind = ?',
                      variables: [
                        Variable<String>(shift.id),
                        Variable<String>(kind),
                      ],
                    )
                    .getSingle())
                .read<int>('s');
        final cashSales = Money(await sum('SALE_CASH'));
        final cashRefunds = Money(-await sum('REFUND_CASH'));
        final expected = expectedCash(
          opening: opening,
          cashSales: cashSales,
          cashRefunds: cashRefunds,
        );
        final variance = CashVariance(expected: expected, counted: counted);
        await _db
            .into(_db.shiftCloses)
            .insert(
              ShiftClosesCompanion.insert(
                id: closeId,
                shiftId: shift.id,
                closedAt: at,
                countedPaise: counted.paise,
                expectedPaise: expected.paise,
                variancePaise: variance.difference.paise,
                countDetail: _countJson(counts),
              ),
            );
        return ShiftCloseReceipt(shiftId: shift.id);
      },
      // The variance goes to the owner (outbox), never back to the cashier.
      details: {'countedPaise': counted.paise},
    );
  }

  /// Closed shifts with expected cash and variance, newest first. Needs
  /// `viewDaybook` (manager, owner): a cashier must never see these.
  Future<List<ShiftCloseReport>> closeReports({required Role? role}) async {
    require(role, Permission.viewDaybook);
    final rows = await _db
        .customSelect(
          'SELECT s.id AS id, u.name AS name, s.opened_at AS opened_at, '
          's.opening_paise AS opening, c.closed_at AS closed_at, '
          'c.counted_paise AS counted, c.expected_paise AS expected '
          'FROM shift_closes c JOIN shifts s ON s.id = c.shift_id '
          'JOIN users u ON u.id = s.cashier_id '
          'ORDER BY c.closed_at DESC, c.id DESC',
        )
        .get();
    return [
      for (final r in rows)
        ShiftCloseReport(
          shiftId: r.read<String>('id'),
          cashierName: r.read<String>('name'),
          openedAt: r.read<DateTime>('opened_at').toUtc(),
          closedAt: r.read<DateTime>('closed_at').toUtc(),
          opening: Money(r.read<int>('opening')),
          expected: Money(r.read<int>('expected')),
          counted: Money(r.read<int>('counted')),
          variance: CashVariance(
            expected: Money(r.read<int>('expected')),
            counted: Money(r.read<int>('counted')),
          ),
        ),
    ];
  }
}
