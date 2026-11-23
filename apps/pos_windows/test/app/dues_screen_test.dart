// Pay later page (owner, 2026-11-23): who owes what, taking a payment, and
// (owner only) writing a debt off. Rules and data are tested elsewhere; this
// checks what a manager and the owner see and can do.
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
import 'package:pos_windows/data/dues_repository.dart';
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
  late DuesRepository dues;
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
    dues = DuesRepository(db, newId: newId);
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
    bool withDues = true,
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
          dues: withDues ? dues : null,
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
    if (withDues) {
      await tester.tap(find.byKey(const Key('pay-later-button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await pump(tester);
    }
  }

  Future<void> owe(
    List<String> barcodes, {
    String name = 'Ravi Kumar',
    String phone = '9876543210',
    int paidNow = 0,
  }) => sales.saveBill(
    role: Role.cashier,
    cashierId: cashierId,
    lines: [for (final b in barcodes) BillLineInput(b)],
    payments: [if (paidNow > 0) Payment(PaymentMode.cash, Money(paidNow))],
    payLater: PayLaterInput(
      customerName: name,
      customerPhone: phone,
      approverRole: Role.manager,
      approvedBy: managerId,
    ),
  );

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pump(const Duration(milliseconds: 400));
    await pump(tester);
  }

  Future<void> fill(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  String banner(WidgetTester tester) =>
      ((tester.widget<Container>(find.byKey(const Key('dues-message'))).child)
              as Text)
          .data!;

  group('the list', () {
    testWidgets('lists who owes, most first, with the total and count', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await owe([kurta[0]]);
        await owe(
          [jeans[0]],
          name: 'Meena Shah',
          phone: '9123456789',
          paidNow: 30000,
        );
      });
      await open(tester);
      expect(textOf(tester, 'dues-total'), '₹1,498.00');
      expect(textOf(tester, 'dues-count'), '2 customers');
      final meena = tester
          .getTopLeft(find.byKey(const Key('dues-customer-9123456789')))
          .dy;
      final ravi = tester
          .getTopLeft(find.byKey(const Key('dues-customer-9876543210')))
          .dy;
      expect(meena, lessThan(ravi)); // owes more
      expect(find.text('₹999.00'), findsOneWidget);
      expect(find.text('₹499.00'), findsOneWidget);
    });

    testWidgets('nobody owing says so', (tester) async {
      await open(tester);
      expect(find.byKey(const Key('dues-empty')), findsOneWidget);
      expect(textOf(tester, 'dues-total'), '₹0.00');
      expect(textOf(tester, 'dues-count'), '0 customers');
    });

    testWidgets('search by name or by part of the phone', (tester) async {
      await tester.runAsync(() async {
        await owe([kurta[0]]);
        await owe([jeans[0]], name: 'Meena Shah', phone: '9123456789');
      });
      await open(tester);
      await fill(tester, 'dues-search', 'MEE');
      await pump(tester);
      expect(find.byKey(const Key('dues-customer-9123456789')), findsOneWidget);
      expect(find.byKey(const Key('dues-customer-9876543210')), findsNothing);
      await fill(tester, 'dues-search', '9876');
      await pump(tester);
      expect(find.byKey(const Key('dues-customer-9876543210')), findsOneWidget);
      expect(find.byKey(const Key('dues-customer-9123456789')), findsNothing);
      await fill(tester, 'dues-search', 'zzz');
      await pump(tester);
      expect(find.byKey(const Key('dues-none')), findsOneWidget);
    });

    testWidgets(
      'a manager and the owner both open it; without the service it is hidden',
      (tester) async {
        await open(tester, manager: true);
        expect(find.byKey(const Key('dues-total')), findsOneWidget);
      },
    );

    testWidgets('the menu item is hidden without the service', (tester) async {
      await open(tester, withDues: false);
      expect(find.byKey(const Key('pay-later-button')), findsNothing);
    });
  });

  group('one customer', () {
    Future<void> pickRavi(WidgetTester tester) async {
      await tester.runAsync(() => owe([kurta[0]]));
      await open(tester);
      await tapKey(tester, 'dues-customer-9876543210');
    }

    testWidgets('shows what they owe, the bill, and the history', (
      tester,
    ) async {
      await pickRavi(tester);
      expect(textOf(tester, 'detail-name'), 'Ravi Kumar');
      expect(textOf(tester, 'detail-owed'), 'Owes ₹499.00');
      expect(
        find.byKey(const Key('due-bill-2026-27/C1/000001')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('history-0')), findsOneWidget);
      expect(find.textContaining('Left to pay later'), findsOneWidget);
    });

    testWidgets('before anyone is picked it asks to pick', (tester) async {
      await tester.runAsync(() => owe([kurta[0]]));
      await open(tester);
      expect(find.byKey(const Key('dues-pick')), findsOneWidget);
    });
  });

  group('taking a payment', () {
    Future<void> pickRavi(WidgetTester tester, {bool manager = false}) async {
      await tester.runAsync(() => owe([kurta[0]]));
      await open(tester, manager: manager);
      await tapKey(tester, 'dues-customer-9876543210');
    }

    testWidgets('a part payment in cash', (tester) async {
      await pickRavi(tester);
      await tapKey(tester, 'take-payment');
      await fill(tester, 'pay-cash', '200');
      expect(textOf(tester, 'pay-preview'), startsWith('Takes ₹200.00 off.'));
      expect(
        textOf(tester, 'pay-preview'),
        contains('Still owed after: ₹299.00.'),
      );
      await tapKey(tester, 'pay-save');
      expect(
        banner(tester),
        'Took ₹200.00 from Ravi Kumar. Still owed: ₹299.00.',
      );
      expect(textOf(tester, 'detail-owed'), 'Owes ₹299.00');
      expect(textOf(tester, 'dues-total'), '₹299.00');
    });

    testWidgets('Pay all fills the cash box and clears the debt', (
      tester,
    ) async {
      await pickRavi(tester);
      await tapKey(tester, 'take-payment');
      await tapKey(tester, 'pay-all');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('pay-cash')))
            .controller!
            .text,
        '499',
      );
      expect(
        textOf(tester, 'pay-preview'),
        contains('Nothing is owed after this.'),
      );
      await tapKey(tester, 'pay-save');
      expect(banner(tester), contains('Nothing is owed now.'));
      expect(textOf(tester, 'detail-owed'), 'Owes nothing now');
      expect(textOf(tester, 'dues-total'), '₹0.00');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('take-payment')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('cash over what is owed says to give change', (tester) async {
      await pickRavi(tester);
      await tapKey(tester, 'take-payment');
      await fill(tester, 'pay-cash', '1000');
      expect(textOf(tester, 'pay-preview'), contains('Give ₹501.00 change.'));
      await tapKey(tester, 'pay-save');
      expect(banner(tester), contains('Give ₹501.00 change.'));
    });

    testWidgets('UPI and card together', (tester) async {
      await pickRavi(tester);
      await tapKey(tester, 'take-payment');
      await fill(tester, 'pay-upi', '100');
      await fill(tester, 'pay-card', '50');
      expect(textOf(tester, 'pay-preview'), startsWith('Takes ₹150.00 off.'));
      await tapKey(tester, 'pay-save');
      final kinds = await tester.runAsync(
        () => db
            .customSelect(
              "SELECT kind FROM daybook WHERE kind LIKE 'DUES_%' ORDER BY kind",
            )
            .get(),
      );
      expect(kinds!.map((k) => k.read<String>('kind')), [
        'DUES_CARD',
        'DUES_UPI',
      ]);
    });

    testWidgets('UPI over what is owed cannot be saved', (tester) async {
      await pickRavi(tester);
      await tapKey(tester, 'take-payment');
      await fill(tester, 'pay-upi', '600');
      expect(
        textOf(tester, 'pay-problem'),
        'UPI and card together are more than is owed.',
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('pay-save')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('nothing typed and a bad amount cannot be saved', (
      tester,
    ) async {
      await pickRavi(tester);
      await tapKey(tester, 'take-payment');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('pay-save')))
            .onPressed,
        isNull,
      );
      await fill(tester, 'pay-cash', 'abc');
      expect(
        textOf(tester, 'pay-problem'),
        'An amount is not a valid rupee amount.',
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('pay-save')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('Cancel takes nothing', (tester) async {
      await pickRavi(tester);
      await tapKey(tester, 'take-payment');
      await fill(tester, 'pay-cash', '100');
      await tester.tap(find.text('Cancel'));
      await pump(tester);
      expect(textOf(tester, 'detail-owed'), 'Owes ₹499.00');
      final c = await tester.runAsync(
        () => db
            .customSelect('SELECT COUNT(*) AS c FROM dues_receipts')
            .getSingle(),
      );
      expect(c!.read<int>('c'), 0);
    });

    testWidgets('a manager can take it too', (tester) async {
      await pickRavi(tester, manager: true);
      await tapKey(tester, 'take-payment');
      await tapKey(tester, 'pay-all');
      await tapKey(tester, 'pay-save');
      expect(textOf(tester, 'detail-owed'), 'Owes nothing now');
    });

    testWidgets('the payment appears in the history', (tester) async {
      await pickRavi(tester);
      await tapKey(tester, 'take-payment');
      await fill(tester, 'pay-cash', '100');
      await tapKey(tester, 'pay-save');
      expect(find.textContaining('Paid'), findsWidgets);
      expect(find.text('-₹100.00'), findsOneWidget);
      expect(find.text('+₹499.00'), findsOneWidget);
    });
  });

  group('writing off', () {
    Future<void> pickRavi(WidgetTester tester, {bool manager = false}) async {
      await tester.runAsync(() => owe([kurta[0]]));
      await open(tester, manager: manager);
      await tapKey(tester, 'dues-customer-9876543210');
    }

    testWidgets('the owner sees the button; a manager does not', (
      tester,
    ) async {
      await pickRavi(tester);
      expect(find.byKey(const Key('write-off')), findsOneWidget);
    });

    testWidgets('a manager has no write-off button', (tester) async {
      await pickRavi(tester, manager: true);
      expect(find.byKey(const Key('take-payment')), findsOneWidget);
      expect(find.byKey(const Key('write-off')), findsNothing);
    });

    testWidgets('the owner writes off part, with a reason', (tester) async {
      await pickRavi(tester);
      await tapKey(tester, 'write-off');
      await fill(tester, 'writeoff-amount', '200');
      await fill(tester, 'writeoff-reason', 'moved away');
      await tapKey(tester, 'writeoff-save');
      expect(banner(tester), 'Wrote off ₹200.00 for Ravi Kumar.');
      expect(textOf(tester, 'detail-owed'), 'Owes ₹299.00');
      expect(find.textContaining('(moved away)'), findsOneWidget);
    });

    testWidgets('the whole amount is filled in at first', (tester) async {
      await pickRavi(tester);
      await tapKey(tester, 'write-off');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('writeoff-amount')))
            .controller!
            .text,
        '499',
      );
    });

    testWidgets('a reason, an amount and not too much are required', (
      tester,
    ) async {
      await pickRavi(tester);
      await tapKey(tester, 'write-off');
      await tapKey(tester, 'writeoff-save');
      expect(
        textOf(tester, 'writeoff-error'),
        'Say why the debt is written off.',
      );
      await fill(tester, 'writeoff-amount', '0');
      await fill(tester, 'writeoff-reason', 'x');
      await tapKey(tester, 'writeoff-save');
      expect(textOf(tester, 'writeoff-error'), 'Type an amount above zero.');
      await fill(tester, 'writeoff-amount', '500');
      await tapKey(tester, 'writeoff-save');
      expect(
        textOf(tester, 'writeoff-error'),
        'That is more than the customer owes.',
      );
      await fill(tester, 'writeoff-amount', 'abc');
      await tapKey(tester, 'writeoff-save');
      expect(textOf(tester, 'writeoff-error'), 'Type an amount above zero.');
      final c = await tester.runAsync(
        () => db
            .customSelect(
              "SELECT COUNT(*) AS c FROM dues_ledger WHERE kind = 'WRITE_OFF'",
            )
            .getSingle(),
      );
      expect(c!.read<int>('c'), 0);
    });
  });
}
