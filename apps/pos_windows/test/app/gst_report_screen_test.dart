// GST reports page (P3-4 second step): invoice and returns registers, tax by
// rate and by day, and the export for the CA. Data and CSV text are tested in
// gst_report_repository_test; this checks what a manager and the owner see.
import 'dart:convert';
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:core_domain/credential_hasher.dart';
import 'package:drift/drift.dart' show Value, Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/app/app.dart';
import 'package:pos_windows/app/label_printer.dart';
import 'package:pos_windows/app/services.dart';
import 'package:pos_windows/app/session_controller.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/auth_service.dart';
import 'package:pos_windows/data/gst_report_repository.dart';
import 'package:pos_windows/data/gst_repository.dart';
import 'package:pos_windows/app/pickers.dart';
import 'package:pos_windows/data/report_repository.dart';
import 'package:pos_windows/data/returns_repository.dart';
import 'package:pos_windows/data/sales_repository.dart';
import 'package:pos_windows/data/shift_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late AuthService auth;
  late StockRepository stock;
  late GstRepository gst;
  String? pickedFolder;
  late SalesRepository sales;
  late ShiftRepository shifts;
  late String cashierId;
  late String cashierHash;
  late List<String> kurta;
  late List<String> jeans;
  late SessionController session;
  late String ownerId;
  late String managerId;
  late String ownerHash;
  late String managerHash;
  var n = 0;
  var staffNo = 0;
  String newId() => 'id-${++n}';

  setUpAll(() {
    final h = CredentialHasher();
    ownerHash = h.hash('a long passphrase');
    managerHash = h.hash('another long passphrase');
    cashierHash = h.hash('482916');
  });

  Future<String> person(String name, Role role, String hash) async {
    final id = newId();
    await db
        .into(db.users)
        .insert(
          UsersCompanion.insert(
            id: id,
            name: name,
            role: role.dbValue,
            credentialHash: hash,
            staffNumber: Value(++staffNo),
            createdAt: DateTime.utc(2026, 11, 20),
            updatedAt: DateTime.utc(2026, 11, 20),
          ),
        );
    return id;
  }

  Future<void> buyStyle(String name, {int mrp = 49900, int? dearer}) =>
      stock.receivePurchase(
        role: Role.owner,
        draft: PurchaseDraft(
          supplier: 'S',
          style: name,
          lines: [
            PurchaseLine(
              size: 'M',
              color: 'Blue',
              quantity: 2,
              cost: Money(10000),
              mrp: Money(mrp),
            ),
            if (dearer != null)
              PurchaseLine(
                size: 'L',
                color: 'Blue',
                quantity: 1,
                cost: Money(12000),
                mrp: Money(dearer),
              ),
          ],
        ),
      );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    staffNo = 0;
    auth = AuthService(db, newId: newId);
    stock = StockRepository(db, newId: newId);
    sales = SalesRepository(db, newId: newId);
    shifts = ShiftRepository(db, newId: newId);
    gst = GstRepository(db, newId: newId);
    pickedFolder = null;
    session = SessionController(auth: auth);
    await stock.ensureCounter();
    ownerId = await person('Meera', Role.owner, ownerHash);
    managerId = await person('Kabir', Role.manager, managerHash);
    cashierId = await person('Asha', Role.cashier, cashierHash);
    await buyStyle('Cotton Kurta');
    await buyStyle('Denim Jeans', mrp: 129900);
    Future<List<String>> codes(String style) async => [
      for (final r
          in await db
              .customSelect(
                'SELECT a.barcode_value AS b FROM articles a '
                'JOIN variants v ON v.id = a.variant_id '
                'JOIN products p ON p.id = v.product_id '
                'WHERE p.name = ? ORDER BY a.barcode_value',
                variables: [Variable<String>(style)],
              )
              .get())
        r.read<String>('b'),
    ];
    kurta = await codes('Cotton Kurta');
    jeans = await codes('Denim Jeans');
    for (final id in [ownerId, managerId, cashierId]) {
      await shifts.openShift(
        role: Role.manager,
        userId: id,
        counts: {Denomination.note500: 4},
      );
    }
  });
  tearDown(() async {
    session.dispose();
    await db.close();
  });

  Future<void> pump(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump();
    }
  }

  Future<void> open(
    WidgetTester tester, {
    bool manager = false,
    bool withReports = true,
  }) async {
    tester.view.physicalSize = const Size(1500, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await session.start();
      await session.signIn(
        manager ? managerId : ownerId,
        manager ? 'another long passphrase' : 'a long passphrase',
      );
    });
    await tester.pumpWidget(
      PosApp(
        session: session,
        services: AppServices(
          stock: stock,
          sales: sales,
          returns: ReturnsRepository(db, newId: newId),
          shifts: shifts,
          reports: ReportRepository(db),
          auth: auth,
          gstReports: withReports ? GstReportRepository(db) : null,
          pickers: FilePickers(folder: () async => pickedFolder),
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
    if (withReports) {
      await tester.tap(find.byKey(const Key('gst-reports-button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await pump(tester);
    }
  }

  Future<void> turnOnGst({GstMode mode = GstMode.inclusive}) => gst.save(
    role: Role.owner,
    actorId: ownerId,
    settings: GstSettings(
      enabled: true,
      mode: mode,
      gstin: '27ABCDE1234F1Z5',
      address: 'x',
    ),
  );

  Future<void> sell(List<String> codes, int pay, {String? customer}) =>
      sales.saveBill(
        role: Role.cashier,
        cashierId: cashierId,
        lines: [for (final c in codes) BillLineInput(c)],
        payments: [Payment(PaymentMode.cash, Money(pay))],
        customerName: customer,
      );

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.tap(find.byKey(Key(key)));
    await tester.pump(const Duration(milliseconds: 300));
    await pump(tester);
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  Future<void> fill(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  group('the page', () {
    testWidgets('says the columns are unverified and lists what is not built', (
      tester,
    ) async {
      await open(tester);
      expect(find.byKey(const Key('gst-report-unverified')), findsOneWidget);
      expect(find.textContaining('unverified'), findsWidgets);
      expect(find.textContaining('HSN'), findsOneWidget);
    });

    testWidgets('with GST off it says no tax and counts the bills', (
      tester,
    ) async {
      await tester.runAsync(() => sell([kurta[0]], 49900));
      await open(tester);
      expect(textOf(tester, 'tile-invoices'), '0');
      expect(textOf(tester, 'tile-net'), '₹0.00');
      expect(find.byKey(const Key('no-invoices')), findsOneWidget);
      expect(find.byKey(const Key('no-rates')), findsOneWidget);
      expect(
        textOf(tester, 'bills-without-gst'),
        startsWith('1 bill was made while GST was off'),
      );
    });

    testWidgets(
      'a manager gets it too; the menu item is hidden without the service',
      (tester) async {
        await open(tester, manager: true);
        expect(find.byKey(const Key('tile-invoices')), findsOneWidget);
      },
    );

    testWidgets('hidden without the service', (tester) async {
      await open(tester, withReports: false);
      expect(find.byKey(const Key('gst-reports-button')), findsNothing);
    });
  });

  group('with GST on', () {
    testWidgets('the tiles, the rate, the day and the invoice', (tester) async {
      await tester.runAsync(() async {
        await turnOnGst();
        await sell([kurta[0], jeans[0]], 179800, customer: 'Ravi Kumar');
      });
      await open(tester);
      expect(textOf(tester, 'tile-invoices'), '1');
      expect(textOf(tester, 'tile-taxable'), '₹1,712.38');
      expect(textOf(tester, 'tile-tax'), '₹85.62');
      expect(textOf(tester, 'tile-net'), '₹85.62');
      expect(find.byKey(const Key('rate-500')), findsOneWidget);
      final today = shopDayText(ShopDay.fromUtc(DateTime.now().toUtc()));
      expect(find.byKey(Key('day-$today')), findsOneWidget);
      expect(
        find.byKey(const Key('invoice-2026-27/C1/000001')),
        findsOneWidget,
      );
      expect(find.textContaining('Ravi Kumar'), findsOneWidget);
      expect(find.byKey(const Key('bills-without-gst')), findsNothing);
    });

    testWidgets('a return takes its tax off the net', (tester) async {
      await tester.runAsync(() async {
        await turnOnGst();
        await sell([kurta[0], kurta[1]], 99800);
        await ReturnsRepository(db, newId: newId).saveReturn(
          role: Role.cashier,
          cashierId: cashierId,
          items: [ReturnItemInput(kurta[0], ReturnOutcome.restock)],
          refundMode: RefundMode.cash,
        );
      });
      await open(tester);
      expect(textOf(tester, 'tile-tax'), '₹47.52');
      expect(textOf(tester, 'tile-returned'), '₹23.76');
      expect(textOf(tester, 'tile-net'), '₹23.76');
      expect(find.byKey(const Key('return-0')), findsOneWidget);
    });
  });

  group('HSN, business customers and purchases', () {
    testWidgets('each has its own section with its figures', (tester) async {
      await tester.runAsync(() async {
        await turnOnGst();
        await gst.setStyleGst(
          role: Role.owner,
          actorId: ownerId,
          styleId:
              (await db
                      .customSelect(
                        "SELECT id FROM products WHERE name = 'Cotton Kurta'",
                      )
                      .getSingle())
                  .read<String>('id'),
          hsn: '6109',
        );
        await sales.saveBill(
          role: Role.cashier,
          cashierId: cashierId,
          lines: [BillLineInput(kurta[0])],
          payments: [Payment(PaymentMode.cash, Money(49900))],
          customerName: 'Shah Traders',
          customerGstin: '29ABCDE1234F1Z5',
        );
        await stock.receivePurchase(
          role: Role.owner,
          draft: PurchaseDraft(
            supplier: 'Sharma Textiles',
            style: 'Silk Saree',
            supplierGstin: '27ABCDE1234F1Z5',
            invoiceNo: 'INV/9',
            inputTax: Money(250000),
            lines: [
              PurchaseLine(
                size: 'M',
                color: 'Blue',
                quantity: 2,
                cost: Money(100000),
                mrp: Money(300000),
              ),
            ],
          ),
        );
      });
      await open(tester);
      Future<void> see(String key) => tester.scrollUntilVisible(
        find.byKey(Key(key)),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await see('hsn-6109-500');
      expect(find.byKey(const Key('hsn-6109-500')), findsOneWidget);
      await see('business-2026-27/C1/000001');
      expect(
        find.byKey(const Key('business-2026-27/C1/000001')),
        findsOneWidget,
      );
      expect(find.textContaining('29ABCDE1234F1Z5'), findsWidgets);
      expect(textOf(tester, 'tile-input'), '₹2,500.00');
      expect(
        textOf(tester, 'tile-after-input'),
        '-₹2,476.24'.replaceFirst('-₹', '-₹'),
      );
      await see('purchase-2');
      expect(find.textContaining('Sharma Textiles'), findsOneWidget);
    });

    testWidgets(
      'a return in a later range than its sale shows a minus, not a crash',
      (tester) async {
        await tester.runAsync(() async {
          await turnOnGst();
          final earlier = SalesRepository(
            db,
            newId: newId,
            now: () => DateTime.now().toUtc().subtract(const Duration(days: 3)),
          );
          await earlier.saveBill(
            role: Role.cashier,
            cashierId: cashierId,
            lines: [BillLineInput(kurta[0])],
            payments: [Payment(PaymentMode.cash, Money(49900))],
          );
          await ReturnsRepository(db, newId: newId).saveReturn(
            role: Role.cashier,
            cashierId: cashierId,
            items: [ReturnItemInput(kurta[0], ReturnOutcome.restock)],
            refundMode: RefundMode.cash,
          );
        });
        await open(tester);
        await tapKey(tester, 'gst-range-today');
        expect(textOf(tester, 'tile-net'), '-₹23.76');
        expect(textOf(tester, 'tile-after-input'), '-₹23.76');
      },
    );

    testWidgets('empty sections say so', (tester) async {
      await open(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('no-business')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('no-hsn')), findsOneWidget);
      expect(find.byKey(const Key('no-business')), findsOneWidget);
    });
  });

  group('the range', () {
    testWidgets('Last month is empty, Today and This month bring it back', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await turnOnGst();
        await sell([kurta[0]], 49900);
      });
      await open(tester);
      await tapKey(tester, 'gst-range-last');
      expect(textOf(tester, 'tile-invoices'), '0');
      await tapKey(tester, 'gst-range-today');
      expect(textOf(tester, 'tile-invoices'), '1');
      await tapKey(tester, 'gst-range-last');
      await tapKey(tester, 'gst-range-month');
      expect(textOf(tester, 'tile-invoices'), '1');
    });

    testWidgets('a bad or backwards range says so', (tester) async {
      await open(tester);
      await fill(tester, 'gst-from', '2026-11-01');
      await tapKey(tester, 'gst-show');
      expect(find.textContaining('day/month/year'), findsOneWidget);
      await fill(tester, 'gst-from', '20/11/2026');
      await fill(tester, 'gst-to', '10/11/2026');
      await tapKey(tester, 'gst-show');
      expect(
        find.text('The last day is before the first day.'),
        findsOneWidget,
      );
    });
  });

  group('the export', () {
    testWidgets('writes the six files into the chosen folder', (tester) async {
      await tester.runAsync(() async {
        await turnOnGst();
        await sell([kurta[0]], 49900, customer: 'Ravi, Kumar');
      });
      final dir = Directory.systemTemp.createTempSync('gst-export');
      addTearDown(() => dir.deleteSync(recursive: true));
      pickedFolder = dir.path;
      await open(tester);
      await tapKey(tester, 'gst-export');
      for (var k = 0; k < 10; k++) {
        await pump(tester);
      }
      expect(find.textContaining('Saved 6 files'), findsOneWidget);
      final names =
          dir
              .listSync()
              .map((e) => e.path.split(Platform.pathSeparator).last)
              .toList()
            ..sort();
      expect(names.length, 6);
      expect(names[0], startsWith('gst-business-customers-'));
      expect(names[1], startsWith('gst-hsn-'));
      expect(names[2], startsWith('gst-invoices-'));
      expect(names[3], startsWith('gst-purchases-'));
      expect(names[4], startsWith('gst-returns-'));
      expect(names[5], startsWith('gst-summary-'));
      final inv = File('${dir.path}${Platform.pathSeparator}${names[2]}')
          .readAsBytesSync();
      expect(inv.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      final text = utf8.decode(inv.sublist(3));
      expect(text, startsWith('Invoice no,Date,Customer,'));
      expect(text, contains('"Ravi, Kumar"'));
    });

    testWidgets('cancelling the folder writes nothing and says nothing', (
      tester,
    ) async {
      await open(tester);
      pickedFolder = null;
      await tapKey(tester, 'gst-export');
      expect(find.byKey(const Key('gst-report-message')), findsNothing);
    });
  });
}
