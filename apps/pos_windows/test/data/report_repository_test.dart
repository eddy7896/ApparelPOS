// P2-7b: the owner's daily report. Totals must agree with the daybook, a day is
// an India calendar day, and only manager and owner may read it (profit reads
// cost). E-MONEY-1, E-AUTHZ-1, E-AUDIT-1.
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/report_repository.dart';
import 'package:pos_windows/data/returns_repository.dart';
import 'package:pos_windows/data/sales_repository.dart';
import 'package:pos_windows/data/shift_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late StockRepository stock;
  late SalesRepository sales;
  late ReturnsRepository returns;
  late ShiftRepository shifts;
  late ReportRepository report;
  late DateTime now;
  late List<String> kurta; // 4 x 499.00, cost 200.00
  late List<String> jeans; // 3 x 1299.00, cost 600.00
  var n = 0;
  String newId() => 'id-${++n}';
  final day = ShopDay(2026, 11, 20);
  final nextDay = ShopDay(2026, 11, 21);

  Future<List<String>> codesOf(String batchId) async => [
    for (final r
        in await db
            .customSelect(
              'SELECT barcode_value FROM articles WHERE batch_id = ? ORDER BY barcode_value',
              variables: [Variable<String>(batchId)],
            )
            .get())
      r.read<String>('barcode_value'),
  ];

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 11, 19, 12);
    n = 0;
    stock = StockRepository(db, newId: newId, now: () => now);
    sales = SalesRepository(db, newId: newId, now: () => now);
    returns = ReturnsRepository(db, newId: newId, now: () => now);
    shifts = ShiftRepository(db, newId: newId, now: () => now);
    report = ReportRepository(db);
    await stock.ensureCounter();
    for (final id in ['cashier-1', 'manager-1']) {
      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              id: id,
              name: id,
              role: id.startsWith('cashier') ? 'CASHIER' : 'MANAGER',
              credentialHash: 'x',
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    final a = await stock.receivePurchase(
      role: Role.owner,
      draft: PurchaseDraft(
        supplier: 'S',
        style: 'Cotton Kurta',
        lines: [
          PurchaseLine(
            size: 'M',
            color: 'Blue',
            quantity: 4,
            cost: Money(20000),
            mrp: Money(49900),
          ),
        ],
      ),
    );
    final b = await stock.receivePurchase(
      role: Role.owner,
      draft: PurchaseDraft(
        supplier: 'S',
        style: 'Denim Jeans',
        lines: [
          PurchaseLine(
            size: 'L',
            color: 'Black',
            quantity: 3,
            cost: Money(60000),
            mrp: Money(129900),
          ),
        ],
      ),
    );
    kurta = await codesOf(a.batchId);
    jeans = await codesOf(b.batchId);
    now = DateTime.utc(2026, 11, 20, 4); // 09:30 India on the 20th
    await shifts.openShift(
      role: Role.cashier,
      userId: 'cashier-1',
      counts: {Denomination.note500: 4},
    );
  });
  tearDown(() => db.close());

  Future<void> sell(
    DateTime at,
    List<BillLineInput> lines,
    List<Payment> pay, {
    Role role = Role.cashier,
  }) async {
    now = at;
    await sales.saveBill(
      role: role,
      cashierId: 'cashier-1',
      lines: lines,
      payments: pay,
    );
  }

  Future<void> giveBack(
    DateTime at,
    List<String> codes,
    RefundMode mode, {
    ReturnOutcome outcome = ReturnOutcome.restock,
    Role role = Role.cashier,
  }) async {
    now = at;
    await returns.saveReturn(
      role: role,
      cashierId: 'cashier-1',
      items: [
        for (final c in codes)
          ReturnItemInput(
            c,
            outcome,
            note: outcome == ReturnOutcome.damaged ? 'torn' : null,
          ),
      ],
      refundMode: mode,
    );
  }

  /// The busy day (20 Nov) described in the comments of each expectation.
  Future<void> busyDay() async {
    await sell(
      DateTime.utc(2026, 11, 20, 5),
      [BillLineInput(kurta[0]), BillLineInput(jeans[0])],
      [Payment(PaymentMode.cash, Money(200000))],
    ); // 1798.00, change 202.00
    await sell(
      DateTime.utc(2026, 11, 20, 6),
      [BillLineInput(kurta[1], discount: PriceCut.percentBp(1000))],
      [Payment(PaymentMode.upi, Money(44910))],
    );
    await sell(
      DateTime.utc(2026, 11, 20, 7),
      [BillLineInput(jeans[1], markdown: PriceCut.percentBp(2000))],
      [Payment(PaymentMode.card, Money(103920))],
      role: Role.manager,
    ); // markdown 259.80
    await giveBack(DateTime.utc(2026, 11, 20, 8), [
      kurta[0],
    ], RefundMode.cash); // 499.00, restocked
    await giveBack(
      DateTime.utc(2026, 11, 20, 9),
      [jeans[0]],
      RefundMode.creditNote,
      outcome: ReturnOutcome.damaged,
    ); // 1299.00, damaged
  }

  group('a busy day', () {
    test('sales, bills, garments, discounts and markdowns', () async {
      await busyDay();
      final r = await report.dailyReport(role: Role.owner, day: day);
      expect(r.billCount, 3);
      expect(r.garmentsSold, 4);
      expect(r.salesTotal, Money(328630));
      expect(r.discountsTotal, Money(4990));
      expect(r.markdownsTotal, Money(25980));
    });
    test('money by mode and refunds by mode come from the daybook', () async {
      await busyDay();
      final r = await report.dailyReport(role: Role.owner, day: day);
      expect(r.moneyIn, {
        PaymentMode.cash: Money(179800),
        PaymentMode.upi: Money(44910),
        PaymentMode.card: Money(103920),
      });
      expect(r.refundsByMode, {
        RefundMode.cash: Money(49900),
        RefundMode.creditNote: Money(129900),
      });
    });
    test('bills and sales by hour of the shop day (India time)', () async {
      await busyDay(); // bills at 10:30, 11:30 and 12:30 India
      final r = await report.dailyReport(role: Role.owner, day: day);
      expect(r.billsByHour.length, 24);
      expect(r.salesByHour.length, 24);
      expect(r.billsByHour[10], 1);
      expect(r.billsByHour[11], 1);
      expect(r.billsByHour[12], 1);
      expect(r.billsByHour.reduce((a, b) => a + b), 3);
      expect(r.salesByHour[10], Money(179800));
      expect(r.salesByHour[11], Money(44910));
      expect(r.salesByHour[12], Money(103920));
      expect(
        r.salesByHour.fold<Money>(Money.zero, (a, b) => a + b),
        r.salesTotal,
      );
    });

    test('a bill just before India midnight is in hour 23, just after in hour 0 of the next day', () async {
      await sell(
        DateTime.utc(2026, 11, 20, 18, 29, 59),
        [BillLineInput(kurta[0])],
        [Payment(PaymentMode.cash, Money(49900))],
      );
      await sell(
        DateTime.utc(2026, 11, 20, 18, 30),
        [BillLineInput(kurta[1])],
        [Payment(PaymentMode.cash, Money(49900))],
      );
      final a = await report.dailyReport(role: Role.owner, day: day);
      final b = await report.dailyReport(role: Role.owner, day: nextDay);
      expect(a.billsByHour[23], 1);
      expect(a.billsByHour[0], 0);
      expect(b.billsByHour[0], 1);
      expect(b.billsByHour[23], 0);
    });

    test('returns taken and the net sales', () async {
      await busyDay();
      final r = await report.dailyReport(role: Role.owner, day: day);
      expect(r.returnCount, 2);
      expect(r.garmentsReturned, 2);
      expect(r.refundsTotal, Money(179800));
      expect(r.netSales, Money(148830));
    });
    test('the totals match the daybook', () async {
      await busyDay();
      final r = await report.dailyReport(role: Role.owner, day: day);
      expect(r.moneyInTotal, r.salesTotal);
      expect(r.refundsPaidTotal, r.refundsTotal);
      expect(r.matchesDaybook, isTrue);
    });
    test('an extra daybook row that no bill explains is caught', () async {
      await busyDay();
      final shift = (await db.customSelect('SELECT id FROM shifts').getSingle())
          .read<String>('id');
      await db.customStatement(
        "INSERT INTO daybook (id, at, shift_id, kind, amount_paise, ref_type, ref_id) "
        "VALUES ('stray', ${DateTime.utc(2026, 11, 20, 10).millisecondsSinceEpoch ~/ 1000}, '$shift', 'SALE_CASH', 100, 'bill', 'none')",
      );
      expect(
        (await report.dailyReport(role: Role.owner, day: day)).matchesDaybook,
        isFalse,
      );
    });
    test('a refund row that no return explains is caught', () async {
      await busyDay();
      final shift = (await db.customSelect('SELECT id FROM shifts').getSingle())
          .read<String>('id');
      await db.customStatement(
        "INSERT INTO daybook (id, at, shift_id, kind, amount_paise, ref_type, ref_id) "
        "VALUES ('stray', ${DateTime.utc(2026, 11, 20, 10).millisecondsSinceEpoch ~/ 1000}, '$shift', 'REFUND_CASH', -100, 'return', 'none')",
      );
      expect(
        (await report.dailyReport(role: Role.owner, day: day)).matchesDaybook,
        isFalse,
      );
    });
    test('a bill paid partly by credit note still matches', () async {
      await busyDay();
      final credit =
          (await db.customSelect('SELECT code FROM credit_notes').getSingle())
              .read<String>('code');
      now = DateTime.utc(2026, 11, 20, 10);
      await sales.saveBill(
        role: Role.cashier,
        cashierId: 'cashier-1',
        lines: [BillLineInput(kurta[2])],
        payments: const [],
        creditNotes: [CreditNoteUseInput(credit, Money(49900))],
      );
      final r = await report.dailyReport(role: Role.owner, day: day);
      expect(r.moneyIn[PaymentMode.creditNote], Money(49900));
      expect(r.matchesDaybook, isTrue);
    });
    test('profit: net sales minus cost of garments sold, restocked cost taken back, damaged kept', () async {
      await busyDay();
      final r = await report.dailyReport(role: Role.owner, day: day);
      // sold cost: kurta x2 (400.00) + jeans x2 (1200.00) = 1600.00
      // restocked return: kurta (200.00); the damaged jeans keep their cost
      expect(r.costOfGoods, Money(140000));
      expect(r.profit, Money(8830));
    });
    test(
      'top styles: the style with more money wins a tie on garments',
      () async {
        await busyDay();
        final r = await report.dailyReport(role: Role.owner, day: day);
        expect(
          [for (final s in r.topStyles) s.name],
          ['Denim Jeans', 'Cotton Kurta'],
        );
        expect(r.topStyles[0].quantity, 2);
        expect(r.topStyles[0].value, Money(233820));
        expect(r.topStyles[1].value, Money(94810));
      },
    );
    test('manager reads the same report as the owner', () async {
      await busyDay();
      final o = await report.dailyReport(role: Role.owner, day: day);
      final m = await report.dailyReport(role: Role.manager, day: day);
      expect(m.salesTotal, o.salesTotal);
      expect(m.profit, o.profit);
    });
  });

  group('the day is an India calendar day', () {
    test('a bill one second before India midnight is on the 20th, at midnight on the 21st', () async {
      await sell(
        DateTime.utc(2026, 11, 20, 18, 29, 59),
        [BillLineInput(kurta[0])],
        [Payment(PaymentMode.cash, Money(49900))],
      );
      await sell(
        DateTime.utc(2026, 11, 20, 18, 30),
        [BillLineInput(kurta[1])],
        [Payment(PaymentMode.cash, Money(49900))],
      );
      expect(
        (await report.dailyReport(role: Role.owner, day: day)).billCount,
        1,
      );
      expect(
        (await report.dailyReport(role: Role.owner, day: nextDay)).billCount,
        1,
      );
    });
    test('the first instant of the 20th India day is on the 20th', () async {
      now = DateTime.utc(2026, 11, 19, 18, 30);
      // a shift must exist for the cashier; it was opened at 04:00 on the 20th, so open a second user's
      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              id: 'cashier-2',
              name: 'c2',
              role: 'CASHIER',
              credentialHash: 'x',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await shifts.openShift(
        role: Role.cashier,
        userId: 'cashier-2',
        counts: const {},
      );
      await sales.saveBill(
        role: Role.cashier,
        cashierId: 'cashier-2',
        lines: [BillLineInput(kurta[0])],
        payments: [Payment(PaymentMode.cash, Money(49900))],
      );
      expect(
        (await report.dailyReport(role: Role.owner, day: day)).billCount,
        1,
      );
      expect(
        (await report.dailyReport(
          role: Role.owner,
          day: day.previous,
        )).billCount,
        0,
      );
    });
    test('a return on the next day belongs to the next day, with its cost taken back there', () async {
      await sell(
        DateTime.utc(2026, 11, 20, 5),
        [BillLineInput(kurta[0])],
        [Payment(PaymentMode.cash, Money(49900))],
      );
      await sell(
        DateTime.utc(2026, 11, 21, 5),
        [BillLineInput(kurta[1])],
        [Payment(PaymentMode.cash, Money(49900))],
      );
      await giveBack(DateTime.utc(2026, 11, 21, 6), [
        kurta[0],
      ], RefundMode.cash);
      final d1 = await report.dailyReport(role: Role.owner, day: day);
      expect(d1.returnCount, 0);
      expect(d1.netSales, Money(49900));
      expect(d1.profit, Money(29900));
      final d2 = await report.dailyReport(role: Role.owner, day: nextDay);
      expect(d2.returnCount, 1);
      expect(d2.refundsTotal, Money(49900));
      expect(d2.netSales, Money.zero);
      // sold one kurta (cost 200) and took one back into stock (cost 200)
      expect(d2.costOfGoods, Money.zero);
      expect(d2.profit, Money.zero);
      expect(d2.matchesDaybook, isTrue);
    });
    test('an empty day is all zeros, not an error', () async {
      final r = await report.dailyReport(
        role: Role.owner,
        day: ShopDay(2026, 1, 1),
      );
      expect(r.billCount, 0);
      expect(r.salesTotal, Money.zero);
      expect(r.billsByHour, List<int>.filled(24, 0));
      expect(r.salesByHour, List<Money>.filled(24, Money.zero));
      expect(r.moneyIn, isEmpty);
      expect(r.refundsByMode, isEmpty);
      expect(r.topStyles, isEmpty);
      expect(r.shiftCloses, isEmpty);
      expect(r.profit, Money.zero);
      expect(r.matchesDaybook, isTrue);
    });
  });

  group('cash variance per shift', () {
    test(
      'lists the shifts closed that day with expected, counted and variance',
      () async {
        await sell(
          DateTime.utc(2026, 11, 20, 5),
          [BillLineInput(kurta[0])],
          [Payment(PaymentMode.cash, Money(49900))],
        );
        now = DateTime.utc(2026, 11, 20, 12);
        // expected 2000.00 + 499.00 = 2499.00; count 2500.00: over 1.00
        await shifts.closeShift(
          role: Role.cashier,
          userId: 'cashier-1',
          counts: {Denomination.note500: 5},
        );
        final r = await report.dailyReport(role: Role.owner, day: day);
        expect(r.shiftCloses.length, 1);
        expect(r.shiftCloses.single.expected, Money(249900));
        expect(r.shiftCloses.single.counted, Money(250000));
        expect(r.shiftCloses.single.variance.kind, VarianceKind.over);
        expect(
          (await report.dailyReport(
            role: Role.owner,
            day: nextDay,
          )).shiftCloses,
          isEmpty,
        );
      },
    );
  });

  group('who may read it', () {
    test('a cashier and nobody are refused', () async {
      await expectLater(
        report.dailyReport(role: Role.cashier, day: day),
        throwsA(isA<PermissionDenied>()),
      );
      await expectLater(
        report.dailyReport(role: null, day: day),
        throwsA(isA<PermissionDenied>()),
      );
    });
  });
}
