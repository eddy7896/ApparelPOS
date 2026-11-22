// Billing: find an item by name as well as by scanning its tag. Typing letters
// lists the shop's styles by size and color (cashier-safe, no cost); the cashier
// picks one and the lowest in-stock barcode goes on the bill. Typing digits is
// still a barcode or credit note.
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:core_domain/credential_hasher.dart';
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
  late StockRepository stock;
  late SalesRepository sales;
  late ShiftRepository shifts;
  late SessionController session;
  late String cashierId;
  late List<String> kurtaM; // 2 x M Blue at 499
  late List<String> denim; // 1 x L Black at 1299
  late List<String> linen; // 5 x S White at 899
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
    final c = await stock.receivePurchase(
      role: Role.owner,
      draft: PurchaseDraft(
        supplier: 'S',
        style: 'Linen Shirt',
        lines: [
          PurchaseLine(
            size: 'S',
            color: 'White',
            quantity: 5,
            cost: Money(30000),
            mrp: Money(89900),
          ),
        ],
      ),
    );
    linen = await codesOf(c.batchId);
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

  Future<void> pick(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await pump(tester);
  }

  String fieldText(WidgetTester tester) => tester
      .widget<TextField>(find.byKey(const Key('barcode-field')))
      .controller!
      .text;

  group('the search box', () {
    testWidgets('says you can scan a tag or type an item name', (tester) async {
      await open(tester);
      expect(find.text('Scan a tag, or type an item name'), findsOneWidget);
    });

    testWidgets('without the lookup service it is the old barcode box', (
      tester,
    ) async {
      await open(tester, withLookup: false);
      expect(find.textContaining('Scan or type a barcode'), findsOneWidget);
      await typeIn(tester, 'kurta');
      expect(find.byKey(const Key('name-results')), findsNothing);
    });

    testWidgets('typing digits does not open the list; scanning still works', (
      tester,
    ) async {
      await open(tester);
      await typeIn(tester, '1234');
      expect(find.byKey(const Key('name-results')), findsNothing);
      await tester.enterText(find.byKey(const Key('barcode-field')), kurtaM[0]);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await pump(tester);
      expect(find.byKey(Key('line-${kurtaM[0]}')), findsOneWidget);
    });
  });

  group('searching by name', () {
    testWidgets(
      'lists the style with each size and color, its price and how many are left',
      (tester) async {
        await open(tester);
        await typeIn(tester, 'kurta');
        expect(find.byKey(const Key('name-results')), findsOneWidget);
        expect(
          find.byKey(const Key('name-style-Cotton Kurta')),
          findsOneWidget,
        );
        expect(find.text('M Blue  ₹499.00  2 left'), findsOneWidget);
        expect(find.text('L Blue  ₹549.00  1 left'), findsOneWidget);
        expect(find.byKey(const Key('name-style-Denim Jeans')), findsNothing);
      },
    );

    testWidgets('capitals do not matter; part of a name is enough', (
      tester,
    ) async {
      await open(tester);
      await typeIn(tester, 'DEN');
      expect(find.byKey(const Key('name-style-Denim Jeans')), findsOneWidget);
    });

    testWidgets('nothing matching says so', (tester) async {
      await open(tester);
      await typeIn(tester, 'saree');
      expect(find.byKey(const Key('name-results-empty')), findsOneWidget);
    });

    testWidgets('clearing the box closes the list', (tester) async {
      await open(tester);
      await typeIn(tester, 'kurta');
      await typeIn(tester, '');
      expect(find.byKey(const Key('name-results')), findsNothing);
    });

    testWidgets('a size and color that is used up cannot be picked', (
      tester,
    ) async {
      await db.customStatement(
        "UPDATE articles SET status = 'SOLD' WHERE barcode_value = '${denim[0]}'",
      );
      await open(tester);
      await typeIn(tester, 'denim');
      final b = tester.widget<OutlinedButton>(
        find.byKey(const Key('pick-Denim Jeans-L-Black')),
      );
      expect(b.onPressed, isNull);
      expect(find.text('L Black  none left'), findsOneWidget);
    });

    testWidgets('no cost appears in the list', (tester) async {
      await open(tester);
      await typeIn(tester, 'kurta');
      expect(find.textContaining('200'), findsNothing);
      expect(find.textContaining('cost'), findsNothing);
    });
  });

  group('picking one', () {
    testWidgets('puts the lowest barcode on the bill and clears the box', (
      tester,
    ) async {
      await open(tester);
      await typeIn(tester, 'kurta');
      await pick(tester, 'pick-Cotton Kurta-M-Blue');
      expect(find.byKey(Key('line-${kurtaM[0]}')), findsOneWidget);
      expect(find.byKey(const Key('name-results')), findsNothing);
      expect(fieldText(tester), '');
      expect(
        tester.widget<Text>(find.byKey(const Key('total-text'))).data,
        '₹499.00',
      );
    });

    testWidgets(
      'picking the same size again adds the next garment, not the same one',
      (tester) async {
        await open(tester);
        for (var i = 0; i < 2; i++) {
          await typeIn(tester, 'kurta');
          await pick(tester, 'pick-Cotton Kurta-M-Blue');
        }
        expect(find.byKey(Key('line-${kurtaM[0]}')), findsOneWidget);
        expect(find.byKey(Key('line-${kurtaM[1]}')), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(const Key('total-text'))).data,
          '₹998.00',
        );
      },
    );

    testWidgets(
      'when every garment of that size is already on the bill, it says so',
      (tester) async {
        await open(tester);
        for (var i = 0; i < 3; i++) {
          await typeIn(tester, 'kurta');
          await pick(tester, 'pick-Cotton Kurta-M-Blue');
        }
        expect(find.byKey(const Key('message-banner')), findsOneWidget);
        expect(find.textContaining('already on this bill'), findsOneWidget);
        expect(find.byKey(Key('line-${kurtaM[0]}')), findsOneWidget);
      },
    );

    testWidgets('a picked garment can be paid for and is then sold', (
      tester,
    ) async {
      await open(tester);
      await typeIn(tester, 'denim');
      await pick(tester, 'pick-Denim Jeans-L-Black');
      await tester.tap(find.byKey(const Key('exact-cash')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('complete-bill')));
      await pump(tester);
      expect(find.byKey(const Key('saved-title')), findsOneWidget);
      final status = await tester.runAsync(
        () async =>
            (await db
                    .customSelect(
                      "SELECT status FROM articles WHERE barcode_value = '${denim[0]}'",
                    )
                    .getSingle())
                .read<String>('status'),
      );
      expect(status, 'SOLD');
    });

    testWidgets('a garment sold meanwhile is refused with the usual message', (
      tester,
    ) async {
      await open(tester);
      await typeIn(tester, 'denim');
      await tester.runAsync(
        () => db.customStatement(
          "UPDATE articles SET status = 'SOLD' WHERE barcode_value = '${denim[0]}'",
        ),
      );
      await pick(tester, 'pick-Denim Jeans-L-Black');
      expect(find.textContaining('Already sold'), findsOneWidget);
      expect(find.byKey(Key('line-${denim[0]}')), findsNothing);
    });
  });

  group('Enter', () {
    testWidgets('with one size and color in stock, adds it', (tester) async {
      await open(tester);
      await typeIn(tester, 'denim');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await pump(tester);
      expect(find.byKey(Key('line-${denim[0]}')), findsOneWidget);
    });

    testWidgets('with several to choose from, asks the cashier to choose', (
      tester,
    ) async {
      await open(tester);
      await typeIn(tester, 'kurta');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await pump(tester);
      expect(find.textContaining('Choose the size and color'), findsOneWidget);
      expect(find.byKey(Key('line-${kurtaM[0]}')), findsNothing);
      expect(find.byKey(const Key('name-results')), findsOneWidget);
    });

    testWidgets('with nothing matching, says so', (tester) async {
      await open(tester);
      await typeIn(tester, 'saree');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await pump(tester);
      expect(find.textContaining('No style like "saree"'), findsOneWidget);
    });
  });

  group('several of one size and color (multiples)', () {
    String qty(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const Key('qty-value'))).data!;

    testWidgets('the quantity starts at 1, goes up and down, and stops at 1', (
      tester,
    ) async {
      await open(tester);
      await typeIn(tester, 'linen');
      expect(qty(tester), '1');
      await tester.tap(find.byKey(const Key('qty-plus')));
      await tester.tap(find.byKey(const Key('qty-plus')));
      await tester.pump();
      expect(qty(tester), '3');
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('qty-minus')));
      }
      await tester.pump();
      expect(qty(tester), '1');
    });

    testWidgets(
      'picking with 3 puts the 3 lowest barcodes on the bill, then the quantity is 1 again',
      (tester) async {
        await open(tester);
        await typeIn(tester, 'linen');
        await tester.tap(find.byKey(const Key('qty-plus')));
        await tester.tap(find.byKey(const Key('qty-plus')));
        await tester.pump();
        await pick(tester, 'pick-Linen Shirt-S-White');
        for (var i = 0; i < 3; i++) {
          expect(find.byKey(Key('line-${linen[i]}')), findsOneWidget);
        }
        expect(find.byKey(Key('line-${linen[3]}')), findsNothing);
        expect(
          tester.widget<Text>(find.byKey(const Key('total-text'))).data,
          '₹2,697.00',
        );
        await typeIn(tester, 'linen');
        expect(qty(tester), '1');
      },
    );

    testWidgets(
      'asking for more than are in stock adds what there is and says so',
      (tester) async {
        await open(tester);
        await typeIn(tester, 'kurta');
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.byKey(const Key('qty-plus')));
        }
        await tester.pump();
        await pick(tester, 'pick-Cotton Kurta-M-Blue'); // 4 wanted, 2 in stock
        expect(find.byKey(Key('line-${kurtaM[0]}')), findsOneWidget);
        expect(find.byKey(Key('line-${kurtaM[1]}')), findsOneWidget);
        expect(
          find.textContaining('Only 2 of 4 could be added'),
          findsOneWidget,
        );
      },
    );

    testWidgets('quantity skips garments already on the bill', (tester) async {
      await open(tester);
      await tester.enterText(find.byKey(const Key('barcode-field')), linen[0]);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await pump(tester);
      await typeIn(tester, 'linen');
      await tester.tap(find.byKey(const Key('qty-plus')));
      await tester.pump();
      await pick(tester, 'pick-Linen Shirt-S-White');
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(Key('line-${linen[i]}')), findsOneWidget);
      }
      expect(find.byKey(Key('line-${linen[3]}')), findsNothing);
    });

    testWidgets(
      'a bill line has a button to add another of the same size and color',
      (tester) async {
        await open(tester);
        await typeIn(tester, 'linen');
        await pick(tester, 'pick-Linen Shirt-S-White');
        await tester.tap(find.byKey(Key('more-${linen[0]}')));
        await pump(tester);
        expect(find.byKey(Key('line-${linen[1]}')), findsOneWidget);
        await tester.tap(find.byKey(Key('more-${linen[0]}')));
        await pump(tester);
        expect(find.byKey(Key('line-${linen[2]}')), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(const Key('total-text'))).data,
          '₹2,697.00',
        );
      },
    );

    testWidgets(
      'the add-another button adds exactly one, whatever the quantity box says',
      (tester) async {
        await open(tester);
        await tester.enterText(
          find.byKey(const Key('barcode-field')),
          linen[0],
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await pump(tester);
        await typeIn(tester, 'linen');
        await tester.tap(find.byKey(const Key('qty-plus')));
        await tester.tap(find.byKey(const Key('qty-plus')));
        await tester.pump();
        await tester.tap(find.byKey(Key('more-${linen[0]}')));
        await pump(tester);
        expect(find.byKey(Key('line-${linen[1]}')), findsOneWidget);
        expect(find.byKey(Key('line-${linen[2]}')), findsNothing);
      },
    );

    testWidgets('the add-another button never reaches a different size', (
      tester,
    ) async {
      await open(tester);
      await tester.enterText(find.byKey(const Key('barcode-field')), kurtaM[0]);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await pump(tester);
      await tester.tap(find.byKey(Key('more-${kurtaM[0]}')));
      await pump(tester);
      expect(find.byKey(Key('line-${kurtaM[1]}')), findsOneWidget);
      await tester.tap(
        find.byKey(Key('more-${kurtaM[0]}')),
      ); // only 2 M Blue exist
      await pump(tester);
      expect(find.textContaining('already on this bill'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key as ValueKey<String>).value.startsWith('line-'),
        ),
        findsNWidgets(2),
      ); // the L Blue was not added
    });

    testWidgets('without the lookup service there is no add-another button', (
      tester,
    ) async {
      await open(tester, withLookup: false);
      await tester.enterText(find.byKey(const Key('barcode-field')), kurtaM[0]);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await pump(tester);
      expect(find.byKey(Key('more-${kurtaM[0]}')), findsNothing);
    });

    testWidgets('three of one article can be paid for and are all sold', (
      tester,
    ) async {
      await open(tester);
      await typeIn(tester, 'linen');
      await tester.tap(find.byKey(const Key('qty-plus')));
      await tester.tap(find.byKey(const Key('qty-plus')));
      await tester.pump();
      await pick(tester, 'pick-Linen Shirt-S-White');
      await tester.tap(find.byKey(const Key('exact-cash')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('complete-bill')));
      await pump(tester);
      expect(find.byKey(const Key('saved-title')), findsOneWidget);
      final sold = await tester.runAsync(
        () async =>
            (await db
                    .customSelect(
                      "SELECT COUNT(*) AS c FROM articles WHERE status = 'SOLD'",
                    )
                    .getSingle())
                .read<int>('c'),
      );
      expect(sold, 3);
    });
  });
}
