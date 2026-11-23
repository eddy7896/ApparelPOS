// Backing up the encrypted database to two places (a USB drive and a folder the
// owner chooses) and restoring one onto a clean machine (ADR-0015, E-BACKUP-1).
//
// A backup is the encrypted file itself: a consistent snapshot made with
// `VACUUM INTO` while the app runs (SQLCipher keeps the same key), checked by
// opening it with the key, then copied to each place under a temporary name and
// checked again before it gets its final name. Opening a backup needs the key:
// on this computer it is in the credential store, on a new one it is the
// recovery key the owner wrote down (ADR-0003 point 10).
//
// If one place is unavailable (a USB drive not plugged in) the other still gets
// its copy, the day counts as partly done and is tried again at the next shift
// close or start-up (owner, 2026-11-21). Files that are not our backups are
// never deleted. Only dart:io builds use this file; the browser preview does
// not (it keeps nothing).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

import '../app_database.dart';
import '../encryption/encrypted_connection.dart';
import '../encryption/key_store.dart';
import 'backup_models.dart';

export 'backup_models.dart';

/// The snapshot of the database could not be made or did not check out.
final class BackupFailed implements Exception {
  BackupFailed(this.message);
  final String message;
  @override
  String toString() => 'BackupFailed: $message';
}

const String _placeSetting = 'backup_place_';
const String _attemptSetting = 'backup_last_attempt_at';
const String _savedSetting = 'backup_last_saved_at';
const String _completeSetting = 'backup_last_complete_at';
const String _failuresSetting = 'backup_last_failures';

/// Opens [file] (read only) with [key], checks it is a healthy database of a
/// version no newer than [maxVersion], and returns its schema version.
int checkBackupFile(File file, Uint8List key, {int? maxVersion}) {
  raw.Database db;
  try {
    db = raw.sqlite3.open(file.path, mode: raw.OpenMode.readOnly);
  } on raw.SqliteException {
    throw BackupFailed('${file.uri.pathSegments.last} cannot be opened');
  }
  try {
    applyKey(db, key);
    final integrity = db.select('PRAGMA integrity_check').first.values.first;
    if (integrity != 'ok') {
      throw BackupFailed(
        '${file.uri.pathSegments.last} is damaged ($integrity)',
      );
    }
    final version = db.select('PRAGMA user_version').first.values.first as int;
    if (maxVersion != null && version > maxVersion) {
      throw BackupTooNew(version, maxVersion);
    }
    return version;
  } finally {
    db.close();
  }
}

/// The backup was made by a newer version of the app.
final class BackupTooNew implements Exception {
  BackupTooNew(this.backupVersion, this.appVersion);
  final int backupVersion;
  final int appVersion;
  @override
  String toString() =>
      'BackupTooNew: the backup is database version $backupVersion but this app knows $appVersion. Update the app';
}

class BackupService {
  BackupService(
    this._db,
    this._dbFile,
    this._keys, {
    required String Function() newId,
    DateTime Function()? now,
    Future<void> Function(File from, File to)? copier,
    this.keep = defaultBackupsToKeep,
  }) : _now = now ?? (() => DateTime.now().toUtc()),
       _copier = copier ?? ((from, to) => from.copy(to.path).then((_) {})),
       _writer = AuditedWriter(_db, now: now, newId: newId);

  final AppDatabase _db;
  final File _dbFile;
  final KeyStore _keys;
  final DateTime Function() _now;
  final Future<void> Function(File from, File to) _copier;

  /// How many backups to keep in each place.
  final int keep;
  final AuditedWriter _writer;
  Future<BackupResult>? _running;

  // ---- settings ---------------------------------------------------------------

  Future<String?> _get(String name) async => (await (_db.select(
    _db.appSettings,
  )..where((s) => s.name.equals(name))).getSingleOrNull())?.value;

