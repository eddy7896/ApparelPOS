// The recovery key: shown to manager and owner only, acknowledged once, never
// written to the database, audit log or outbox. P3-1.
import 'dart:math';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/encryption/encrypted_connection.dart';
import 'package:pos_windows/data/encryption/key_store.dart';
import 'package:pos_windows/data/recovery_key_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late MemoryKeyStore keys;
  late RecoveryKeyRepository repo;
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    keys = MemoryKeyStore(newDatabaseKey(Random(3)));
    repo = RecoveryKeyRepository(
      db,
      keys,
      newId: newId,
      now: () => DateTime.utc(2026, 11, 21),
    );
    n = 0;
  });
  tearDown(() => db.close());

  test('needs acknowledging at first, not after', () async {
    expect(await repo.needsAcknowledgement(), isTrue);
    await repo.acknowledge(role: Role.owner, userId: 'u1');
    expect(await repo.needsAcknowledgement(), isFalse);
  });

  test('shows the key in its written form to manager and owner', () async {
    final text = await repo.recoveryKeyText(role: Role.owner);
    expect(text, RecoveryKey.format((await keys.read())!));
    expect(await repo.recoveryKeyText(role: Role.manager), text);
    expect(RecoveryKey.parse(text!), await keys.read());
  });

  test(
    'a cashier and nobody are refused, for showing and for acknowledging',
    () async {
      await expectLater(
        repo.recoveryKeyText(role: Role.cashier),
        throwsA(isA<PermissionDenied>()),
      );
      await expectLater(
        repo.recoveryKeyText(role: null),
        throwsA(isA<PermissionDenied>()),
      );
      await expectLater(
        repo.acknowledge(role: Role.cashier, userId: 'u'),
        throwsA(isA<PermissionDenied>()),
      );
      expect(await repo.needsAcknowledgement(), isTrue);
    },
  );

  test('no key in the store gives nothing to show', () async {
    final none = RecoveryKeyRepository(db, MemoryKeyStore(), newId: newId);
    expect(await none.recoveryKeyText(role: Role.owner), isNull);
  });

  test('the acknowledgement is audited and queued without the key', () async {
    await repo.acknowledge(role: Role.owner, userId: 'owner-1');
    final audit = await db
        .customSelect(
          "SELECT * FROM audit_log WHERE action = 'security.recovery_key_acknowledged'",
        )
        .getSingle();
    expect(audit.read<String>('actor'), 'owner-1');
    final key = (await keys.read())!;
    final hex = RecoveryKey.hex(key);
    final text = RecoveryKey.format(key);
    final everything = [
      for (final t in ['audit_log', 'outbox', 'app_settings'])
        ...(await db.customSelect('SELECT * FROM $t').get()).map(
          (r) => r.data.values.join('|'),
        ),
    ].join('\n');
    expect(everything, isNot(contains(hex)));
    expect(everything.toUpperCase(), isNot(contains(text)));
    expect(everything.toUpperCase(), isNot(contains(hex.toUpperCase())));
  });
}
