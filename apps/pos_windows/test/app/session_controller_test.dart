// Who is signed in, when the counter locks itself, and the first-launch setup
// (ADR-0002: the install wizard sets the first owner). P2-2 part 2.
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/app/session_controller.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/auth_service.dart';

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

  test(
    'starts loading, then asks for first-time setup when there are no users',
    () async {
      expect(session.stage, SessionStage.loading);
      await session.start();
      expect(session.stage, SessionStage.needsSetup);
      expect(session.choices, isEmpty);
    },
  );

  test('starts on the lock screen when users exist', () async {
    await auth.createUser(name: 'Asha', role: Role.cashier, secret: '482916');
    await session.start();
    expect(session.stage, SessionStage.locked);
    expect(session.choices.map((c) => c.name), ['Asha']);
  });

  group('first-time setup', () {
    setUp(() => session.start());

    test('creates the owner and signs them in', () async {
      final r = await session.createFirstOwner(
        name: 'Meera',
        password: 'a long passphrase',
        confirm: 'a long passphrase',
      );
      expect(r, SetupResult.done);
      expect(session.stage, SessionStage.signedIn);
      expect(session.user!.name, 'Meera');
      expect(session.user!.role, Role.owner);
    });

    test('a short password is refused and nothing is created', () async {
      final r = await session.createFirstOwner(
        name: 'Meera',
        password: 'short',
        confirm: 'short',
      );
      expect(r, SetupResult.weakPassword);
      expect(session.stage, SessionStage.needsSetup);
      expect(await auth.signInChoices(), isEmpty);
    });

    test('the two passwords must match', () async {
      final r = await session.createFirstOwner(
        name: 'Meera',
        password: 'a long passphrase',
        confirm: 'a long passphrasE',
      );
      expect(r, SetupResult.mismatch);
      expect(await auth.signInChoices(), isEmpty);
    });

    test('a blank name is refused', () async {
      final r = await session.createFirstOwner(
        name: '  ',
        password: 'a long passphrase',
        confirm: 'a long passphrase',
      );
      expect(r, SetupResult.blankName);
    });

    test('setup cannot run again once a user exists', () async {
      await session.createFirstOwner(
        name: 'Meera',
        password: 'a long passphrase',
        confirm: 'a long passphrase',
      );
      session.lock();
      final r = await session.createFirstOwner(
        name: 'Intruder',
        password: 'another long passphrase',
        confirm: 'another long passphrase',
      );
      expect(r, SetupResult.notAllowed);
      expect((await auth.signInChoices()).map((c) => c.name), ['Meera']);
    });
  });

  group('signing in and locking', () {
    late String asha;
    setUp(() async {
      asha = await auth.createUser(
        name: 'Asha',
        role: Role.cashier,
        secret: '482916',
      );
      await session.start();
    });

    test(
      'a right PIN signs in; a wrong PIN does not and stays locked',
      () async {
        expect(await session.signIn(asha, '000000'), isA<WrongSecret>());
        expect(session.stage, SessionStage.locked);
        expect(session.user, isNull);
        expect(await session.signIn(asha, '482916'), isA<SignedIn>());
        expect(session.stage, SessionStage.signedIn);
        expect(session.user!.role, Role.cashier);
      },
    );

    test(
      'lock() signs out and returns to the lock screen with the names',
      () async {
        await session.signIn(asha, '482916');
        session.lock();
        expect(session.stage, SessionStage.locked);
        expect(session.user, isNull);
        expect(session.choices.map((c) => c.name), ['Asha']);
      },
    );

    test('lock() when nobody is signed in changes nothing', () async {
      session.lock();
      expect(session.stage, SessionStage.locked);
    });

    test(
      'five idle minutes lock the counter; four minutes 59 seconds do not',
      () async {
        await session.signIn(asha, '482916');
        now = now.add(const Duration(minutes: 4, seconds: 59));
        expect(session.checkIdle(), isFalse);
        expect(session.stage, SessionStage.signedIn);
        now = now.add(const Duration(seconds: 1));
        expect(session.checkIdle(), isTrue);
        expect(session.stage, SessionStage.locked);
      },
    );

    test('activity restarts the idle time', () async {
      await session.signIn(asha, '482916');
      now = now.add(const Duration(minutes: 4));
      session.noteActivity();
      now = now.add(const Duration(minutes: 4));
      expect(session.checkIdle(), isFalse);
      now = now.add(const Duration(minutes: 1));
      expect(session.checkIdle(), isTrue);
    });

    test('idle checks do nothing on the lock screen', () async {
      now = now.add(const Duration(hours: 2));
      expect(session.checkIdle(), isFalse);
      expect(session.stage, SessionStage.locked);
    });

    test('a locked-out account stays out even with the right PIN', () async {
      for (var i = 0; i < 5; i++) {
        await session.signIn(asha, '00000$i');
      }
      final r = await session.signIn(asha, '482916');
      expect(r, isA<AccountLocked>());
      expect(session.stage, SessionStage.locked);
    });
  });

  group('practice users (development builds only)', () {
    test(
      'creates a practice owner and cashier and shows the lock screen',
      () async {
        await session.start();
        final ok = await session.createPracticeUsers();
        expect(ok, isTrue);
        expect(session.stage, SessionStage.locked);
        expect(session.choices.map((c) => c.name), [
          'Practice Cashier',
          'Practice Owner',
        ]);
        expect(
          await session.signIn(
            session.choices.first.userId,
            practiceCashierPin,
          ),
          isA<SignedIn>(),
        );
      },
    );

    test('does nothing when real users already exist', () async {
      await auth.createUser(name: 'Asha', role: Role.cashier, secret: '482916');
      await session.start();
      expect(await session.createPracticeUsers(), isFalse);
      expect((await auth.signInChoices()).map((c) => c.name), ['Asha']);
    });
  });
}
