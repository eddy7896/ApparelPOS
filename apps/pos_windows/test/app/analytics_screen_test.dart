// The analytics screen: numbers, charts and plain readings for the manager and
// owner (the mock-up's board 8). The numbers come from AnalyticsRepository,
// which has its own tests; this checks what is shown and what can be tried.
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/app/app.dart';
import 'package:pos_windows/app/label_printer.dart';
import 'package:pos_windows/app/services.dart';
import 'package:pos_windows/app/session_controller.dart';
import 'package:pos_windows/app/ui/analytics_screen.dart';
import 'package:pos_windows/data/analytics_repository.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/auth_service.dart';
import 'package:pos_windows/data/report_repository.dart';
import 'package:pos_windows/data/returns_repository.dart';
import 'package:pos_windows/data/sales_repository.dart';
import 'package:pos_windows/data/shift_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late AuthService auth;
  late ShiftRepository shifts;
  late SalesRepository sales;
  late ReturnsRepository returns;
  late SessionController session;
  late String ownerId;
  late String ashaId;
  late List<String> kurta; // 10 x 499, bought 60 days ago
  late List<String> jeans; // 4 x 1299, bought 10 days ago
  late DateTime now;
  var n = 0;
  String newId() => 'id-${++n}';
  final today = DateTime.utc(2026, 11, 21, 6, 30); // Sat 21 Nov, 12:00 India

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
    auth = AuthService(db, newId: newId);
    final stock = StockRepository(db, newId: newId, now: () => now);
    shifts = ShiftRepository(db, newId: newId, now: () => now);
    sales = SalesRepository(db, newId: newId, now: () => now);
    returns = ReturnsRepository(db, newId: newId, now: () => now);
    session = SessionController(auth: auth, now: () => today);
    await stock.ensureCounter();
    ownerId = await auth.createUser(
      name: 'Meera',
      role: Role.owner,
      secret: 'a long passphrase',
    );
    ashaId = await auth.createUser(
      name: 'Asha',
      role: Role.cashier,
      secret: '482916',
    );
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
      userId: ashaId,
      counts: const {},
    );
    now = today;
  });
  tearDown(() async {
    session.dispose();
    await db.close();
  });

  Future<void> sell(
    DateTime at,
    List<String> codes, {
    PaymentMode mode = PaymentMode.cash,
  }) async {
    final saved = now;
    now = at;
    var total = Money.zero;
    for (final c in codes) {
      total += kurta.contains(c) ? Money(49900) : Money(129900);
    }
    await sales.saveBill(
      role: Role.cashier,
      cashierId: ashaId,
      lines: [for (final c in codes) BillLineInput(c)],
      payments: [Payment(mode, total)],
    );
    now = saved;
  }

  Future<void> pump(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)),
      );
      await tester.pump();
    }
  }

  AppServices services() => AppServices(
    stock: StockRepository(db, newId: newId),
    sales: sales,
    returns: returns,
    shifts: shifts,
    reports: ReportRepository(db),
    auth: auth,
    analytics: AnalyticsRepository(db, now: () => today),
    printer: const SystemLabelPrinter(),
    fonts: () async => LabelFonts(
      regular: File('assets/fonts/NotoSans-Regular.ttf').readAsBytesSync(),
      bold: File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync(),
    ),
  );

  Future<void> openScreen(WidgetTester tester, {double width = 1500}) async {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await session.start();
      await session.signIn(ownerId, 'a long passphrase');
    });
    await tester.pumpWidget(PosApp(session: session, services: services()));
    await pump(tester);
    await tester.tap(find.byKey(const Key('analytics-button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await pump(tester);
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  Future<void> busyWeek() async {
    await sell(DateTime.utc(2026, 11, 20, 5), [
      kurta[0],
      kurta[1],
    ]); // 998 at 10:30
    await sell(DateTime.utc(2026, 11, 20, 6), [
      jeans[0],
    ], mode: PaymentMode.upi); // 1299
    await sell(DateTime.utc(2026, 11, 12, 5), [
      kurta[2],
    ]); // the week before: 499
  }

  group('getting there', () {
    testWidgets('the owner reaches it from the left menu', (tester) async {
      await openScreen(tester);
      expect(find.text('Analytics'), findsWidgets);
      expect(find.byKey(const Key('kpi-net')), findsOneWidget);
    });

    testWidgets('without the analytics service the menu item is not shown', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1500, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        await session.start();
        await session.signIn(ownerId, 'a long passphrase');
      });
      final s = services();
      await tester.pumpWidget(
        PosApp(
          session: session,
          services: AppServices(
            stock: s.stock,
            sales: s.sales,
            returns: s.returns,
            shifts: s.shifts,
            reports: s.reports,
            auth: s.auth,
            printer: s.printer,
            fonts: s.fonts,
          ),
        ),
      );
      await pump(tester);
      expect(find.byKey(const Key('analytics-button')), findsNothing);
    });

    testWidgets('a cashier who reaches the screen anyway is refused', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await session.start();
        await session.signIn(ashaId, '482916');
      });
      await tester.pumpWidget(
        MaterialApp(
          home: AnalyticsScreen(session: session, services: services()),
        ),
      );
      await pump(tester);
      expect(find.byKey(const Key('analytics-error')), findsOneWidget);
      expect(find.byKey(const Key('kpi-net')), findsNothing);
    });
  });

  group('the numbers', () {
    testWidgets('start empty and say so', (tester) async {
      await openScreen(tester);
      expect(textOf(tester, 'kpi-net'), '₹0.00');
      expect(textOf(tester, 'kpi-bills'), '0');
      expect(find.byKey(const Key('insight-none')), findsOneWidget);
      expect(find.byKey(const Key('modes-empty')), findsOneWidget);
      expect(find.byKey(const Key('sellers-empty')), findsOneWidget);
      expect(find.byKey(const Key('closes-empty')), findsOneWidget);
    });

    testWidgets('net sales, bills, average bill, returns and profit', (
      tester,
    ) async {
      await busyWeek();
      await openScreen(tester);
      expect(textOf(tester, 'kpi-net'), '₹2,297.00');
      expect(textOf(tester, 'kpi-bills'), '2');
      expect(textOf(tester, 'kpi-avg'), 'average bill ₹1,148.50');
      expect(textOf(tester, 'kpi-returns'), '0.0%');
      // sales 2297, cost 200 + 200 + 600 = 1000
      expect(textOf(tester, 'kpi-profit'), '₹1,297.00');
    });

    testWidgets('the change against the week before is stated in words', (
      tester,
    ) async {
      await busyWeek();
      await openScreen(tester);
      expect(textOf(tester, 'kpi-change'), 'Up 360.3% on the week before');
    });

    testWidgets('a fall against the week before says Down, with a down arrow', (
      tester,
    ) async {
      await sell(DateTime.utc(2026, 11, 12, 5), [
        kurta[0],
        kurta[1],
      ]); // 998 before
      await sell(DateTime.utc(2026, 11, 20, 5), [kurta[2]]); // 499 now
      await openScreen(tester);
      expect(textOf(tester, 'kpi-change'), 'Down 50.0% on the week before');
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
    });

    testWidgets('no earlier sales means no percentage is invented', (
      tester,
    ) async {
      await sell(DateTime.utc(2026, 11, 20, 5), [kurta[0]]);
      await openScreen(tester);
      expect(textOf(tester, 'kpi-change'), 'No earlier sales to compare with');
    });

    testWidgets('the date range is spelled out', (tester) async {
      await openScreen(tester);
      expect(
        textOf(tester, 'range-text'),
        'Sun 15 Nov to Sat 21 Nov, compared with Sun 8 Nov to Sat 14 Nov',
      );
    });

    testWidgets('Last 30 days brings in older sales', (tester) async {
      await sell(DateTime.utc(2026, 10, 27, 5), [kurta[0]]); // 25 days ago
      await openScreen(tester);
      expect(textOf(tester, 'kpi-bills'), '0');
      await tester.tap(find.byKey(const Key('range-month')));
      await pump(tester);
      expect(textOf(tester, 'kpi-bills'), '1');
      expect(textOf(tester, 'kpi-net'), '₹499.00');
      expect(
        textOf(tester, 'range-text'),
        startsWith('Fri 23 Oct to Sat 21 Nov'),
      );
    });
  });

  group('sales each day', () {
    testWidgets('tapping the chart shows that day with the day before it', (
      tester,
    ) async {
      await busyWeek();
      await openScreen(tester);
      expect(find.byKey(const Key('trend-tooltip')), findsNothing);
      final rect = tester.getRect(find.byKey(const Key('trend-chart')));
      // the last day sits at the right end of the plot
      await tester.tapAt(Offset(rect.right - 12 - 1, rect.top + 100));
      await tester.pump();
      expect(find.byKey(const Key('trend-tooltip')), findsOneWidget);
      expect(textOf(tester, 'tip-day'), 'Sat 21 Nov');
      expect(textOf(tester, 'tip-net'), '₹0.00');
      // the day with sales: 20 Nov is the second to last point
      final plotW = rect.width - 56 - 12;
      await tester.tapAt(
        Offset(rect.left + 56 + plotW * 5 / 6, rect.top + 100),
      );
      await tester.pump();
      expect(textOf(tester, 'tip-day'), 'Fri 20 Nov');
      expect(textOf(tester, 'tip-net'), '₹2,297.00');
      expect(textOf(tester, 'tip-bills'), '2 bills');
      expect(textOf(tester, 'tip-previous'), '₹0.00');
    });

    testWidgets('the same numbers are there as a table', (tester) async {
      await busyWeek();
      await openScreen(tester);
      await tester.tap(find.byKey(const Key('trend-table-toggle')));
      await tester.pump();
      expect(find.byKey(const Key('trend-chart')), findsNothing);
      expect(find.byKey(const Key('trend-table')), findsOneWidget);
      expect(find.text('₹2,297.00'), findsWidgets);
      expect(find.text('Fri 20 Nov'), findsOneWidget);
      await tester.tap(find.byKey(const Key('trend-table-toggle')));
      await tester.pump();
      expect(find.byKey(const Key('trend-chart')), findsOneWidget);
    });
  });

  group('what the days say', () {
    testWidgets('best day, trend, busiest time and the strongest weekday', (
      tester,
    ) async {
      await busyWeek();
      await sell(DateTime.utc(2026, 11, 16, 5), [
        kurta[3],
      ]); // an earlier, smaller day
      await openScreen(tester);
      expect(
        textOf(tester, 'insight-best-day'),
        'Best day: Fri 20 Nov, ₹2,297.00.',
      );
      expect(textOf(tester, 'insight-hour'), 'Busiest time: 10 am to 11 am.');
      expect(textOf(tester, 'insight-trend'), contains('rising'));
      expect(
        textOf(tester, 'insight-weekday'),
        contains('Fridays are your strongest'),
      );
    });
  });

  group('busiest hours', () {
    testWidgets('the readout starts on the peak and follows a tap', (
      tester,
    ) async {
      await busyWeek();
      await openScreen(tester);
      expect(
        textOf(tester, 'hours-readout'),
        startsWith('Busiest: 10 am to 11 am, 1 bills'),
      );
      await tester.tap(find.byKey(const Key('hour-11')));
      await tester.pump();
      expect(textOf(tester, 'hours-readout'), '11 am to 12 pm: 1 bills');
      await tester.tap(find.byKey(const Key('hour-15')));
      await tester.pump();
      expect(textOf(tester, 'hours-readout'), '3 pm to 4 pm: 0 bills');
    });
  });

  group('how customers paid and best sellers', () {
    testWidgets('payment modes are ranked with their share', (tester) async {
      await busyWeek();
      await openScreen(tester);
      expect(find.byKey(const Key('mode-UPI')), findsOneWidget);
      expect(find.byKey(const Key('mode-Cash')), findsOneWidget);
      expect(find.text('56%'), findsOneWidget); // 1299 of 2297
      expect(find.text('43%'), findsOneWidget); // 998 of 2297
      final upi = tester.getTopLeft(find.byKey(const Key('mode-UPI'))).dy;
      final cash = tester.getTopLeft(find.byKey(const Key('mode-Cash'))).dy;
      expect(upi, lessThan(cash)); // the larger one first
    });

    testWidgets('shares are worked out against the money taken', (
      tester,
    ) async {
      await sell(DateTime.utc(2026, 11, 20, 5), [kurta[0]]);
      await sell(DateTime.utc(2026, 11, 20, 6), [
        kurta[1],
      ], mode: PaymentMode.upi);
      await openScreen(tester);
      expect(find.text('50%'), findsNWidgets(2));
    });

    testWidgets('best sellers switch between garments and sales', (
      tester,
    ) async {
      await busyWeek();
      await openScreen(tester);
      // by garments: kurta 2, jeans 1
      expect(find.text('2 sold'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('seller-Cotton Kurta'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('seller-Denim Jeans'))).dy,
        ),
      );
      await tester.tap(find.byKey(const Key('sellers-by-value')));
      await tester.pump();
      // by sales: jeans 1299 beats kurta 998
      expect(
        tester.getTopLeft(find.byKey(const Key('seller-Denim Jeans'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('seller-Cotton Kurta'))).dy,
        ),
      );
      expect(find.text('₹1,299.00'), findsWidgets);
    });
  });

  group('how much of each style has sold, and slow movers', () {
    testWidgets('percent sold, and a slow mover is named with a warning', (
      tester,
    ) async {
      await busyWeek(); // kurta: 3 of 10 sold = 30%? busyWeek sells kurta x3
      await openScreen(tester);
      expect(find.byKey(const Key('through-Cotton Kurta')), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
      expect(
        find.byKey(const Key('slow-Cotton Kurta')),
        findsNothing,
      ); // 30% is enough
      expect(find.byKey(const Key('through-Denim Jeans')), findsOneWidget);
      expect(
        find.byKey(const Key('slow-Denim Jeans')),
        findsNothing,
      ); // too new
    });

    testWidgets('an old style that has barely sold is a slow mover', (
      tester,
    ) async {
      await sell(DateTime.utc(2026, 11, 20, 5), [kurta[0]]); // 1 of 10 = 10%
      await openScreen(tester);
      expect(find.byKey(const Key('slow-Cotton Kurta')), findsOneWidget);
      expect(find.textContaining('Slow mover: 9 left'), findsOneWidget);
      expect(
        textOf(tester, 'insight-slow'),
        '1 style is a slow mover: Cotton Kurta.',
      );
    });

    testWidgets('the rule is written on the card', (tester) async {
      await openScreen(tester);
      expect(
        find.textContaining('30 days or more with under 25% sold'),
        findsOneWidget,
      );
    });
  });

  group('cash over and short', () {
    testWidgets('shows who closed, how much over or short, and exact', (
      tester,
    ) async {
      Future<void> close(int day, int notes) async {
        now = DateTime.utc(2026, 11, day, 12);
        await shifts.closeShift(
          role: Role.cashier,
          userId: ashaId,
          counts: {Denomination.note500: notes},
        );
      }

      now = DateTime.utc(2026, 11, 14, 5);
      // the shift opened in setUp has an empty drawer; close it exact
      await close(14, 0);
      now = DateTime.utc(2026, 11, 15, 5);
      await shifts.openShift(
        role: Role.cashier,
        userId: ashaId,
        counts: {Denomination.note500: 2},
      );
      await close(15, 1); // counted 500 of 1000: short 500
      now = DateTime.utc(2026, 11, 16, 5);
      await shifts.openShift(
        role: Role.cashier,
        userId: ashaId,
        counts: {Denomination.note500: 2},
      );
      await close(16, 3); // counted 1500 of 1000: over 500
      now = today;
      await openScreen(tester);
      expect(find.byKey(const Key('close-0')), findsOneWidget);
      expect(find.text('Exact'), findsOneWidget);
      expect(find.text('-₹500.00'), findsOneWidget);
      expect(find.text('+₹500.00'), findsOneWidget);
      expect(find.text('Asha'), findsNWidgets(3));
    });
  });

  group('cost', () {
    testWidgets('no garment cost is shown, only profit', (tester) async {
      await busyWeek();
      await openScreen(tester);
      expect(find.textContaining('Cost'), findsNothing);
      expect(find.textContaining('cost'), findsNothing);
      expect(find.text('₹200.00'), findsNothing);
    });
  });

  testWidgets('a narrow window still lays out without errors', (tester) async {
    await busyWeek();
    await openScreen(tester, width: 800);
    expect(find.byKey(const Key('kpi-net')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
