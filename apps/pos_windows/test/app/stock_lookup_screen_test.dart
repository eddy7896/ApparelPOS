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
import 'package:pos_windows/app/ui/ui_tokens.dart';
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
      expect(textOf(tester, 'count-Cotton Kurta-L-Blue'), 'Out of stock');
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

  group('out of stock and running low, made obvious', () {
    testWidgets(
      'an out-of-stock size and color is red, with the words, a block icon and a struck-through name',
      (tester) async {
        await open(tester);
        await goToLookup(tester);
        await type(tester, 'kurta');
        final tile = tester.widget<Container>(
          find.byKey(const Key('variant-Cotton Kurta-L-Blue')),
        );
        expect((tile.decoration as BoxDecoration).color, UiColors.dangerSoft);
        expect(textOf(tester, 'count-Cotton Kurta-L-Blue'), 'Out of stock');
        expect(
          find.descendant(
            of: find.byKey(const Key('variant-Cotton Kurta-L-Blue')),
            matching: find.byIcon(Icons.block),
          ),
          findsOneWidget,
        );
        final name = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const Key('variant-Cotton Kurta-L-Blue')),
            matching: find.text('L · Blue'),
          ),
        );
        expect(name.style?.decoration, TextDecoration.lineThrough);
        final ok = tester.widget<Container>(
          find.byKey(const Key('variant-Cotton Kurta-M-Blue')),
        );
        expect(
          (ok.decoration as BoxDecoration).color,
          isNot(UiColors.dangerSoft),
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('variant-Cotton Kurta-M-Blue')),
            matching: find.byIcon(Icons.block),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('one or two left is amber and says Only N left', (
      tester,
    ) async {
      await open(tester);
      await goToLookup(tester);
      await type(tester, 'denim');
      expect(textOf(tester, 'count-Denim Jeans-L-Black'), 'Only 1 left');
      expect(textOf(tester, 'style-total-Denim Jeans'), 'Only 1 left');
      final tile = tester.widget<Container>(
        find.byKey(const Key('variant-Denim Jeans-L-Black')),
      );
      expect((tile.decoration as BoxDecoration).color, UiColors.amberSoft);
      expect(
        find.descendant(
          of: find.byKey(const Key('variant-Denim Jeans-L-Black')),
          matching: find.byIcon(Icons.warning_amber_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a style with nothing left says Out of stock on its header', (
      tester,
    ) async {
      await db.customStatement(
        "UPDATE articles SET status = 'SOLD' WHERE variant_id IN (SELECT v.id FROM variants v JOIN products p ON p.id = v.product_id WHERE p.name = 'Denim Jeans')",
      );
      await open(tester);
      await goToLookup(tester);
      await type(tester, 'denim');
      expect(textOf(tester, 'style-total-Denim Jeans'), 'Out of stock');
    });

    testWidgets(
      'a summary counts the sizes and colors that are out and running low',
      (tester) async {
        await open(tester);
        await goToLookup(tester);
        expect(
          textOf(tester, 'lookup-summary-text'),
          '1 size and color is out of stock, 1 running low',
        );
      },
    );

    testWidgets('the summary is amber, not red, when nothing is out but something is low', (tester) async {
      await db.customStatement("UPDATE articles SET status = 'IN_STOCK'");
      await db.customStatement(
        "INSERT INTO articles (id, barcode_value, variant_id, batch_id, mrp_paise, status, created_at, updated_at) SELECT 'x1', '999900000001', variant_id, batch_id, mrp_paise, 'IN_STOCK', created_at, updated_at FROM articles LIMIT 1",
      );
      await open(tester);
      await goToLookup(tester);
      // Cotton Kurta L Blue is back to 1 (low) so the summary is the amber one, not red
      final box = tester.widget<Container>(
        find.byKey(const Key('lookup-summary')),
      );
      expect((box.decoration as BoxDecoration).color, UiColors.amberSoft);
    });

    testWidgets(
      'filter chips show counts: all, in stock, running low, out of stock',
      (tester) async {
        await open(tester);
        await goToLookup(tester);
        expect(find.text('All (3)'), findsOneWidget);
        expect(find.text('In stock (2)'), findsOneWidget);
        expect(find.text('Running low (1)'), findsOneWidget);
        expect(find.text('Out of stock (1)'), findsOneWidget);
      },
    );

    testWidgets(
      'Out of stock shows only what is out, hiding the styles that have none',
      (tester) async {
        await open(tester);
        await goToLookup(tester);
        await tester.tap(find.byKey(const Key('filter-out')));
        await tester.pump();
        expect(
          find.byKey(const Key('variant-Cotton Kurta-L-Blue')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('variant-Cotton Kurta-M-Blue')),
          findsNothing,
        );
        expect(find.byKey(const Key('style-Denim Jeans')), findsNothing);
      },
    );

    testWidgets(
      'Running low shows only what is running low; In stock hides what is out',
      (tester) async {
        await open(tester);
        await goToLookup(tester);
        await tester.tap(find.byKey(const Key('filter-low')));
        await tester.pump();
        expect(
          find.byKey(const Key('variant-Denim Jeans-L-Black')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('style-Cotton Kurta')), findsNothing);
        await tester.tap(find.byKey(const Key('filter-in')));
        await tester.pump();
        expect(
          find.byKey(const Key('variant-Cotton Kurta-L-Blue')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('variant-Cotton Kurta-M-Blue')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('variant-Denim Jeans-L-Black')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'a filter with nothing to show says so, and All brings it back',
      (tester) async {
        await open(tester);
        await goToLookup(tester);
        await type(tester, 'denim');
        await tester.tap(find.byKey(const Key('filter-out')));
        await tester.pump();
        expect(find.byKey(const Key('filter-empty')), findsOneWidget);
        await tester.tap(find.byKey(const Key('filter-all')));
        await tester.pump();
        expect(find.byKey(const Key('style-Denim Jeans')), findsOneWidget);
      },
    );

    testWidgets('the filter stays when the search changes', (tester) async {
      await open(tester);
      await goToLookup(tester);
      await tester.tap(find.byKey(const Key('filter-out')));
      await tester.pump();
      await type(tester, 'kurta');
      expect(
        find.byKey(const Key('variant-Cotton Kurta-M-Blue')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('variant-Cotton Kurta-L-Blue')),
        findsOneWidget,
      );
    });
  });
}