  Future<void> _set(String name, String value) => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(name: name, value: value),
      );

  Future<void> _clear(String name) =>
      (_db.delete(_db.appSettings)..where((s) => s.name.equals(name))).go();

  /// The chosen places, slot 1 then 2, skipping empty slots.
  Future<List<(int, String)>> places() async => [
    for (final slot in [1, 2])
      if (await _get('$_placeSetting$slot') case final String path
          when path.isNotEmpty)
        (slot, path),
  ];

  /// Chooses (or clears, with null) the folder for [slot] 1 or 2. Needs
  /// `backupAndRestore`.
  Future<void> setPlace({
    required Role? role,
    required int slot,
    String? path,
  }) async {
    require(role, Permission.backupAndRestore);
    if (slot != 1 && slot != 2) {
      throw ArgumentError.value(slot, 'slot', 'must be 1 or 2');
    }
    final clean = path?.trim();
    if (clean == null || clean.isEmpty) {
      await _clear('$_placeSetting$slot');
    } else {
      await _set('$_placeSetting$slot', clean);
    }
  }

  DateTime? _time(String? text) =>
      text == null ? null : DateTime.tryParse(text)?.toUtc();

  /// The places and the last results, for the manager. Needs
  /// `backupAndRestore`; a cashier never sees backup problems.
  Future<BackupStatus> status({required Role? role}) async {
    require(role, Permission.backupAndRestore);
    final failures = <int, String>{};
    final text = await _get(_failuresSetting);
    if (text != null) {
      final map = jsonDecode(text) as Map<String, dynamic>;
      map.forEach((k, v) => failures[int.parse(k)] = v as String);
    }
    return BackupStatus(
      places: {
        for (final slot in [1, 2]) slot: await _get('$_placeSetting$slot'),
      },
      lastAttemptAt: _time(await _get(_attemptSetting)),
      lastSavedAt: _time(await _get(_savedSetting)),
      lastCompleteAt: _time(await _get(_completeSetting)),
      failures: failures,
    );
  }

  /// True when no complete backup (every place) was made on today's India day.
  Future<bool> isDue() async =>
      isBackupDue(_time(await _get(_completeSetting)), _now());

  // ---- backing up -------------------------------------------------------------

  /// Backs up now. Needs `backupAndRestore`. Throws [NoBackupPlaces] or
  /// [BackupFailed]; a place that fails is reported in the result instead.
  Future<BackupResult> backupNow({required Role? role}) async {
    require(role, Permission.backupAndRestore);
    return _run();
  }

  /// The automatic backup at start-up: runs only if one is due and a place is
  /// chosen. Returns null when nothing was done. Not tied to a person: the
  /// app calls it. A failure is recorded for the manager, never thrown.
  Future<BackupResult?> backupIfDue() async {
    if (!await isDue() || (await places()).isEmpty) {
      return null;
    }
    return _runQuietly();
  }

  /// The automatic backup after a shift close: only when no shift is left
  /// open. Returns null when nothing was done.
  Future<BackupResult?> backupAfterShiftClose({
    required int openShiftsLeft,
  }) async {
    if (!backupAfterClose(openShiftsLeft: openShiftsLeft) ||
        (await places()).isEmpty) {
      return null;
    }
    return _runQuietly();
  }

  Future<BackupResult?> _runQuietly() async {
    try {
      return await _run();
    } on Object {
      return null; // recorded by _run for the manager; billing must go on
    }
  }

  Future<BackupResult> _run() {
    // One backup at a time; a second request gets the same run.
    return _running ??= _doRun().whenComplete(() => _running = null);
  }

  String _short(Object e) {
    final t = e.toString().replaceFirst(RegExp(r'^[A-Za-z]*Exception: '), '');
    return t.length > 120 ? '${t.substring(0, 120)}...' : t;
  }

  Future<BackupResult> _doRun() async {
    final places = await this.places();
    if (places.isEmpty) {
      throw NoBackupPlaces();
    }
    final at = _now();
    final name = BackupName.format(at);
    final snap = File('${_dbFile.path}.snapshot');
    if (snap.existsSync()) {
      snap.deleteSync();
    }
    final key = await _keys.read();
    try {
      if (key == null) {
        throw BackupFailed('the database key is missing');
      }
      final quoted = snap.path.replaceAll("'", "''");
      await _db.customStatement("VACUUM INTO '$quoted'");
      checkBackupFile(snap, key);
    } on Object catch (e) {
      if (snap.existsSync()) {
        snap.deleteSync();
      }
      await _record(at, [
        for (final (slot, _) in places)
          PlaceResult(slot: slot, ok: false, error: _short(e)),
      ]);
      if (e is BackupFailed) {
        rethrow;
      }
      throw BackupFailed(_short(e));
    }
    final results = <PlaceResult>[];
    try {
      for (final (slot, path) in places) {
        results.add(await _toPlace(slot, path, name, snap, key));
      }
    } finally {
      if (snap.existsSync()) {
        snap.deleteSync();
      }
    }
    final result = BackupResult(at: at, places: results);
    await _record(at, results);
    return result;
  }

  Future<PlaceResult> _toPlace(
    int slot,
    String path,
    String name,
    File snap,
    Uint8List key,
  ) async {
    final dir = Directory(path);
    final partial = File('${dir.path}${Platform.pathSeparator}$name.partial');
    try {
      if (!dir.existsSync()) {
        throw BackupFailed(
          'the folder is not there (is the drive plugged in?)',
        );
      }
      await _copier(snap, partial);
      checkBackupFile(partial, key);
      final finalFile = File('${dir.path}${Platform.pathSeparator}$name');
      if (finalFile.existsSync()) {
        finalFile.deleteSync(); // two backups in the same second (Windows cannot rename over a file)
      }
      partial.renameSync(finalFile.path);
      final names = [
        for (final f in dir.listSync().whereType<File>())
          f.uri.pathSegments.last,
      ];
      final doomed = backupsToDelete(names, keep: keep);
      for (final n in doomed) {
        File('${dir.path}${Platform.pathSeparator}$n').deleteSync();
      }
      return PlaceResult(
        slot: slot,
        ok: true,
        fileName: name,
        pruned: doomed.length,
      );
    } on Object catch (e) {
      try {
        if (partial.existsSync()) {
          partial.deleteSync();
        }
      } on Object {
        // nothing more to do for a half-written file on a drive that went away
      }
      return PlaceResult(slot: slot, ok: false, error: _short(e));
    }
  }

  Future<void> _record(DateTime at, List<PlaceResult> results) async {
    final saved = results.any((r) => r.ok);
    final complete = results.isNotEmpty && results.every((r) => r.ok);
    final failures = {
      for (final r in results)
        if (!r.ok) '${r.slot}': r.error ?? 'failed',
    };
    await _writer.run<void>(
      action: 'backup.run',
      entityType: 'backup',
      entityId: BackupName.format(at),
      body: () async {
        await _set(_attemptSetting, at.toIso8601String());
        if (saved) {
          await _set(_savedSetting, at.toIso8601String());
        }
        if (complete) {
          await _set(_completeSetting, at.toIso8601String());
        }
        if (failures.isEmpty) {
          await _clear(_failuresSetting);
        } else {
          await _set(_failuresSetting, jsonEncode(failures));
        }
      },
      // Counts only: no paths and nothing about the key.
      details: {
        'placesOk': results.where((r) => r.ok).length,
        'placesFailed': failures.length,
      },
    );
  }
}

