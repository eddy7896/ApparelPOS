import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  final today = ShopDay(2026, 11, 23);
  PriceCut pct(int bp) => PriceCut.percentBp(bp);
  PriceCut amt(int paise) => PriceCut.amount(Money(paise));

  MarkdownProblem? problem(PriceCut cut, {ShopDay? last, int lowest = 49900}) =>
      markdownProblem(
        cut: cut,
        lastDay: last ?? shopDayPlus(today, 7),
        today: today,
        lowestMrp: Money(lowest),
      );

  group('markdownProblem', () {
    test('a normal percent or amount with a later end date is fine', () {
      expect(problem(pct(2000)), isNull);
      expect(problem(amt(10000)), isNull);
    });
    test('zero takes nothing off', () {
      expect(problem(pct(0)), MarkdownProblem.nothingOff);
      expect(problem(amt(0)), MarkdownProblem.nothingOff);
    });
    test('100% is refused, 99.99% is allowed', () {
      expect(problem(pct(10000)), MarkdownProblem.percentTooBig);
      expect(problem(pct(9999)), isNull);
    });
    test('an amount must be below the cheapest price', () {
      expect(problem(amt(49900)), MarkdownProblem.amountTooBig);
      expect(problem(amt(49899)), isNull);
      expect(problem(amt(60000)), MarkdownProblem.amountTooBig);
    });
    test('the last day may be today but not yesterday', () {
      expect(problem(pct(1000), last: today), isNull);
      expect(
        problem(pct(1000), last: today.previous),
        MarkdownProblem.endsInPast,
      );
    });
    test('the last day may be 366 days away but not 367', () {
      expect(problem(pct(1000), last: shopDayPlus(today, 366)), isNull);
      expect(
        problem(pct(1000), last: shopDayPlus(today, 367)),
        MarkdownProblem.endsTooFar,
      );
    });
    test('the first problem wins: nothing off before a past date', () {
      expect(problem(pct(0), last: today.previous), MarkdownProblem.nothingOff);
    });
    test('every problem has words', () {
      for (final p in MarkdownProblem.values) {
        expect(markdownProblemText(p), isNotEmpty);
      }
    });
  });

  group('effectiveMarkdown', () {
    test('no cut and a zero cut are nothing', () {
      expect(effectiveMarkdown(null, Money(49900)), isNull);
      expect(effectiveMarkdown(pct(0), Money(49900)), isNull);
    });
    test('a percent always applies', () {
      expect(effectiveMarkdown(pct(2000), Money(100)), isNotNull);
    });
    test('an amount applies only while it is below the garment price', () {
      expect(effectiveMarkdown(amt(10000), Money(49900)), isNotNull);
      expect(effectiveMarkdown(amt(49899), Money(49900)), isNotNull);
      expect(effectiveMarkdown(amt(49900), Money(49900)), isNull);
      expect(effectiveMarkdown(amt(10000), Money(9000)), isNull);
    });
  });

  group('markdownActive', () {
    final endsBefore = DateTime.utc(2026, 11, 29, 18, 30); // end of 29 Nov IST
    test('applies right up to the end of its last day', () {
      expect(
        markdownActive(endsBefore, DateTime.utc(2026, 11, 29, 18, 29)),
        isTrue,
      );
    });
    test('stops at India midnight', () {
      expect(markdownActive(endsBefore, endsBefore), isFalse);
      expect(markdownActive(endsBefore, DateTime.utc(2026, 11, 30)), isFalse);
    });
    test('markdownEndsBefore is the India midnight after the last day', () {
      expect(markdownEndsBefore(ShopDay(2026, 11, 29)), endsBefore);
    });
  });

  group('markdownLabel', () {
    test('percentages', () {
      expect(markdownLabel(pct(2000)), '20%');
      expect(markdownLabel(pct(1250)), '12.5%');
      expect(markdownLabel(pct(1205)), '12.05%');
      expect(markdownLabel(pct(50)), '0.5%');
    });
    test('amounts', () {
      expect(markdownLabel(amt(10000)), '₹100');
      expect(markdownLabel(amt(4950)), '₹49.50');
      expect(markdownLabel(amt(5)), '₹0.05');
    });
  });

  group('dates', () {
    test('parseShopDay reads day/month/year', () {
      expect(parseShopDay('25/12/2026')?.compareTo(ShopDay(2026, 12, 25)), 0);
      expect(parseShopDay(' 5 / 1 / 2027 ')?.compareTo(ShopDay(2027, 1, 5)), 0);
    });
    test('parseShopDay refuses the rest', () {
      for (final t in [
        '',
        '2026-12-25',
        '25/12/26',
        '31/02/2026',
        '00/12/2026',
        '25/13/2026',
        'abc',
        '25/12/2026/1',
      ]) {
        expect(parseShopDay(t), isNull, reason: t);
      }
    });
    test('shopDayText pads and round trips', () {
      expect(shopDayText(ShopDay(2026, 1, 5)), '05/01/2026');
      expect(parseShopDay(shopDayText(today))?.compareTo(today), 0);
    });
    test('shopDayPlus crosses months and years', () {
      expect(shopDayText(shopDayPlus(ShopDay(2026, 12, 30), 3)), '02/01/2027');
      expect(shopDayText(shopDayPlus(today, 0)), '23/11/2026');
    });
    test('endOfMonth handles 30, 31 and leap February', () {
      expect(shopDayText(endOfMonth(ShopDay(2026, 11, 3))), '30/11/2026');
      expect(shopDayText(endOfMonth(ShopDay(2026, 12, 31))), '31/12/2026');
      expect(shopDayText(endOfMonth(ShopDay(2028, 2, 1))), '29/02/2028');
      expect(shopDayText(endOfMonth(ShopDay(2026, 2, 1))), '28/02/2026');
    });
  });
}
