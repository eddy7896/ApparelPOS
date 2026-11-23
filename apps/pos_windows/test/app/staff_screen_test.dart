// The staff screen in Manager Mode (owner, 2026-11-22). The rules and the
// database are tested in staff_repository_test.dart; this checks what the
// owner and a manager see and can do. Counters are not here (Release 2).
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:core_domain/credential_hasher.dart';
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
import 'package:pos_windows/data/report_repository.dart';
import 'package:pos_windows/data/returns_repository.dart';
import 'package:pos_windows/data/sales_repository.dart';
import 'package:pos_windows/data/shift_repository.dart';
import 'package:pos_windows/data/staff_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late AuthService auth;
  late ShiftRepository shifts;
  late SessionController session;
  late String ownerId;
  late String managerId;
  late String ashaId;
  late String ownerHash;
  late String managerHash;
  late String ashaHash;
  var n = 0;
  String newId() => 'id-${++n}';

  setUpAll(() {
    final h = CredentialHasher();
    ownerHash = h.hash('a long passphrase');
    managerHash = h.hash('another long passphrase');
    ashaHash = h.hash('482916');
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
            createdAt: DateTime.utc(2026, 11, 20),
            updatedAt: DateTime.utc(2026, 11, 20),
          ),
        );
    return id;
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    auth = AuthService(db, newId: newId);
    shifts = ShiftRepository(db, newId: newId);
    session = SessionController(auth: auth);
    await StockRepository(db, newId: newId).ensureCounter();
    ownerId = await person('Meera', Role.owner, ownerHash);
    managerId = await person('Kabir', Role.manager, managerHash);
    ashaId = await person('Asha', Role.cashier, ashaHash);
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

  AppServices services({bool withStaff = true}) => AppServices(
    stock: StockRepository(db, newId: newId),
    sales: SalesRepository(db, newId: newId),
    returns: ReturnsRepository(db, newId: newId),
    shifts: shifts,
    reports: ReportRepository(db),
    auth: auth,
    staff: withStaff ? StaffRepository(db, auth, newId: newId) : null,
    printer: const SystemLabelPrinter(),
    fonts: () async => LabelFonts(
      regular: File('assets/fonts/NotoSans-Regular.ttf').readAsBytesSync(),
      bold: File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync(),
    ),
  );

  Future<void> open(
    WidgetTester tester, {
    bool asManager = false,
    bool withStaff = true,
  }) async {
    tester.view.physicalSize = const Size(1500, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await session.start();
      await session.signIn(
        asManager ? managerId : ownerId,
        asManager ? 'another long passphrase' : 'a long passphrase',
      );
    });
    await tester.pumpWidget(
      PosApp(
        session: session,
        services: services(withStaff: withStaff),
      ),
    );
    await pump(tester);
    if (withStaff) {
      await tester.tap(find.byKey(const Key('staff-button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await pump(tester);
    }
  }

  Future<void> tapAndWait(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> fillAdd(
    WidgetTester tester, {
    String? name,
    required String secret,
    String? again,
  }) async {
    if (name != null) {
      await tester.enterText(find.byKey(const Key('staff-name')), name);
    }
    await tester.enterText(find.byKey(const Key('staff-secret')), secret);
    await tester.enterText(
      find.byKey(const Key('staff-secret-again')),
      again ?? secret,
    );
    await tester.tap(find.byKey(const Key('staff-save')));
    await tester.pump();
    await pump(tester);
  }

  String messageText(WidgetTester tester) {
    final w = tester.widget<Container>(find.byKey(const Key('staff-message')));
    return ((w.child) as Text).data!;
  }

  group('getting there', () {
    testWidgets('the owner and a manager reach Staff from the left menu', (
      tester,
    ) async {
      await open(tester);
      expect(find.byKey(const Key('add-cashier-button')), findsOneWidget);
    });

    testWidgets('a manager reaches it too', (tester) async {
      await open(tester, asManager: true);
      expect(find.byKey(const Key('add-cashier-button')), findsOneWidget);
    });

    testWidgets('without the staff service the menu item is not shown', (
      tester,
    ) async {
      await open(tester, withStaff: false);
      expect(find.byKey(const Key('staff-button')), findsNothing);
    });

    testWidgets('the screen says a second counter waits for Release 2', (
      tester,
    ) async {
      await open(tester);
      expect(find.textContaining('waits for Release 2'), findsOneWidget);
    });
  });

  group('who sees which buttons', () {
    testWidgets('the owner can add a manager; a manager cannot', (
      tester,
    ) async {
      await open(tester);
      expect(find.byKey(const Key('add-manager-button')), findsOneWidget);
    });

    testWidgets('a manager sees no Add manager', (tester) async {
      await open(tester, asManager: true);
      expect(find.byKey(const Key('add-manager-button')), findsNothing);
    });

    testWidgets(
      'the owner sees everyone, marked (you), with no Turn off on themselves',
      (tester) async {
        await open(tester);
        expect(find.text('Meera (you)'), findsOneWidget);
        expect(find.byKey(const Key('turn-off-Meera')), findsNothing);
        expect(find.byKey(const Key('turn-off-Asha')), findsOneWidget);
        expect(find.byKey(const Key('turn-off-Kabir')), findsOneWidget);
        expect(
          find.byKey(const Key('reset-Meera')),
          findsOneWidget,
        ); // change my password
      },
    );

    testWidgets('a manager can only manage cashiers (and their own password)', (
      tester,
    ) async {
      await open(tester, asManager: true);
      expect(find.byKey(const Key('turn-off-Asha')), findsOneWidget);
      expect(find.byKey(const Key('rename-Asha')), findsOneWidget);
      expect(find.byKey(const Key('reset-Asha')), findsOneWidget);
      expect(
        find.byKey(const Key('reset-Kabir')),
        findsOneWidget,
      ); // own password
      expect(find.byKey(const Key('rename-Kabir')), findsNothing);
      expect(find.byKey(const Key('turn-off-Meera')), findsNothing);
      expect(find.byKey(const Key('reset-Meera')), findsNothing);
      expect(find.byKey(const Key('rename-Meera')), findsNothing);
    });
  });

  group('adding a cashier', () {
    testWidgets(
      'name, PIN and the PIN again; the cashier is listed and can be chosen at sign-in',
      (tester) async {
        await open(tester);
        await tapAndWait(tester, 'add-cashier-button');
        expect(find.text('PIN: 6 to 12 digits'), findsOneWidget);
        await tester.runAsync(() async {});
        await fillAdd(tester, name: 'Ravi', secret: '135792');
        await pump(tester);
        expect(find.byKey(const Key('staff-Ravi')), findsOneWidget);
        expect(messageText(tester), 'Ravi was added.');
        expect(session.choices.map((c) => c.name), contains('Ravi'));
      },
    );

    testWidgets('two different PINs are refused in the dialog', (tester) async {
      await open(tester);
      await tapAndWait(tester, 'add-cashier-button');
      await fillAdd(tester, name: 'Ravi', secret: '135792', again: '135793');
      expect(find.byKey(const Key('staff-dialog-problem')), findsOneWidget);
      expect(find.textContaining('not the same'), findsOneWidget);
      expect(find.byKey(const Key('staff-Ravi')), findsNothing);
    });

    testWidgets('a blank name is refused in the dialog', (tester) async {
      await open(tester);
      await tapAndWait(tester, 'add-cashier-button');
      await fillAdd(tester, name: '  ', secret: '135792');
      expect(find.byKey(const Key('staff-dialog-problem')), findsOneWidget);
    });

    testWidgets('a weak PIN is explained and nothing is added', (tester) async {
      await open(tester);
      await tapAndWait(tester, 'add-cashier-button');
      await fillAdd(tester, name: 'Ravi', secret: '123');
      expect(messageText(tester), 'The PIN needs at least 6 digits.');
      expect(find.byKey(const Key('staff-Ravi')), findsNothing);
    });

    testWidgets('a name already used is explained', (tester) async {
      await open(tester);
      await tapAndWait(tester, 'add-cashier-button');
      await fillAdd(tester, name: 'asha', secret: '135792');
      expect(messageText(tester), 'The name "asha" is already used.');
    });

    testWidgets('the owner adds a manager with a password', (tester) async {
      await open(tester);
      await tapAndWait(tester, 'add-manager-button');
      expect(find.text('Password: at least 10 characters'), findsOneWidget);
      await fillAdd(tester, name: 'Dev', secret: 'yet another passphrase');
      expect(find.byKey(const Key('staff-Dev')), findsOneWidget);
    });
  });

  group('changing and turning off', () {
    testWidgets('a new PIN for a cashier', (tester) async {
      await open(tester, asManager: true);
      await tapAndWait(tester, 'reset-Asha');
      await fillAdd(tester, secret: '975310');
      expect(messageText(tester), 'New PIN saved for Asha.');
      final r = await tester.runAsync(
        () => auth.signIn(userId: ashaId, secret: '975310'),
      );
      expect(r, isA<SignedIn>());
    });

    testWidgets('rename', (tester) async {
      await open(tester);
      await tapAndWait(tester, 'rename-Asha');
      await tester.enterText(find.byKey(const Key('rename-field')), 'Asha Rao');
      await tester.tap(find.byKey(const Key('rename-save')));
      await tester.pump();
      await pump(tester);
      expect(find.byKey(const Key('staff-Asha Rao')), findsOneWidget);
      expect(session.choices.map((c) => c.name), contains('Asha Rao'));
    });

    testWidgets(
      'turn off asks first, then the cashier leaves the sign-in list; turn on brings them back',
      (tester) async {
        await open(tester);
        await tapAndWait(tester, 'turn-off-Asha');
        expect(find.text('Turn off Asha?'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const Key('off-Asha')), findsNothing);

        await tapAndWait(tester, 'turn-off-Asha');
        await tester.tap(find.byKey(const Key('turn-off-confirm')));
        await tester.pump();
        await pump(tester);
        expect(find.byKey(const Key('off-Asha')), findsOneWidget);
        expect(session.choices.map((c) => c.name), isNot(contains('Asha')));

        await tapAndWait(tester, 'turn-on-Asha');
        await pump(tester);
        expect(find.byKey(const Key('off-Asha')), findsNothing);
        expect(session.choices.map((c) => c.name), contains('Asha'));
      },
    );

    testWidgets(
      'someone with a shift open cannot be turned off, and it says why',
      (tester) async {
        await tester.runAsync(
          () => shifts.openShift(
            role: Role.cashier,
            userId: ashaId,
            counts: const {},
          ),
        );
        await open(tester);
        await tapAndWait(tester, 'turn-off-Asha');
        await tester.tap(find.byKey(const Key('turn-off-confirm')));
        await tester.pump();
        await pump(tester);
        expect(messageText(tester), contains('shift is still open'));
        expect(find.byKey(const Key('off-Asha')), findsNothing);
      },
    );
  });

  testWidgets('a narrow window lays out without errors', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    await open(tester);
    expect(tester.takeException(), isNull);
  });
}
