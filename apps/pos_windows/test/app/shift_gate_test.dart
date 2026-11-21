// Opening a shift before selling or taking a return: the cash count form and
// the gate in front of the register and the returns screen. P2-6b.
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
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

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late AuthService auth;
  late ShiftRepository shifts;
  late SessionController session;
  late String cashierId;
  late String managerId;
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    auth = AuthService(db, newId: newId);
    final stock = StockRepository(db, newId: newId);
    shifts = ShiftRepository(db, newId: newId);
    session = SessionController(auth: auth);
    await stock.ensureCounter();
    cashierId = await auth.createUser(
      name: 'Asha',
      role: Role.cashier,
      secret: '482916',
    );
    managerId = await auth.createUser(
      name: 'Meera',
      role: Role.manager,
      secret: 'a long passphrase',
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

  Future<void> open(WidgetTester tester, {bool manager = false}) async {
    tester.view.physicalSize = const Size(1500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await session.start();
      await session.signIn(
        manager ? managerId : cashierId,
        manager ? 'a long passphrase' : '482916',
      );
    });
    await tester.pumpWidget(
      PosApp(
        session: session,
        services: AppServices(
          stock: StockRepository(db, newId: newId),
          sales: SalesRepository(db, newId: newId),
          returns: ReturnsRepository(db, newId: newId),
          shifts: shifts,
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

  Future<void> count(WidgetTester tester, String denom, String n) async {
    await tester.enterText(find.byKey(Key('count-$denom')), n);
    await tester.pump();
  }

  testWidgets(
    'a cashier with no shift sees the open-shift form, not the register',
    (tester) async {
      await open(tester);
      expect(find.byKey(const Key('open-shift-title')), findsOneWidget);
      expect(find.byKey(const Key('barcode-field')), findsNothing);
      expect(find.byKey(const Key('count-note500')), findsOneWidget);
      expect(find.byKey(const Key('count-coin1')), findsOneWidget);
      expect(find.byKey(const Key('count-note2000')), findsNothing);
    },
  );

  testWidgets('the total follows what is typed', (tester) async {
    await open(tester);
    expect(textOf(tester, 'count-total'), 'Total counted: ₹0.00');
    await count(tester, 'note500', '2');
    await count(tester, 'coin10', '3');
    await count(tester, 'note10', '1');
    expect(textOf(tester, 'count-total'), 'Total counted: ₹1,040.00');
  });

  testWidgets('an absurd count disables the button', (tester) async {
    await open(tester);
    await count(tester, 'note500', '${maxCountPerDenomination + 1}');
    expect(textOf(tester, 'count-total'), contains('too big'));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('count-submit')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('opening the shift records the count and shows the register', (
    tester,
  ) async {
    await open(tester);
    await count(tester, 'note500', '4');
    await tester.tap(find.byKey(const Key('count-submit')));
    await pump(tester);
    expect(find.byKey(const Key('barcode-field')), findsOneWidget);
    expect(find.byKey(const Key('open-shift-title')), findsNothing);
    final row = await tester.runAsync(
      () => db
          .customSelect('SELECT opening_paise, cashier_id FROM shifts')
          .getSingle(),
    );
    expect(row!.read<int>('opening_paise'), 200000);
    expect(row.read<String>('cashier_id'), cashierId);
  });

  testWidgets('an empty drawer can open a shift', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('count-submit')));
    await pump(tester);
    expect(find.byKey(const Key('barcode-field')), findsOneWidget);
  });

  testWidgets('with a shift already open the register shows straight away', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await session.start();
      await shifts.openShift(
        role: Role.cashier,
        userId: cashierId,
        counts: const {},
      );
    });
    await open(tester);
    expect(find.byKey(const Key('barcode-field')), findsOneWidget);
  });

  testWidgets('a manager opening Billing or Returns is asked for a shift too', (
    tester,
  ) async {
    await open(tester, manager: true);
    await tester.tap(find.byKey(const Key('billing-button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await pump(tester);
    expect(find.byKey(const Key('open-shift-title')), findsOneWidget);
    expect(find.byKey(const Key('barcode-field')), findsNothing);
  });

  testWidgets('the cashier Returns screen is gated as well', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('returns-button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await pump(tester);
    expect(find.byKey(const Key('open-shift-title')), findsOneWidget);
    expect(find.byKey(const Key('return-barcode-field')), findsNothing);
  });
}
