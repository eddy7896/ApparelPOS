// The billing register: scan, discounts with manager approval, payment, the
// saved bill and printing. P2-4c.
import 'dart:io';
import 'dart:typed_data';

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
import 'package:pos_windows/data/returns_repository.dart';
import 'package:pos_windows/data/sales_repository.dart';
import 'package:pos_windows/data/shift_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

class FakePrinter implements LabelPrinter {
  final printed = <Uint8List>[];
  @override
  Future<void> printSheet(Uint8List pdf, {required String name}) async =>
      printed.add(pdf);
}

const managerPassword = 'a long passphrase';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late AuthService auth;
  late StockRepository stock;
  late SalesRepository sales;
  late ShiftRepository shifts;
  late SessionController session;
  late FakePrinter printer;
  late List<String> barcodes; // two M Blue at 499.00, one L Blue at 999.00
  late String cashierId;
  late String managerId;
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    auth = AuthService(db, newId: newId);
    stock = StockRepository(db, newId: newId);
    sales = SalesRepository(db, newId: newId);
    shifts = ShiftRepository(db, newId: newId);
    session = SessionController(auth: auth);
    printer = FakePrinter();
    await stock.ensureCounter();
    await stock.seedDefaultOptions();
    await stock.setShopName(role: Role.owner, name: 'Sample Apparel');
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
          PurchaseLine(
            size: 'L',
            color: 'Blue',
            quantity: 1,
            cost: Money(40000),
            mrp: Money(99900),
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
    await shifts.openShift(
      role: Role.cashier,
      userId: cashierId,
      counts: {Denomination.note500: 4},
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

  Future<void> open(
    WidgetTester tester, {
    String? as,
    String? secret,
    bool withShift = true,
  }) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await session.start();
      await session.signIn(as ?? cashierId, secret ?? '482916');
      if (withShift &&
          await shifts.currentShift(session.user!.userId) == null) {
        await shifts.openShift(
          role: session.user!.role,
          userId: session.user!.userId,
          counts: {Denomination.note500: 4},
        );
      }
    });
    await tester.pumpWidget(
      PosApp(
        session: session,
        services: AppServices(
          stock: stock,
          sales: sales,
          returns: ReturnsRepository(db, newId: newId),
          shifts: shifts,
          auth: auth,
          printer: printer,
          fonts: () async => LabelFonts(
            regular: File('assets/fonts/NotoSans-Regular.ttf')
                .readAsBytesSync(),
            bold: File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> scan(WidgetTester tester, String code) async {
    await tester.enterText(find.byKey(const Key('barcode-field')), code);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pump(tester);
  }

  Future<void> type(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  bool canComplete(WidgetTester tester) =>
      tester
          .widget<FilledButton>(find.byKey(const Key('complete-bill')))
          .onPressed !=
      null;

  Future<String> statusOf(String code) async =>
      (await db
              .customSelect(
                'SELECT status FROM articles WHERE barcode_value = ?',
                variables: [Variable<String>(code)],
              )
              .getSingle())
          .read<String>('status');

  Future<void> tapRunAsync(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await pump(tester);
  }

  group('getting to the register', () {
    testWidgets('a cashier lands on the register', (tester) async {
      await open(tester);
      expect(find.byKey(const Key('barcode-field')), findsOneWidget);
      expect(find.byKey(const Key('stock-entry-button')), findsNothing);
    });
    testWidgets('a manager opens it with the Billing button', (tester) async {
      await open(tester, as: managerId, secret: managerPassword);
      expect(find.byKey(const Key('barcode-field')), findsNothing);
      await tester.tap(find.byKey(const Key('billing-button')));
      await pump(tester);
      expect(find.byKey(const Key('barcode-field')), findsOneWidget);
    });
  });

  group('scanning', () {
    testWidgets('a scan adds a line and the total', (tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      expect(find.byKey(Key('line-${barcodes[0]}')), findsOneWidget);
      expect(textOf(tester, 'total-text'), '₹499.00');
      await scan(tester, barcodes[2]);
      expect(textOf(tester, 'total-text'), '₹1,498.00');
    });
    testWidgets('the same tag twice says so and adds nothing', (tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await scan(tester, barcodes[0]);
      expect(find.byKey(const Key('message-banner')), findsOneWidget);
      expect(find.textContaining('already on this bill'), findsOneWidget);
      expect(textOf(tester, 'total-text'), '₹499.00');
    });
    testWidgets('an unknown barcode is not found', (tester) async {
      await open(tester);
      await scan(tester, '000000000000');
      expect(find.textContaining('Not found'), findsOneWidget);
      expect(find.byKey(const Key('bill-lines')), findsNothing);
    });
    testWidgets('a sold barcode names the bill that sold it', (tester) async {
      final first = await tester.runAsync(
        () => sales.saveBill(
          role: Role.cashier,
          cashierId: cashierId,
          lines: [BillLineInput(barcodes[0])],
          payments: [Payment(PaymentMode.cash, Money(49900))],
        ),
      );
      await open(tester);
      await scan(tester, barcodes[0]);
      expect(
        find.textContaining(
          'Already sold on bill ${first!.billNumber.format()}',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('bill-lines')), findsNothing);
    });
    testWidgets('a line can be removed', (tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await tester.tap(find.byKey(Key('remove-${barcodes[0]}')));
      await tester.pump();
      expect(find.byKey(Key('line-${barcodes[0]}')), findsNothing);
      expect(textOf(tester, 'total-text'), '₹0.00');
    });
    testWidgets('an empty bill cannot be completed', (tester) async {
      await open(tester);
      expect(canComplete(tester), isFalse);
    });
  });

  group('paying', () {
    testWidgets('not enough cash keeps Complete off and shows what is due', (
      tester,
    ) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await type(tester, 'cash-field', '300');
      expect(canComplete(tester), isFalse);
      expect(textOf(tester, 'due-text'), 'Still due: ₹199.00');
    });
    testWidgets('cash over the total shows change and saves the bill', (
      tester,
    ) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await type(tester, 'cash-field', '500');
      expect(textOf(tester, 'change-text'), 'Change to give: ₹1.00');
      expect(canComplete(tester), isTrue);
      await tapRunAsync(tester, 'complete-bill');
      expect(find.byKey(const Key('saved-title')), findsOneWidget);
      expect(textOf(tester, 'saved-bill-no'), startsWith('20'));
      expect(textOf(tester, 'saved-change'), 'Change to give: ₹1.00');
      expect(await statusOf(barcodes[0]), 'SOLD');
    });
    testWidgets('Exact cash fills the total', (tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await tester.tap(find.byKey(const Key('exact-cash')));
      await tester.pump();
      expect(canComplete(tester), isTrue);
      expect(find.byKey(const Key('change-text')), findsNothing);
    });
    testWidgets('UPI over the total is a problem and blocks Complete', (
      tester,
    ) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await type(tester, 'upi-field', '600');
      expect(find.byKey(const Key('payment-problem')), findsOneWidget);
      expect(canComplete(tester), isFalse);
    });
    testWidgets('a split of UPI and cash is saved per mode', (tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await type(tester, 'upi-field', '300');
      await type(tester, 'cash-field', '199');
      expect(canComplete(tester), isTrue);
      await tapRunAsync(tester, 'complete-bill');
      final rows = await tester.runAsync(
        () => db
            .customSelect('SELECT mode, amount_paise FROM bill_payments')
            .get(),
      );
      expect(
        {
          for (final r in rows!)
            r.read<String>('mode'): r.read<int>('amount_paise'),
        },
        {'upi': 30000, 'cash': 19900},
      );
    });
    testWidgets('a nonsense amount is a problem', (tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await type(tester, 'cash-field', '12abc');
      expect(canComplete(tester), isFalse);
      expect(find.byKey(const Key('payment-problem')), findsOneWidget);
    });
    testWidgets('customer details are saved on the bill', (tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await type(tester, 'customer-name', 'Ravi');
      await type(tester, 'customer-phone', '9876543210');
      await tester.tap(find.byKey(const Key('exact-cash')));
      await tester.pump();
      await tapRunAsync(tester, 'complete-bill');
      final b = await tester.runAsync(
        () => db
            .customSelect('SELECT customer_name, customer_phone FROM bills')
            .getSingle(),
      );
      expect(b!.read<String>('customer_name'), 'Ravi');
      expect(b.read<String>('customer_phone'), '9876543210');
    });
    testWidgets('a bad phone says so and nothing is saved', (tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await type(tester, 'customer-phone', 'abc');
      await tester.tap(find.byKey(const Key('exact-cash')));
      await tester.pump();
      await tapRunAsync(tester, 'complete-bill');
      expect(find.textContaining('phone number'), findsOneWidget);
      expect(find.byKey(const Key('saved-title')), findsNothing);
      expect(await tester.runAsync(() => statusOf(barcodes[0])), 'IN_STOCK');
    });
    testWidgets('a garment sold at another moment is refused when completing', (
      tester,
    ) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await tester.runAsync(
        () => sales.saveBill(
          role: Role.cashier,
          cashierId: cashierId,
          lines: [BillLineInput(barcodes[0])],
          payments: [Payment(PaymentMode.cash, Money(49900))],
        ),
      );
      await tester.tap(find.byKey(const Key('exact-cash')));
      await tester.pump();
      await tapRunAsync(tester, 'complete-bill');
      expect(find.textContaining('was sold'), findsOneWidget);
      expect(find.byKey(const Key('saved-title')), findsNothing);
    });
  });

  group('discounts', () {
    Future<void> discount(WidgetTester tester, String code, String text) async {
      await tester.tap(find.byKey(Key('discount-$code')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('discount-input')), text);
      await tester.tap(find.byKey(const Key('discount-apply')));
      await pump(tester);
    }

    testWidgets('10% comes off the price', (tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await discount(tester, barcodes[0], '10%');
      expect(textOf(tester, 'price-${barcodes[0]}'), '₹449.10');
      expect(textOf(tester, 'total-text'), '₹449.10');
    });
    testWidgets('an amount discount works', (tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await discount(tester, barcodes[0], '49');
      expect(textOf(tester, 'total-text'), '₹450.00');
    });
    testWidgets('an amount over 10% of the price also asks a manager', (
      tester,
    ) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await discount(tester, barcodes[0], '99');
      expect(find.byKey(const Key('approver-password')), findsOneWidget);
    });
    testWidgets('empty text removes the discount', (tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await discount(tester, barcodes[0], '10%');
      await discount(tester, barcodes[0], '');
      expect(textOf(tester, 'total-text'), '₹499.00');
    });
    testWidgets('nonsense is refused with a message', (tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await discount(tester, barcodes[0], 'lots');
      expect(find.textContaining('is not a discount'), findsOneWidget);
      expect(textOf(tester, 'total-text'), '₹499.00');
    });
    testWidgets('over 10% asks a manager; a wrong password is refused', (
      tester,
    ) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await discount(tester, barcodes[0], '20%');
      expect(find.byKey(const Key('approver-password')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('approver-password')),
        'not it',
      );
      await tester.tap(find.byKey(const Key('approver-ok')));
      await pump(tester);
      expect(find.byKey(const Key('approval-error')), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await pump(tester);
      expect(textOf(tester, 'total-text'), '₹499.00');
    });
    testWidgets('a manager approves and the bill is saved under the cashier', (
      tester,
    ) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await discount(tester, barcodes[0], '20%');
      await tester.enterText(
        find.byKey(const Key('approver-password')),
        managerPassword,
      );
      await tester.tap(find.byKey(const Key('approver-ok')));
      await pump(tester);
      expect(textOf(tester, 'total-text'), '₹399.20');
      await tester.tap(find.byKey(const Key('exact-cash')));
      await tester.pump();
      await tapRunAsync(tester, 'complete-bill');
      expect(find.byKey(const Key('saved-title')), findsOneWidget);
      final b = await tester.runAsync(
        () => db.customSelect('SELECT cashier_id FROM bills').getSingle(),
      );
      expect(b!.read<String>('cashier_id'), cashierId);
      final a = await tester.runAsync(
        () => db
            .customSelect(
              "SELECT details FROM audit_log WHERE action = 'sale.bill'",
            )
            .getSingle(),
      );
      expect(a!.read<String>('details'), contains(managerId));
    });
  });

  group('after the bill', () {
    Future<void> sellOneBill(WidgetTester tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await tester.tap(find.byKey(const Key('exact-cash')));
      await tester.pump();
      await tapRunAsync(tester, 'complete-bill');
    }

    testWidgets('Print sends a PDF to the printer', (tester) async {
      await sellOneBill(tester);
      await tester.runAsync(
        () => tester.tap(find.byKey(const Key('print-bill'))),
      );
      await pump(tester);
      expect(printer.printed.length, 1);
      expect(
        String.fromCharCodes(printer.printed.single.sublist(0, 5)),
        '%PDF-',
      );
    });
    testWidgets('New bill starts empty, ready to scan', (tester) async {
      await sellOneBill(tester);
      await tester.tap(find.byKey(const Key('new-bill')));
      await tester.pump();
      expect(find.byKey(const Key('barcode-field')), findsOneWidget);
      expect(find.byKey(const Key('bill-lines')), findsNothing);
      expect(textOf(tester, 'total-text'), '₹0.00');
      await scan(tester, barcodes[1]);
      expect(find.byKey(Key('line-${barcodes[1]}')), findsOneWidget);
    });
    testWidgets('a manager approval does not carry over to the next bill', (
      tester,
    ) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await tester.tap(find.byKey(Key('discount-${barcodes[0]}')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('discount-input')), '20%');
      await tester.tap(find.byKey(const Key('discount-apply')));
      await pump(tester);
      await tester.enterText(
        find.byKey(const Key('approver-password')),
        managerPassword,
      );
      await tester.tap(find.byKey(const Key('approver-ok')));
      await pump(tester);
      await tester.tap(find.byKey(const Key('exact-cash')));
      await tester.pump();
      await tapRunAsync(tester, 'complete-bill');
      await tester.tap(find.byKey(const Key('new-bill')));
      await tester.pump();
      await scan(tester, barcodes[1]);
      await tester.tap(find.byKey(Key('discount-${barcodes[1]}')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('discount-input')), '20%');
      await tester.tap(find.byKey(const Key('discount-apply')));
      await pump(tester);
      expect(find.byKey(const Key('approver-password')), findsOneWidget);
    });
    testWidgets('the next bill gets the next number', (tester) async {
      await sellOneBill(tester);
      final first = textOf(tester, 'saved-bill-no');
      await tester.tap(find.byKey(const Key('new-bill')));
      await tester.pump();
      await scan(tester, barcodes[1]);
      await tester.tap(find.byKey(const Key('exact-cash')));
      await tester.pump();
      await tapRunAsync(tester, 'complete-bill');
      expect(textOf(tester, 'saved-bill-no'), isNot(first));
      expect(textOf(tester, 'saved-bill-no'), endsWith('000002'));
    });
  });

  group('locking', () {
    testWidgets('locking forgets the bill in progress', (tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      session.lock();
      await tester.pump();
      expect(find.byKey(const Key('barcode-field')), findsNothing);
      expect(await tester.runAsync(() => statusOf(barcodes[0])), 'IN_STOCK');
    });
  });
}
