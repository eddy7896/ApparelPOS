// The owner's analytics: sales by day against the period before, bills by hour
// (India time), money by payment mode, best sellers, sell-through and slow
// movers, cash closes, and profit for manager and owner only. E-MONEY-1,
// E-AUTHZ-1.
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/analytics_repository.dart';
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
  late AnalyticsRepository analytics;
  late DateTime now;
  late List<String> kurta; // 10 x 499.00, cost 200.00, bought 60 days ago
  late List<String> jeans; // 4 x 1299.00, cost 600.00, bought 10 days ago
  var n = 0;
  String newId() => 'id-${++n}';

  // "Today" in these tests is Sat 21 Nov 2026 at 12:00 India.
  final today = DateTime.utc(2026, 11, 21, 6, 30);

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
    n = 0;
    now = today.subtract(const Duration(days: 60));
    stock = StockRepository(db, newId: newId, now: () => now);
    sales = SalesRepository(db, newId: newId, now: () => now);
    returns = ReturnsRepository(db, newId: newId, now: () => now);
    shifts = ShiftRepository(db, newId: newId, now: () => now);
    await stock.ensureCounter();
    for (final id in ['cashier-1', 'manager-1']) {
      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              id: id,
              name: id == 'cashier-1' ? 'Asha' : 'Meera',
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
            quantity: 10,
            cost: Money(20000),
            mrp: Money(49900),
          ),
        ],
      ),
    );
    now = today.subtract(const Duration(days: 10));
    final b = await stock.receivePurchase(
      role: Role.owner,
      draft: PurchaseDraft(
        supplier: 'S',
        style: 'Denim Jeans',
        lines: [
          PurchaseLine(
            size: 'L',
            color: 'Black',
            quantity: 4,
            cost: Money(60000),
            mrp: Money(129900),
          ),
        ],
      ),
    );
    kurta = await codesOf(a.batchId);
    jeans = await codesOf(b.batchId);
    now = today.subtract(const Duration(days: 30));
    await shifts.openShift(
      role: Role.cashier,
      userId: 'cashier-1',
      counts: const {},
    );
    now = today;
    analytics = AnalyticsRepository(db, now: () => now);
  });
  tearDown(() => db.close());

  Future<void> sell(
    DateTime at,
    List<String> codes, {
    PaymentMode mode = PaymentMode.cash,
    Money? pay,
  }) async {
    final saved = now;
    now = at;
    var total = Money.zero;
    final lines = [for (final c in codes) BillLineInput(c)];
    for (final c in codes) {
      total += kurta.contains(c) ? Money(49900) : Money(129900);
    }
    await sales.saveBill(
      role: Role.cashier,
      cashierId: 'cashier-1',
      lines: lines,
      payments: [Payment(mode, pay ?? total)],
    );
    now = saved;
  }

  Future<AnalyticsOverview> overview(
    AnalyticsRange range, {
    Role role = Role.manager,
  }) => analytics.overview(role: role, range: range);

  DayTotal dayOf(AnalyticsOverview o, int d) =>
      o.current.singleWhere((x) => x.day == ShopDay(2026, 11, d));

  group('sales each day', () {
    test('a week and the week before, oldest first, ending today', () async {
      final o = await overview(AnalyticsRange.week);
      expect(o.current.length, 7);
      expect(o.previous.length, 7);
      expect(o.current.first.day, ShopDay(2026, 11, 15));
      expect(o.current.last.day, ShopDay(2026, 11, 21));
      expect(o.previous.first.day, ShopDay(2026, 11, 8));
      expect(o.previous.last.day, ShopDay(2026, 11, 14));
    });

    test('totals per day, with days without sales at zero', () async {
      await sell(DateTime.utc(2026, 11, 21, 5), [kurta[0], kurta[1]]);
      await sell(DateTime.utc(2026, 11, 19, 8), [jeans[0]]);
      final o = await overview(AnalyticsRange.week);
      expect(dayOf(o, 21).sales, Money(99800));
      expect(dayOf(o, 21).bills, 1);
      expect(dayOf(o, 19).sales, Money(129900));
      expect(dayOf(o, 20).sales, Money.zero);
      expect(dayOf(o, 20).bills, 0);
      expect(o.netTotal, Money(229700));
      expect(o.billCount, 2);
    });

    test('refunds come off the day the return was made', () async {
      await sell(DateTime.utc(2026, 11, 19, 8), [kurta[0]]);
      now = DateTime.utc(2026, 11, 21, 5);
      await returns.saveReturn(
        role: Role.cashier,
        cashierId: 'cashier-1',
        items: [ReturnItemInput(kurta[0], ReturnOutcome.restock)],
        refundMode: RefundMode.cash,
      );
      now = today;
      final o = await overview(AnalyticsRange.week);
      expect(dayOf(o, 19).net, Money(49900));
      expect(dayOf(o, 21).refunds, Money(49900));
      expect(dayOf(o, 21).net, Money(-49900));
      expect(o.netTotal, Money.zero);
      expect(o.returnCount, 1);
    });

    test(
      'a day is an India day: 23:59 is still that day, 00:00 the next',
      () async {
        await sell(DateTime.utc(2026, 11, 19, 18, 29), [
          kurta[0],
        ]); // 23:59 on the 19th
        await sell(DateTime.utc(2026, 11, 19, 18, 30), [
          kurta[1],
        ]); // 00:00 on the 20th
        final o = await overview(AnalyticsRange.week);
        expect(dayOf(o, 19).bills, 1);
        expect(dayOf(o, 20).bills, 1);
      },
    );

    test(
      'the period before is compared and the change is in basis points',
      () async {
        await sell(DateTime.utc(2026, 11, 20, 5), [
          kurta[0],
          kurta[1],
        ]); // this week 998
        await sell(DateTime.utc(2026, 11, 12, 5), [
          kurta[2],
        ]); // the week before 499
        final o = await overview(AnalyticsRange.week);
        expect(o.previousNetTotal, Money(49900));
        expect(o.change, 10000); // doubled: +100%
      },
    );

    test('nothing in the period before gives no change figure', () async {
      await sell(DateTime.utc(2026, 11, 20, 5), [kurta[0]]);
      expect((await overview(AnalyticsRange.week)).change, isNull);
    });

    test(
      'a month covers 30 days; a sale 25 days ago is in it but not in the week',
      () async {
        await sell(DateTime.utc(2026, 10, 27, 5), [
          kurta[0],
        ]); // 25 days before the 21st
        final week = await overview(AnalyticsRange.week);
        final month = await overview(AnalyticsRange.month);
        expect(week.billCount, 0);
        expect(month.current.length, 30);
        expect(month.previous.length, 30);
        expect(month.billCount, 1);
        expect(month.netTotal, Money(49900));
      },
    );
  });

  group('bills by hour (India time)', () {
    test('04:30 UTC is 10 am and 18:30 UTC is midnight', () async {
      await sell(DateTime.utc(2026, 11, 20, 4, 30), [kurta[0]]);
      await sell(DateTime.utc(2026, 11, 20, 4, 59), [kurta[1]]);
      await sell(DateTime.utc(2026, 11, 20, 18, 30), [kurta[2]]);
      final o = await overview(AnalyticsRange.week);
      expect(o.billsByHour.length, 24);
      expect(o.billsByHour[10], 2);
      expect(o.billsByHour[0], 1);
      expect(o.billsByHour.reduce((a, b) => a + b), 3);
      expect(peakHour(o.billsByHour), 10);
    });

    test('only the range is counted', () async {
      await sell(DateTime.utc(2026, 11, 5, 5), [kurta[0]]); // 16 days ago
      expect(
        (await overview(AnalyticsRange.week)).billsByHour
            .reduce((a, b) => a + b),
        0,
      );
      expect(
        (await overview(AnalyticsRange.month)).billsByHour
            .reduce((a, b) => a + b),
        1,
      );
    });
  });

  group('money by payment mode', () {
    test('adds up what the daybook says', () async {
      await sell(DateTime.utc(2026, 11, 20, 5), [kurta[0]]);
      await sell(DateTime.utc(2026, 11, 20, 6), [
        kurta[1],
      ], mode: PaymentMode.upi);
      await sell(DateTime.utc(2026, 11, 20, 7), [
        jeans[0],
      ], mode: PaymentMode.card);
      final o = await overview(AnalyticsRange.week);
      expect(o.moneyIn[PaymentMode.cash], Money(49900));
      expect(o.moneyIn[PaymentMode.upi], Money(49900));
      expect(o.moneyIn[PaymentMode.card], Money(129900));
      final total = o.moneyIn.values.fold(Money.zero, (a, b) => a + b);
      expect(total, o.netTotal);
    });
  });

  group('best sellers', () {
    test('quantity and value per style in the range', () async {
      await sell(DateTime.utc(2026, 11, 20, 5), [kurta[0], kurta[1], jeans[0]]);
      await sell(DateTime.utc(2026, 11, 20, 6), [kurta[2]]);
      final o = await overview(AnalyticsRange.week);
      final k = o.styles.singleWhere((s) => s.name == 'Cotton Kurta');
      final j = o.styles.singleWhere((s) => s.name == 'Denim Jeans');
      expect(k.quantity, 3);
      expect(k.value, Money(149700));
      expect(j.quantity, 1);
      expect(j.value, Money(129900));
    });
  });

  group('how much of each style has sold', () {
    test(
      'counts sold garments of all bought, and flags a slow mover',
      () async {
        await sell(DateTime.utc(2026, 11, 20, 5), [
          kurta[0],
          kurta[1],
        ]); // 2 of 10 = 20%
        final o = await overview(AnalyticsRange.week);
        final k = o.sellThrough.singleWhere((s) => s.name == 'Cotton Kurta');
        expect(k.bought, 10);
        expect(k.sold, 2);
        expect(k.percent, 20);
        expect(k.unsold, 8);
        expect(k.slow, isTrue); // 60 days old, 20% sold
      },
    );

    test('a style that is too new is never slow', () async {
      final o = await overview(AnalyticsRange.week);
      final j = o.sellThrough.singleWhere((s) => s.name == 'Denim Jeans');
      expect(j.sold, 0);
      expect(j.slow, isFalse); // bought 10 days ago
    });

    test('a style that has sold enough is not slow', () async {
      for (var i = 0; i < 3; i++) {
        await sell(DateTime.utc(2026, 11, 20, 5 + i), [kurta[i]]);
      }
      final o = await overview(AnalyticsRange.week);
      expect(
        o.sellThrough.singleWhere((s) => s.name == 'Cotton Kurta').slow,
        isFalse,
      ); // 30%
    });

    test('a damaged garment is not counted as sold', () async {
      await sell(DateTime.utc(2026, 11, 20, 5), [kurta[0]]);
      now = DateTime.utc(2026, 11, 21, 5);
      await returns.saveReturn(
        role: Role.cashier,
        cashierId: 'cashier-1',
        items: [ReturnItemInput(kurta[0], ReturnOutcome.damaged, note: 'torn')],
        refundMode: RefundMode.cash,
      );
      now = today;
      final o = await overview(AnalyticsRange.week);
      expect(
        o.sellThrough.singleWhere((s) => s.name == 'Cotton Kurta').sold,
        0,
      );
    });

    test('a restocked garment is not counted as sold', () async {
      await sell(DateTime.utc(2026, 11, 20, 5), [kurta[0]]);
      now = DateTime.utc(2026, 11, 21, 5);
      await returns.saveReturn(
        role: Role.cashier,
        cashierId: 'cashier-1',
        items: [ReturnItemInput(kurta[0], ReturnOutcome.restock)],
        refundMode: RefundMode.cash,
      );
      now = today;
      final o = await overview(AnalyticsRange.week);
      expect(
        o.sellThrough.singleWhere((s) => s.name == 'Cotton Kurta').sold,
        0,
      );
    });
  });

  group('sales by category (owner, 2026-11-23)', () {
    Future<void> categorise() async {
      await db.customStatement(
        "INSERT INTO categories (id, name, created_at, updated_at) VALUES ('men', 'Men', 1700000000, 1700000000)",
      );
      await db.customStatement(
        "INSERT INTO categories (id, name, parent_id, created_at, updated_at) VALUES ('shirts', 'Shirts', 'men', 1700000000, 1700000000)",
      );
      await db.customStatement(
        "UPDATE products SET category_id = 'shirts' WHERE name = 'Cotton Kurta'",
      );
    }

    test(
      'value and garments by category, this period and the one before',
      () async {
        await categorise();
        await sell(DateTime.utc(2026, 11, 20, 5), [
          kurta[0],
          kurta[1],
        ]); // this week, categorised
        await sell(DateTime.utc(2026, 11, 20, 6), [
          jeans[0],
        ]); // this week, no category
        await sell(DateTime.utc(2026, 11, 12, 5), [
          kurta[2],
        ]); // the week before
        final o = await overview(AnalyticsRange.week);
        expect(o.categoryValue['shirts'], 99800);
        expect(o.categoryValue[null], 129900);
        expect(o.categoryQuantity['shirts'], 2);
        expect(o.categoryQuantity[null], 1);
        expect(o.categoryValuePrevious['shirts'], 49900);
        expect(o.categoryValuePrevious.containsKey(null), isFalse);
      },
    );

    test('the category totals add up to the sales of the range', () async {
      await categorise();
      await sell(DateTime.utc(2026, 11, 20, 5), [kurta[0], jeans[0]]);
      final o = await overview(AnalyticsRange.week);
      expect(o.categoryValue.values.fold(0, (a, b) => a + b), 49900 + 129900);
    });

    test('a style put in a category later moves its sales with it', () async {
      await sell(DateTime.utc(2026, 11, 20, 5), [kurta[0]]);
      expect((await overview(AnalyticsRange.week)).categoryValue.keys, [null]);
      await categorise();
      expect((await overview(AnalyticsRange.week)).categoryValue.keys, [
        'shirts',
      ]);
    });

    test('sell-through rows carry the category of the style', () async {
      await categorise();
      final o = await overview(AnalyticsRange.week);
      expect(
        o.sellThrough.singleWhere((s) => s.name == 'Cotton Kurta').categoryId,
        'shirts',
      );
      expect(
        o.sellThrough.singleWhere((s) => s.name == 'Denim Jeans').categoryId,
        isNull,
      );
    });
  });

  group('cash over and short', () {
    test('the last 8 closes, oldest first, with who and how much', () async {
      for (var i = 0; i < 10; i++) {
        now = DateTime.utc(2026, 11, 10 + i, 12);
        await shifts.openShift(
          role: Role.cashier,
          userId: 'manager-1',
          counts: {Denomination.note500: 2},
        );
        now = DateTime.utc(2026, 11, 10 + i, 14);
        await shifts.closeShift(
          role: Role.cashier,
          userId: 'manager-1',
          counts: {Denomination.note500: i == 9 ? 1 : 2},
        );
      }
      now = today;
      final o = await overview(AnalyticsRange.week);
      expect(o.recentCloses.length, 8);
      expect(o.recentCloses.first.closedAt, DateTime.utc(2026, 11, 12, 14));
      expect(o.recentCloses.last.closedAt, DateTime.utc(2026, 11, 19, 14));
      expect(o.recentCloses.last.cashierName, 'Meera');
      expect(
        o.recentCloses.last.variance,
        Money(-50000),
      ); // counted 500 of 1000
      expect(o.recentCloses.first.variance, Money.zero);
    });
  });

  group('trend reading', () {
    test('the insights are worked out from the current days', () async {
      await sell(DateTime.utc(2026, 11, 20, 5), [kurta[0], kurta[1]]);
      final o = await overview(AnalyticsRange.week);
      expect(o.insights.bestDay!.day, ShopDay(2026, 11, 20));
    });
  });

  group('who may see it, and profit', () {
    test('a cashier and nobody are refused', () async {
      await expectLater(
        analytics.overview(role: Role.cashier, range: AnalyticsRange.week),
        throwsA(isA<PermissionDenied>()),
      );
      await expectLater(
        analytics.overview(role: null, range: AnalyticsRange.week),
        throwsA(isA<PermissionDenied>()),
      );
    });

    test(
      'a manager and the owner see profit: net sales less cost of goods',
      () async {
        await sell(DateTime.utc(2026, 11, 20, 5), [kurta[0], jeans[0]]);
        for (final role in [Role.manager, Role.owner]) {
          final o = await overview(AnalyticsRange.week, role: role);
          // 499 + 1299 = 1798 sales, cost 200 + 600 = 800
          expect(o.profit, Money(99800));
        }
      },
    );

    test('profit agrees with the daily report added up day by day', () async {
      await sell(DateTime.utc(2026, 11, 20, 5), [kurta[0], jeans[0]]);
      await sell(DateTime.utc(2026, 11, 18, 5), [kurta[1]]);
      now = DateTime.utc(2026, 11, 21, 5);
      await returns.saveReturn(
        role: Role.cashier,
        cashierId: 'cashier-1',
        items: [ReturnItemInput(kurta[1], ReturnOutcome.restock)],
        refundMode: RefundMode.cash,
      );
      now = today;
      final report = ReportRepository(db);
      var sum = Money.zero;
      for (final d in daysEndingAt(ShopDay(2026, 11, 21), 7)) {
        sum += (await report.dailyReport(role: Role.owner, day: d)).profit!;
      }
      expect((await overview(AnalyticsRange.week)).profit, sum);
    });
  });

  group('cost stays out of everything but profit (E-AUTHZ-1)', () {
    test('the cost table is only mentioned in the profit query', () {
      final lines = File('lib/data/analytics_repository.dart')
          .readAsLinesSync();
      final hits = [
        for (var i = 0; i < lines.length; i++)
          if (RegExp(r'batch_lines|unit_cost|unitCost|batchLines')
                  .hasMatch(lines[i]) &&
              !lines[i].trimLeft().startsWith('//'))
            i,
      ];
      final profitStart = lines.indexWhere(
        (l) => l.contains('Future<Money> _profit'),
      );
      expect(hits, isNotEmpty);
      expect(hits.every((i) => i > profitStart), isTrue);
    });
  });
}
