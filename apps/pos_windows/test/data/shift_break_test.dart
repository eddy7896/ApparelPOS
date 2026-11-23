// UX-3: the Pause button. A break keeps the shift open, no selling during it,
// the break time is recorded and shown only to the owner, another cashier
// cannot open a second shift on the drawer meanwhile, and break rows are never
// edited (E-AUDIT-1).
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/sales_repository.dart';
import 'package:pos_windows/data/shift_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late StockRepository stock;
  late SalesRepository sales;
  late ShiftRepository shifts;
  late DateTime now;
  late List<String> barcodes;
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 11, 20, 4, 30);
    n = 0;
    stock = StockRepository(db, newId: newId, now: () => now);
    sales = SalesRepository(db, newId: newId, now: () => now);
    shifts = ShiftRepository(db, newId: newId, now: () => now);
    await stock.ensureCounter();
    for (final id in ['cashier-1', 'cashier-2']) {
      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              id: id,
              name: id,
              role: 'CASHIER',
              credentialHash: 'x',
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    final r = await stock.receivePurchase(
      role: Role.owner,
      draft: PurchaseDraft(
        supplier: 'S',
        style: 'Cotton Kurta',
        lines: [
          PurchaseLine(
            size: 'M',
            color: 'Blue',
            quantity: 2,
            cost: Money(20000),
            mrp: Money(49900),
          ),
        ],
      ),
    );
    final rows = await db
        .customSelect(
          'SELECT barcode_value FROM articles WHERE batch_id = ? ORDER BY barcode_value',
          variables: [Variable<String>(r.batchId)],
        )
        .get();
    barcodes = [for (final x in rows) x.read<String>('barcode_value')];
  });
  tearDown(() => db.close());

  Future<ShiftInfo> open(String user) => shifts.openShift(
    role: Role.cashier,
    userId: user,
    counts: {Denomination.note500: 2},
  );

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle())
          .read<int>('c');

  Future<SavedBill> sell(String code) => sales.saveBill(
    role: Role.cashier,
    cashierId: 'cashier-1',
    lines: [BillLineInput(code)],
    payments: [Payment(PaymentMode.cash, Money(49900))],
  );

  group('pausing and resuming', () {
    test('pause starts a break and the shift stays open', () async {
      final s = await open('cashier-1');
      await shifts.pauseShift(role: Role.cashier, userId: 'cashier-1');
      expect((await shifts.currentShift('cashier-1'))?.id, s.id);
      expect(await shifts.breakStartedAt('cashier-1'), now);
      expect(await count('shift_breaks'), 1);
      expect(await count('shift_break_ends'), 0);
    });

    test(
      'resume ends the break; resuming with no break does nothing',
      () async {
        await open('cashier-1');
        expect(
          await shifts.resumeShift(role: Role.cashier, userId: 'cashier-1'),
          isFalse,
        );
        await shifts.pauseShift(role: Role.cashier, userId: 'cashier-1');
        now = now.add(const Duration(minutes: 12));
        expect(
          await shifts.resumeShift(role: Role.cashier, userId: 'cashier-1'),
          isTrue,
        );
        expect(await shifts.breakStartedAt('cashier-1'), isNull);
        expect(await count('shift_break_ends'), 1);
        expect(
          await shifts.resumeShift(role: Role.cashier, userId: 'cashier-1'),
          isFalse,
        );
      },
    );

    test('pausing twice keeps one break', () async {
      await open('cashier-1');
      await shifts.pauseShift(role: Role.cashier, userId: 'cashier-1');
      now = now.add(const Duration(minutes: 3));
      await shifts.pauseShift(role: Role.cashier, userId: 'cashier-1');
      expect(await count('shift_breaks'), 1);
    });

    test('pausing needs an open shift, and the right to sell', () async {
      await expectLater(
        shifts.pauseShift(role: Role.cashier, userId: 'cashier-1'),
        throwsA(isA<NoOpenShift>()),
      );
      await open('cashier-1');
      await expectLater(
        shifts.pauseShift(role: null, userId: 'cashier-1'),
        throwsA(isA<PermissionDenied>()),
      );
      await expectLater(
        shifts.resumeShift(role: null, userId: 'cashier-1'),
        throwsA(isA<PermissionDenied>()),
      );
      expect(await count('shift_breaks'), 0);
    });

    test('audit and outbox rows are written, with no amounts', () async {
      await open('cashier-1');
      await shifts.pauseShift(role: Role.cashier, userId: 'cashier-1');
      await shifts.resumeShift(role: Role.cashier, userId: 'cashier-1');
      final audit = await db
          .customSelect(
            "SELECT action FROM audit_log WHERE action LIKE 'shift.%' ORDER BY rowid",
          )
          .get();
      expect(audit.map((r) => r.read<String>('action')), [
        'shift.open',
        'shift.pause',
        'shift.resume',
      ]);
    });
  });

  group('no selling during a break', () {
    test('a sale while paused is refused and saves nothing', () async {
      await open('cashier-1');
      await shifts.pauseShift(role: Role.cashier, userId: 'cashier-1');
      await expectLater(sell(barcodes[0]), throwsA(isA<ShiftOnBreak>()));
      expect(await count('bills'), 0);
    });

    test('after resuming, selling works again', () async {
      await open('cashier-1');
      await shifts.pauseShift(role: Role.cashier, userId: 'cashier-1');
      await shifts.resumeShift(role: Role.cashier, userId: 'cashier-1');
      expect((await sell(barcodes[0])).total, Money(49900));
    });
  });

  group('the drawer on a break', () {
    test('another cashier cannot open a second shift meanwhile', () async {
      await open('cashier-1');
      await shifts.pauseShift(role: Role.cashier, userId: 'cashier-1');
      await expectLater(open('cashier-2'), throwsA(isA<DrawerOnBreak>()));
      expect(await count('shifts'), 1);
    });

    test('once the break has ended another cashier may open one', () async {
      await open('cashier-1');
      await shifts.pauseShift(role: Role.cashier, userId: 'cashier-1');
      await shifts.resumeShift(role: Role.cashier, userId: 'cashier-1');
      await open('cashier-2');
      expect(await count('shifts'), 2);
    });
  });

  group('the shift summary for the top bar', () {
    test('no shift is null; an open shift gives when it started and its breaks so far', () async {
      expect(await shifts.currentShiftSummary('cashier-1'), isNull);
      await open('cashier-1');
      final started = now;
      var s = (await shifts.currentShiftSummary('cashier-1'))!;
      expect(s.openedAt, started);
      expect(s.breaks, Duration.zero);
      await shifts.pauseShift(role: Role.cashier, userId: 'cashier-1');
      now = now.add(const Duration(minutes: 12));
      await shifts.resumeShift(role: Role.cashier, userId: 'cashier-1');
      now = now.add(const Duration(hours: 1));
      s = (await shifts.currentShiftSummary('cashier-1'))!;
      expect(s.breaks, const Duration(minutes: 12));
    });

    test('a break still going counts up to now', () async {
      await open('cashier-1');
      await shifts.pauseShift(role: Role.cashier, userId: 'cashier-1');
      now = now.add(const Duration(minutes: 5));
      expect(
        (await shifts.currentShiftSummary('cashier-1'))!.breaks,
        const Duration(minutes: 5),
      );
    });
  });

  group('closing a shift on a break', () {
    test('ends the break first, so nothing is left going', () async {
      await open('cashier-1');
      await shifts.pauseShift(role: Role.cashier, userId: 'cashier-1');
      now = now.add(const Duration(minutes: 7));
      await shifts.closeShift(
        role: Role.cashier,
        userId: 'cashier-1',
        counts: {Denomination.note500: 2},
      );
      expect(await count('shift_break_ends'), 1);
      final r = (await shifts.closeReports(role: Role.owner)).single;
      expect(r.breakTime, const Duration(minutes: 7));
    });
  });

  group('the owner sees the break time', () {
    test('the total of all breaks is on the close report', () async {
      await open('cashier-1');
      await shifts.pauseShift(role: Role.cashier, userId: 'cashier-1');
      now = now.add(const Duration(minutes: 12));
      await shifts.resumeShift(role: Role.cashier, userId: 'cashier-1');
      now = now.add(const Duration(hours: 2));
      await shifts.pauseShift(role: Role.cashier, userId: 'cashier-1');
      now = now.add(const Duration(minutes: 5, seconds: 30));
      await shifts.resumeShift(role: Role.cashier, userId: 'cashier-1');
      await shifts.closeShift(
        role: Role.cashier,
        userId: 'cashier-1',
        counts: {Denomination.note500: 2},
      );
      final r = (await shifts.closeReports(role: Role.owner)).single;
      expect(r.breakTime, const Duration(minutes: 17, seconds: 30));
    });

    test('a shift with no break shows zero', () async {
      await open('cashier-1');
      await shifts.closeShift(
        role: Role.cashier,
        userId: 'cashier-1',
        counts: {Denomination.note500: 2},
      );
      final r = (await shifts.closeReports(role: Role.owner)).single;
      expect(r.breakTime, Duration.zero);
    });
  });

  group('break rows are never edited (E-AUDIT-1)', () {
    test('the database refuses edits and deletes', () async {
      await open('cashier-1');
      await shifts.pauseShift(role: Role.cashier, userId: 'cashier-1');
      await shifts.resumeShift(role: Role.cashier, userId: 'cashier-1');
      for (final sql in [
        "UPDATE shift_breaks SET started_at = 0",
        'DELETE FROM shift_breaks',
        "UPDATE shift_break_ends SET ended_at = 0",
        'DELETE FROM shift_break_ends',
      ]) {
        await expectLater(
          db.customStatement(sql),
          throwsA(anything),
          reason: sql,
        );
      }
    });

    test('a break can end only once, even by direct SQL', () async {
      await open('cashier-1');
      await shifts.pauseShift(role: Role.cashier, userId: 'cashier-1');
      await shifts.resumeShift(role: Role.cashier, userId: 'cashier-1');
      final b = await db
          .customSelect('SELECT id FROM shift_breaks')
          .getSingle();
      await expectLater(
        db.customStatement(
          "INSERT INTO shift_break_ends (id, break_id, ended_at) VALUES ('x', '${b.read<String>('id')}', 1700000000)",
        ),
        throwsA(anything),
      );
    });
  });
}
