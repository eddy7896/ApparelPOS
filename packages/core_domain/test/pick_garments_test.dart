import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('pickGarments (several of one size and color on a bill)', () {
    test('takes the lowest barcodes first', () {
      expect(pickGarments(['3', '1', '2'], {}, 2), ['1', '2']);
    });

    test('skips garments already on the bill', () {
      expect(pickGarments(['1', '2', '3', '4'], {'1', '3'}, 2), ['2', '4']);
    });

    test('gives only what is left when there are not enough', () {
      expect(pickGarments(['1', '2'], {'1'}, 5), ['2']);
    });

    test('nothing left gives an empty list', () {
      expect(pickGarments(['1'], {'1'}, 1), isEmpty);
      expect(pickGarments([], {}, 3), isEmpty);
    });

    test('a count of zero or less gives nothing', () {
      expect(pickGarments(['1', '2'], {}, 0), isEmpty);
      expect(pickGarments(['1', '2'], {}, -2), isEmpty);
    });

    test('the same barcode listed twice is picked once', () {
      expect(pickGarments(['1', '1', '2'], {}, 3), ['1', '2']);
    });

    test('the quantity is kept between 1 and 50', () {
      expect(clampGarmentCount(0), 1);
      expect(clampGarmentCount(-4), 1);
      expect(clampGarmentCount(7), 7);
      expect(clampGarmentCount(51), 50);
      expect(maxGarmentsAtOnce, 50);
    });
  });
}
