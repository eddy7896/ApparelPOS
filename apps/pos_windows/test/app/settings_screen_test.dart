// Settings: the shop's stock categories (owner, 2026-11-23). Rules and data are
// tested elsewhere; this checks what the owner and a manager see and can do.
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:core_domain/credential_hasher.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/app/app.dart';
import 'package:pos_windows/app/label_printer.dart';
import 'package:pos_windows/app/services.dart';
import 'package:pos_windows/app/session_controller.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/auth_service.dart';
import 'package:pos_windows/data/category_repository.dart';
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
  late CategoryRepository cats;
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

  Future<void> buyStyle(String name) => stock.receivePurchase(
    role: Role.owner,
    draft: PurchaseDraft(
      supplier: 'S',
      style: name,
      lines: [
        PurchaseLine(
          size: 'M',
          color: 'Blue',
          quantity: 1,
          cost: Money(10000),
          mrp: Money(20000),
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
    cats = CategoryRepository(db, newId: newId);
    session = SessionController(auth: auth);
    await stock.ensureCounter();
    ownerId = await person('Meera', Role.owner, ownerHash);
    managerId = await person('Kabir', Role.manager, managerHash);
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
    bool withCategories = true,
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
          sales: SalesRepository(db, newId: newId),
          returns: ReturnsRepository(db, newId: newId),
          shifts: ShiftRepository(db, newId: newId),
          reports: ReportRepository(db),
          auth: auth,
          categories: withCategories ? cats : null,
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
    if (withCategories) {
      await tester.tap(find.byKey(const Key('settings-button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await pump(tester);
    }
  }

  Future<void> typeName(WidgetTester tester, String name) async {
    await tester.enterText(find.byKey(const Key('category-name-field')), name);
    await tester.tap(find.byKey(const Key('category-name-save')));
    await tester.pump();
    await pump(tester);
  }

  String message(WidgetTester tester) =>
      ((tester
                  .widget<Container>(find.byKey(const Key('settings-message')))
                  .child)
              as Text)
          .data!;

  Future<void> addGroup(WidgetTester tester, String name) async {
    await tester.tap(find.byKey(const Key('add-group-button')));
    await tester.pump(const Duration(milliseconds: 400));
    await typeName(tester, name);
  }

  Future<void> addCategory(
    WidgetTester tester,
    String group,
    String name,
  ) async {
    await tester.tap(find.byKey(Key('add-in-$group')));
    await tester.pump(const Duration(milliseconds: 400));
    await typeName(tester, name);
  }

  group('getting there', () {
    testWidgets(
      'the owner reaches Settings from the left menu and sees an empty list',
      (tester) async {
        await open(tester);
        expect(find.byKey(const Key('add-group-button')), findsOneWidget);
        expect(find.byKey(const Key('categories-empty')), findsOneWidget);
      },
    );

    testWidgets('a manager reaches it too', (tester) async {
      await open(tester, manager: true);
      expect(find.byKey(const Key('add-group-button')), findsOneWidget);
    });

    testWidgets('without the category service the menu item is not shown', (
      tester,
    ) async {
      await open(tester, withCategories: false);
      expect(find.byKey(const Key('settings-button')), findsNothing);
    });
  });

  group('setting up groups and categories', () {
    testWidgets('add a group, then a category inside it', (tester) async {
      await open(tester);
      await addGroup(tester, 'Men');
      expect(find.byKey(const Key('node-Men')), findsOneWidget);
      expect(message(tester), 'Group "Men" added.');
      await addCategory(tester, 'Men', 'Shirts');
      expect(find.byKey(const Key('node-Men › Shirts')), findsOneWidget);
      expect(message(tester), 'Category "Shirts" added to Men.');
      expect(find.byKey(const Key('categories-empty')), findsNothing);
    });

    testWidgets('only a group has an Add category button', (tester) async {
      await open(tester);
      await addGroup(tester, 'Men');
      await addCategory(tester, 'Men', 'Shirts');
      expect(find.byKey(const Key('add-in-Men')), findsOneWidget);
      expect(find.byKey(const Key('add-in-Shirts')), findsNothing);
    });

    testWidgets('a name already used is explained; a blank name too', (
      tester,
    ) async {
      await open(tester);
      await addGroup(tester, 'Men');
      await addGroup(tester, 'men');
      expect(message(tester), '"men" is already used here.');
      await addGroup(tester, '   ');
      expect(message(tester), contains('Type a name of 1 to 40 letters'));
    });

    testWidgets('rename keeps the place', (tester) async {
      await open(tester);
      await addGroup(tester, 'Men');
      await tester.tap(find.byKey(const Key('rename-Men')));
      await tester.pump(const Duration(milliseconds: 400));
      await typeName(tester, 'Gents');
      expect(find.byKey(const Key('node-Gents')), findsOneWidget);
      expect(find.byKey(const Key('node-Men')), findsNothing);
    });

    testWidgets('remove asks first, and an empty one goes', (tester) async {
      await open(tester);
      await addGroup(tester, 'Men');
      await tester.tap(find.byKey(const Key('delete-Men')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Cancel'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('node-Men')), findsOneWidget);
      await tester.tap(find.byKey(const Key('delete-Men')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const Key('delete-confirm')));
      await tester.pump();
      await pump(tester);
      expect(find.byKey(const Key('node-Men')), findsNothing);
      expect(find.byKey(const Key('categories-empty')), findsOneWidget);
    });

    testWidgets('one with a category in it cannot be removed and says why', (
      tester,
    ) async {
      await open(tester);
      await addGroup(tester, 'Men');
      await addCategory(tester, 'Men', 'Shirts');
      await tester.tap(find.byKey(const Key('delete-Men')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const Key('delete-confirm')));
      await tester.pump();
      await pump(tester);
      expect(message(tester), contains('still has styles or categories'));
      expect(find.byKey(const Key('node-Men')), findsOneWidget);
    });
  });

  group('putting styles in categories', () {
    Future<void> choose(WidgetTester tester, String style, String path) async {
      final field = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key as ValueKey<String>).value.startsWith('style-cat-$style-'),
      );
      await tester.tap(field);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text(path).last);
      await tester.pump();
      await pump(tester);
    }

    testWidgets('a style is put in a category and the count shows it', (
      tester,
    ) async {
      await buyStyle('Cotton Kurta');
      await open(tester);
      await addGroup(tester, 'Men');
      await addCategory(tester, 'Men', 'Shirts');
      expect(find.byKey(const Key('style-row-Cotton Kurta')), findsOneWidget);
      await choose(tester, 'Cotton Kurta', 'Men › Shirts');
      expect(find.text('1 style'), findsOneWidget);
      expect(message(tester), 'Cotton Kurta moved.');
    });

    testWidgets(
      'only places that can take styles are offered, never a group that has categories',
      (tester) async {
        await buyStyle('Cotton Kurta');
        await open(tester);
        await addGroup(tester, 'Men');
        await addCategory(tester, 'Men', 'Shirts');
        await addGroup(
          tester,
          'Kids',
        ); // a group with no categories is a place itself
        final field = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key as ValueKey<String>).value.startsWith(
                'style-cat-Cotton Kurta-',
              ),
        );
        await tester.tap(field);
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Men › Shirts'), findsWidgets);
        expect(find.text('Kids'), findsWidgets);
        expect(
          find.descendant(
            of: find.byType(DropdownMenuItem<String?>),
            matching: find.text('Men'),
          ),
          findsNothing,
        ); // the group with categories is not an option
      },
    );

    testWidgets(
      'the No category chip lists only styles still to be put somewhere',
      (tester) async {
        await buyStyle('Cotton Kurta');
        await buyStyle('Denim Jeans');
        await open(tester);
        await addGroup(tester, 'Men');
        await choose(tester, 'Cotton Kurta', 'Men');
        expect(find.text('All (2)'), findsOneWidget);
        expect(find.text('No category (1)'), findsOneWidget);
        await tester.tap(find.byKey(const Key('filter-styles-none')));
        await tester.pump();
        expect(find.byKey(const Key('style-row-Denim Jeans')), findsOneWidget);
        expect(find.byKey(const Key('style-row-Cotton Kurta')), findsNothing);
      },
    );
  });

  testWidgets('a narrow window lays out without errors', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    await buyStyle('Cotton Kurta');
    await open(tester);
    expect(tester.takeException(), isNull);
  });
}
