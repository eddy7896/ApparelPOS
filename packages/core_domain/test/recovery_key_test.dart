import 'dart:typed_data';

import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

Uint8List bytes(int Function(int) f) =>
    Uint8List.fromList([for (var i = 0; i < 32; i++) f(i)]);

void main() {
  final key = bytes((i) => i * 7 + 3);

  group('the check group', () {
    test(
      'is CRC-16/CCITT-FALSE: the standard answer for "123456789" is 0x29B1',
      () {
        expect(
          RecoveryKey.crc16(Uint8List.fromList('123456789'.codeUnits)),
          0x29B1,
        );
      },
    );
    test('the check group of a key is its CRC', () {
      final k = bytes((i) => i);
      expect(
        RecoveryKey.format(k).split('-').last,
        RecoveryKey.crc16(k).toRadixString(16).toUpperCase().padLeft(4, '0'),
      );
    });
  });

  group('RecoveryKey', () {
    test('is 16 groups of 4 hex digits plus a 4 digit check group', () {
      final text = RecoveryKey.format(key);
      final groups = text.split('-');
      expect(groups.length, 17);
      expect(groups.every((g) => RegExp(r'^[0-9A-F]{4}$').hasMatch(g)), isTrue);
    });
    test('the first 16 groups are the key itself', () {
      final text = RecoveryKey.format(
        Uint8List(32)
          ..[0] = 0xAB
          ..[31] = 0x01,
      );
      expect(text.startsWith('AB00-'), isTrue);
      expect(text.split('-')[15], '0001');
    });
    test('parses what it formats, in any case, with spaces or no dashes', () {
      final text = RecoveryKey.format(key);
      expect(RecoveryKey.parse(text), key);
      expect(RecoveryKey.parse(text.toLowerCase()), key);
      expect(RecoveryKey.parse(text.replaceAll('-', ' ')), key);
      expect(RecoveryKey.parse(text.replaceAll('-', '')), key);
      expect(RecoveryKey.parse('  $text \n'), key);
    });
    test('hex of the key is what the database is opened with', () {
      expect(
        RecoveryKey.hex(
          Uint8List(32)
            ..[0] = 0xAB
            ..[31] = 0x01,
        ),
        'ab${'00' * 30}01',
      );
      expect(RecoveryKey.hex(key).length, 64);
    });
    test('a single wrong character is caught by the check group', () {
      final text = RecoveryKey.format(key);
      for (var i = 0; i < text.length; i++) {
        if (text[i] == '-') continue;
        final wrong = text[i] == '0' ? '1' : '0';
        final bad = text.replaceRange(i, i + 1, wrong);
        expect(RecoveryKey.parse(bad), isNull, reason: 'position $i');
      }
    });
    test('two swapped groups are caught', () {
      final g = RecoveryKey.format(key).split('-');
      final t = g[0];
      g[0] = g[1];
      g[1] = t;
      expect(RecoveryKey.parse(g.join('-')), isNull);
    });
    test('wrong length, letters outside hex and empty text are refused', () {
      final text = RecoveryKey.format(key);
      expect(RecoveryKey.parse(''), isNull);
      expect(RecoveryKey.parse(text.substring(0, text.length - 5)), isNull);
      expect(RecoveryKey.parse('$text-0000'), isNull);
      expect(RecoveryKey.parse(text.replaceFirst('-', 'G')), isNull);
    });
    test('the key must be exactly 32 bytes', () {
      expect(() => RecoveryKey.format(Uint8List(31)), throwsArgumentError);
      expect(() => RecoveryKey.format(Uint8List(33)), throwsArgumentError);
      expect(() => RecoveryKey.hex(Uint8List(16)), throwsArgumentError);
    });
    test('different keys give different texts', () {
      expect(
        RecoveryKey.format(key),
        isNot(RecoveryKey.format(bytes((i) => i))),
      );
    });
  });
}
