// Where the database key is kept. On Windows it is the Windows credential
// store, so the key stays out of the database file and out of the repository
// (ADR-0003 point 4). Tests use the in-memory store.
import 'dart:typed_data';

import 'package:core_domain/core_domain.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps one 32-byte database key.
abstract class KeyStore {
  /// The stored key, or null if there is none.
  Future<Uint8List?> read();

  /// Stores [key] (32 bytes), replacing any earlier one.
  Future<void> write(Uint8List key);
}

/// The key in the operating system's credential store (Windows Credential
/// Manager) through `flutter_secure_storage`. The key is stored as 64 hex
/// digits. Not exercised by the automated tests (they need a real Windows
/// session); only the Windows build proves it compiles.
class SecureKeyStore implements KeyStore {
  SecureKeyStore({
    FlutterSecureStorage? storage,
    this.name = 'apparel_pos_db_key',
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final String name;

  @override
  Future<Uint8List?> read() async {
    final text = await _storage.read(key: name);
    if (text == null || text.length != RecoveryKey.keyBytes * 2) {
      return null;
    }
    final out = Uint8List(RecoveryKey.keyBytes);
    for (var i = 0; i < out.length; i++) {
      final b = int.tryParse(text.substring(i * 2, i * 2 + 2), radix: 16);
      if (b == null) {
        return null;
      }
      out[i] = b;
    }
    return out;
  }

  @override
  Future<void> write(Uint8List key) =>
      _storage.write(key: name, value: RecoveryKey.hex(key));
}

/// A key kept in memory only: for tests.
class MemoryKeyStore implements KeyStore {
  MemoryKeyStore([Uint8List? key])
    : _key = key == null ? null : Uint8List.fromList(key);

  Uint8List? _key;

  @override
  Future<Uint8List?> read() async =>
      _key == null ? null : Uint8List.fromList(_key!);

  @override
  Future<void> write(Uint8List key) async => _key = Uint8List.fromList(key);
}
