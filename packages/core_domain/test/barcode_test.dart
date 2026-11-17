// E-SERIAL-1: a barcode is unique; each counter issues from its own lot range.
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('check digit (Luhn)', () {
    test('matches known reference values', () {
      expect(luhnCheckDigit('7992739871'), 3);
      expect(luhnCheckDigit('26110010001'), 3);
      expect(luhnCheckDigit('26110019999'), 9);
      expect(luhnCheckDigit('25120000000'), 7);
      expect(luhnCheckDigit('99123999999'), 8);
    });
    test('rejects non-digits', () {
      expect(() => luhnCheckDigit('12a'), throwsArgumentError);
    });
  });

  group('Barcode encode / parse', () {
    test('encodes YYMM + lot + serial + check digit, 12 digits', () {
      const b = Barcode(year: 26, month: 11, lot: 1, serial: 1);
      expect(b.value, '261100100013');
      expect(b.value.length, 12);
      expect(
        const Barcode(year: 26, month: 11, lot: 1, serial: 9999).value,
        '261100199999',
      );
      expect(
        const Barcode(year: 25, month: 12, lot: 0, serial: 0).value,
        '251200000007',
      );
    });

    test('parse is the inverse of encode', () {
      for (final b in [
        const Barcode(year: 0, month: 1, lot: 0, serial: 0),
        const Barcode(year: 26, month: 11, lot: 123, serial: 4567),
        const Barcode(year: 99, month: 12, lot: 999, serial: 9999),
      ]) {
        expect(Barcode.parse(b.value), b);
      }
    });

    test('parse rejects a wrong check digit (any single digit changed)', () {
      const good = '261100100013';
      expect(Barcode.tryParse(good), isNotNull);
      for (var i = 0; i < good.length; i++) {
        for (var d = 0; d < 10; d++) {
          if (good[i] == '$d') continue;
          final bad = good.replaceRange(i, i + 1, '$d');
          expect(Barcode.tryParse(bad), isNull, reason: bad);
        }
      }
    });

    test('parse rejects bad length, non-digits and impossible month', () {
      expect(Barcode.tryParse('26110010001'), isNull); // 11 digits
      expect(Barcode.tryParse('2611001000133'), isNull);
      expect(Barcode.tryParse('26110010001x'), isNull);
      expect(Barcode.tryParse(''), isNull);
      // month 13 and 00 with otherwise valid check digits
      expect(
        Barcode.tryParse('2613001000${luhnCheckDigit('2613001000')}'),
        isNull,
      );
      expect(
        Barcode.tryParse('2600001000${luhnCheckDigit('2600001000')}'),
        isNull,
      );
      expect(() => Barcode.parse('nope'), throwsFormatException);
    });

    test('constructor rejects out-of-range parts', () {
      expect(
        () => Barcode(year: 100, month: 1, lot: 0, serial: 0),
        throwsArgumentError,
      );
      expect(
        () => Barcode(year: 1, month: 13, lot: 0, serial: 0),
        throwsArgumentError,
      );
      expect(
        () => Barcode(year: 1, month: 0, lot: 0, serial: 0),
        throwsArgumentError,
      );
      expect(
        () => Barcode(year: 1, month: 1, lot: 1000, serial: 0),
        throwsArgumentError,
      );
      expect(
        () => Barcode(year: 1, month: 1, lot: 0, serial: 10000),
        throwsArgumentError,
      );
      expect(
        () => Barcode(year: 1, month: 1, lot: -1, serial: 0),
        throwsArgumentError,
      );
    });

    test('code 128 subset C needs an even digit count', () {
      expect(
        const Barcode(
          year: 26,
          month: 11,
          lot: 5,
          serial: 5,
        ).value.length.isEven,
        isTrue,
      );
    });
  });

  group('LotRange', () {
    test('contains and overlaps (inclusive ends)', () {
      final a = LotRange(0, 499);
      expect(a.contains(0), isTrue);
      expect(a.contains(499), isTrue);
      expect(a.contains(500), isFalse);
      expect(a.overlaps(LotRange(499, 600)), isTrue);
      expect(a.overlaps(LotRange(500, 999)), isFalse);
      expect(a.overlaps(LotRange(100, 200)), isTrue);
    });
    test('rejects invalid ranges', () {
      expect(() => LotRange(5, 4), throwsArgumentError);
      expect(() => LotRange(-1, 4), throwsArgumentError);
      expect(() => LotRange(0, 1000), throwsArgumentError);
    });
  });

  group('counter ranges', () {
    test('disjoint ranges are accepted', () {
      expect(
        () => checkCounterRanges({
          'c1': LotRange(0, 499),
          'c2': LotRange(500, 999),
        }),
        returnsNormally,
      );
    });
    test('overlapping ranges are rejected and name both counters', () {
      expect(
        () => checkCounterRanges({
          'c1': LotRange(0, 500),
          'c2': LotRange(500, 999),
        }),
        throwsA(
          isA<RangeOverlap>().having(
            (e) => e.message,
            'message',
            allOf(contains('c1'), contains('c2')),
          ),
        ),
      );
    });
  });

  group('LotCursor issuing', () {
    test('issues consecutive serials from the start of a lot', () {
      final cursor = LotCursor.start(LotRange(10, 19));
      final r = cursor.issue(3, year: 26, month: 11);
      expect(r.barcodes.map((b) => (b.lot, b.serial)), [
        (10, 0),
        (10, 1),
        (10, 2),
      ]);
      expect(r.cursor.nextSerial, 3);
      expect(r.cursor.lot, 10);
    });

    test('continues where it stopped, never repeating', () {
      var c = LotCursor.start(LotRange(10, 19));
      final seen = <String>{};
      for (var i = 0; i < 50; i++) {
        final r = c.issue(7, year: 26, month: 11);
        for (final b in r.barcodes) {
          expect(seen.add(b.value), isTrue, reason: b.value);
        }
        c = r.cursor;
      }
      expect(seen.length, 350);
    });

    test('a lot holds 10000 serials; the 10001st throws LotFull', () {
      var c = LotCursor.start(LotRange(10, 19));
      c = c.issue(10000, year: 26, month: 11).cursor;
      expect(() => c.issue(1, year: 26, month: 11), throwsA(isA<LotFull>()));
    });

    test('a request that would not fit issues nothing', () {
      final c = LotCursor.start(LotRange(10, 19))
          .issue(9990, year: 26, month: 11)
          .cursor;
      expect(() => c.issue(11, year: 26, month: 11), throwsA(isA<LotFull>()));
      expect(c.nextSerial, 9990);
    });

    test('nextLot moves one lot on inside the range, then exhausts', () {
      var c = LotCursor.start(LotRange(10, 11));
      c = c.nextLot();
      expect(c.lot, 11);
      expect(c.nextSerial, 0);
      expect(() => c.nextLot(), throwsA(isA<RangeExhausted>()));
    });

    test('count must be at least 1', () {
      final c = LotCursor.start(LotRange(0, 9));
      expect(() => c.issue(0, year: 26, month: 11), throwsArgumentError);
    });

    test(
      'two counters with disjoint ranges never produce the same barcode',
      () {
        final ranges = {'c1': LotRange(0, 499), 'c2': LotRange(500, 999)};
        checkCounterRanges(ranges);
        final all = <String>{};
        var total = 0;
        for (final entry in ranges.entries) {
          var c = LotCursor.start(entry.value);
          for (var lot = 0; lot < 3; lot++) {
            final r = c.issue(2500, year: 26, month: 11);
            total += r.barcodes.length;
            all.addAll(r.barcodes.map((b) => b.value));
            c = r.cursor.nextLot();
          }
        }
        expect(all.length, total);
      },
    );

    test('lot numbers outside a counter range are never issued', () {
      var c = LotCursor.start(LotRange(500, 502));
      final lots = <int>{};
      for (var i = 0; i < 3; i++) {
        lots.addAll(c.issue(5, year: 26, month: 11).barcodes.map((b) => b.lot));
        if (i < 2) c = c.nextLot();
      }
      expect(lots, {500, 501, 502});
    });
  });
}