// ---- restoring ----------------------------------------------------------------

/// A restore needs a key and there is none (not in this computer's credential
/// store, and no recovery key was typed in).
final class RestoreKeyRequired implements Exception {
  @override
  String toString() => 'RestoreKeyRequired: type in the recovery key';
}

/// The computer already holds a different key for its current database.
/// Replacing it would make the before-restore copy unreadable.
final class RestoreKeyMismatch implements Exception {
  @override
  String toString() =>
      'RestoreKeyMismatch: this computer has a different database key than the backup';
}

/// What a restore did.
final class RestoreResult {
  const RestoreResult({required this.version, this.beforeRestoreCopy});

  /// The restored database's schema version.
  final int version;

  /// Where the database that was here before was kept, or null if there was none.
  final File? beforeRestoreCopy;
}

String _suffix(DateTime at) =>
    '.before-restore-${BackupName.format(at).replaceAll('apparel-pos-', '').replaceAll('.backup', '')}';

/// Restores [backup] over [target] (the database file). The database must be
/// closed first. The key is [recoveryKey] if given, else the one in [keys]. The
/// backup is checked before anything is changed; the database that was at
/// [target] is kept aside as a before-restore copy (owner, 2026-11-21) and put
/// back if the restore fails. On success the key is saved in [keys] if it holds
/// none. Throws [RestoreKeyRequired], [WrongDatabaseKey], [BackupFailed],
/// [BackupTooNew] or [RestoreKeyMismatch]. [afterMovedAside] exists for tests
/// of the rollback. Who may do this is checked by the
/// screen (manager or owner, or first launch before any user exists).
Future<RestoreResult> restoreBackup({
  required File backup,
  required File target,
  required KeyStore keys,
  Uint8List? recoveryKey,
  required int appSchemaVersion,
  DateTime? now,
  Future<void> Function()? afterMovedAside,
  bool replaceKey = false,
}) async {
  final stored = await keys.read();
  final key = recoveryKey ?? stored;
  if (key == null) {
    throw RestoreKeyRequired();
  }
  final version = checkBackupFile(backup, key, maxVersion: appSchemaVersion);
  final hasCurrent = target.existsSync() && target.lengthSync() > 0;
  if (!replaceKey && hasCurrent && stored != null && !_same(stored, key)) {
    throw RestoreKeyMismatch();
  }
  final stamp = _suffix(now ?? DateTime.now().toUtc());
  final moved = <File, File>{};
  void moveAside(String path) {
    final f = File(path);
    if (f.existsSync()) {
      final aside = File('$path$stamp');
      f.renameSync(aside.path);
      moved[aside] = f;
    }
  }

  void putBack() {
    for (final e in moved.entries) {
      if (e.value.existsSync()) {
        e.value.deleteSync();
      }
      e.key.renameSync(e.value.path);
    }
  }

  final tmp = File('${target.path}.restoring');
  try {
    if (tmp.existsSync()) {
      tmp.deleteSync();
    }
    await backup.copy(tmp.path);
    checkBackupFile(tmp, key, maxVersion: appSchemaVersion);
    for (final p in [target.path, '${target.path}-wal', '${target.path}-shm']) {
      moveAside(p);
    }
    await afterMovedAside?.call(); // a test can make the restore fail here
    tmp.renameSync(target.path);
  } on Object {
    if (tmp.existsSync()) {
      tmp.deleteSync();
    }
    putBack();
    rethrow;
  }
  if (stored == null || (replaceKey && !_same(stored, key))) {
    await keys.write(key);
  }
  final aside = File('${target.path}$stamp');
  return RestoreResult(
    version: version,
    beforeRestoreCopy: aside.existsSync() ? aside : null,
  );
}

