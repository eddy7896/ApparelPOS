// Argon2id hashing for PINs and passwords (E-AUTH-1, ADR-0002), using the
// pure-Dart hashlib package. The stored text is the standard encoded form
// ($argon2id$v=19$m=...,t=...,p=...$salt$hash), so the settings travel with the
// hash and can be raised later (needsRehash). The secret itself is never stored.
// The salt is random per hash.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:hashlib/hashlib.dart';

/// Settings for new hashes: the OWASP minimum recommendation for Argon2id
/// (19 MiB, 2 passes, 1 lane). About 65 ms on a 2026 Mac; unverified on the
/// shop laptop. Raise them later; old hashes keep verifying.
const int argon2MemoryKiB = 19456;
const int argon2Passes = 2;
const int argon2Lanes = 1;
const int _saltBytes = 16;

// Refuse absurd settings in a damaged or hostile stored hash.
const int _maxMemoryKiB = 262144;
const int _maxPasses = 10;
const int _maxLanes = 8;

class CredentialHasher {
  CredentialHasher({Uint8List Function()? saltSource})
    : _saltSource = saltSource ?? _randomSalt;

  final Uint8List Function() _saltSource;

  static Uint8List _randomSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(_saltBytes, (_) => random.nextInt(256)),
    );
  }

  /// Hashes [secret] (a PIN or password; the caller has already checked it with
  /// `checkPin` or `checkPassword`) and returns the text to store.
  String hash(String secret) {
    if (secret.isEmpty) {
      throw ArgumentError.value(secret, 'secret', 'must not be empty');
    }
    final salt = _saltSource();
    if (salt.length < _saltBytes) {
      throw StateError('salt must be at least $_saltBytes bytes');
    }
    return argon2id(
      utf8.encode(secret),
      salt,
      security: Argon2Security(
        'pos',
        m: argon2MemoryKiB,
        t: argon2Passes,
        p: argon2Lanes,
      ),
    ).encoded();
  }

  /// True only if [stored] is a valid Argon2id hash of [secret]. Anything
  /// damaged, foreign or the wrong type is simply false.
  bool verify(String stored, String secret) {
    final params = _parse(stored);
    if (params == null || secret.isEmpty) {
      return false;
    }
    try {
      return argon2Verify(stored, utf8.encode(secret));
    } catch (_) {
      return false;
    }
  }

  /// True when [stored] was made with weaker settings than today's, so it
  /// should be hashed again after the next correct sign-in.
  bool needsRehash(String stored) {
    final params = _parse(stored);
    if (params == null) {
      return true;
    }
    return params.memoryKiB < argon2MemoryKiB ||
        params.passes < argon2Passes ||
        params.lanes < argon2Lanes;
  }
}

class _Params {
  _Params(this.memoryKiB, this.passes, this.lanes);
  final int memoryKiB;
  final int passes;
  final int lanes;
}

_Params? _parse(String stored) {
  final parts = stored.split(r'$');
  if (parts.length != 6 ||
      parts[0] != '' ||
      parts[1] != 'argon2id' ||
      parts[2] != 'v=19') {
    return null;
  }
  final match = RegExp(r'^m=(\d+),t=(\d+),p=(\d+)$').firstMatch(parts[3]);
  if (match == null || parts[4].isEmpty || parts[5].isEmpty) {
    return null;
  }
  final m = int.parse(match.group(1)!);
  final t = int.parse(match.group(2)!);
  final p = int.parse(match.group(3)!);
  if (m < 8 ||
      m > _maxMemoryKiB ||
      t < 1 ||
      t > _maxPasses ||
      p < 1 ||
      p > _maxLanes) {
    return null;
  }
  return _Params(m, t, p);
}
