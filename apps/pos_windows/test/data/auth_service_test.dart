// P2-2 sign-in service: users table, Argon2id hashes, lockout saved per user,
// audit of security events. E-AUTH-1 and E-AUTH-2.
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/auth_service.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late AuthService auth;
  late DateTime now;
  var n = 0;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 11, 20, 10);
    n = 0;
    auth = AuthService(db, now: () => now, newId: () => 'id-${++n}');
  });
  tearDown(() => db.close());

  Future<List<Map<String, Object?>>> rows(String sql) async =>
      (await db.customSelect(sql).get()).map((r) => r.data).toList();

  group('creating users', () {
    test('a cashier needs a PIN of exactly 6 digits', () async {
      await expectLater(
        auth.createUser(name: 'Asha', role: Role.cashier, secret: '1234567'),
        throwsA(isA<WeakSecret>()),
      );
      await expectLater(
        auth.createUser(name: 'Asha', role: Role.cashier, secret: '12345'),
        throwsA(isA<WeakSecret>()),
      );
      await expectLater(
        auth.createUser(name: 'Asha', role: Role.cashier, secret: '12345a'),
        throwsA(isA<WeakSecret>()),
      );
      final id = await auth.createUser(
        name: 'Asha',
        role: Role.cashier,
        secret: '123456',
      );
      expect(id, isNotEmpty);
    });

    test(
      'a manager or owner needs a password of at least 10 characters',
      () async {
        await expectLater(
          auth.createUser(name: 'Boss', role: Role.owner, secret: 'short'),
          throwsA(isA<WeakSecret>()),
        );
        await expectLater(
          auth.createUser(name: 'Boss', role: Role.manager, secret: '123456'),
          throwsA(isA<WeakSecret>()),
        );
        await auth.createUser(
          name: 'Boss',
          role: Role.owner,
          secret: 'a long passphrase',
        );
      },
    );

    test(
      'the PIN is stored as an Argon2id hash, never as text (E-AUTH-1)',
      () async {
        await auth.createUser(
          name: 'Asha',
          role: Role.cashier,
          secret: '482916',
        );
        final all = await rows('SELECT * FROM users');
        final hash = all.single['credential_hash'] as String;
        expect(hash.startsWith(r'$argon2id$'), isTrue);
        for (final value in all.single.values) {
          expect(
            '$value'.contains('482916'),
            isFalse,
            reason: 'column value $value',
          );
        }
      },
    );

    test('names are unique ignoring upper and lower case', () async {
      await auth.createUser(name: 'Asha', role: Role.cashier, secret: '123456');
      await expectLater(
        auth.createUser(name: 'ASHA', role: Role.cashier, secret: '654321'),
        throwsA(anything),
      );
    });

    test('a blank name is refused', () async {
      await expectLater(
        auth.createUser(name: '   ', role: Role.cashier, secret: '123456'),
        throwsArgumentError,
      );
    });

    test('creating a user writes an audit row and an outbox row without the secret', () async {
      await auth.createUser(
        name: 'Asha',
        role: Role.cashier,
        secret: '482916',
        actor: 'owner-1',
      );
      final audit = await rows(
        "SELECT * FROM audit_log WHERE action = 'user.create'",
      );
      expect(audit.length, 1);
      expect(audit.single['actor'], 'owner-1');
      final outbox = await rows(
        "SELECT * FROM outbox WHERE operation = 'user.create'",
      );
      expect(outbox.length, 1);
      for (final r in [...audit, ...outbox]) {
        for (final value in r.values) {
          expect('$value'.contains('482916'), isFalse);
          expect('$value'.contains('argon2'), isFalse);
        }
      }
    });
  });

  group('signing in', () {
    late String asha;
    setUp(() async {
      asha = await auth.createUser(
        name: 'Asha',
        role: Role.cashier,
        secret: '482916',
      );
    });

    test('the right PIN signs in and returns the role', () async {
      final r = await auth.signIn(userId: asha, secret: '482916');
      expect(r, isA<SignedIn>());
      expect((r as SignedIn).role, Role.cashier);
      expect(r.name, 'Asha');
      expect(r.userId, asha);
    });

    test('a wrong PIN is refused and says how many tries are left', () async {
      final r = await auth.signIn(userId: asha, secret: '000000');
      expect(r, isA<WrongSecret>());
      expect((r as WrongSecret).triesLeft, 4);
      final r2 = await auth.signIn(userId: asha, secret: '000001');
      expect((r2 as WrongSecret).triesLeft, 3);
    });

    test('an unknown user is refused', () async {
      expect(
        await auth.signIn(userId: 'nobody', secret: '482916'),
        isA<UnknownUser>(),
      );
    });

    test('a deactivated user cannot sign in', () async {
      await auth.deactivate(userId: asha, actor: 'owner-1');
      expect(
        await auth.signIn(userId: asha, secret: '482916'),
        isA<UnknownUser>(),
      );
    });

    test('five wrong tries lock the account for 5 minutes, even for the right PIN (E-AUTH-2)', () async {
      for (var i = 0; i < 4; i++) {
        expect(
          await auth.signIn(userId: asha, secret: '00000$i'),
          isA<WrongSecret>(),
        );
      }
      final fifth = await auth.signIn(userId: asha, secret: '000009');
      expect(fifth, isA<AccountLocked>());
      expect(
        (fifth as AccountLocked).until,
        now.add(const Duration(minutes: 5)),
      );

      final right = await auth.signIn(userId: asha, secret: '482916');
      expect(right, isA<AccountLocked>());

      now = now.add(const Duration(minutes: 4, seconds: 59));
      expect(
        await auth.signIn(userId: asha, secret: '482916'),
        isA<AccountLocked>(),
      );
      now = now.add(const Duration(seconds: 1));
      expect(
        await auth.signIn(userId: asha, secret: '482916'),
        isA<SignedIn>(),
      );
    });

    test('the lock survives closing and reopening the database', () async {
      for (var i = 0; i < 5; i++) {
        await auth.signIn(userId: asha, secret: '00000$i');
      }
      final again = AuthService(db, now: () => now, newId: () => 'x${++n}');
      expect(
        await again.signIn(userId: asha, secret: '482916'),
        isA<AccountLocked>(),
      );
    });

    test('a correct PIN clears the wrong-try count', () async {
      for (var i = 0; i < 4; i++) {
        await auth.signIn(userId: asha, secret: '00000$i');
      }
      expect(
        await auth.signIn(userId: asha, secret: '482916'),
        isA<SignedIn>(),
      );
      final r = await auth.signIn(userId: asha, secret: '000000');
      expect((r as WrongSecret).triesLeft, 4);
    });

    test(
      'a locked account does not even check the PIN (no work, no counting)',
      () async {
        for (var i = 0; i < 5; i++) {
          await auth.signIn(userId: asha, secret: '00000$i');
        }
        final before = await rows(
          'SELECT failures, lock_count, locked_until FROM users',
        );
        await auth.signIn(userId: asha, secret: '000000');
        expect(
          await rows('SELECT failures, lock_count, locked_until FROM users'),
          before,
        );
      },
    );

    test('lockouts get longer: 5 then 10 minutes', () async {
      for (var i = 0; i < 5; i++) {
        await auth.signIn(userId: asha, secret: '00000$i');
      }
      now = now.add(const Duration(minutes: 5));
      AuthResultHolder? last;
      for (var i = 0; i < 5; i++) {
        last = AuthResultHolder(
          await auth.signIn(userId: asha, secret: '00001$i'),
        );
      }
      expect(
        (last!.result as AccountLocked).until,
        now.add(const Duration(minutes: 10)),
      );
    });

    test(
      'a manager signs in with a password, and a PIN is not accepted for them',
      () async {
        final boss = await auth.createUser(
          name: 'Boss',
          role: Role.owner,
          secret: 'a long passphrase',
        );
        expect(
          await auth.signIn(userId: boss, secret: 'a long passphrase'),
          isA<SignedIn>(),
        );
        expect(
          await auth.signIn(userId: boss, secret: '123456'),
          isA<WrongSecret>(),
        );
      },
    );

    test('a lockout and a correct sign-in are written to the audit log without secrets', () async {
      for (var i = 0; i < 5; i++) {
        await auth.signIn(userId: asha, secret: '00000$i');
      }
      now = now.add(const Duration(minutes: 5));
      await auth.signIn(userId: asha, secret: '482916');
      final actions = (await rows(
        'SELECT action FROM audit_log ORDER BY at, rowid',
      )).map((r) => r['action']).toList();
      expect(actions, containsAll(['auth.locked', 'auth.signin']));
      final all = await rows('SELECT details FROM audit_log');
      for (final r in all) {
        expect('${r['details']}'.contains('482916'), isFalse);
        expect('${r['details']}'.contains('000001'), isFalse);
      }
    });

    test('sign-in events are not queued for the cloud', () async {
      await auth.signIn(userId: asha, secret: '482916');
      await auth.signIn(userId: asha, secret: '000000');
      final ops = (await rows('SELECT operation FROM outbox'))
          .map((r) => r['operation'])
          .toList();
      expect(ops, ['user.create']);
    });
  });

  group('changing a PIN or password', () {
    test('the new secret works and the old one does not', () async {
      final id = await auth.createUser(
        name: 'Asha',
        role: Role.cashier,
        secret: '482916',
      );
      await auth.changeSecret(
        userId: id,
        newSecret: '135790',
        actor: 'owner-1',
      );
      expect(
        await auth.signIn(userId: id, secret: '482916'),
        isA<WrongSecret>(),
      );
      expect(await auth.signIn(userId: id, secret: '135790'), isA<SignedIn>());
    });

    test('a weak new secret is refused and nothing changes', () async {
      final id = await auth.createUser(
        name: 'Asha',
        role: Role.cashier,
        secret: '482916',
      );
      await expectLater(
        auth.changeSecret(userId: id, newSecret: '123', actor: 'x'),
        throwsA(isA<WeakSecret>()),
      );
      expect(await auth.signIn(userId: id, secret: '482916'), isA<SignedIn>());
    });

    test('changing the secret clears a lock', () async {
      final id = await auth.createUser(
        name: 'Asha',
        role: Role.cashier,
        secret: '482916',
      );
      for (var i = 0; i < 5; i++) {
        await auth.signIn(userId: id, secret: '00000$i');
      }
      await auth.changeSecret(
        userId: id,
        newSecret: '135790',
        actor: 'owner-1',
      );
      expect(await auth.signIn(userId: id, secret: '135790'), isA<SignedIn>());
    });
  });

  group('the sign-in screen list', () {
    test('lists active names and roles only, never hashes', () async {
      final a = await auth.createUser(
        name: 'Asha',
        role: Role.cashier,
        secret: '482916',
      );
      await auth.createUser(
        name: 'Boss',
        role: Role.owner,
        secret: 'a long passphrase',
      );
      await auth.deactivate(userId: a, actor: 'x');
      final list = await auth.signInChoices();
      expect(list.map((c) => c.name), ['Boss']);
      expect(list.single.role, Role.owner);
    });
  });
}

class AuthResultHolder {
  AuthResultHolder(this.result);
  final SignInResult result;
}
