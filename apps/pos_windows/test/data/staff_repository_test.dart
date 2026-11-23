// Staff management in Manager Mode (owner, 2026-11-22): the owner and manager
// add cashiers, only the owner adds managers; PINs and passwords follow the
// sign-in rules; turning someone off keeps their history; nobody turns off
// themselves, the last owner, or someone with an open shift. E-AUTH-1,
// E-AUDIT-1.
import 'package:core_domain/core_domain.dart';
import 'package:core_domain/credential_hasher.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/auth_service.dart';
import 'package:pos_windows/data/shift_repository.dart';
import 'package:pos_windows/data/staff_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late AuthService auth;
  late StaffRepository staff;
  late ShiftRepository shifts;
  late String ownerId;
  late String managerId;
  late String ashaId;
  var n = 0;
  String newId() => 'id-${++n}';
  late String ownerHash;
  late String managerHash;
  late String ashaHash;

  setUpAll(() {
    final hasher = CredentialHasher();
    ownerHash = hasher.hash('a long passphrase');
    managerHash = hasher.hash('another long passphrase');
    ashaHash = hasher.hash('482916');
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    auth = AuthService(db, newId: newId);
    staff = StaffRepository(db, auth, newId: newId);
    shifts = ShiftRepository(db, newId: newId);
    await StockRepository(db, newId: newId).ensureCounter();
    // Hashing is slow, so the three starting people share hashes made once.
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

    ownerId = await person('Meera', Role.owner, ownerHash);
    managerId = await person('Kabir', Role.manager, managerHash);
    ashaId = await person('Asha', Role.cashier, ashaHash);
  });
  tearDown(() => db.close());

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle())
          .read<int>('c');

  Future<List<String>> actions() async => [
    for (final r
        in await db
            .customSelect('SELECT action FROM audit_log ORDER BY rowid')
            .get())
      r.read<String>('action'),
  ];

  Future<String> add(
    String name,
    Role role,
    String secret, {
    Role actor = Role.owner,
    String? actorId,
  }) => staff.add(
    actorRole: actor,
    actorId: actorId ?? ownerId,
    name: name,
    role: role,
    secret: secret,
  );

  group('the list', () {
    test(
      'manager and owner see everyone, off ones included, with no secrets',
      () async {
        await staff.turnOff(
          actorRole: Role.owner,
          actorId: ownerId,
          userId: ashaId,
        );
        for (final role in [Role.owner, Role.manager]) {
          final list = await staff.list(role: role);
          expect(
            list.map((s) => s.name),
            containsAll(['Asha', 'Kabir', 'Meera']),
          );
          expect(list.singleWhere((s) => s.name == 'Asha').active, isFalse);
          expect(list.singleWhere((s) => s.name == 'Meera').active, isTrue);
        }
      },
    );

    test('on people come first, then by name', () async {
      await staff.turnOff(
        actorRole: Role.owner,
        actorId: ownerId,
        userId: ashaId,
      );
      final list = await staff.list(role: Role.owner);
      expect(list.map((s) => s.name), ['Kabir', 'Meera', 'Asha']);
    });

    test('a cashier and nobody are refused', () async {
      await expectLater(
        staff.list(role: Role.cashier),
        throwsA(isA<PermissionDenied>()),
      );
      await expectLater(
        staff.list(role: null),
        throwsA(isA<PermissionDenied>()),
      );
    });
  });

  group('adding people', () {
    test(
      'the owner adds a cashier who can then sign in with the PIN',
      () async {
        final id = await add('Ravi', Role.cashier, '135792');
        final r = await auth.signIn(userId: id, secret: '135792');
        expect(r, isA<SignedIn>());
      },
    );

    test('a manager adds a cashier', () async {
      await add(
        'Ravi',
        Role.cashier,
        '135792',
        actor: Role.manager,
        actorId: managerId,
      );
      expect(await count('users'), 4);
    });

    test('only the owner adds a manager', () async {
      await add('Dev', Role.manager, 'yet another passphrase');
      await expectLater(
        add(
          'Zed',
          Role.manager,
          'yet another passphrase',
          actor: Role.manager,
          actorId: managerId,
        ),
        throwsA(isA<PermissionDenied>()),
      );
      await expectLater(
        add(
          'Zed',
          Role.owner,
          'yet another passphrase',
          actor: Role.manager,
          actorId: managerId,
        ),
        throwsA(isA<PermissionDenied>()),
      );
      expect(await count('users'), 4);
    });

    test('a cashier cannot add anyone', () async {
      await expectLater(
        add(
          'Ravi',
          Role.cashier,
          '135792',
          actor: Role.cashier,
          actorId: ashaId,
        ),
        throwsA(isA<PermissionDenied>()),
      );
    });

    test('a weak PIN or password is refused and nothing is saved', () async {
      await expectLater(
        add('Ravi', Role.cashier, '123'),
        throwsA(isA<WeakSecret>()),
      );
      await expectLater(
        add('Dev', Role.manager, 'short'),
        throwsA(isA<WeakSecret>()),
      );
      expect(await count('users'), 3);
    });

    test('a blank, long or odd name is refused', () async {
      for (final bad in ['   ', 'a' * 41, 'Ravi\nKumar']) {
        await expectLater(
          add(bad, Role.cashier, '135792'),
          throwsA(isA<InvalidStaffName>()),
        );
      }
      expect(await count('users'), 3);
    });

    test('the name is cleaned before it is saved', () async {
      final id = await add('  Ravi   Kumar ', Role.cashier, '135792');
      final list = await staff.list(role: Role.owner);
      expect(list.singleWhere((s) => s.id == id).name, 'Ravi Kumar');
    });

    test('a name already used (any capitals) is refused, even if that person is off', () async {
      await expectLater(
        add('asha', Role.cashier, '135792'),
        throwsA(isA<NameTaken>()),
      );
      await staff.turnOff(
        actorRole: Role.owner,
        actorId: ownerId,
        userId: ashaId,
      );
      await expectLater(
        add('ASHA', Role.cashier, '135792'),
        throwsA(isA<NameTaken>()),
      );
      expect(await count('users'), 3);
    });

    test('the audit row says who added whom, never the PIN', () async {
      await add('Ravi', Role.cashier, '135792');
      final row = await db
          .customSelect(
            "SELECT actor, details FROM audit_log WHERE action = 'user.create' ORDER BY rowid DESC LIMIT 1",
          )
          .getSingle();
      expect(row.read<String>('actor'), ownerId);
      expect(row.read<String>('details'), isNot(contains('135792')));
    });
  });

  group('a new PIN or password', () {
    test(
      'a manager resets a cashier PIN; the new one works and the old does not',
      () async {
        await staff.resetSecret(
          actorRole: Role.manager,
          actorId: managerId,
          userId: ashaId,
          newSecret: '975310',
        );
        expect(
          await auth.signIn(userId: ashaId, secret: '482916'),
          isA<WrongSecret>(),
        );
        expect(
          await auth.signIn(userId: ashaId, secret: '975310'),
          isA<SignedIn>(),
        );
      },
    );

    test('it clears a lockout', () async {
      for (var i = 0; i < 5; i++) {
        await auth.signIn(userId: ashaId, secret: '000000');
      }
      expect(
        await auth.signIn(userId: ashaId, secret: '482916'),
        isA<AccountLocked>(),
      );
      await staff.resetSecret(
        actorRole: Role.owner,
        actorId: ownerId,
        userId: ashaId,
        newSecret: '975310',
      );
      expect(
        await auth.signIn(userId: ashaId, secret: '975310'),
        isA<SignedIn>(),
      );
    });

    test('a manager cannot reset the owner or another manager', () async {
      await expectLater(
        staff.resetSecret(
          actorRole: Role.manager,
          actorId: managerId,
          userId: ownerId,
          newSecret: 'a brand new passphrase',
        ),
        throwsA(isA<PermissionDenied>()),
      );
      expect(
        await auth.signIn(userId: ownerId, secret: 'a long passphrase'),
        isA<SignedIn>(),
      );
    });

    test('anyone with the right can change their own password', () async {
      await staff.resetSecret(
        actorRole: Role.manager,
        actorId: managerId,
        userId: managerId,
        newSecret: 'a brand new passphrase',
      );
      expect(
        await auth.signIn(userId: managerId, secret: 'a brand new passphrase'),
        isA<SignedIn>(),
      );
    });

    test('a weak new secret is refused and nothing changes', () async {
      await expectLater(
        staff.resetSecret(
          actorRole: Role.owner,
          actorId: ownerId,
          userId: ashaId,
          newSecret: '12',
        ),
        throwsA(isA<WeakSecret>()),
      );
      expect(
        await auth.signIn(userId: ashaId, secret: '482916'),
        isA<SignedIn>(),
      );
    });

    test('a cashier cannot reset anyone, not even themselves here', () async {
      await expectLater(
        staff.resetSecret(
          actorRole: Role.cashier,
          actorId: ashaId,
          userId: ashaId,
          newSecret: '975310',
        ),
        throwsA(isA<PermissionDenied>()),
      );
    });
  });

  group('renaming', () {
    test(
      'a manager renames a cashier; the sign-in list shows the new name',
      () async {
        await staff.rename(
          actorRole: Role.manager,
          actorId: managerId,
          userId: ashaId,
          name: 'Asha Rao',
        );
        expect(
          (await auth.signInChoices()).map((c) => c.name),
          contains('Asha Rao'),
        );
      },
    );

    test('a name in use or a bad name is refused', () async {
      await expectLater(
        staff.rename(
          actorRole: Role.owner,
          actorId: ownerId,
          userId: ashaId,
          name: 'kabir',
        ),
        throwsA(isA<NameTaken>()),
      );
      await expectLater(
        staff.rename(
          actorRole: Role.owner,
          actorId: ownerId,
          userId: ashaId,
          name: ' ',
        ),
        throwsA(isA<InvalidStaffName>()),
      );
    });

    test('keeping the same name with other capitals is fine', () async {
      await staff.rename(
        actorRole: Role.owner,
        actorId: ownerId,
        userId: ashaId,
        name: 'ASHA',
      );
      expect(
        (await staff.list(role: Role.owner)).any((s) => s.name == 'ASHA'),
        isTrue,
      );
    });

    test('a manager cannot rename a manager', () async {
      await expectLater(
        staff.rename(
          actorRole: Role.manager,
          actorId: managerId,
          userId: managerId,
          name: 'Kab',
        ),
        throwsA(isA<PermissionDenied>()),
      );
    });
  });

  group('turning someone off and on', () {
    test(
      'off: not in the sign-in list, cannot sign in, history stays',
      () async {
        await shifts.openShift(
          role: Role.cashier,
          userId: ashaId,
          counts: const {},
        );
        await shifts.closeShift(
          role: Role.cashier,
          userId: ashaId,
          counts: const {},
        );
        await staff.turnOff(
          actorRole: Role.manager,
          actorId: managerId,
          userId: ashaId,
        );
        expect(
          (await auth.signInChoices()).map((c) => c.name),
          isNot(contains('Asha')),
        );
        expect(
          await auth.signIn(userId: ashaId, secret: '482916'),
          isA<UnknownUser>(),
        );
        expect(await count('shifts'), 1); // the shop's records are never edited
        expect(await count('users'), 3);
      },
    );

    test('on again: back in the list and can sign in', () async {
      await staff.turnOff(
        actorRole: Role.owner,
        actorId: ownerId,
        userId: ashaId,
      );
      await staff.turnOn(
        actorRole: Role.manager,
        actorId: managerId,
        userId: ashaId,
      );
      expect((await auth.signInChoices()).map((c) => c.name), contains('Asha'));
      expect(
        await auth.signIn(userId: ashaId, secret: '482916'),
        isA<SignedIn>(),
      );
    });

    test('never yourself', () async {
      await expectLater(
        staff.turnOff(actorRole: Role.owner, actorId: ownerId, userId: ownerId),
        throwsA(
          isA<CannotTurnOff>().having(
            (e) => e.block,
            'block',
            TurnOffBlock.yourself,
          ),
        ),
      );
    });

    test('never the last owner who can sign in', () async {
      final second = await add(
        'Second',
        Role.owner,
        'a second long passphrase',
      );
      // the second owner may turn off the first, but then is the last one
      await staff.turnOff(
        actorRole: Role.owner,
        actorId: second,
        userId: ownerId,
      );
      await expectLater(
        staff.turnOff(actorRole: Role.owner, actorId: ownerId, userId: second),
        throwsA(isA<CannotTurnOff>()),
      );
      await expectLater(
        staff.turnOff(actorRole: Role.owner, actorId: second, userId: second),
        throwsA(isA<CannotTurnOff>()),
      );
      expect(
        (await auth.signInChoices()).any((c) => c.role == Role.owner),
        isTrue,
      );
    });

    test('not while their shift is open', () async {
      await shifts.openShift(
        role: Role.cashier,
        userId: ashaId,
        counts: const {},
      );
      await expectLater(
        staff.turnOff(actorRole: Role.owner, actorId: ownerId, userId: ashaId),
        throwsA(
          isA<CannotTurnOff>().having(
            (e) => e.block,
            'block',
            TurnOffBlock.openShift,
          ),
        ),
      );
      expect((await auth.signInChoices()).map((c) => c.name), contains('Asha'));
    });

    test('a manager cannot turn off a manager or the owner', () async {
      await expectLater(
        staff.turnOff(
          actorRole: Role.manager,
          actorId: managerId,
          userId: ownerId,
        ),
        throwsA(isA<PermissionDenied>()),
      );
    });

    test('a cashier cannot turn anyone off', () async {
      await expectLater(
        staff.turnOff(
          actorRole: Role.cashier,
          actorId: ashaId,
          userId: managerId,
        ),
        throwsA(isA<PermissionDenied>()),
      );
    });

    test('turning off one already off, or on one already on, changes nothing and is quiet', () async {
      await staff.turnOn(
        actorRole: Role.owner,
        actorId: ownerId,
        userId: ashaId,
      );
      final before = (await actions()).length;
      await staff.turnOff(
        actorRole: Role.owner,
        actorId: ownerId,
        userId: ashaId,
      );
      await staff.turnOff(
        actorRole: Role.owner,
        actorId: ownerId,
        userId: ashaId,
      );
      expect((await actions()).where((a) => a == 'user.deactivate').length, 1);
      expect((await actions()).length, before + 1);
    });
  });

  group('the audit trail', () {
    test('each change is one row with the actor and no secret', () async {
      await add('Ravi', Role.cashier, '135792');
      await staff.resetSecret(
        actorRole: Role.owner,
        actorId: ownerId,
        userId: ashaId,
        newSecret: '975310',
      );
      await staff.rename(
        actorRole: Role.owner,
        actorId: ownerId,
        userId: ashaId,
        name: 'Asha Rao',
      );
      await staff.turnOff(
        actorRole: Role.owner,
        actorId: ownerId,
        userId: ashaId,
      );
      await staff.turnOn(
        actorRole: Role.owner,
        actorId: ownerId,
        userId: ashaId,
      );
      expect(
        await actions(),
        containsAllInOrder([
          'user.create',
          'user.secret_changed',
          'user.rename',
          'user.deactivate',
          'user.activate',
        ]),
      );
      final all = await db
          .customSelect('SELECT details, actor FROM audit_log')
          .get();
      for (final r in all) {
        for (final secret in ['135792', '975310', '482916']) {
          expect(r.read<String>('details'), isNot(contains(secret)));
        }
      }
    });
  });
}
