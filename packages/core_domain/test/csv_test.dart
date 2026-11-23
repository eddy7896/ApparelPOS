import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('csvField', () {
    test('plain text is left alone', () {
      expect(csvField('Cotton Kurta'), 'Cotton Kurta');
      expect(csvField(''), '');
    });
    test('a comma, quote or line break quotes the field', () {
      expect(csvField('Ravi, Kumar'), '"Ravi, Kumar"');
      expect(csvField('say "hi"'), '"say ""hi"""');
      expect(csvField('a\nb'), '"a\nb"');
      expect(csvField('a\rb'), '"a\rb"');
    });
    test('a field a spreadsheet could run as a formula is defused', () {
      for (final c in ['=', '+', '-', '@']) {
        expect(csvField('${c}1+1'), "'${c}1+1");
      }
      expect(csvField('=A,B'), '"\'=A,B"');
    });
  });
  test('csvRow joins the fields', () {
    expect(csvRow(['a', 'b,c', '']), 'a,"b,c",');
  });
  test('plainRupees', () {
    expect(plainRupees(Money(149900)), '1499.00');
    expect(plainRupees(Money(5)), '0.05');
    expect(plainRupees(Money.zero), '0.00');
    expect(plainRupees(Money(-2050)), '-20.50');
    expect(plainRupees(Money(1000000000)), '10000000.00');
  });
}
