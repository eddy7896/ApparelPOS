// E-AUTH-1: PINs and passwords are hashed with Argon2id, never stored as text.
import 'dart:typed_data';

import 'package:core_domain/credential_hasher.dart';
import 'package:hashlib/hashlib.dart';
import 'package:test/test.dart';

void main() {
  test('the library reproduces the RFC 9106 Argon2id test vector', () {
    final tag = Argon2(
      type: Argon2Type.argon2id,
      version: Argon2Version.v13,
      salt: List.filled(16, 2),
      key: List.filled(8, 3),
      personalization: List.filled(12, 4),
      iterations: 3,
      parallelism: 4,
      memorySizeKB: 32,
      hashLength: 32,
    ).convert(List.filled(32, 1));
    expect(
      tag.hex(),
      '0d640df58d78766c08c037a34a8b53c9d01ef0452d75b65eb52520e96b01e659',
    );
  });

  group('CredentialHasher', () {
    final hasher = CredentialHasher();

    test('uses Argon2id with the chosen settings and a salt', () {
      final h = hasher.hash('123456');
      expect(
        h.startsWith(r'$argon2id$v=19$m=19456,t=2,p=1$'),
        isTrue,
        reason: h,
      );
      expect(h.split(r'$').length, 6); // "", argon2id, v, params, salt, hash
    });

    test('the secret never appears in the stored text', () {
      final h = hasher.hash('123456');
      expect(h.contains('123456'), isFalse);
      final p = hasher.hash('correct horse battery');
      expect(p.contains('correct'), isFalse);
    });

    test('the same secret hashes differently each time (random salt)', () {
      expect(hasher.hash('123456'), isNot(hasher.hash('123456')));
    });

    test('verify accepts the right secret and refuses a wrong one', () {
      final h = hasher.hash('123456');
      expect(hasher.verify(h, '123456'), isTrue);
      expect(hasher.verify(h, '123457'), isFalse);
      expect(hasher.verify(h, '12345'), isFalse);
      expect(hasher.verify(h, ''), isFalse);
      expect(hasher.verify(h, '1234560'), isFalse);
    });

    test('works for passwords with spaces and non-English characters', () {
      const pw = 'पासवर्ड और space 😀';
      final h = hasher.hash(pw);
      expect(hasher.verify(h, pw), isTrue);
      expect(hasher.verify(h, 'पासवर्ड और space'), isFalse);
    });

    test('an empty secret is refused', () {
      expect(() => hasher.hash(''), throwsArgumentError);
    });

    test(
      'a damaged or foreign hash is simply "no", never a crash or a yes',
      () {
        for (final bad in [
          '',
          'plain',
          r'$argon2id$',
          r'$argon2id$v=19$m=1,t=1,p=1$AAAA$',
          '123456',
        ]) {
          expect(hasher.verify(bad, '123456'), isFalse, reason: bad);
        }
      },
    );

    test(
      'a hash made with an older, weaker setting still verifies and is flagged',
      () {
        final weak = argon2id(
          Uint8List.fromList('123456'.codeUnits),
          Uint8List.fromList(List.filled(16, 9)),
          security: Argon2Security('weak', m: 1024, t: 1, p: 1),
        ).encoded();
        expect(hasher.verify(weak, '123456'), isTrue);
        expect(hasher.needsRehash(weak), isTrue);
        expect(hasher.needsRehash(hasher.hash('123456')), isFalse);
      },
    );

    test('a hash made with a different Argon2 type is refused', () {
      final d = argon2d(
        Uint8List.fromList('123456'.codeUnits),
        Uint8List.fromList(List.filled(16, 9)),
        security: Argon2Security('t', m: 1024, t: 1, p: 1),
      ).encoded();
      expect(hasher.verify(d, '123456'), isFalse);
    });

    test('salt comes from the supplied source (tests can fix it)', () {
      final fixed = CredentialHasher(
        saltSource: () => Uint8List.fromList(List.filled(16, 5)),
      );
      expect(fixed.hash('123456'), fixed.hash('123456'));
    });

    test('a salt shorter than 16 bytes is refused', () {
      final short = CredentialHasher(saltSource: () => Uint8List(8));
      expect(() => short.hash('123456'), throwsStateError);
    });
  });
}
