// The Manager Mode stock entry screen: choose sizes and colors, fill the grid,
// save a purchase, print the labels. P2-3b.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
import 'package:pos_windows/data/stock_repository.dart';

class FakePrinter implements LabelPrinter {
  final printed = <Uint8List>[];
  @override
  Future<void> printSheet(Uint8List pdf, {required String name}) async =>
      printed.add(pdf);
}

int pageCount(Uint8List b) =>
    RegExp(r'/Type\s*/Page(?![a-z])').allMatches(latin1.decode(b)).length;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late AuthService auth;
  late StockRepository stock;
  late SessionController session;
  late FakePrinter printer;
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    auth = AuthService(db, newId: newId);
    stock = StockRepository(db, newId: newId);
    await stock.ensureCounter();
    await stock.seedDefaultOptions();
    session = SessionController(auth: auth);
    printer = FakePrinter();
  });
  tearDown(() async {
    session.dispose();
    await db.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)),
      );
      await tester.pump();
    }
  }

  Future<void> open(
    WidgetTester tester, {
    Role role = Role.owner,
    bool shopName = true,
    bool goToStock = true,
  }) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      final secret = role.usesPin ? '482916' : 'a long passphrase';
      final id = await auth.createUser(
        name: 'Meera',
        role: role,
        secret: secret,
      );
      if (shopName) {
        await stock.setShopName(role: Role.owner, name: 'Sample Apparel');
      }
      await session.start();
      await session.signIn(id, secret);
    });
    final services = AppServices(
      stock: stock,
      sales: SalesRepository(db, newId: newId),
      returns: ReturnsRepository(db, newId: newId),
      auth: auth,
      printer: printer,
      fonts: () async => LabelFonts(
        regular: File('assets/fonts/NotoSans-Regular.ttf').readAsBytesSync(),
        bold: File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync(),
      ),
    );
    await tester.pumpWidget(PosApp(session: session, services: services));
    await tester.pump();
    if (goToStock) {
      await tester.tap(find.byKey(const Key('stock-entry-button')));
      await settle(tester);
    }
  }

  Future<void> choose(
    WidgetTester tester,
    List<String> sizes,
    List<String> colors,
  ) async {
    for (final s in sizes) {
      await tester.tap(find.byKey(Key('size-chip-$s')));
    }
    for (final c in colors) {
      await tester.tap(find.byKey(Key('color-chip-$c')));
    }
    await tester.pump();
  }

  Future<void> type(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  Future<void> fillValid(WidgetTester tester) async {
    await type(tester, 'supplier-field', 'Sample Supplier');
    await type(tester, 'style-field', 'Cotton Kurta');
    await choose(tester, ['M', 'L'], ['Blue']);
    await type(tester, 'default-cost', '200');
    await type(tester, 'default-mrp', '499');
    await type(tester, 'qty-M-Blue', '3');
    await type(tester, 'qty-L-Blue', '2');
  }

  bool saveEnabled(WidgetTester tester) =>
      tester
          .widget<FilledButton>(find.byKey(const Key('save-purchase')))
          .onPressed !=
      null;

  group('getting to the screen', () {
    testWidgets('a manager or owner has a Stock entry button', (tester) async {
      await open(tester, goToStock: false);
      expect(find.byKey(const Key('stock-entry-button')), findsOneWidget);
    });

    testWidgets('a cashier does not', (tester) async {
      await open(tester, role: Role.cashier, goToStock: false);
      expect(find.text('Sales Mode'), findsOneWidget);
      expect(find.byKey(const Key('stock-entry-button')), findsNothing);
    });
  });

  group('shop name', () {
    testWidgets('is asked once, the first time, and saved', (tester) async {
      await open(tester, shopName: false);
      expect(find.byKey(const Key('shop-name-field')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('shop-name-field')),
        'Sample Apparel',
      );
      await tester.tap(find.byKey(const Key('shop-name-save')));
      await settle(tester);
      expect(find.byKey(const Key('shop-name-field')), findsNothing);
      expect(await tester.runAsync(() => stock.shopName()), 'Sample Apparel');
    });

    testWidgets('is not asked again when it exists', (tester) async {
      await open(tester);
      expect(find.byKey(const Key('shop-name-field')), findsNothing);
    });
  });

  group('the grid', () {
    testWidgets('lists the default sizes and colors as choices', (
      tester,
    ) async {
      await open(tester);
      for (final s in ['S', 'M', 'L', 'XL', 'XXL']) {
        expect(find.byKey(Key('size-chip-$s')), findsOneWidget);
      }
      expect(find.byKey(const Key('color-chip-Blue')), findsOneWidget);
    });

    testWidgets('one row per chosen size and color', (tester) async {
      await open(tester);
      await choose(tester, ['M', 'L'], ['Blue', 'Red']);
      for (final k in ['M-Blue', 'M-Red', 'L-Blue', 'L-Red']) {
        expect(find.byKey(Key('qty-$k')), findsOneWidget);
        expect(find.byKey(Key('cost-$k')), findsOneWidget);
        expect(find.byKey(Key('mrp-$k')), findsOneWidget);
      }
      expect(find.byKey(const Key('qty-S-Blue')), findsNothing);
      await tester.tap(find.byKey(const Key('size-chip-L')));
      await tester.pump();
      expect(find.byKey(const Key('qty-L-Blue')), findsNothing);
    });

    testWidgets('default cost and MRP fill every row until a row is edited', (
      tester,
    ) async {
      await open(tester);
      await choose(tester, ['M', 'L'], ['Blue']);
      await type(tester, 'default-cost', '200');
      await type(tester, 'default-mrp', '499');
      String text(String key) =>
          tester.widget<TextField>(find.byKey(Key(key))).controller!.text;
      expect(
        (
          text('cost-M-Blue'),
          text('mrp-M-Blue'),
          text('cost-L-Blue'),
          text('mrp-L-Blue'),
        ),
        ('200', '499', '200', '499'),
      );
      await type(tester, 'mrp-L-Blue', '549');
      await type(tester, 'cost-L-Blue', '250');
      await type(tester, 'default-mrp', '599');
      await type(tester, 'default-cost', '210');
      expect((text('mrp-M-Blue'), text('mrp-L-Blue')), ('599', '549'));
      expect((text('cost-M-Blue'), text('cost-L-Blue')), ('210', '250'));
    });

    testWidgets('adding a new size or color makes it a choice', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('add-size')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('add-option-field')), '3XL');
      await tester.tap(find.byKey(const Key('add-option-save')));
      await settle(tester);
      expect(find.byKey(const Key('size-chip-3XL')), findsOneWidget);
      await tester.tap(find.byKey(const Key('add-color')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('add-option-field')),
        'Navy Blue',
      );
      await tester.tap(find.byKey(const Key('add-option-save')));
      await settle(tester);
      expect(find.byKey(const Key('color-chip-Navy Blue')), findsOneWidget);
    });
  });

  group('checks while typing', () {
    testWidgets(
      'saving is off, with a reason, until there is something valid',
      (tester) async {
        await open(tester);
        expect(saveEnabled(tester), isFalse);
        expect(
          find.text('Choose at least one size and one color.'),
          findsOneWidget,
        );
        await choose(tester, ['M'], ['Blue']);
        expect(find.text('Enter the supplier.'), findsOneWidget);
        expect(find.text('Enter the style name.'), findsOneWidget);
        expect(
          find.text('Enter a quantity of at least 1 for M Blue.'),
          findsOneWidget,
        );
        expect(saveEnabled(tester), isFalse);
      },
    );

    testWidgets('a filled-in purchase can be saved and shows the total', (
      tester,
    ) async {
      await open(tester);
      await fillValid(tester);
      expect(saveEnabled(tester), isTrue);
      expect(find.text('Total: 5 garments'), findsOneWidget);
    });

    testWidgets('a cost that is not rupees shows a message', (tester) async {
      await open(tester);
      await fillValid(tester);
      await type(tester, 'cost-M-Blue', 'abc');
      expect(
        find.text('Enter the cost as rupees, like 250 or 250.50, for M Blue.'),
        findsOneWidget,
      );
      expect(saveEnabled(tester), isFalse);
    });

    testWidgets('an MRP below the cost is a warning, saving still works', (
      tester,
    ) async {
      await open(tester);
      await fillValid(tester);
      await type(tester, 'mrp-M-Blue', '150');
      expect(
        find.text('Check: the MRP is below the cost for M Blue.'),
        findsOneWidget,
      );
      expect(saveEnabled(tester), isTrue);
    });
  });

  group('saving and printing', () {
    testWidgets('saves the garments and offers to print', (tester) async {
      await open(tester);
      await fillValid(tester);
      await tester.tap(find.byKey(const Key('save-purchase')));
      await settle(tester);
      expect(find.byKey(const Key('saved-dialog')), findsOneWidget);
      expect(find.textContaining('Saved 5 garments'), findsOneWidget);
      final c = await tester.runAsync(
        () => db.customSelect('SELECT COUNT(*) AS c FROM articles').getSingle(),
      );
      expect(c!.read<int>('c'), 5);
    });

    testWidgets(
      'printing sends one A4 sheet to the printer, starting at the chosen cell',
      (tester) async {
        await open(tester);
        await fillValid(tester);
        await tester.tap(find.byKey(const Key('save-purchase')));
        await settle(tester);
        await tester.tap(find.byKey(const Key('cell-4')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('print-labels')));
        await settle(tester);
        expect(printer.printed.length, 1);
        expect(latin1.decode(printer.printed.single.sublist(0, 5)), '%PDF-');
        expect(pageCount(printer.printed.single), 1);
      },
    );

    testWidgets(
      'starting near the end of the sheet continues on a second page',
      (tester) async {
        await open(tester);
        await fillValid(tester);
        await tester.tap(find.byKey(const Key('save-purchase')));
        await settle(tester);
        await tester.tap(find.byKey(const Key('cell-22')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('print-labels')));
        await settle(tester);
        expect(
          pageCount(printer.printed.single),
          2,
        ); // 3 on the first sheet, 2 on the next
      },
    );

    testWidgets(
      '"Not now" skips printing and the form is cleared for the next purchase',
      (tester) async {
        await open(tester);
        await fillValid(tester);
        await tester.tap(find.byKey(const Key('save-purchase')));
        await settle(tester);
        await tester.tap(find.byKey(const Key('skip-print')));
        await settle(tester);
        expect(printer.printed, isEmpty);
        expect(find.byKey(const Key('saved-dialog')), findsNothing);
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('supplier-field')))
              .controller!
              .text,
          '',
        );
        expect(find.byKey(const Key('qty-M-Blue')), findsNothing);
      },
    );

    testWidgets('a second purchase continues the barcodes after the first', (
      tester,
    ) async {
      await open(tester);
      await fillValid(tester);
      await tester.tap(find.byKey(const Key('save-purchase')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('skip-print')));
      await settle(tester);
      await fillValid(tester);
      await tester.tap(find.byKey(const Key('save-purchase')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('skip-print')));
      await settle(tester);
      final rows = await tester.runAsync(
        () => db.customSelect('SELECT barcode_value FROM articles').get(),
      );
      final serials =
          rows!
              .map((r) => Barcode.parse(r.read<String>('barcode_value')).serial)
              .toList()
            ..sort();
      expect(serials, List.generate(10, (i) => i));
    });
  });

  group('locking while on this screen', () {
    testWidgets(
      'closes the screen and shows the lock screen, forgetting the form',
      (tester) async {
        await open(tester);
        await fillValid(tester);
        session.lock();
        await tester.pump();
        await tester.pump();
        expect(find.byKey(const Key('supplier-field')), findsNothing);
        expect(find.text('Choose your name'), findsOneWidget);
      },
    );
  });

  group('printing problems', () {
    testWidgets(
      'a style the tag font cannot draw says so instead of printing a box',
      (tester) async {
        await open(tester);
        await fillValid(tester);
        await type(tester, 'style-field', 'कुर्ता');
        await tester.tap(find.byKey(const Key('save-purchase')));
        await settle(tester);
        await tester.tap(find.byKey(const Key('print-labels')));
        await settle(tester);
        expect(printer.printed, isEmpty);
        expect(find.textContaining('cannot draw'), findsWidgets);
      },
    );
  });
}
