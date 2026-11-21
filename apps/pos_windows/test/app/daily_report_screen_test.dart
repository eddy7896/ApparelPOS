// The owner's daily report screen. P2-7c.
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
import 'package:pos_windows/app/ui/daily_report_screen.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/auth_service.dart';
import 'package:pos_windows/data/report_repository.dart';
import 'package:pos_windows/data/returns_repository.dart';
import 'package:pos_windows/data/sales_repository.dart';
import 'package:pos_windows/data/shift_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

const managerPassword = 'a long passphrase';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late AuthService auth;
  late StockRepository stock;
  late SalesRepository sales;
  late ReturnsRepository returns;
  late ShiftRepository shifts;
  late SessionController session;
  late AppServices services;
  late String cashierId;
  late String managerId;
  late List<String> kurta;
  late List<String> jeans;
  // "Now" on the counter: 20 Nov 2026, 15:30 India.
  final clock = DateTime.utc(2026, 11, 20, 10);
  var now = clock;
  var n = 0;
  String newId() => 'id-${++n}';

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
    now = DateTime.utc(2026, 11, 20, 4);
    auth = AuthService(db, newId: newId);
    stock = StockRepository(db, newId: newId, now: () => now);
    sales = SalesRepository(db, newId: newId, now: () => now);
    returns = ReturnsRepository(db, newId: newId, now: () => now);
    shifts = ShiftRepository(db, newId: newId, now: () => now);
    session = SessionController(auth: auth, now: () => clock);
    await stock.ensureCounter();
    await stock.seedDefaultOptions();
    cashierId = await auth.createUser(
      name: 'Asha',
      role: Role.cashier,
      secret: '482916',
    );
    managerId = await auth.createUser(
      name: 'Meera',
      role: Role.manager,
      secret: managerPassword,
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
    await shifts.openShift(
      role: Role.cashier,
      userId: cashierId,
      counts: {Denomination.note500: 4},
    );
    services = AppServices(
      stock: stock,
      sales: sales,
      returns: returns,
      shifts: shifts,
      reports: ReportRepository(db),
      auth: auth,
      printer: const SystemLabelPrinter(),
      fonts: () async => LabelFonts(
        regular: File('assets/fonts/NotoSans-Regular.ttf').readAsBytesSync(),
        bold: File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync(),
      ),
    );
  });
  tearDown(() async {
    session.dispose();
    await db.close();
  });

  Future<void> pump(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)),
      );
      await tester.pump();
    }
  }

  Future<void> slide(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await pump(tester);
  }

  Future<void> sell(
    DateTime at,
    List<BillLineInput> lines,
    List<Payment> pay, {
    Role role = Role.cashier,
  }) async {
    now = at;
    await sales.saveBill(
      role: role,
      cashierId: cashierId,
      lines: lines,
      payments: pay,
    );
  }

  Future<void> busyDay() async {
    await sell(
      DateTime.utc(2026, 11, 20, 5),
      [BillLineInput(kurta[0]), BillLineInput(jeans[0])],
      [Payment(PaymentMode.cash, Money(200000))],
    );
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
    );
    now = DateTime.utc(2026, 11, 20, 8);
    await returns.saveReturn(
      role: Role.cashier,
      cashierId: cashierId,
      items: [ReturnItemInput(kurta[0], ReturnOutcome.restock)],
      refundMode: RefundMode.cash,
    );
    now = DateTime.utc(2026, 11, 20, 9);
    await returns.saveReturn(
      role: Role.cashier,
      cashierId: cashierId,
      items: [ReturnItemInput(jeans[0], ReturnOutcome.damaged, note: 'torn')],
      refundMode: RefundMode.creditNote,
    );
    now = DateTime.utc(2026, 11, 20, 9, 30);
    await shifts.closeShift(
      role: Role.cashier,
      userId: cashierId,
      counts: {Denomination.note500: 5},
    ); // expected 3798.00? see test
  }

  Future<void> openReport(WidgetTester tester, {bool manager = true}) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await session.start();
      await session.signIn(
        manager ? managerId : cashierId,
        manager ? managerPassword : '482916',
      );
    });
    await tester.pumpWidget(PosApp(session: session, services: services));
    await pump(tester);
    await tester.tap(find.byKey(const Key('daily-report-button')));
    await slide(tester);
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  group('getting to it', () {
    testWidgets('a manager has a Daily report button and it opens on today', (
      tester,
    ) async {
      await openReport(tester);
      expect(textOf(tester, 'day-text'), '20-11-2026');
      expect(find.byKey(const Key('report-list')), findsOneWidget);
    });
    testWidgets(
      'a cashier has no button, and the screen refuses one who reaches it',
      (tester) async {
        await tester.runAsync(() async {
          await session.start();
          await session.signIn(cashierId, '482916');
        });
        await tester.pumpWidget(
          MaterialApp(
            home: DailyReportScreen(session: session, services: services),
          ),
        );
        await pump(tester);
        expect(find.byKey(const Key('report-error')), findsOneWidget);
        expect(find.byKey(const Key('report-list')), findsNothing);
      },
    );
  });

  group('the figures', () {
    testWidgets('sales, bills, garments, discounts and markdowns', (
      tester,
    ) async {
      await tester.runAsync(busyDay);
      await openReport(tester);
      expect(textOf(tester, 'sales-total'), '₹3,286.30');
      expect(textOf(tester, 'bill-count'), '3');
      expect(textOf(tester, 'garments-sold'), '4');
      expect(textOf(tester, 'discounts'), '₹49.90');
      expect(textOf(tester, 'markdowns'), '₹259.80');
    });
    testWidgets('returns, refunds and net sales', (tester) async {
      await tester.runAsync(busyDay);
      await openReport(tester);
      expect(textOf(tester, 'return-count'), '2');
      expect(textOf(tester, 'garments-returned'), '2');
      expect(textOf(tester, 'refunds-total'), '₹1,798.00');
      expect(textOf(tester, 'net-sales'), '₹1,488.30');
    });
    testWidgets('money taken and refunds paid out, by mode', (tester) async {
      await tester.runAsync(busyDay);
      await openReport(tester);
      expect(textOf(tester, 'money-cash'), '₹1,798.00');
      expect(textOf(tester, 'money-upi'), '₹449.10');
      expect(textOf(tester, 'money-card'), '₹1,039.20');
      expect(find.byKey(const Key('money-credit_note')), findsNothing);
      expect(textOf(tester, 'money-total'), '₹3,286.30');
      expect(textOf(tester, 'refund-cash'), '₹499.00');
      expect(textOf(tester, 'refund-credit_note'), '₹1,299.00');
    });
    testWidgets(
      'the cash count shows expected, counted and short, over or exact',
      (tester) async {
        await tester.runAsync(busyDay);
        await openReport(tester);
        // expected 2000.00 + cash sales 1798.00 - cash refunds 499.00 = 3299.00; counted 2500.00
        expect(
          find.textContaining('expected ₹3,299.00, counted ₹2,500.00'),
          findsOneWidget,
        );
        expect(find.textContaining('Short ₹799.00'), findsOneWidget);
      },
    );
    testWidgets('top styles are ranked', (tester) async {
      await tester.runAsync(busyDay);
      await openReport(tester);
      expect(find.text('1. Denim Jeans'), findsOneWidget);
      expect(find.text('2. Cotton Kurta'), findsOneWidget);
      expect(textOf(tester, 'style-0'), '2 sold, ₹2,338.20');
    });
    testWidgets('profit and cost of goods are shown to a manager', (
      tester,
    ) async {
      await tester.runAsync(busyDay);
      await openReport(tester);
      expect(textOf(tester, 'cost-of-goods'), '₹1,400.00');
      expect(textOf(tester, 'profit'), '₹88.30');
    });
    testWidgets('a loss is shown as a loss with a minus sign', (tester) async {
      // one jeans sold at 20% off cost 600.00, sold for 1039.20: profit; instead sell kurta at 100% off
      await tester.runAsync(
        () => sell(
          DateTime.utc(2026, 11, 20, 5),
          [BillLineInput(kurta[0], discount: PriceCut.percentBp(10000))],
          const [],
          role: Role.manager,
        ),
      );
      await openReport(tester);
      expect(find.text('Loss'), findsOneWidget);
      expect(textOf(tester, 'profit'), '-₹200.00');
    });
    testWidgets('no warning when the daybook agrees', (tester) async {
      await tester.runAsync(busyDay);
      await openReport(tester);
      expect(find.byKey(const Key('mismatch-warning')), findsNothing);
    });
    testWidgets('a daybook row nothing explains shows a warning', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await busyDay();
        final shift =
            (await db.customSelect('SELECT id FROM shifts').getSingle())
                .read<String>('id');
        await db.customStatement(
          "INSERT INTO daybook (id, at, shift_id, kind, amount_paise, ref_type, ref_id) VALUES ('stray', ${DateTime.utc(2026, 11, 20, 6).millisecondsSinceEpoch ~/ 1000}, '$shift', 'SALE_CASH', 100, 'bill', 'none')",
        );
      });
      await openReport(tester);
      expect(find.byKey(const Key('mismatch-warning')), findsOneWidget);
    });
  });

  group('moving between days', () {
    testWidgets(
      'Next is off on today; Previous shows yesterday, which is empty',
      (tester) async {
        await tester.runAsync(busyDay);
        await openReport(tester);
        expect(
          tester
              .widget<IconButton>(find.byKey(const Key('day-next')))
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<TextButton>(find.byKey(const Key('day-today')))
              .onPressed,
          isNull,
        );
        await tester.tap(find.byKey(const Key('day-prev')));
        await pump(tester);
        expect(textOf(tester, 'day-text'), '19-11-2026');
        expect(textOf(tester, 'sales-total'), '₹0.00');
        expect(find.byKey(const Key('no-sales')), findsOneWidget);
        expect(find.byKey(const Key('no-closes')), findsOneWidget);
        expect(find.byKey(const Key('no-refunds')), findsOneWidget);
      },
    );
    testWidgets('Next and Today bring the busy day back', (tester) async {
      await tester.runAsync(busyDay);
      await openReport(tester);
      await tester.tap(find.byKey(const Key('day-prev')));
      await pump(tester);
      await tester.tap(find.byKey(const Key('day-prev')));
      await pump(tester);
      expect(textOf(tester, 'day-text'), '18-11-2026');
      await tester.tap(find.byKey(const Key('day-today')));
      await pump(tester);
      expect(textOf(tester, 'day-text'), '20-11-2026');
      expect(textOf(tester, 'sales-total'), '₹3,286.30');
      await tester.tap(find.byKey(const Key('day-prev')));
      await pump(tester);
      await tester.tap(find.byKey(const Key('day-next')));
      await pump(tester);
      expect(textOf(tester, 'day-text'), '20-11-2026');
    });
    testWidgets('India midnight splits the days', (tester) async {
      await tester.runAsync(() async {
        await sell(
          DateTime.utc(2026, 11, 19, 18, 29, 59),
          [BillLineInput(kurta[0])],
          [Payment(PaymentMode.cash, Money(49900))],
        );
        await sell(
          DateTime.utc(2026, 11, 19, 18, 30),
          [BillLineInput(kurta[1])],
          [Payment(PaymentMode.cash, Money(49900))],
        );
      });
      await openReport(tester);
      expect(textOf(tester, 'bill-count'), '1'); // 20 Nov
      await tester.tap(find.byKey(const Key('day-prev')));
      await pump(tester);
      expect(textOf(tester, 'bill-count'), '1'); // 19 Nov
    });
  });
}
