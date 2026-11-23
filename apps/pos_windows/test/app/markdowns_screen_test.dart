// Markdowns page (owner, 2026-11-23): a manager or the owner sets a percentage
// or an amount off a whole style until a last day. Rules and data are tested
// elsewhere; this checks what they see and can do.
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
import 'package:pos_windows/data/markdown_repository.dart';
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
  late MarkdownRepository marks;
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
    marks = MarkdownRepository(db, newId: newId);
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
    bool withMarkdowns = true,
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
          markdowns: withMarkdowns ? marks : null,
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
    if (withMarkdowns) {
      await tester.tap(find.byKey(const Key('markdowns-button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await pump(tester);
    }
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pump(const Duration(milliseconds: 400));
    await pump(tester);
  }

  Future<void> fill(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  String message(WidgetTester tester) =>
      ((tester
                  .widget<Container>(find.byKey(const Key('markdowns-message')))
                  .child)
              as Text)
          .data!;

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  String labelOf(WidgetTester tester, String key) => tester
      .widget<Text>(
        find.descendant(of: find.byKey(Key(key)), matching: find.byType(Text)),
      )
      .data!;

  Future<void> setPercent(
    WidgetTester tester,
    String style,
    String percent, {
    String chip = 'md-week',
  }) async {
    await tapKey(tester, 'markdown-set-$style');
    await fill(tester, 'md-value', percent);
    await tester.tap(find.byKey(Key(chip)));
    await tester.pump();
    await tapKey(tester, 'md-save');
  }

  group('opening the page', () {
    testWidgets('lists each style with its stock and price range', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await buyStyle('Cotton Kurta', dearer: 59900);
        await buyStyle('Denim Jeans', mrp: 129900);
      });
      await open(tester);
      expect(
        find.byKey(const Key('markdown-row-Cotton Kurta')),
        findsOneWidget,
      );
      expect(find.text('3 in stock, ₹499.00 to ₹599.00'), findsOneWidget);
      expect(find.text('2 in stock, ₹1,299.00'), findsOneWidget);
    });

    testWidgets('a manager gets it too', (tester) async {
      await tester.runAsync(() => buyStyle('Cotton Kurta'));
      await open(tester, manager: true);
      expect(
        find.byKey(const Key('markdown-row-Cotton Kurta')),
        findsOneWidget,
      );
    });

    testWidgets('with no styles it says so', (tester) async {
      await open(tester);
      expect(find.byKey(const Key('markdowns-empty')), findsOneWidget);
    });

    testWidgets('without the service the menu item is hidden', (tester) async {
      await open(tester, withMarkdowns: false);
      expect(find.byKey(const Key('markdowns-button')), findsNothing);
    });
  });

  group('setting one', () {
    testWidgets('a percent until a week from now', (tester) async {
      await tester.runAsync(() => buyStyle('Cotton Kurta'));
      await open(tester);
      await setPercent(tester, 'Cotton Kurta', '20');
      expect(message(tester), startsWith('Cotton Kurta: 20% off until'));
      expect(
        labelOf(tester, 'markdown-label-Cotton Kurta'),
        startsWith('20% off until'),
      );
      final row = await tester.runAsync(
        () => db
            .customSelect('SELECT percent_bp FROM style_markdowns')
            .getSingle(),
      );
      expect(row!.read<int>('percent_bp'), 2000);
    });

    testWidgets('an amount in rupees', (tester) async {
      await tester.runAsync(() => buyStyle('Cotton Kurta'));
      await open(tester);
      await tapKey(tester, 'markdown-set-Cotton Kurta');
      await tapKey(tester, 'md-kind-amount');
      await fill(tester, 'md-value', '100');
      await tester.tap(find.byKey(const Key('md-30')));
      await tester.pump();
      await tapKey(tester, 'md-save');
      expect(
        labelOf(tester, 'markdown-label-Cotton Kurta'),
        startsWith('₹100 off until'),
      );
      final row = await tester.runAsync(
        () => db
            .customSelect('SELECT amount_paise FROM style_markdowns')
            .getSingle(),
      );
      expect(row!.read<int>('amount_paise'), 10000);
    });

    testWidgets('the dialog shows what the price becomes', (tester) async {
      await tester.runAsync(() => buyStyle('Cotton Kurta', dearer: 59900));
      await open(tester);
      await tapKey(tester, 'markdown-set-Cotton Kurta');
      await fill(tester, 'md-value', '20');
      expect(
        textOf(tester, 'md-preview'),
        '₹499.00 becomes ₹399.20; ₹599.00 becomes ₹479.20',
      );
      await tapKey(tester, 'md-kind-amount');
      await fill(tester, 'md-value', '100');
      expect(
        textOf(tester, 'md-preview'),
        '₹499.00 becomes ₹399.00; ₹599.00 becomes ₹499.00',
      );
    });

    testWidgets('the last day can be typed', (tester) async {
      await tester.runAsync(() => buyStyle('Cotton Kurta'));
      await open(tester);
      final day = shopDayPlus(ShopDay.fromUtc(DateTime.now().toUtc()), 10);
      await tapKey(tester, 'markdown-set-Cotton Kurta');
      await fill(tester, 'md-value', '15');
      await fill(tester, 'md-last-day', shopDayText(day));
      await tapKey(tester, 'md-save');
      expect(
        labelOf(tester, 'markdown-label-Cotton Kurta'),
        '15% off until ${shopDayText(day)}',
      );
    });

    testWidgets('the end of this month chip fills the last day', (
      tester,
    ) async {
      await tester.runAsync(() => buyStyle('Cotton Kurta'));
      await open(tester);
      await tapKey(tester, 'markdown-set-Cotton Kurta');
      await tester.tap(find.byKey(const Key('md-month-end')));
      await tester.pump();
      final today = ShopDay.fromUtc(DateTime.now().toUtc());
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('md-last-day')))
            .controller!
            .text,
        shopDayText(endOfMonth(today)),
      );
    });

    testWidgets('changing it shows the old values and replaces them', (
      tester,
    ) async {
      await tester.runAsync(() => buyStyle('Cotton Kurta'));
      await open(tester);
      await setPercent(tester, 'Cotton Kurta', '20');
      await tapKey(tester, 'markdown-set-Cotton Kurta');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('md-value')))
            .controller!
            .text,
        '20',
      );
      await fill(tester, 'md-value', '30');
      await tapKey(tester, 'md-save');
      expect(
        labelOf(tester, 'markdown-label-Cotton Kurta'),
        startsWith('30% off until'),
      );
    });

    testWidgets('Remove puts the MRP back', (tester) async {
      await tester.runAsync(() => buyStyle('Cotton Kurta'));
      await open(tester);
      await setPercent(tester, 'Cotton Kurta', '20');
      await tapKey(tester, 'markdown-remove-Cotton Kurta');
      expect(
        find.byKey(const Key('markdown-label-Cotton Kurta')),
        findsNothing,
      );
      expect(message(tester), 'Cotton Kurta is back at its MRP.');
    });
  });

  group('what the dialog refuses', () {
    Future<void> tryOne(
      WidgetTester tester, {
      String? value,
      String? last,
      bool amount = false,
    }) async {
      await tapKey(tester, 'markdown-set-Cotton Kurta');
      if (amount) {
        await tapKey(tester, 'md-kind-amount');
      }
      if (value != null) {
        await fill(tester, 'md-value', value);
      }
      if (last != null) {
        await fill(tester, 'md-last-day', last);
      }
      await tapKey(tester, 'md-save');
    }

    String error(WidgetTester tester) => textOf(tester, 'md-error');

    testWidgets('no value, a bad value and zero', (tester) async {
      await tester.runAsync(() => buyStyle('Cotton Kurta'));
      await open(tester);
      final ok = shopDayText(
        shopDayPlus(ShopDay.fromUtc(DateTime.now().toUtc()), 3),
      );
      await tryOne(tester, last: ok);
      expect(error(tester), 'Type a percentage such as 20.');
      await fill(tester, 'md-value', 'abc');
      await tapKey(tester, 'md-save');
      expect(error(tester), 'Type a percentage such as 20.');
      await fill(tester, 'md-value', '0');
      await tapKey(tester, 'md-save');
      expect(error(tester), 'Type a percentage or an amount above zero.');
      await fill(tester, 'md-value', '100');
      await tapKey(tester, 'md-save');
      expect(error(tester), 'A markdown must be under 100%.');
      await fill(tester, 'md-value', '101');
      await tapKey(tester, 'md-save');
      expect(error(tester), 'Type a percentage such as 20.');
    });

    testWidgets('an amount that is not under the cheapest price', (
      tester,
    ) async {
      await tester.runAsync(() => buyStyle('Cotton Kurta'));
      await open(tester);
      final ok = shopDayText(
        shopDayPlus(ShopDay.fromUtc(DateTime.now().toUtc()), 3),
      );
      await tryOne(tester, value: '499', last: ok, amount: true);
      expect(
        error(tester),
        'The amount must be less than the cheapest price of this style in stock.',
      );
    });

    testWidgets('a missing, odd, past or far last day', (tester) async {
      await tester.runAsync(() => buyStyle('Cotton Kurta'));
      await open(tester);
      final today = ShopDay.fromUtc(DateTime.now().toUtc());
      await tryOne(tester, value: '20');
      expect(error(tester), contains('day/month/year'));
      await fill(tester, 'md-last-day', '2026-12-01');
      await tapKey(tester, 'md-save');
      expect(error(tester), contains('day/month/year'));
      await fill(tester, 'md-last-day', shopDayText(today.previous));
      await tapKey(tester, 'md-save');
      expect(error(tester), 'The last day cannot be before today.');
      await fill(tester, 'md-last-day', shopDayText(shopDayPlus(today, 500)));
      await tapKey(tester, 'md-save');
      expect(error(tester), contains('more than a year away'));
      expect(
        find.byKey(const Key('markdown-label-Cotton Kurta')),
        findsNothing,
      );
    });

    testWidgets('Cancel leaves things as they were', (tester) async {
      await tester.runAsync(() => buyStyle('Cotton Kurta'));
      await open(tester);
      await tapKey(tester, 'markdown-set-Cotton Kurta');
      await fill(tester, 'md-value', '20');
      await tester.tap(find.text('Cancel'));
      await pump(tester);
      expect(
        find.byKey(const Key('markdown-label-Cotton Kurta')),
        findsNothing,
      );
      expect(find.byKey(const Key('md-value')), findsNothing);
    });
  });

  group('finding styles', () {
    testWidgets('search by name and show only the marked-down ones', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await buyStyle('Cotton Kurta');
        await buyStyle('Denim Jeans', mrp: 129900);
      });
      await open(tester);
      await setPercent(tester, 'Cotton Kurta', '20');
      await fill(tester, 'markdown-search', 'DEN');
      await pump(tester);
      expect(find.byKey(const Key('markdown-row-Denim Jeans')), findsOneWidget);
      expect(find.byKey(const Key('markdown-row-Cotton Kurta')), findsNothing);
      await fill(tester, 'markdown-search', '');
      await pump(tester);
      await tapKey(tester, 'markdown-only');
      expect(
        find.byKey(const Key('markdown-row-Cotton Kurta')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('markdown-row-Denim Jeans')), findsNothing);
      await fill(tester, 'markdown-search', 'zzz');
      await pump(tester);
      expect(find.byKey(const Key('markdowns-none')), findsOneWidget);
    });

    testWidgets('an ended markdown is shown as ended and can be removed', (
      tester,
    ) async {
      await tester.runAsync(() => buyStyle('Cotton Kurta'));
      await tester.runAsync(() async {
        final id =
            (await db.customSelect('SELECT id FROM products').getSingle())
                .read<String>('id');
        await db.customStatement(
          "INSERT INTO style_markdowns (product_id, percent_bp, ends_before, set_by, created_at, updated_at) VALUES ('$id', 2000, 1700000000, 'u', 1690000000, 1690000000)",
        );
      });
      await open(tester);
      expect(
        labelOf(tester, 'markdown-label-Cotton Kurta'),
        startsWith('Ended '),
      );
      await tapKey(tester, 'markdown-remove-Cotton Kurta');
      expect(
        find.byKey(const Key('markdown-label-Cotton Kurta')),
        findsNothing,
      );
    });
  });
}
