// The GST card in Settings (P3-4, owner 2026-11-23): off by default, only the
// owner can switch it on or change it. EVERY GST RULE is unverified until the
// CA confirms it, and the card says so. Rules and data are tested elsewhere.
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
import 'package:pos_windows/data/gst_repository.dart';
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
  late GstRepository gst;
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

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    staffNo = 0;
    auth = AuthService(db, newId: newId);
    stock = StockRepository(db, newId: newId);
    gst = GstRepository(db, newId: newId);
    session = SessionController(auth: auth);
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
    bool withGst = true,
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
          gst: withGst ? gst : null,
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
    if (withGst) {
      await tester.tap(find.byKey(const Key('settings-button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await pump(tester);
    }
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.tap(find.byKey(Key(key)));
    await tester.pump(const Duration(milliseconds: 300));
    await pump(tester);
  }

  Future<void> fill(WidgetTester tester, String key, String text) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  String message(WidgetTester tester) =>
      ((tester.widget<Container>(find.byKey(const Key('gst-message'))).child)
              as Text)
          .data!;

  Future<GstSettings> stored() => gst.settings(role: Role.owner);

  Future<void> fillGood(WidgetTester tester) async {
    await fill(tester, 'gst-gstin', '27abcde1234f1z5');
    await fill(tester, 'gst-address', '12 Market Road, Pune');
  }

  group('the card', () {
    testWidgets('says every rule is unverified, and GST is off to begin with', (
      tester,
    ) async {
      await open(tester);
      expect(find.byKey(const Key('gst-unverified')), findsOneWidget);
      expect(
        find.textContaining('unverified until your CA confirms'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('gst-switch')))
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('gst-rate')))
            .controller!
            .text,
        '5',
      );
    });

    testWidgets(
      'the Settings page opens with only the GST card when categories are not set up',
      (tester) async {
        await open(tester);
        expect(find.byKey(const Key('gst-card')), findsOneWidget);
        expect(find.byKey(const Key('add-group-button')), findsNothing);
      },
    );

    testWidgets('a manager sees GST but cannot change it', (tester) async {
      await open(tester, manager: true);
      expect(
        textOf(tester, 'gst-readonly'),
        'GST is off. Only the owner can change it.',
      );
      expect(find.byKey(const Key('gst-switch')), findsNothing);
      expect(find.byKey(const Key('gst-save')), findsNothing);
    });

    testWidgets('a manager sees what the owner chose', (tester) async {
      await tester.runAsync(
        () => gst.save(
          role: Role.owner,
          actorId: ownerId,
          settings: const GstSettings(
            enabled: true,
            mode: GstMode.exclusive,
            gstin: '27ABCDE1234F1Z5',
            address: 'x',
          ),
        ),
      );
      await open(tester, manager: true);
      expect(
        textOf(tester, 'gst-readonly'),
        'GST is on (5%, tax added to prices). Only the owner can change it.',
      );
    });
  });

  group('switching it on', () {
    testWidgets('the owner fills in the GSTIN and address and saves', (
      tester,
    ) async {
      await open(tester);
      await tapKey(tester, 'gst-switch');
      await fillGood(tester);
      await tapKey(tester, 'gst-save');
      expect(message(tester), startsWith('GST is on.'));
      final s = (await tester.runAsync(stored))!;
      expect(s.enabled, isTrue);
      expect(s.gstin, '27ABCDE1234F1Z5');
      expect(s.address, '12 Market Road, Pune');
      expect(s.rateBp, 500);
      expect(s.mode, GstMode.inclusive);
      expect(s.rounding, GstRounding.perItem);
    });

    testWidgets(
      'without a GSTIN or address it says what is missing and stays off',
      (tester) async {
        await open(tester);
        await tapKey(tester, 'gst-switch');
        await tapKey(tester, 'gst-save');
        expect(message(tester), 'Type the shop GSTIN.');
        await fill(tester, 'gst-gstin', 'nope');
        await tapKey(tester, 'gst-save');
        expect(message(tester), contains('does not look like a GSTIN'));
        await fill(tester, 'gst-gstin', '27ABCDE1234F1Z5');
        await tapKey(tester, 'gst-save');
        expect(message(tester), 'Type the shop address.');
        expect((await tester.runAsync(stored))!.enabled, isFalse);
      },
    );

    testWidgets('a bad rate is refused', (tester) async {
      await open(tester);
      await tapKey(tester, 'gst-switch');
      await fillGood(tester);
      await fill(tester, 'gst-rate', 'abc');
      await tapKey(tester, 'gst-save');
      expect(message(tester), 'Type the rate as a percentage, such as 5.');
      await fill(tester, 'gst-rate', '0');
      await tapKey(tester, 'gst-save');
      expect(message(tester), contains('above 0%'));
      await fill(tester, 'gst-rate', '60');
      await tapKey(tester, 'gst-save');
      expect(message(tester), contains('at most 50%'));
      expect((await tester.runAsync(stored))!.enabled, isFalse);
    });

    testWidgets('the choices are saved: rate, tax added, once per bill', (
      tester,
    ) async {
      await open(tester);
      await tapKey(tester, 'gst-switch');
      await fillGood(tester);
      await fill(tester, 'gst-rate', '12.5');
      await tapKey(tester, 'gst-mode-exclusive');
      await tapKey(tester, 'gst-round-bill');
      await tapKey(tester, 'gst-save');
      final s = (await tester.runAsync(stored))!;
      expect(s.rateBp, 1250);
      expect(s.mode, GstMode.exclusive);
      expect(s.rounding, GstRounding.perBill);
    });

    testWidgets('each invoice field can be switched off and on', (
      tester,
    ) async {
      await open(tester);
      await tapKey(tester, 'gst-switch');
      await fillGood(tester);
      await tapKey(tester, 'gst-field-tax_per_item'); // on by default: now off
      await tapKey(
        tester,
        'gst-field-amount_in_words',
      ); // off by default: now on
      await tapKey(tester, 'gst-save');
      final s = (await tester.runAsync(stored))!;
      expect(s.prints(GstInvoiceField.taxPerItem), isFalse);
      expect(s.prints(GstInvoiceField.amountInWords), isTrue);
      expect(s.prints(GstInvoiceField.shopGstin), isTrue);
    });

    testWidgets('a saved choice is shown again next time', (tester) async {
      await tester.runAsync(
        () => gst.save(
          role: Role.owner,
          actorId: ownerId,
          settings: const GstSettings(
            enabled: true,
            rateBp: 1200,
            gstin: '27ABCDE1234F1Z5',
            address: 'Road 1',
            mode: GstMode.exclusive,
          ),
        ),
      );
      await open(tester);
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('gst-switch')))
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('gst-rate')))
            .controller!
            .text,
        '12',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('gst-gstin')))
            .controller!
            .text,
        '27ABCDE1234F1Z5',
      );
      expect(
        tester
            .widget<SegmentedButton<GstMode>>(
              find.byType(SegmentedButton<GstMode>),
            )
            .selected,
        {GstMode.exclusive},
      );
    });
  });

  group('switching it off', () {
    testWidgets('the owner turns it off; the other choices are kept', (
      tester,
    ) async {
      await tester.runAsync(
        () => gst.save(
          role: Role.owner,
          actorId: ownerId,
          settings: const GstSettings(
            enabled: true,
            rateBp: 1200,
            gstin: '27ABCDE1234F1Z5',
            address: 'Road 1',
          ),
        ),
      );
      await open(tester);
      await tapKey(tester, 'gst-switch');
      await tapKey(tester, 'gst-save');
      expect(message(tester), 'GST is off. Bills already made do not change.');
      final s = (await tester.runAsync(stored))!;
      expect(s.enabled, isFalse);
      expect(s.rateBp, 1200);
      expect(s.gstin, '27ABCDE1234F1Z5');
    });
  });
}
