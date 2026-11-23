// The stock lookup screen: a cashier checks "do you have this in M, blue?"
// from Sales Mode; a manager or owner from the left menu. No cost anywhere.
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
import 'package:pos_windows/data/stock_lookup_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late AuthService auth;
  late SessionController session;
  late String ownerId;
  late String ashaId;
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    auth = AuthService(db, newId: newId);
    final stock = StockRepository(db, newId: newId);
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
            quantity: 3,
            cost: Money(23456),
            mrp: Money(49900),
          ),
          PurchaseLine(
            size: 'L',
            color: 'Blue',
            quantity: 1,
            cost: Money(23456),
            mrp: Money(54900),
          ),
        ],
      ),
    );
    await stock.receivePurchase(
      role: Role.owner,
      draft: PurchaseDraft(
        supplier: 'S',
        style: 'Denim Jeans',
        lines: [
          PurchaseLine(
            size: 'L',
            color: 'Black',
            quantity: 1,
            cost: Money(23456),
            mrp: Money(129900),
          ),
        ],
      ),
    );
    final blueL =
        (await db
                .customSelect(
                  "SELECT a.barcode_value AS b FROM articles a JOIN variants v ON v.id = a.variant_id WHERE v.size = 'L' AND v.color = 'Blue' AND a.batch_id = ?",
                  variables: [Variable<String>(r.batchId)],
                )
                .getSingle())
            .read<String>('b');
    await db.customStatement(
      "UPDATE articles SET status = 'SOLD' WHERE barcode_value = '$blueL'",
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
    bool owner = false,
    bool withLookup = true,
  }) async {
    tester.view.physicalSize = const Size(1500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await session.start();
      await session.signIn(
        owner ? ownerId : ashaId,
        owner ? 'a long passphrase' : '482916',
      );
      if (!owner) {
        await ShiftRepository(
          db,
          newId: newId,
        ).openShift(role: Role.cashier, userId: ashaId, counts: const {});
      }
    });
    await tester.pumpWidget(
      PosApp(
        session: session,
        services: AppServices(
          stock: StockRepository(db, newId: newId),
          sales: SalesRepository(db, newId: newId),
          returns: ReturnsRepository(db, newId: newId),
          shifts: ShiftRepository(db, newId: newId),
          reports: ReportRepository(db),
          auth: auth,
          stockLookup: withLookup ? StockLookupRepository(db) : null,
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

  Future<void> goToLookup(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('stock-lookup-button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await pump(tester);
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('lookup-field')), text);
    await pump(tester);
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  group('getting there', () {
    testWidgets('a cashier has a Stock button in the top bar', (tester) async {
      await open(tester);
      await goToLookup(tester);
      expect(find.byKey(const Key('lookup-field')), findsOneWidget);
    });

    testWidgets('a manager or owner has Stock lookup in the left menu', (
      tester,
    ) async {
      await open(tester, owner: true);
      await goToLookup(tester);
      expect(find.byKey(const Key('lookup-field')), findsOneWidget);
    });

    testWidgets('without the lookup service the buttons are not shown', (
      tester,
    ) async {
      await open(tester, withLookup: false);
      expect(find.byKey(const Key('stock-lookup-button')), findsNothing);
    });

    testWidgets(
      'a bill in progress is still there when the cashier comes back',
      (tester) async {
        await open(tester);
        await goToLookup(tester);
        await tester.pageBack();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byKey(const Key('barcode-field')), findsOneWidget);
      },
    );
  });

  group('what the cashier sees', () {
    testWidgets('every style at first, with what is in stock', (tester) async {
      await open(tester);
      await goToLookup(tester);
      expect(find.byKey(const Key('style-Cotton Kurta')), findsOneWidget);
      expect(find.byKey(const Key('style-Denim Jeans')), findsOneWidget);
      expect(textOf(tester, 'style-total-Cotton Kurta'), '3 in stock');
    });

    testWidgets('typing narrows it; sizes and colors show counts and MRP', (
      tester,
    ) async {
      await open(tester);
      await goToLookup(tester);
      await type(tester, 'kurta');
      expect(find.byKey(const Key('style-Denim Jeans')), findsNothing);
      expect(textOf(tester, 'count-Cotton Kurta-M-Blue'), '3 in stock');
      expect(textOf(tester, 'count-Cotton Kurta-L-Blue'), 'None left');
      expect(find.text('₹499.00'), findsOneWidget);
      expect(find.text('₹549.00'), findsOneWidget);
    });

    testWidgets('a style that is not in the shop says so', (tester) async {
      await open(tester);
      await goToLookup(tester);
      await type(tester, 'saree');
      expect(find.byKey(const Key('lookup-empty')), findsOneWidget);
    });

    testWidgets('no cost appears anywhere on the screen', (tester) async {
      await open(tester);
      await goToLookup(tester);
      await type(tester, 'kurta');
      expect(find.textContaining('234'), findsNothing);
      expect(find.textContaining('Cost'), findsNothing);
      expect(find.textContaining('cost'), findsNothing);
    });

    testWidgets('a manager sees the same, still no cost', (tester) async {
      await open(tester, owner: true);
      await goToLookup(tester);
      await type(tester, 'kurta');
      expect(textOf(tester, 'count-Cotton Kurta-M-Blue'), '3 in stock');
      expect(find.textContaining('234'), findsNothing);
    });
  });
}
