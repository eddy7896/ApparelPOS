// P1-3: price = MRP, then markdown (percent or amount). A marked-down garment
// takes no cashier discount (owner, 2026-11-18). Integer paise throughout.
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('PriceCut construction', () {
    test('percent is 0 to 100 percent in basis points', () {
      expect(() => PriceCut.percentBp(0), returnsNormally);
      expect(() => PriceCut.percentBp(10000), returnsNormally);
      expect(() => PriceCut.percentBp(-1), throwsArgumentError);
      expect(() => PriceCut.percentBp(10001), throwsArgumentError);
    });
    test('amount must not be negative', () {
      expect(() => PriceCut.amount(const Money(0)), returnsNormally);
      expect(() => PriceCut.amount(const Money(-1)), throwsArgumentError);
    });
  });

  group('PriceCut.of (how much is taken off)', () {
    test('percent off MRP', () {
      expect(
        PriceCut.percentBp(2000).of(const Money(99900)),
        const Money(19980),
      );
      expect(PriceCut.percentBp(0).of(const Money(99900)), Money.zero);
      expect(
        PriceCut.percentBp(10000).of(const Money(99900)),
        const Money(99900),
      );
    });
    test('percent cut rounds half up (cut of 12.5 paise is 13)', () {
      expect(PriceCut.percentBp(500).of(const Money(250)), const Money(13));
    });
    test('amount off', () {
      expect(
        PriceCut.amount(const Money(10000)).of(const Money(99900)),
        const Money(10000),
      );
    });
    test('an amount larger than the price is refused', () {
      expect(
        () => PriceCut.amount(const Money(100)).of(const Money(99)),
        throwsA(isA<PriceCutTooLarge>()),
      );
    });
    test('an amount equal to the price makes it free, not negative', () {
      expect(
        PriceCut.amount(const Money(99)).of(const Money(99)),
        const Money(99),
      );
    });
  });

  group('priceLine', () {
    test('no markdown, no discount: price is the MRP', () {
      final p = priceLine(mrp: const Money(99900));
      expect(p.finalPrice, const Money(99900));
      expect(p.markdownAmount, Money.zero);
      expect(p.discountAmount, Money.zero);
      expect(p.markedDown, isFalse);
    });

    test('percent markdown', () {
      final p = priceLine(
        mrp: const Money(99900),
        markdown: PriceCut.percentBp(2000),
      );
      expect(p.priceAfterMarkdown, const Money(79920));
      expect(p.finalPrice, const Money(79920));
      expect(p.markdownAmount, const Money(19980));
      expect(p.markedDown, isTrue);
    });

    test('amount markdown', () {
      final p = priceLine(
        mrp: const Money(99900),
        markdown: PriceCut.amount(Money.rupees(100)),
      );
      expect(p.finalPrice, const Money(89900));
    });

    test('a zero markdown does not count as marked down', () {
      final p = priceLine(
        mrp: const Money(99900),
        markdown: PriceCut.percentBp(0),
      );
      expect(p.markedDown, isFalse);
      final q = priceLine(
        mrp: const Money(99900),
        markdown: PriceCut.amount(Money.zero),
        cashierDiscount: PriceCut.percentBp(1000),
      );
      expect(q.finalPrice, const Money(89910));
    });

    test('cashier discount applies to a full-price garment', () {
      final p = priceLine(
        mrp: const Money(99900),
        cashierDiscount: PriceCut.percentBp(1000),
      );
      expect(p.discountAmount, const Money(9990));
      expect(p.finalPrice, const Money(89910));
    });

    test('cashier discount on a marked-down garment is refused', () {
      expect(
        () => priceLine(
          mrp: const Money(99900),
          markdown: PriceCut.percentBp(2000),
          cashierDiscount: PriceCut.percentBp(500),
        ),
        throwsA(isA<DiscountNotAllowed>()),
      );
      expect(
        () => priceLine(
          mrp: const Money(99900),
          markdown: PriceCut.amount(const Money(1)),
          cashierDiscount: PriceCut.amount(const Money(1)),
        ),
        throwsA(isA<DiscountNotAllowed>()),
      );
    });

    test('price never goes below zero and never above the MRP', () {
      for (final mrp in [0, 1, 99, 12345, 99999]) {
        for (final bp in [0, 1, 500, 5000, 9999, 10000]) {
          final p = priceLine(
            mrp: Money(mrp),
            markdown: PriceCut.percentBp(bp),
          );
          expect(p.finalPrice.paise, inInclusiveRange(0, mrp));
          expect(p.finalPrice + p.markdownAmount, Money(mrp));
        }
      }
    });

    test('negative MRP is refused', () {
      expect(() => priceLine(mrp: const Money(-1)), throwsArgumentError);
    });
  });
}
