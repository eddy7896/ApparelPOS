// The recovery key: the database key shown once to the owner (or manager) so a
// backup can be opened on a new machine if the laptop or its Windows account is
// lost (owner, 2026-11-21). The owner must write it down and type its last
// group back before the app lets them carry on. The key is read from the key
// store only to show it; it is never written to the database, the audit log or
// the outbox (an acknowledgement records only that it was done, and by whom).
import 'dart:typed_data';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';
import 'encryption/key_store.dart';

const String _ackSetting = 'recovery_key_acknowledged_at';

class RecoveryKeyRepository {
  RecoveryKeyRepository(
    this._db,
    this._keys, {
    required String Function() newId,
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc()),
       _writer = AuditedWriter(_db, now: now, newId: newId);

  final AppDatabase _db;
  final KeyStore _keys;
  final DateTime Function() _now;
  final AuditedWriter _writer;

  /// True until the owner has acknowledged the recovery key.
  Future<bool> needsAcknowledgement() async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((s) => s.name.equals(_ackSetting))).getSingleOrNull();
    return row == null;
  }

  /// The recovery key text, for showing on screen. Needs `backupAndRestore`
  /// (manager, owner). Null if the key store holds no key.
  Future<String?> recoveryKeyText({required Role? role}) async {
    require(role, Permission.backupAndRestore);
    final key = await _keys.read();
    return key == null ? null : RecoveryKey.format(key);
  }

  /// Records that the recovery key was written down. Needs
  /// `backupAndRestore`. The key itself is not recorded anywhere.
  Future<void> acknowledge({
    required Role? role,
    required String userId,
  }) async {
    require(role, Permission.backupAndRestore);
    await _writer.run<void>(
      action: 'security.recovery_key_acknowledged',
      entityType: 'security',
      entityId: 'recovery-key',
      actor: userId,
      body: () async {
        await _db
            .into(_db.appSettings)
            .insertOnConflictUpdate(
              AppSettingsCompanion.insert(
                name: _ackSetting,
                value: _now().toIso8601String(),
              ),
            );
      },
      details: const {},
    );
  }

  /// For tests of the format only: the key as bytes.
  Future<Uint8List?> keyBytesForTest() => _keys.read();
}
