// Typing an amount: "499", "499.5", "1,499.50" become exact paise with no
// floating point (E-MONEY-1).
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  test('whole rupees', () {
    expect(parseRupees('499'), const Money(49900));
    expect(parseRupees('0'), Money.zero);
    expect(parseRupees('  250 '), const Money(25000));
  });

  test('rupees and paise', () {
    expect(parseRupees('499.50'), const Money(49950));
    expect(parseRupees('499.5'), const Money(49950));
    expect(parseRupees('499.05'), const Money(49905));
    expect(parseRupees('0.99'), const Money(99));
    expect(parseRupees('499.'), const Money(49900));
    expect(parseRupees('.5'), const Money(50));
  });

  test('commas and a rupee sign are allowed', () {
    expect(parseRupees('1,499'), const Money(149900));
    expect(parseRupees('1,23,456.78'), const Money(12345678));
    expect(parseRupees('₹499'), const Money(49900));
    expect(parseRupees('₹ 1,499.50'), const Money(149950));
  });

  test('more than two decimals is refused, never rounded', () {
    expect(parseRupees('499.555'), isNull);
    expect(parseRupees('0.001'), isNull);
  });

  test('empty, negative or not a number is refused', () {
    for (final bad in [
      '',
      ' ',
      '-5',
      '+5',
      'abc',
      '12a',
      '1.2.3',
      '1e3',
      '.',
      '₹',
      '4 99',
      '१२३',
    ]) {
      expect(parseRupees(bad), isNull, reason: bad);
    }
  });

  test('very large amounts are refused instead of overflowing', () {
    expect(parseRupees('1000000000'), isNull); // 100 crore rupees
    expect(parseRupees('99999999.99'), const Money(9999999999));
  });
}
