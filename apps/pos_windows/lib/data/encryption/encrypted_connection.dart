// Opens the counter's database encrypted with SQLCipher (E-ENC-1, ADR-0003).
//
//  - The key is 32 random bytes made on first launch and kept in a [KeyStore].
//  - The database is opened with that raw key, and the build is checked to
//    really be SQLCipher: a build that quietly fell back to plain SQLite would
//    store plain text, so that stops the app instead ([EncryptionUnavailable]).
//  - An existing database with no key is never replaced by a new empty one: if
//    the key is gone, opening stops with [KeyMissing] and the owner restores
//    from the recovery key.
//  - A plain-text database left by an earlier development build is converted in
//    place, and its plain-text copy and journal files are deleted.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:sqlite3/common.dart' show CommonDatabase;
import 'package:sqlite3/sqlite3.dart';

import 'key_store.dart';

/// The SQLite library in use is not SQLCipher, so nothing would be encrypted.
final class EncryptionUnavailable implements Exception {
  @override
  String toString() =>
      'EncryptionUnavailable: this build has no SQLCipher, so the database '
      'cannot be encrypted';
}

/// A database file exists but its key is not in the key store.
final class KeyMissing implements Exception {
  @override
  String toString() =>
      'KeyMissing: the database file exists but its key is not in this '
      'computer\'s credential store. Restore it with the recovery key';
}

/// The key does not open the database.
final class WrongDatabaseKey implements Exception {
  @override
  String toString() => 'WrongDatabaseKey: the key does not open this database';
}

/// The SQLite file header of an unencrypted database.
const String _plainHeader = 'SQLite format 3\u0000';

/// True when [file] exists and starts with the plain SQLite header.
bool isPlainDatabase(File file) {
  if (!file.existsSync() || file.lengthSync() < _plainHeader.length) {
    return false;
  }
  final raf = file.openSync();
  try {
    final head = raf.readSync(_plainHeader.length);
    return String.fromCharCodes(head) == _plainHeader;
  } finally {
    raf.closeSync();
  }
}

/// Throws [EncryptionUnavailable] unless [cipherVersion] (what
/// `PRAGMA cipher_version` returned) names a real SQLCipher.
void requireCipher(String? cipherVersion) {
  if (cipherVersion == null || cipherVersion.trim().isEmpty) {
    throw EncryptionUnavailable();
  }
}

Uint8List newDatabaseKey([Random? random]) {
  final r = random ?? Random.secure();
  return Uint8List.fromList([
    for (var i = 0; i < RecoveryKey.keyBytes; i++) r.nextInt(256),
  ]);
}

String? _cipherVersion(CommonDatabase db) {
  final rows = db.select('PRAGMA cipher_version');
  return rows.isEmpty ? null : rows.first.values.first?.toString();
}

/// `PRAGMA key` for a raw 32-byte key (hex only, so nothing can be injected).
String _keyPragma(Uint8List key) =>
    'PRAGMA key = "x\'${RecoveryKey.hex(key)}\'"';

/// Sets the key on an open connection, checks the build is SQLCipher and that
/// the key opens the file. Throws [EncryptionUnavailable] or [WrongDatabaseKey].
void applyKey(CommonDatabase db, Uint8List key) {
  db.execute(_keyPragma(key));
  requireCipher(_cipherVersion(db));
  try {
    db.select('SELECT count(*) FROM sqlite_master');
  } on SqliteException {
    throw WrongDatabaseKey();
  }
}

/// Converts a plain-text database at [path] into an encrypted one with [key],
/// replacing it, and deletes the plain-text file and its journal files. The
/// original is replaced only after the encrypted copy has been opened with the
/// key and checked.
void encryptPlainDatabase(String path, Uint8List key) {
  final tmp = '$path.encrypting';
  void remove(String p) {
    final f = File(p);
    if (f.existsSync()) {
      f.deleteSync();
    }
  }

  for (final p in [tmp, '$tmp-wal', '$tmp-shm']) {
    remove(p);
  }
  final plain = sqlite3.open(path);
  try {
    requireCipher(_cipherVersion(plain));
    plain.select('PRAGMA wal_checkpoint(TRUNCATE)');
    final version =
        plain.select('PRAGMA user_version').first.values.first as int;
    final quoted = tmp.replaceAll("'", "''");
    plain.execute(
      "ATTACH DATABASE '$quoted' AS encrypted KEY \"x'${RecoveryKey.hex(key)}'\"",
    );
    plain.select("SELECT sqlcipher_export('encrypted')");
    plain.execute('PRAGMA encrypted.user_version = $version');
    plain.execute('DETACH DATABASE encrypted');
  } finally {
    plain.close();
  }
  final check = sqlite3.open(tmp);
  try {
    applyKey(check, key);
  } on Object {
    remove(tmp);
    rethrow;
  } finally {
    check.close();
  }
  for (final p in [path, '$path-wal', '$path-shm']) {
    remove(p);
  }
  File(tmp).renameSync(path);
}

Uint8List _createKey(Random? random) => newDatabaseKey(random);

/// Opens the encrypted database file, making the key (and the file) on first
/// launch. Throws [EncryptionUnavailable], [KeyMissing] or [WrongDatabaseKey]
/// before any app code runs, so the start-up error page can say what is wrong.
Future<QueryExecutor> openEncryptedDatabase(
  File file,
  KeyStore keys, {
  Random? random,
  bool inBackground = true,
}) async {
  var key = await keys.read();
  final exists = file.existsSync() && file.lengthSync() > 0;
  if (exists && isPlainDatabase(file)) {
    // A plain-text database from an earlier development build.
    if (key == null) {
      key = _createKey(random);
      await keys.write(key);
    }
    encryptPlainDatabase(file.path, key);
  } else if (exists) {
    if (key == null) {
      throw KeyMissing();
    }
  } else if (key == null) {
    key = _createKey(random);
    await keys.write(key);
  }
  // Check on this isolate that the build is SQLCipher and the key opens the file.
  final probe = sqlite3.open(file.path);
  try {
    applyKey(probe, key);
  } finally {
    probe.close();
  }
  final opened = key;
  void setup(CommonDatabase db) => applyKey(db, opened);
  return inBackground
      ? NativeDatabase.createInBackground(file, setup: setup)
      : NativeDatabase(file, setup: setup);
}
