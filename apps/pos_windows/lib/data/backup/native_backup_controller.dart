// The desktop implementation of what the backup screens call: [BackupService]
// for backing up, and restoring over the open database (which has to be closed
// first, so a restore always ends with the app closing). Desktop only.
import 'dart:io';
import 'dart:typed_data';

import 'package:core_domain/core_domain.dart';

import '../app_database.dart';
import '../encryption/encrypted_connection.dart';
import '../encryption/key_store.dart';
import 'backup_service.dart';

void _discardCopies(File db) => discardBeforeRestoreCopies(db);

class NativeBackupController implements BackupController {
  NativeBackupController(
    this._db,
    this._dbFile,
    this._keys,
    this._service, {
    Future<void> Function()? quitApp,
  }) : _quit = quitApp ?? (() async => exit(0));

  final AppDatabase _db;
  final File _dbFile;
  final KeyStore _keys;
  final BackupService _service;
  final Future<void> Function() _quit;

  @override
  Future<BackupStatus> status({required Role? role}) =>
      _service.status(role: role);

  @override
  Future<void> setPlace({
    required Role? role,
    required int slot,
    String? path,
  }) => _service.setPlace(role: role, slot: slot, path: path);

  @override
  Future<BackupResult> backupNow({required Role? role}) =>
      _service.backupNow(role: role);

  @override
  Future<BackupResult?> backupIfDue() => _service.backupIfDue();

  @override
  Future<BackupResult?> backupAfterShiftClose({required int openShiftsLeft}) =>
      _service.backupAfterShiftClose(openShiftsLeft: openShiftsLeft);

  @override
  Future<RestoreReport> restore({
    required String backupPath,
    String? recoveryKeyText,
    bool firstRun = false,
  }) async {
    Uint8List? typed;
    if (recoveryKeyText != null && recoveryKeyText.trim().isNotEmpty) {
      typed = RecoveryKey.parse(recoveryKeyText);
      if (typed == null) {
        return const RestoreReport(RestoreOutcome.badRecoveryKey);
      }
    }
    if (firstRun) {
      final users = await _db
          .customSelect('SELECT COUNT(*) AS c FROM users')
          .getSingle();
      if (users.read<int>('c') > 0) {
        return const RestoreReport(RestoreOutcome.notEmpty);
      }
    }
    final key = typed ?? await _keys.read();
    if (key == null) {
      return const RestoreReport(RestoreOutcome.keyRequired);
    }
    // Check the backup before the database is closed, so a wrong key or a bad
    // file leaves the app running.
    final backup = File(backupPath);
    try {
      checkBackupFile(backup, key, maxVersion: _db.schemaVersion);
    } on Object catch (e) {
      return RestoreReport(_outcomeOf(e));
    }
    await _db.close();
    try {
      await restoreBackup(
        backup: backup,
        target: _dbFile,
        keys: _keys,
        recoveryKey: typed,
        appSchemaVersion: _db.schemaVersion,
        replaceKey: firstRun,
      );
      if (firstRun) {
        _discardCopies(_dbFile); // the empty database that was here
      }
      return const RestoreReport(RestoreOutcome.done, needsRestart: true);
    } on Object catch (e) {
      return RestoreReport(_outcomeOf(e), needsRestart: true);
    }
  }

  RestoreOutcome _outcomeOf(Object e) => switch (e) {
    WrongDatabaseKey() => RestoreOutcome.wrongKey,
    BackupTooNew() => RestoreOutcome.tooNew,
    RestoreKeyMismatch() => RestoreOutcome.keyMismatch,
    RestoreKeyRequired() => RestoreOutcome.keyRequired,
    BackupFailed() => RestoreOutcome.damaged,
    _ => RestoreOutcome.failed,
  };

  @override
  Future<int> beforeRestoreCopyCount() async =>
      beforeRestoreCopies(_dbFile).length;

  @override
  Future<void> discardBeforeRestoreCopies({required Role? role}) async {
    require(role, Permission.backupAndRestore);
    _discardCopies(_dbFile);
  }

  @override
  Future<void> quit() => _quit();
}
