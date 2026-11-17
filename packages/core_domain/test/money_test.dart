// E-MONEY-1: money is integer paise; rounding is exact (half up, away from zero).
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('construction and arithmetic', () {
    test('holds integer paise', () {
      expect(const Money(12550).paise, 12550);
      expect(Money.zero.paise, 0);
    });

    test('rupees constructor converts to paise', () {
      expect(Money.rupees(499), const Money(49900));
      expect(Money.rupees(499, 50), const Money(49950));
    });

    test('add, subtract, negate', () {
      expect(const Money(100) + const Money(250), const Money(350));
      expect(const Money(100) - const Money(250), const Money(-150));
      expect(-const Money(100), const Money(-100));
    });

    test('times a whole quantity', () {
      expect(const Money(49900).times(3), const Money(149700));
      expect(const Money(49900).times(0), Money.zero);
    });

    test('compares and sorts', () {
      expect(const Money(1) < const Money(2), isTrue);
      expect(const Money(2) >= const Money(2), isTrue);
      expect(const Money(3).compareTo(const Money(2)), greaterThan(0));
    });

    test('equal values are equal and hash the same', () {
      expect(const Money(5), const Money(5));
      expect(const Money(5).hashCode, const Money(5).hashCode);
      expect(const Money(5), isNot(const Money(6)));
    });
  });

  group('percentBp rounds half up, away from zero', () {
    test('exact results are not changed', () {
      expect(const Money(10000).percentBp(1000), const Money(1000)); // 10%
      expect(const Money(49900).percentBp(0), Money.zero);
      expect(const Money(49900).percentBp(10000), const Money(49900)); // 100%
    });

    test('below half rounds down', () {
      // 5% of 1 paisa x ... 1 paisa * 4.99% = 0.0499 paisa -> 0
      expect(const Money(1).percentBp(499), Money.zero);
      // 12.4 paise -> 12
      expect(const Money(248).percentBp(500), const Money(12));
    });

    test('exactly half rounds up', () {
      // 250 paise * 5% = 12.5 -> 13
      expect(const Money(250).percentBp(500), const Money(13));
      // 10 paise * 5% = 0.5 -> 1
      expect(const Money(10).percentBp(500), const Money(1));
    });

    test('above half rounds up', () {
      // 252 paise * 5% = 12.6 -> 13
      expect(const Money(252).percentBp(500), const Money(13));
    });

    test('negative amounts mirror positive ones', () {
      expect(const Money(-250).percentBp(500), const Money(-13));
      expect(const Money(-248).percentBp(500), const Money(-12));
      expect(const Money(-10).percentBp(500), const Money(-1));
    });

    test('a return reverses a sale exactly', () {
      for (final p in [1, 7, 99, 250, 12345, 49900, 99999]) {
        for (final bp in [1, 500, 1200, 2500, 9999]) {
          expect(Money(-p).percentBp(bp), -Money(p).percentBp(bp));
        }
      }
    });

    test('rejects negative basis points', () {
      expect(() => const Money(100).percentBp(-1), throwsArgumentError);
    });
  });

  test('money.dart contains no floating-point type (E-MONEY-1)', () {
    final src = File('lib/src/money.dart').readAsStringSync();
    final code = src
        .split('\n')
        .where((l) => !l.trimLeft().startsWith('//'))
        .join('\n');
    expect(RegExp(r'\b(double|num)\b').hasMatch(code), isFalse);
    expect(RegExp(r'(?<![~/])/(?![/=*])').hasMatch(code), isFalse,
        reason: 'use ~/ for integer division');
  });
}
