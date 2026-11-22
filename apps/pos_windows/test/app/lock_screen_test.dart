// The lock screen, first-time setup and idle lock as the user sees them.
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/app/app.dart';
import 'package:pos_windows/app/ui/notice.dart';
import 'package:pos_windows/app/label_printer.dart';
import 'package:pos_windows/app/services.dart';
import 'package:pos_windows/app/session_controller.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/auth_service.dart';
import 'package:pos_windows/data/report_repository.dart';
import 'package:pos_windows/data/returns_repository.dart';
import 'package:pos_windows/data/sales_repository.dart';
import 'package:pos_windows/data/shift_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late AuthService auth;
  late SessionController session;
  late DateTime now;
  var n = 0;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 11, 20, 10);
    n = 0;
    auth = AuthService(db, now: () => now, newId: () => 'id-${++n}');
    session = SessionController(auth: auth, now: () => now);
  });
  tearDown(() async {
    session.dispose();
    await db.close();
  });

  Future<void> show(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => session.start());
    await tester.pumpWidget(
      PosApp(
        session: session,
        services: AppServices(
          stock: StockRepository(db, newId: () => 'unused-${++n}'),
          sales: SalesRepository(db, newId: () => 'unused-sales-${++n}'),
          returns: ReturnsRepository(db, newId: () => 'unused-returns-${++n}'),
          shifts: ShiftRepository(db, newId: () => 'unused-shifts-${++n}'),
          reports: ReportRepository(db),
          auth: auth,
          printer: const SystemLabelPrinter(),
          fonts: () async => throw StateError('fonts are not used here'),
        ),
        idleCheckEvery: const Duration(seconds: 5),
      ),
    );
    await tester.pump();
  }

  Future<void> tapPin(WidgetTester tester, String pin) async {
    for (final d in pin.split('')) {
      await tester.tap(find.byKey(Key('key-$d')));
    }
    await tester.pump();
    await tester.tap(find.byKey(const Key('signin-submit')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump();
  }

  group('first-time setup', () {
    testWidgets('a new install asks for the owner account', (tester) async {
      await show(tester);
      expect(find.text('Set up your shop'), findsOneWidget);
      expect(find.byKey(const Key('setup-password')), findsOneWidget);
    });

    testWidgets('a short password shows a message and creates nothing', (
      tester,
    ) async {
      await show(tester);
      await tester.enterText(find.byKey(const Key('setup-name')), 'Meera');
      await tester.enterText(find.byKey(const Key('setup-password')), 'short');
      await tester.enterText(find.byKey(const Key('setup-confirm')), 'short');
      await tester.tap(find.byKey(const Key('setup-submit')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      expect(
        find.text('The password must be at least 10 characters.'),
        findsOneWidget,
      );
      expect(find.text('Set up your shop'), findsOneWidget);
    });

    testWidgets('different passwords show a message', (tester) async {
      await show(tester);
      await tester.enterText(find.byKey(const Key('setup-name')), 'Meera');
      await tester.enterText(
        find.byKey(const Key('setup-password')),
        'a long passphrase',
      );
      await tester.enterText(
        find.byKey(const Key('setup-confirm')),
        'a long passphrasE',
      );
      await tester.tap(find.byKey(const Key('setup-submit')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      expect(find.text('The two passwords do not match.'), findsOneWidget);
    });

    testWidgets('a good setup opens Manager Mode for the owner', (
      tester,
    ) async {
      await show(tester);
      await tester.enterText(find.byKey(const Key('setup-name')), 'Meera');
      await tester.enterText(
        find.byKey(const Key('setup-password')),
        'a long passphrase',
      );
      await tester.enterText(
        find.byKey(const Key('setup-confirm')),
        'a long passphrase',
      );
      await tester.tap(find.byKey(const Key('setup-submit')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 600)),
      );
      await tester.pump();
      expect(find.text('Manager Mode'), findsOneWidget);
      expect(find.textContaining('Meera'), findsWidgets);
    });

    testWidgets('the password fields hide what is typed', (tester) async {
      await show(tester);
      for (final k in ['setup-password', 'setup-confirm']) {
        final field = tester.widget<TextField>(find.byKey(Key(k)));
        expect(field.obscureText, isTrue, reason: k);
      }
    });
  });

  group('lock screen', () {
    late String asha;
    late String boss;
    setUp(() async {
      asha = await auth.createUser(
        name: 'Asha',
        role: Role.cashier,
        secret: '482916',
      );
      boss = await auth.createUser(
        name: 'Boss',
        role: Role.owner,
        secret: 'a long passphrase',
      );
    });

    testWidgets('lists the names and roles, never any hash', (tester) async {
      await show(tester);
      expect(find.text('Asha'), findsOneWidget);
      expect(find.text('Cashier'), findsOneWidget);
      expect(find.text('Boss'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
      expect(find.textContaining('argon2'), findsNothing);
    });

    testWidgets(
      'shows no encryption warning on desktop, where it is encrypted',
      (tester) async {
        await show(tester);
        expect(find.textContaining('not encrypted'), findsNothing);
        expect(find.textContaining('Browser preview'), findsNothing);
      },
    );

    testWidgets('the browser preview warns that nothing is encrypted or kept', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EncryptionNotice(encrypted: false)),
        ),
      );
      expect(find.textContaining('not encrypted'), findsNothing);
      expect(
        find.textContaining('nothing here is encrypted or kept'),
        findsOneWidget,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EncryptionNotice(encrypted: true)),
        ),
      );
      expect(find.textContaining('encrypted'), findsNothing);
    });

    testWidgets(
      'a cashier types the PIN on the keypad and opens Sales Mode only',
      (tester) async {
        await show(tester);
        await tester.tap(find.byKey(Key('user-$asha')));
        await tester.pump();
        await tapPin(tester, '482916');
        expect(find.text('Sales Mode'), findsOneWidget);
        expect(find.text('Manager Mode'), findsNothing);
      },
    );

    testWidgets('a wrong PIN says how many tries are left and stays locked', (
      tester,
    ) async {
      await show(tester);
      await tester.tap(find.byKey(Key('user-$asha')));
      await tester.pump();
      await tapPin(tester, '000000');
      expect(find.text('Wrong PIN. 4 tries left.'), findsOneWidget);
      expect(find.text('Sales Mode'), findsNothing);
    });

    testWidgets(
      'five wrong PINs show the lock message, even a right PIN is refused',
      (tester) async {
        await show(tester);
        await tester.tap(find.byKey(Key('user-$asha')));
        await tester.pump();
        for (var i = 0; i < 5; i++) {
          await tapPin(tester, '00000$i');
        }
        expect(find.textContaining('Locked'), findsOneWidget);
        await tapPin(tester, '482916');
        expect(find.text('Sales Mode'), findsNothing);
        expect(find.textContaining('Locked'), findsOneWidget);
      },
    );

    testWidgets('the keypad only accepts digits and has a backspace', (
      tester,
    ) async {
      await show(tester);
      await tester.tap(find.byKey(Key('user-$asha')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('key-1')));
      await tester.tap(find.byKey(const Key('key-2')));
      await tester.tap(find.byKey(const Key('key-backspace')));
      await tester.pump();
      final field = tester.widget<TextField>(
        find.byKey(const Key('secret-field')),
      );
      expect(field.controller!.text, '1');
      expect(field.obscureText, isTrue);
    });

    testWidgets('a manager or owner types a password, shown hidden', (
      tester,
    ) async {
      await show(tester);
      await tester.tap(find.byKey(Key('user-$boss')));
      await tester.pump();
      expect(find.byKey(const Key('key-1')), findsNothing);
      final field = tester.widget<TextField>(
        find.byKey(const Key('secret-field')),
      );
      expect(field.obscureText, isTrue);
      await tester.enterText(
        find.byKey(const Key('secret-field')),
        'a long passphrase',
      );
      await tester.tap(find.byKey(const Key('signin-submit')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await tester.pump();
      expect(find.text('Manager Mode'), findsOneWidget);
    });

    testWidgets(
      'every name stays on screen; tapping another switches the entry',
      (tester) async {
        await show(tester);
        await tester.tap(find.byKey(Key('user-$asha')));
        await tester.pump();
        expect(find.text('Hello Asha, type your PIN'), findsOneWidget);
        expect(find.byKey(Key('user-$boss')), findsOneWidget); // still listed
        await tester.tap(find.byKey(Key('user-$boss')));
        await tester.pump();
        expect(find.text('Hello Boss, type your password'), findsOneWidget);
        expect(find.byKey(const Key('key-1')), findsNothing);
        await tester.tap(find.byKey(Key('user-$asha')));
        await tester.pump();
        expect(find.byKey(const Key('key-1')), findsOneWidget);
      },
    );

    testWidgets(
      'the PIN stops at 6 digits: extra key presses do nothing, and exactly 6 dots show',
      (tester) async {
        await show(tester);
        await tester.tap(find.byKey(Key('user-$asha')));
        await tester.pump();
        for (final d in ['1', '2', '3', '4', '5', '6', '7', '8']) {
          await tester.tap(find.byKey(Key('key-$d')));
        }
        await tester.pump();
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('secret-field')))
              .controller!
              .text,
          '123456',
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('pin-dots')),
            matching: find.byType(Container),
          ),
          findsNWidgets(6),
        );
        expect(find.text('Exactly 6 digits'), findsOneWidget);
      },
    );

    testWidgets('typing on a keyboard also stops at 6 digits', (tester) async {
      await show(tester);
      await tester.tap(find.byKey(Key('user-$asha')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('secret-field')), '12345678');
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('secret-field')))
            .controller!
            .text,
        '123456',
      );
    });

    testWidgets(
      'a cashier sees a dot filled for each digit typed, and Clear empties them',
      (tester) async {
        await show(tester);
        await tester.tap(find.byKey(Key('user-$asha')));
        await tester.pump();
        int filled() => tester
            .widgetList<Container>(
              find.descendant(
                of: find.byKey(const Key('pin-dots')),
                matching: find.byType(Container),
              ),
            )
            .where((c) => (c.decoration as BoxDecoration).color != Colors.white)
            .length;
        expect(filled(), 0);
        await tester.tap(find.byKey(const Key('key-1')));
        await tester.tap(find.byKey(const Key('key-2')));
        await tester.tap(find.byKey(const Key('key-3')));
        await tester.pump();
        expect(filled(), 3);
        await tester.tap(find.byKey(const Key('key-clear')));
        await tester.pump();
        expect(filled(), 0);
      },
    );
  });

  group('locking again', () {
    late String asha;
    setUp(() async {
      asha = await auth.createUser(
        name: 'Asha',
        role: Role.cashier,
        secret: '482916',
      );
    });

    Future<void> signInAsha(WidgetTester tester) async {
      await show(tester);
      await tester.tap(find.byKey(Key('user-$asha')));
      await tester.pump();
      await tapPin(tester, '482916');
      expect(find.text('Sales Mode'), findsOneWidget);
    }

    testWidgets('the Lock button locks', (tester) async {
      await signInAsha(tester);
      await tester.tap(find.byKey(const Key('lock-button')));
      await tester.pump();
      expect(find.text('Sales Mode'), findsNothing);
      expect(find.byKey(Key('user-$asha')), findsOneWidget);
    });

    testWidgets('Ctrl+L locks at once', (tester) async {
      await signInAsha(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(find.text('Sales Mode'), findsNothing);
      expect(find.byKey(Key('user-$asha')), findsOneWidget);
    });

    testWidgets('five idle minutes lock the counter', (tester) async {
      await signInAsha(tester);
      now = now.add(const Duration(minutes: 4, seconds: 59));
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Sales Mode'), findsOneWidget);
      now = now.add(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Sales Mode'), findsNothing);
      expect(find.byKey(Key('user-$asha')), findsOneWidget);
    });

    testWidgets('touching the screen restarts the idle time', (tester) async {
      await signInAsha(tester);
      now = now.add(const Duration(minutes: 4));
      await tester.tapAt(const Offset(600, 450));
      await tester.pump();
      now = now.add(const Duration(minutes: 4));
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Sales Mode'), findsOneWidget);
    });
  });
}