bool _same(Uint8List a, Uint8List b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// The before-restore copies next to [target], newest first.
List<File> beforeRestoreCopies(File target) {
  final dir = target.parent;
  final base = target.uri.pathSegments.last;
  final found = [
    for (final f in dir.listSync().whereType<File>())
      if (f.uri.pathSegments.last.startsWith('$base.before-restore-') &&
          !f.path.endsWith('-wal') &&
          !f.path.endsWith('-shm'))
        f,
  ]..sort((a, b) => b.path.compareTo(a.path));
  return found;
}

/// Deletes the before-restore copies of [target] (and their journal files):
/// the owner confirmed the restored data looks right.
void discardBeforeRestoreCopies(File target) {
  for (final f in beforeRestoreCopies(target)) {
    for (final p in [f.path, '${f.path}-wal', '${f.path}-shm']) {
      final file = File(p);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }
}

/// The backup files in [place], newest first, with their time.
List<(File, DateTime)> listBackups(Directory place) {
  if (!place.existsSync()) {
    return const [];
  }
  final out = [
    for (final f in place.listSync().whereType<File>())
      if (BackupName.parse(f.uri.pathSegments.last) case final DateTime t)
        (f, t),
  ]..sort((a, b) => b.$2.compareTo(a.$2));
  return out;
}
