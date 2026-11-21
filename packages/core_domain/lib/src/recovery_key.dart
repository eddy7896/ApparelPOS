// The database key and its recovery form (owner, 2026-11-21). The database is
// encrypted with a random 32-byte key kept in the Windows credential store. The
// same key is shown once to the owner as a recovery key, so a backup can be
// opened on a new machine if the laptop or its Windows account is lost.
//
// Text form: the 32 bytes as 16 groups of 4 hex digits, then a 4-digit check
// group (CRC-16/CCITT-FALSE of the bytes), separated by dashes, upper case:
// `A1B2-...-C3D4-9F0E`. Typing it back tolerates spaces, lower case and missing
// dashes, and a typing mistake is caught by the check group.

import 'dart:typed_data';

abstract final class RecoveryKey {
  static const int keyBytes = 32;

  static void _checkLength(Uint8List key) {
    if (key.length != keyBytes) {
      throw ArgumentError.value(key.length, 'key', 'must be $keyBytes bytes');
    }
  }

  /// CRC-16/CCITT-FALSE: polynomial 0x1021, start 0xFFFF (public so a test can
  /// check it against the standard answer for the text "123456789", 0x29B1).
  static int crc16(Uint8List data) {
    var crc = 0xFFFF;
    for (final b in data) {
      crc ^= b << 8;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 0x8000) != 0
            ? ((crc << 1) ^ 0x1021) & 0xFFFF
            : (crc << 1) & 0xFFFF;
      }
    }
    return crc;
  }

  static String _hex(Uint8List bytes) =>
      [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();

  /// The key as 64 lower-case hex digits: what the database is opened with.
  static String hex(Uint8List key) {
    _checkLength(key);
    return _hex(key);
  }

  /// The text the owner writes down.
  static String format(Uint8List key) {
    _checkLength(key);
    final digits = _hex(key).toUpperCase();
    final groups = [
      for (var i = 0; i < digits.length; i += 4) digits.substring(i, i + 4),
      crc16(key).toRadixString(16).toUpperCase().padLeft(4, '0'),
    ];
    return groups.join('-');
  }

  /// The key for what the owner typed, or null if it is not a valid recovery
  /// key (wrong length, not hex, or the check group does not match).
  static Uint8List? parse(String text) {
    final clean = text.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    if (clean.length != keyBytes * 2 + 4 ||
        !RegExp(r'^[0-9A-F]+$').hasMatch(clean)) {
      return null;
    }
    final key = Uint8List(keyBytes);
    for (var i = 0; i < keyBytes; i++) {
      key[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
    }
    final check = int.parse(clean.substring(keyBytes * 2), radix: 16);
    return check == crc16(key) ? key : null;
  }
}
