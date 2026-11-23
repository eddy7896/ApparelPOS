// Code 128 Subset C encoder (digit pairs). Checked against run-lengths from an
// independent library (see fixtures/code128c_oracle.json).
import 'dart:convert';
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

String runsToString(List<int> runs) => runs.join();

void main() {
  final fixtures =
      (jsonDecode(File('test/fixtures/code128c_oracle.json').readAsStringSync())
              as Map<String, dynamic>)['cases']
          as Map<String, dynamic>;

  group('matches the independent oracle', () {
    for (final entry in fixtures.entries) {
      test('digits ${entry.key}', () {
        expect(runsToString(code128CRuns(entry.key)), entry.value);
      });
    }
  });

  group('structure', () {
    test('starts with Start C and ends with the stop pattern', () {
      final runs = runsToString(code128CRuns('261100100013'));
      expect(runs.startsWith('211232'), isTrue);
      expect(runs.endsWith('2331112'), isTrue);
    });

    test('module count is 11 per symbol plus 13 for the stop', () {
      for (final digits in ['00', '0000', '261100100013', '99999999']) {
        final total = code128CRuns(digits).reduce((a, b) => a + b);
        final symbols = digits.length ~/ 2 + 2; // start, data pairs, checksum
        expect(total, 11 * symbols + 13, reason: digits);
      }
    });

    test(
      'bars and spaces alternate, starting with a bar (odd count of runs)',
      () {
        final runs = code128CRuns('261100100013');
        // 6 runs per symbol x (start + 6 pairs + check) + 7 for the stop
        expect(runs.length, 6 * 8 + 7);
        expect(runs.every((r) => r >= 1 && r <= 4), isTrue);
      },
    );

    test('every real barcode value encodes', () {
      const b = Barcode(year: 26, month: 11, lot: 123, serial: 4567);
      expect(() => code128CRuns(b.value), returnsNormally);
    });
  });

  group('rejects bad input', () {
    test(
      'odd length',
      () => expect(() => code128CRuns('123'), throwsArgumentError),
    );
    test('empty', () => expect(() => code128CRuns(''), throwsArgumentError));
    test(
      'non-digits',
      () => expect(() => code128CRuns('12a4'), throwsArgumentError),
    );
  });
}
