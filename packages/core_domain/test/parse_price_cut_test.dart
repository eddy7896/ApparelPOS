import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('parsePriceCut', () {
    test('a percent', () {
      expect(parsePriceCut('10%')!.basisPoints, 1000);
      expect(parsePriceCut(' 10 % ')!.basisPoints, 1000);
      expect(parsePriceCut('12.5%')!.basisPoints, 1250);
      expect(parsePriceCut('0.25%')!.basisPoints, 25);
      expect(parsePriceCut('100%')!.basisPoints, 10000);
      expect(parsePriceCut('0%')!.isZero, isTrue);
    });
    test('an amount in rupees', () {
      expect(parsePriceCut('50')!.amountOff, Money(5000));
      expect(parsePriceCut('₹49.50')!.amountOff, Money(4950));
      expect(parsePriceCut('1,200')!.amountOff, Money(120000));
    });
    test('nothing sensible gives null', () {
      for (final bad in [
        '',
        '  ',
        '%',
        'abc',
        '10 percent',
        '-5',
        '-5%',
        '101%',
        '100.01%',
        '12.345%',
        '1.5.5%',
        '5%%',
        '12.345',
      ]) {
        expect(parsePriceCut(bad), isNull, reason: bad);
      }
    });
  });
}
