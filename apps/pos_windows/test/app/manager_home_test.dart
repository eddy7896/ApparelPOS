// UX-4: Manager Mode home. A rail with every place, and a Today page with a
// greeting, the day so far and the shifts. No cost or profit on this page.
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
  late List<String> barcodes;
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    auth = AuthService(db, newId: newId);
    final stock = StockRepository(db, newId: newId);
    shifts = ShiftRepository(db, newId: newId);
    sales = SalesRepository(db, newId: newId);
    returns = ReturnsRepository(db, newId: newId);
    session = SessionController(auth: auth);
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

  Future<void> open(WidgetTester tester, {double width = 1500}) async {
    tester.view.physicalSize = Size(width, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await session.start();
      await session.signIn(ownerId, 'a long passphrase');
    });
    await tester.pumpWidget(
      PosApp(
        session: session,
        services: AppServices(
          stock: StockRepository(db, newId: newId),
          sales: sales,
          returns: returns,
          shifts: shifts,
          reports: ReportRepository(db),
          auth: auth,
          printer: const SystemLabelPrinter(),
          fonts: () async => LabelFonts(
            regular: File('assets/fonts/NotoSans-Regular.ttf')
                .readAsBytesSync(),
            bold: File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync(),
          ),
        ),
      ),
    );
    await pump(tester);
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  testWidgets('greets by name with the shop date', (tester) async {
    await open(tester);
    expect(textOf(tester, 'home-greeting'), endsWith(', Meera'));
    expect(textOf(tester, 'home-greeting'), startsWith('Good '));
    final local = DateTime.now().toUtc().add(shopUtcOffset);
    expect(textOf(tester, 'home-date'), contains('${local.year}'));
  });

  testWidgets('the rail lists every place and marks Today', (tester) async {
    await open(tester);
    for (final key in [
      'nav-today',
      'billing-button',
      'returns-button',
      'stock-entry-button',
      'daily-report-button',
      'shift-closes-button',
      'backups-button',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      expect(
        tester.getSize(find.byKey(Key(key))).height,
        greaterThanOrEqualTo(48),
        reason: key,
      );
    }
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('a narrow window keeps the rail as icons only', (tester) async {
    await open(tester, width: 800);
    expect(find.byKey(const Key('billing-button')), findsOneWidget);
    expect(find.text('Billing'), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('billing-button'))).width,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('the day so far starts at zero', (tester) async {
    await open(tester);
    expect(textOf(tester, 'stat-sales'), '₹0.00');
    expect(textOf(tester, 'stat-bills'), '0');
    expect(textOf(tester, 'stat-garments'), '0');
    expect(textOf(tester, 'stat-returns'), '0');
    expect(textOf(tester, 'home-open-shifts'), 'No shift is open now.');
  });

  testWidgets('today\'s bills and open shifts show on the page', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await shifts.openShift(
        role: Role.cashier,
        userId: ashaId,
        counts: const {},
      );
      await sales.saveBill(
        role: Role.cashier,
        cashierId: ashaId,
        lines: [BillLineInput(barcodes[0]), BillLineInput(barcodes[1])],
        payments: [Payment(PaymentMode.cash, Money(99800))],
      );
      await returns.saveReturn(
        role: Role.cashier,
        cashierId: ashaId,
        items: [ReturnItemInput(barcodes[0], ReturnOutcome.restock)],
        refundMode: RefundMode.cash,
      );
    });
    await open(tester);
    // Sales are what the bills came to, before the return.
    expect(textOf(tester, 'stat-sales'), '₹998.00');
    expect(textOf(tester, 'stat-bills'), '1');
    expect(textOf(tester, 'stat-garments'), '2');
    expect(textOf(tester, 'stat-returns'), '1');
    expect(textOf(tester, 'home-open-shifts'), '1 shift is open now.');
  });

  testWidgets('cost and profit are not on the home page', (tester) async {
    await open(tester);
    expect(find.textContaining('Profit'), findsNothing);
    expect(find.textContaining('Cost'), findsNothing);
  });

  testWidgets('Open today\'s report goes to the daily report', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('home-open-report')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await pump(tester);
    expect(find.byKey(const Key('report-title')), findsOneWidget);
  });
}
