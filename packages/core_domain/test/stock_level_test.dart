import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('stockLevel (assistant\'s rule, to be confirmed by the owner)', () {
    test('low stock is 2 or fewer', () {
      expect(lowStockAtMost, 2);
    });
    test('none is out', () {
      expect(stockLevel(0), StockLevel.out);
    });
    test('1 and 2 are low', () {
      expect(stockLevel(1), StockLevel.low);
      expect(stockLevel(2), StockLevel.low);
    });
    test('3 and more are fine', () {
      expect(stockLevel(3), StockLevel.ok);
      expect(stockLevel(500), StockLevel.ok);
    });
    test('a negative count (bad data) is treated as out, never as plenty', () {
      expect(stockLevel(-1), StockLevel.out);
    });
  });

  group('StockFilter', () {
    test('all keeps everything', () {
      for (final n in [0, 1, 2, 3, 40]) {
        expect(StockFilter.all.keeps(n), isTrue, reason: '$n');
      }
    });
    test('in stock keeps one or more', () {
      expect(StockFilter.inStock.keeps(0), isFalse);
      expect(StockFilter.inStock.keeps(1), isTrue);
    });
    test('out of stock keeps only none', () {
      expect(StockFilter.outOfStock.keeps(0), isTrue);
      expect(StockFilter.outOfStock.keeps(1), isFalse);
    });
    test(
      'low stock keeps 1 and 2 but not none (that is out) and not plenty',
      () {
        expect(StockFilter.low.keeps(0), isFalse);
        expect(StockFilter.low.keeps(1), isTrue);
        expect(StockFilter.low.keeps(2), isTrue);
        expect(StockFilter.low.keeps(3), isFalse);
      },
    );
  });
}
