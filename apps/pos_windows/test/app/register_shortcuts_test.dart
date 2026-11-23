// Register shortcuts and Hold bill: F4 puts the bill aside, F6 starts a fresh
// search, Esc closes the bill-done popup or the name results.
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:core_domain/credential_hasher.dart';
import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late StockRepository stock;
  late SalesRepository sales;
  late ShiftRepository shifts;
  late SessionController session;
  late String cashierId;
  late List<String> kurtaM; // 2 x M Blue at 499
  late List<String> denim; // 1 x L Black at 1299
  late String ashaHash;
  var n = 0;
  String newId() => 'id-${++n}';

  setUpAll(() => ashaHash = CredentialHasher().hash('482916'));

  Future<List<String>> codesOf(String batchId, {String? size}) async => [
    for (final r
        in await db
            .customSelect(
              'SELECT a.barcode_value AS b FROM articles a JOIN variants v ON v.id = a.variant_id '
              'WHERE a.batch_id = ? ${size == null ? '' : "AND v.size = '$size'"} ORDER BY a.barcode_value',
              variables: [Variable<String>(batchId)],
            )
            .get())
      r.read<String>('b'),
  ];

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    auth = AuthService(db, newId: newId);
    stock = StockRepository(db, newId: newId);
    sales = SalesRepository(db, newId: newId);
    shifts = ShiftRepository(db, newId: newId);
    session = SessionController(auth: auth);
    await stock.ensureCounter();
    await stock.seedDefaultOptions();
    final a = await stock.receivePurchase(
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
            cost: Money(20000),
            mrp: Money(54900),
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
            quantity: 1,
            cost: Money(60000),
            mrp: Money(129900),
          ),
        ],
      ),
    );
    kurtaM = await codesOf(a.batchId, size: 'M');
    denim = await codesOf(b.batchId);
    cashierId = newId();
    await db
        .into(db.users)
        .insert(
          UsersCompanion.insert(
            id: cashierId,
            name: 'Asha',
            role: 'CASHIER',
            credentialHash: ashaHash,
            createdAt: DateTime.utc(2026, 11, 20),
            updatedAt: DateTime.utc(2026, 11, 20),
          ),
        );
    await shifts.openShift(
      role: Role.cashier,
      userId: cashierId,
      counts: const {},
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

  Future<void> open(WidgetTester tester, {bool withLookup = true}) async {
    tester.view.physicalSize = const Size(1500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await session.start();
      await session.signIn(cashierId, '482916');
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

  Future<void> typeIn(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('barcode-field')), text);
    await pump(tester);
  }

  String fieldText(WidgetTester tester) => tester
      .widget<TextField>(find.byKey(const Key('barcode-field')))
      .controller!
      .text;

  Future<void> scan(WidgetTester tester, String code) async {
    await tester.enterText(find.byKey(const Key('barcode-field')), code);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pump(tester);
  }

  Future<void> key(WidgetTester tester, LogicalKeyboardKey k) async {
    await tester.sendKeyEvent(k);
    await pump(tester);
  }

  bool enabled(WidgetTester tester, String k) =>
      tester.widget<ButtonStyleButton>(find.byKey(Key(k))).onPressed != null;

  group('F4 hold bill', () {
    testWidgets('puts the bill aside and starts an empty one', (tester) async {
      await open(tester);
      await scan(tester, kurtaM[0]);
      await scan(tester, denim[0]);
      await key(tester, LogicalKeyboardKey.f4);
      expect(find.byKey(Key('line-${kurtaM[0]}')), findsNothing);
      expect(find.byKey(const Key('held-bills')), findsOneWidget);
      expect(find.text('Held 1: 2 garments, ₹1,798.00'), findsOneWidget);
      expect(find.text('₹0.00'), findsWidgets);
    });

    testWidgets('does nothing when the bill is empty', (tester) async {
      await open(tester);
      await key(tester, LogicalKeyboardKey.f4);
      expect(find.byKey(const Key('held-bills')), findsNothing);
      expect(enabled(tester, 'hold-bill'), isFalse);
    });

    testWidgets('the Hold bill button does the same', (tester) async {
      await open(tester);
      await scan(tester, kurtaM[0]);
      expect(enabled(tester, 'hold-bill'), isTrue);
      await tester.tap(find.byKey(const Key('hold-bill')));
      await pump(tester);
      expect(find.byKey(const Key('held-label-0')), findsOneWidget);
    });

    testWidgets('Resume brings back the garments, discount and customer', (
      tester,
    ) async {
      await open(tester);
      await scan(tester, kurtaM[0]);
      await tester.enterText(find.byKey(const Key('customer-name')), 'Meera');
      await key(tester, LogicalKeyboardKey.f4);
      await scan(tester, denim[0]);
      await key(tester, LogicalKeyboardKey.f4);
      expect(find.byKey(const Key('held-label-1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('held-resume-0')));
      await pump(tester);
      expect(find.byKey(Key('line-${kurtaM[0]}')), findsOneWidget);
      expect(find.byKey(Key('line-${denim[0]}')), findsNothing);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('customer-name')))
            .controller!
            .text,
        'Meera',
      );
      expect(find.byKey(const Key('held-label-0')), findsOneWidget);
      expect(find.byKey(const Key('held-label-1')), findsNothing);
    });

    testWidgets('Resume keeps the way of paying that was chosen', (
      tester,
    ) async {
      await open(tester);
      await scan(tester, kurtaM[0]);
      await tester.tap(find.byKey(const Key('method-upi')));
      await pump(tester);
      await key(tester, LogicalKeyboardKey.f4);
      // the new bill starts on Cash
      expect(find.byKey(const Key('non-cash-note')), findsNothing);
      await tester.tap(find.byKey(const Key('held-resume-0')));
      await pump(tester);
      expect(find.byKey(const Key('non-cash-note')), findsOneWidget);
    });

    testWidgets('will not resume over a bill that is on screen', (
      tester,
    ) async {
      await open(tester);
      await scan(tester, kurtaM[0]);
      await key(tester, LogicalKeyboardKey.f4);
      await scan(tester, denim[0]);
      await tester.tap(find.byKey(const Key('held-resume-0')));
      await pump(tester);
      expect(find.byKey(Key('line-${denim[0]}')), findsOneWidget);
      expect(find.byKey(Key('line-${kurtaM[0]}')), findsNothing);
      expect(find.byKey(const Key('held-label-0')), findsOneWidget);
      expect(find.textContaining('Finish or hold the bill'), findsOneWidget);
    });

    testWidgets('a held garment cannot be put on another bill', (tester) async {
      await open(tester);
      await scan(tester, kurtaM[0]);
      await key(tester, LogicalKeyboardKey.f4);
      await scan(tester, kurtaM[0]);
      expect(find.byKey(Key('line-${kurtaM[0]}')), findsNothing);
      expect(find.textContaining('is on a held bill'), findsOneWidget);
    });

    testWidgets('Drop forgets a held bill', (tester) async {
      await open(tester);
      await scan(tester, kurtaM[0]);
      await key(tester, LogicalKeyboardKey.f4);
      await tester.tap(find.byKey(const Key('held-drop-0')));
      await pump(tester);
      expect(find.byKey(const Key('held-bills')), findsNothing);
      await scan(tester, kurtaM[0]);
      expect(find.byKey(Key('line-${kurtaM[0]}')), findsOneWidget);
    });

    testWidgets('while a bill is held, Pause and Close shift stay off', (
      tester,
    ) async {
      await open(tester);
      expect(enabled(tester, 'pause-button'), isTrue);
      await scan(tester, kurtaM[0]);
      await key(tester, LogicalKeyboardKey.f4);
      await pump(tester);
      expect(enabled(tester, 'pause-button'), isFalse);
      expect(enabled(tester, 'close-shift-button'), isFalse);
      await tester.tap(find.byKey(const Key('held-drop-0')));
      await pump(tester);
      expect(enabled(tester, 'pause-button'), isTrue);
    });

    testWidgets('a resumed bill can be completed and saved', (tester) async {
      await open(tester);
      await scan(tester, kurtaM[0]);
      await key(tester, LogicalKeyboardKey.f4);
      await tester.tap(find.byKey(const Key('held-resume-0')));
      await pump(tester);
      await tester.tap(find.byKey(const Key('exact-cash')));
      await pump(tester);
      await key(tester, LogicalKeyboardKey.f9);
      expect(find.byKey(const Key('saved-title')), findsOneWidget);
    });
  });

  group('F6 and Esc', () {
    testWidgets('F6 clears the box and the name list for a fresh search', (
      tester,
    ) async {
      await open(tester);
      await typeIn(tester, 'kurta');
      expect(find.byKey(const Key('name-results')), findsOneWidget);
      await key(tester, LogicalKeyboardKey.f6);
      expect(find.byKey(const Key('name-results')), findsNothing);
      expect(fieldText(tester), '');
    });

    testWidgets('Esc closes the name list', (tester) async {
      await open(tester);
      await typeIn(tester, 'kurta');
      await key(tester, LogicalKeyboardKey.escape);
      expect(find.byKey(const Key('name-results')), findsNothing);
      expect(fieldText(tester), '');
    });

    testWidgets('Esc leaves a bill in progress alone', (tester) async {
      await open(tester);
      await scan(tester, kurtaM[0]);
      await key(tester, LogicalKeyboardKey.escape);
      expect(find.byKey(Key('line-${kurtaM[0]}')), findsOneWidget);
    });

    testWidgets('Esc closes the bill-done popup', (tester) async {
      await open(tester);
      await scan(tester, kurtaM[0]);
      await tester.tap(find.byKey(const Key('exact-cash')));
      await pump(tester);
      await key(tester, LogicalKeyboardKey.f9);
      expect(find.byKey(const Key('bill-done-popup')), findsOneWidget);
      await key(tester, LogicalKeyboardKey.escape);
      expect(find.byKey(const Key('bill-done-popup')), findsNothing);
      expect(find.byKey(Key('line-${kurtaM[0]}')), findsNothing);
    });

    testWidgets('the shortcut hints are shown', (tester) async {
      await open(tester);
      for (final hint in ['F4 Hold bill', 'F6 New search', 'Esc Close popup']) {
        expect(
          find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText() == hint,
          ),
          findsOneWidget,
          reason: hint,
        );
      }
    });
  });
}
