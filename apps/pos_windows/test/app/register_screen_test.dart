// The billing register: scan, discounts with manager approval, payment, the
// saved bill and printing. P2-4c.
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/app/app.dart';
import 'package:pos_windows/app/label_printer.dart';
import 'package:pos_windows/app/services.dart';
import 'package:pos_windows/app/session_controller.dart';
import 'package:pos_windows/app/ui/ui_tokens.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/auth_service.dart';
import 'package:pos_windows/data/report_repository.dart';
import 'package:pos_windows/data/returns_repository.dart';
import 'package:pos_windows/data/dues_repository.dart';
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
    bool withDues = false,
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
          reports: ReportRepository(db),
          auth: auth,
          dues: withDues ? DuesRepository(db, newId: newId) : null,
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

  group('the look (mock-up board 3)', () {
    testWidgets('the garments card counts the garments', (tester) async {
      await open(tester);
      expect(textOf(tester, 'lines-count'), 'Garments');
      await scan(tester, barcodes[0]);
      expect(textOf(tester, 'lines-count'), '1 garment');
      await scan(tester, barcodes[1]);
      expect(textOf(tester, 'lines-count'), '2 garments');
    });

    testWidgets('the total panel says what is to pay and how many garments', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Total to pay'), findsOneWidget);
      expect(find.text('Scan the first tag to begin.'), findsOneWidget);
      await scan(tester, barcodes[0]);
      expect(find.text('1 garment'), findsWidgets);
    });

    testWidgets(
      'F9 completes the bill when it can be completed, and does nothing otherwise',
      (tester) async {
        await open(tester);
        await scan(tester, barcodes[0]);
        await tester.sendKeyEvent(LogicalKeyboardKey.f9); // nothing paid yet
        await pump(tester);
        expect(find.byKey(const Key('saved-title')), findsNothing);
        await tester.tap(find.byKey(const Key('exact-cash')));
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.f9);
        await pump(tester);
        expect(find.byKey(const Key('saved-title')), findsOneWidget);
      },
    );

    testWidgets('F2 brings the cursor back to the scan box', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('customer-name')));
      await tester.pump();
      bool scanHasFocus() => tester
          .widget<TextField>(find.byKey(const Key('barcode-field')))
          .focusNode!
          .hasFocus;
      expect(scanHasFocus(), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pump();
      expect(scanHasFocus(), isTrue);
    });

    testWidgets('a discounted line shows the struck-through MRP', (
      tester,
    ) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await tester.tap(find.byKey(Key('discount-${barcodes[0]}')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('discount-input')), '10%');
      await tester.tap(find.byKey(const Key('discount-apply')));
      await pump(tester);
      expect(textOf(tester, 'price-${barcodes[0]}'), '₹449.10');
      final struck = tester
          .widgetList<Text>(find.text('₹499.00'))
          .where((t) => t.style?.decoration == TextDecoration.lineThrough);
      expect(struck.length, 1);
    });

    testWidgets('Still due is an amber notice and Change a green one', (
      tester,
    ) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await type(tester, 'cash-field', '300');
      final due = tester.widget<Container>(
        find
            .ancestor(
              of: find.byKey(const Key('due-text')),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((due.decoration as BoxDecoration).color, UiColors.amberSoft);
      await type(tester, 'cash-field', '500');
      final change = tester.widget<Container>(
        find
            .ancestor(
              of: find.byKey(const Key('change-text')),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((change.decoration as BoxDecoration).color, UiColors.successSoft);
    });
  });

  group('the payment card (mock-up board 3)', () {
    Future<void> choose(WidgetTester tester, String m) async {
      await tester.tap(find.byKey(Key('method-$m')));
      await tester.pump();
    }

    testWidgets(
      'Cash, UPI, Card and Split chips; Cash is chosen to begin with',
      (tester) async {
        await open(tester);
        for (final m in ['cash', 'upi', 'card', 'split']) {
          expect(find.byKey(Key('method-$m')), findsOneWidget, reason: m);
        }
        expect(find.byKey(const Key('cash-field')), findsOneWidget);
        expect(find.byKey(const Key('upi-field')), findsNothing);
        expect(find.byKey(const Key('card-field')), findsNothing);
        expect(find.byKey(const Key('non-cash-note')), findsNothing);
      },
    );

    testWidgets('the chosen chip has the 2 dp outline in the main color', (
      tester,
    ) async {
      await open(tester);
      OutlinedButton chip(String m) =>
          tester.widget<OutlinedButton>(find.byKey(Key('method-$m')));
      BorderSide? side(OutlinedButton b) => b.style?.side?.resolve({});
      expect(side(chip('cash'))!.width, 2);
      expect(side(chip('upi'))!.width, 1);
      await choose(tester, 'upi');
      expect(side(chip('upi'))!.width, 2);
      expect(side(chip('cash'))!.width, 1);
    });

    testWidgets(
      'UPI pays the whole bill: no amount to type, the mock-up note shows, Complete is ready',
      (tester) async {
        await open(tester);
        await scan(tester, barcodes[0]);
        expect(canComplete(tester), isFalse); // nothing paid yet in cash
        await choose(tester, 'upi');
        expect(find.byKey(const Key('non-cash-note')), findsOneWidget);
        expect(find.byKey(const Key('cash-field')), findsNothing);
        expect(find.byKey(const Key('quick-cash-500')), findsNothing);
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
          {'upi': 49900},
        );
      },
    );

    testWidgets('Card pays the whole bill as card', (tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await scan(tester, barcodes[1]);
      await choose(tester, 'card');
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
        {'card': 99800},
      );
    });

    testWidgets('UPI follows the bill: a garment added later is included', (
      tester,
    ) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await choose(tester, 'upi');
      await scan(tester, barcodes[1]);
      await tapRunAsync(tester, 'complete-bill');
      final rows = await tester.runAsync(
        () => db.customSelect('SELECT amount_paise FROM bill_payments').get(),
      );
      expect(rows!.single.read<int>('amount_paise'), 99800);
    });

    testWidgets('going back to Cash clears the UPI choice', (tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await choose(tester, 'upi');
      await choose(tester, 'cash');
      expect(find.byKey(const Key('non-cash-note')), findsNothing);
      expect(canComplete(tester), isFalse);
    });

    testWidgets('Split brings back the cash, UPI and card amounts', (
      tester,
    ) async {
      await open(tester);
      await choose(tester, 'split');
      expect(find.byKey(const Key('cash-field')), findsOneWidget);
      expect(find.byKey(const Key('upi-field')), findsOneWidget);
      expect(find.byKey(const Key('card-field')), findsOneWidget);
      expect(find.byKey(const Key('exact-cash')), findsOneWidget);
    });

    testWidgets('the cash chip that matches the amount is lit', (tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await tester.tap(find.byKey(const Key('quick-cash-500')));
      await tester.pump();
      BorderSide? side(String k) => tester
          .widget<OutlinedButton>(find.byKey(Key(k)))
          .style
          ?.side
          ?.resolve({});
      expect(side('quick-cash-500')!.width, 2);
      expect(side('quick-cash-1000')!.width, 1);
    });

    testWidgets('going to UPI and back leaves no stale cash amount', (
      tester,
    ) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await type(tester, 'cash-field', '300');
      await choose(tester, 'upi');
      await choose(tester, 'cash');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('cash-field')))
            .controller!
            .text,
        '',
      );
    });

    testWidgets(
      'Complete bill sits at the bottom of the right column, not just after the fields',
      (tester) async {
        await open(tester); // window is 1000 high
        final r = tester.getRect(find.byKey(const Key('complete-bill')));
        expect(r.bottom, greaterThan(900));
      },
    );

    testWidgets('a new bill starts on Cash again', (tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await choose(tester, 'upi');
      await tapRunAsync(tester, 'complete-bill');
      await tester.tap(find.byKey(const Key('new-bill')));
      await tester.pump();
      expect(find.byKey(const Key('cash-field')), findsOneWidget);
      expect(find.byKey(const Key('non-cash-note')), findsNothing);
    });

    testWidgets('Complete bill is always on screen, even on a short window', (
      tester,
    ) async {
      await open(tester);
      tester.view.physicalSize = const Size(1500, 760);
      await scan(tester, barcodes[0]);
      await tester.pump();
      final r = tester.getRect(find.byKey(const Key('complete-bill')));
      expect(r.bottom, lessThanOrEqualTo(760));
      expect(r.top, greaterThanOrEqualTo(0));
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
    testWidgets('quick cash buttons offer round amounts and fill the cash', (
      tester,
    ) async {
      await open(tester);
      expect(find.byKey(const Key('quick-cash-500')), findsNothing);
      await scan(tester, barcodes[0]); // ₹499
      expect(find.byKey(const Key('quick-cash-500')), findsOneWidget);
      expect(find.byKey(const Key('quick-cash-1000')), findsOneWidget);
      await tester.tap(find.byKey(const Key('quick-cash-1000')));
      await tester.pump();
      expect(textOf(tester, 'change-text'), 'Change to give: ₹501.00');
      expect(canComplete(tester), isTrue);
    });
    testWidgets('the buttons are at least 48 by 48 for touch', (tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      for (final key in [
        'exact-cash',
        'quick-cash-500',
        'complete-bill',
        'discount-${barcodes[0]}',
        'remove-${barcodes[0]}',
      ]) {
        final size = tester.getSize(find.byKey(Key(key)));
        expect(size.height, greaterThanOrEqualTo(48), reason: key);
        expect(size.width, greaterThanOrEqualTo(48), reason: key);
      }
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
      await tester.tap(find.byKey(const Key('method-split')));
      await tester.pump();
      await type(tester, 'upi-field', '600');
      expect(find.byKey(const Key('payment-problem')), findsOneWidget);
      expect(canComplete(tester), isFalse);
    });
    testWidgets('a split of UPI and cash is saved per mode', (tester) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await tester.tap(find.byKey(const Key('method-split')));
      await tester.pump();
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
    testWidgets(
      'a held bill keeps its manager approval for when it is resumed',
      (tester) async {
        await open(tester);
        await scan(tester, barcodes[0]);
        await discount(tester, barcodes[0], '20%');
        await tester.enterText(
          find.byKey(const Key('approver-password')),
          managerPassword,
        );
        await tester.tap(find.byKey(const Key('approver-ok')));
        await pump(tester);
        await tester.tap(find.byKey(const Key('hold-bill')));
        await pump(tester);
        await tester.tap(find.byKey(const Key('held-resume-0')));
        await pump(tester);
        expect(textOf(tester, 'total-text'), '₹399.20');
        await tester.tap(find.byKey(const Key('exact-cash')));
        await tester.pump();
        await tapRunAsync(tester, 'complete-bill');
        expect(find.byKey(const Key('saved-title')), findsOneWidget);
        final a = await tester.runAsync(
          () => db
              .customSelect(
                "SELECT details FROM audit_log WHERE action = 'sale.bill'",
              )
              .getSingle(),
        );
        expect(a!.read<String>('details'), contains(managerId));
      },
    );
  });

  group('a markdown set in Stock', () {
    Future<void> markKurta(String pct) async {
      await db.customStatement(
        'INSERT INTO style_markdowns (product_id, percent_bp, ends_before, set_by, created_at, updated_at) '
        "SELECT id, $pct, 4102444800, 'm', 1700000000, 1700000000 FROM products",
      );
    }

    testWidgets('the line shows the sale, takes no discount and totals less', (
      tester,
    ) async {
      await tester.runAsync(() => markKurta('2000'));
      await open(tester);
      await scan(tester, barcodes[0]);
      expect(textOf(tester, 'price-${barcodes[0]}'), '₹399.20');
      expect(textOf(tester, 'total-text'), '₹399.20');
      expect(find.byKey(Key('sale-tag-${barcodes[0]}')), findsOneWidget);
      expect(find.text('Sale 20% off'), findsOneWidget);
      expect(find.byKey(Key('discount-${barcodes[0]}')), findsNothing);
      expect(find.textContaining('markdown 20% -₹99.80'), findsOneWidget);
    });

    testWidgets('a garment of an unmarked style has the discount button', (
      tester,
    ) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      expect(find.byKey(Key('discount-${barcodes[0]}')), findsOneWidget);
      expect(find.byKey(Key('sale-tag-${barcodes[0]}')), findsNothing);
    });

    testWidgets('the bill is saved at the marked-down price', (tester) async {
      await tester.runAsync(() => markKurta('2000'));
      await open(tester);
      await scan(tester, barcodes[0]);
      await tester.tap(find.byKey(const Key('exact-cash')));
      await tester.pump();
      await tapRunAsync(tester, 'complete-bill');
      expect(find.byKey(const Key('saved-title')), findsOneWidget);
      final b = await tester.runAsync(
        () => db
            .customSelect(
              'SELECT l.markdown_paise AS m, b.total_paise AS t '
              'FROM bill_lines l JOIN bills b ON b.id = l.bill_id',
            )
            .getSingle(),
      );
      expect(b!.read<int>('m'), 9980);
      expect(b.read<int>('t'), 39920);
    });

    testWidgets('a markdown set while the bill is open stops the bill once', (
      tester,
    ) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      expect(textOf(tester, 'total-text'), '₹499.00');
      await tester.runAsync(() => markKurta('2000'));
      await tester.tap(find.byKey(const Key('exact-cash')));
      await tester.pump();
      await tapRunAsync(tester, 'complete-bill');
      expect(find.byKey(const Key('saved-title')), findsNothing);
      expect(
        find.textContaining('A markdown changed while this bill was open'),
        findsOneWidget,
      );
      expect(textOf(tester, 'total-text'), '₹399.20');
      expect(find.byKey(Key('sale-tag-${barcodes[0]}')), findsOneWidget);
      // pay the new total and complete
      await tester.tap(find.byKey(const Key('exact-cash')));
      await tester.pump();
      await tapRunAsync(tester, 'complete-bill');
      expect(find.byKey(const Key('saved-title')), findsOneWidget);
    });

    testWidgets('a discount typed before the markdown came is dropped', (
      tester,
    ) async {
      await open(tester);
      await scan(tester, barcodes[0]);
      await tester.tap(find.byKey(Key('discount-${barcodes[0]}')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('discount-input')), '5%');
      await tester.tap(find.byKey(const Key('discount-apply')));
      await pump(tester);
      expect(textOf(tester, 'total-text'), '₹474.05');
      await tester.runAsync(() => markKurta('2000'));
      await tester.tap(find.byKey(const Key('exact-cash')));
      await tester.pump();
      await tapRunAsync(tester, 'complete-bill');
      expect(textOf(tester, 'total-text'), '₹399.20');
      await tester.tap(find.byKey(const Key('exact-cash')));
      await tester.pump();
      await tapRunAsync(tester, 'complete-bill');
      expect(find.byKey(const Key('saved-title')), findsOneWidget);
      final b = await tester.runAsync(
        () => db
            .customSelect(
              'SELECT discount_paise, markdown_paise FROM bill_lines',
            )
            .getSingle(),
      );
      expect(b!.read<int>('discount_paise'), 0);
      expect(b.read<int>('markdown_paise'), 9980);
    });

    testWidgets('prices that did not change do not stop the bill', (
      tester,
    ) async {
      await tester.runAsync(() => markKurta('2000'));
      await open(tester);
      await scan(tester, barcodes[0]);
      await tester.tap(find.byKey(const Key('exact-cash')));
      await tester.pump();
      await tapRunAsync(tester, 'complete-bill');
      expect(find.byKey(const Key('saved-title')), findsOneWidget);
    });
  });

  group('pay later at the register', () {
    Future<void> approve(WidgetTester tester, String password) async {
      await tester.enterText(
        find.byKey(const Key('approver-password')),
        password,
      );
      await tester.tap(find.byKey(const Key('approver-ok')));
      await pump(tester);
    }

    Future<void> chooseLater(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('method-later')));
      await pump(tester);
    }

    Future<void> laterApproved(WidgetTester tester) async {
      await chooseLater(tester);
      await approve(tester, managerPassword);
    }

    testWidgets('the choice is hidden when pay later is not set up', (
      tester,
    ) async {
      await open(tester);
      expect(find.byKey(const Key('method-later')), findsNothing);
      expect(find.byKey(const Key('dues-button')), findsNothing);
    });

    testWidgets('a cashier is asked for a manager before Pay later opens', (
      tester,
    ) async {
      await open(tester, withDues: true);
      await scan(tester, barcodes[2]);
      await chooseLater(tester);
      expect(find.byKey(const Key('approver-password')), findsOneWidget);
      await approve(tester, managerPassword);
      expect(find.byKey(const Key('upi-field')), findsOneWidget);
      expect(find.byKey(const Key('card-field')), findsOneWidget);
      expect(textOf(tester, 'owed-later'), 'To pay later: ₹999.00');
      expect(textOf(tester, 'later-note'), contains('name and phone'));
    });

    testWidgets('cancelling the approval leaves the way of paying alone', (
      tester,
    ) async {
      await open(tester, withDues: true);
      await scan(tester, barcodes[2]);
      await chooseLater(tester);
      await tester.tap(find.text('Cancel'));
      await pump(tester);
      expect(find.byKey(const Key('owed-later')), findsNothing);
      expect(find.byKey(const Key('upi-field')), findsNothing);
      expect(find.byKey(const Key('exact-cash')), findsOneWidget);
    });

    testWidgets('a wrong password does not open Pay later', (tester) async {
      await open(tester, withDues: true);
      await scan(tester, barcodes[2]);
      await chooseLater(tester);
      await approve(tester, 'not the password at all');
      expect(find.byKey(const Key('approval-error')), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await pump(tester);
      expect(find.byKey(const Key('owed-later')), findsNothing);
    });

    testWidgets('a manager signed in needs no approval', (tester) async {
      await open(
        tester,
        as: managerId,
        secret: managerPassword,
        withDues: true,
      );
      await tester.tap(find.byKey(const Key('billing-button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await pump(tester);
      await scan(tester, barcodes[2]);
      await chooseLater(tester);
      expect(find.byKey(const Key('approver-password')), findsNothing);
      expect(textOf(tester, 'owed-later'), 'To pay later: ₹999.00');
      await type(tester, 'customer-name', 'Ravi');
      await type(tester, 'customer-phone', '9876543210');
      expect(textOf(tester, 'later-note'), 'Allowed by you.');
    });

    testWidgets('Complete bill waits for the name and the phone', (
      tester,
    ) async {
      await open(tester, withDues: true);
      await scan(tester, barcodes[2]);
      await laterApproved(tester);
      expect(canComplete(tester), isFalse);
      await type(tester, 'customer-name', 'Ravi Kumar');
      expect(canComplete(tester), isFalse);
      await type(tester, 'customer-phone', '12345');
      expect(canComplete(tester), isFalse);
      await type(tester, 'customer-phone', '98765 43210');
      expect(canComplete(tester), isTrue);
      expect(textOf(tester, 'later-note'), 'Allowed by Meera.');
      await type(tester, 'customer-name', '  ');
      expect(canComplete(tester), isFalse);
    });

    testWidgets('part now, the rest is owed and the bill says so', (
      tester,
    ) async {
      await open(tester, withDues: true);
      await scan(tester, barcodes[2]);
      await laterApproved(tester);
      await type(tester, 'customer-name', 'Ravi Kumar');
      await type(tester, 'customer-phone', '9876543210');
      await type(tester, 'cash-field', '200');
      expect(textOf(tester, 'owed-later'), 'To pay later: ₹799.00');
      await tapRunAsync(tester, 'complete-bill');
      expect(find.byKey(const Key('saved-title')), findsOneWidget);
      expect(textOf(tester, 'saved-owed'), 'To pay later: ₹799.00');
      final row = await tester.runAsync(
        () => db
            .customSelect(
              'SELECT amount_paise, approved_by, actor_id FROM dues_ledger',
            )
            .getSingle(),
      );
      expect(row!.read<int>('amount_paise'), 79900);
      expect(row.read<String>('approved_by'), managerId);
      expect(row.read<String>('actor_id'), cashierId);
      final c = await tester.runAsync(
        () => db.customSelect('SELECT name, phone FROM customers').getSingle(),
      );
      expect(c!.read<String>('name'), 'Ravi Kumar');
      expect(c.read<String>('phone'), '9876543210');
    });

    testWidgets('nothing paid now is allowed', (tester) async {
      await open(tester, withDues: true);
      await scan(tester, barcodes[0]);
      await laterApproved(tester);
      await type(tester, 'customer-name', 'Ravi');
      await type(tester, 'customer-phone', '9876543210');
      expect(textOf(tester, 'owed-later'), 'To pay later: ₹499.00');
      await tapRunAsync(tester, 'complete-bill');
      expect(textOf(tester, 'saved-owed'), 'To pay later: ₹499.00');
    });

    testWidgets('UPI now and the rest later', (tester) async {
      await open(tester, withDues: true);
      await scan(tester, barcodes[2]);
      await laterApproved(tester);
      await type(tester, 'customer-name', 'Ravi');
      await type(tester, 'customer-phone', '9876543210');
      await type(tester, 'upi-field', '500');
      expect(textOf(tester, 'owed-later'), 'To pay later: ₹499.00');
      await tapRunAsync(tester, 'complete-bill');
      expect(textOf(tester, 'saved-owed'), 'To pay later: ₹499.00');
    });

    testWidgets('paying it all in Pay later is just a normal bill', (
      tester,
    ) async {
      await open(tester, withDues: true);
      await scan(tester, barcodes[0]);
      await laterApproved(tester);
      await type(tester, 'cash-field', '499');
      expect(find.byKey(const Key('owed-later')), findsNothing);
      expect(canComplete(tester), isTrue);
      await tapRunAsync(tester, 'complete-bill');
      expect(find.byKey(const Key('saved-title')), findsOneWidget);
      expect(find.byKey(const Key('saved-owed')), findsNothing);
      final c = await tester.runAsync(
        () => db
            .customSelect('SELECT COUNT(*) AS c FROM dues_ledger')
            .getSingle(),
      );
      expect(c!.read<int>('c'), 0);
    });

    testWidgets('UPI and card more than the total is still refused', (
      tester,
    ) async {
      await open(tester, withDues: true);
      await scan(tester, barcodes[0]);
      await laterApproved(tester);
      await type(tester, 'customer-name', 'Ravi');
      await type(tester, 'customer-phone', '9876543210');
      await type(tester, 'upi-field', '600');
      expect(find.byKey(const Key('payment-problem')), findsOneWidget);
      expect(canComplete(tester), isFalse);
    });

    testWidgets('going back to Cash puts the normal payment back', (
      tester,
    ) async {
      await open(tester, withDues: true);
      await scan(tester, barcodes[0]);
      await laterApproved(tester);
      await tester.tap(find.byKey(const Key('method-cash')));
      await pump(tester);
      expect(find.byKey(const Key('owed-later')), findsNothing);
      expect(find.byKey(const Key('exact-cash')), findsOneWidget);
      expect(canComplete(tester), isFalse);
      await tester.tap(find.byKey(const Key('exact-cash')));
      await pump(tester);
      expect(canComplete(tester), isTrue);
      // and choosing Pay later again does not ask a second time
      await chooseLater(tester);
      expect(find.byKey(const Key('approver-password')), findsNothing);
    });

    testWidgets('the name and phone say they are required', (tester) async {
      await open(tester, withDues: true);
      await scan(tester, barcodes[0]);
      expect(find.text('Customer name (optional)'), findsOneWidget);
      await laterApproved(tester);
      expect(find.text('Customer name (required)'), findsOneWidget);
      expect(find.text('Phone (required)'), findsOneWidget);
    });

    testWidgets('a held bill keeps who allowed pay later', (tester) async {
      await open(tester, withDues: true);
      await scan(tester, barcodes[0]);
      await laterApproved(tester);
      await type(tester, 'customer-name', 'Ravi');
      await type(tester, 'customer-phone', '9876543210');
      await tester.tap(find.byKey(const Key('hold-bill')));
      await pump(tester);
      await tester.tap(find.byKey(const Key('held-resume-0')));
      await pump(tester);
      expect(textOf(tester, 'owed-later'), 'To pay later: ₹499.00');
      expect(textOf(tester, 'later-note'), 'Allowed by Meera.');
      await tapRunAsync(tester, 'complete-bill');
      final row = await tester.runAsync(
        () =>
            db.customSelect('SELECT approved_by FROM dues_ledger').getSingle(),
      );
      expect(row!.read<String>('approved_by'), managerId);
    });

    testWidgets('a new bill starts on Cash and asks again', (tester) async {
      await open(tester, withDues: true);
      await scan(tester, barcodes[0]);
      await laterApproved(tester);
      await type(tester, 'customer-name', 'Ravi');
      await type(tester, 'customer-phone', '9876543210');
      await tapRunAsync(tester, 'complete-bill');
      await tester.tap(find.byKey(const Key('new-bill')));
      await tester.pump();
      await scan(tester, barcodes[1]);
      await chooseLater(tester);
      expect(find.byKey(const Key('approver-password')), findsOneWidget);
    });

    testWidgets('Pay dues opens the Pay later page', (tester) async {
      await open(tester, withDues: true);
      await tester.tap(find.byKey(const Key('dues-button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await pump(tester);
      expect(find.byKey(const Key('dues-total')), findsOneWidget);
      expect(find.byKey(const Key('write-off')), findsNothing);
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
    testWidgets('bill done is a popup over the register, not a new screen', (
      tester,
    ) async {
      await open(tester);
      expect(find.byKey(const Key('bill-done-popup')), findsNothing);
      await scan(tester, barcodes[0]);
      await tester.tap(find.byKey(const Key('exact-cash')));
      await tester.pump();
      await tapRunAsync(tester, 'complete-bill');
      expect(find.byKey(const Key('bill-done-popup')), findsOneWidget);
      // the register is still drawn behind it
      expect(find.byKey(const Key('total-text')), findsOneWidget);
      // and cannot be reached: tapping a button behind does nothing
      await tester.tap(
        find.byKey(const Key('complete-bill')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(await statusOf(barcodes[0]), 'SOLD');
      await tester.tap(find.byKey(const Key('new-bill')));
      await tester.pump();
      expect(find.byKey(const Key('bill-done-popup')), findsNothing);
    });
    testWidgets('Enter on the popup starts the next bill', (tester) async {
      await sellOneBill(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.byKey(const Key('bill-done-popup')), findsNothing);
      expect(textOf(tester, 'total-text'), '₹0.00');
    });
    testWidgets('P on the popup prints the bill', (tester) async {
      await sellOneBill(tester);
      await tester.runAsync(() async {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await pump(tester);
      expect(printer.printed.length, 1);
      expect(find.byKey(const Key('bill-done-popup')), findsOneWidget);
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
