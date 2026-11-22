import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

List<int> rupees(Money due) =>
    quickCashAmounts(due).map((m) => m.paise ~/ 100).toList();

void main() {
  group('quickCashAmounts', () {
    test('offers the next round amounts above what is due, smallest first', () {
      expect(rupees(Money.rupees(1798)), [1800, 2000, 2500]);
      expect(rupees(Money.rupees(499)), [500, 1000, 1500]);
    });

    test('never offers the exact amount (that has its own button)', () {
      expect(rupees(Money.rupees(500)), [600, 1000, 1500]);
    });

    test('rounds a part-rupee amount up', () {
      expect(rupees(const Money(49950)), [500, 1000, 1500]);
    });

    test('has no repeats and keeps at most three', () {
      final r = rupees(Money.rupees(90));
      expect(r.toSet().length, r.length);
      expect(r.length, lessThanOrEqualTo(3));
      expect(r, everyElement(greaterThan(90)));
    });

    test('offers nothing when nothing is due', () {
      expect(quickCashAmounts(Money.zero), isEmpty);
      expect(quickCashAmounts(const Money(-500)), isEmpty);
    });
  });
}
