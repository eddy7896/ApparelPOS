import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Denomination', () {
    test('lists the notes and coins the owner chose, biggest first', () {
      expect(
        [for (final d in Denomination.values) d.value.paise ~/ 100],
        [500, 200, 100, 50, 20, 10, 10, 5, 2, 1],
      );
    });
    test('a 10 rupee note and a 10 rupee coin are different entries', () {
      expect(Denomination.note10, isNot(Denomination.coin10));
      expect(Denomination.note10.isNote, isTrue);
      expect(Denomination.coin10.isNote, isFalse);
    });
    test('db values are unique and round trip', () {
      final values = {for (final d in Denomination.values) d.dbValue};
      expect(values.length, Denomination.values.length);
      for (final d in Denomination.values) {
        expect(Denomination.fromDb(d.dbValue), d);
      }
      expect(Denomination.fromDb('note2000'), isNull);
    });
  });

  group('countCash', () {
    test('adds up every count times its value', () {
      final total = countCash({
        Denomination.note500: 2,
        Denomination.note100: 3,
        Denomination.coin10: 4,
        Denomination.coin1: 7,
      });
      expect(total, Money.rupees(1000 + 300 + 40 + 7));
    });
    test('nothing counted is zero', () {
      expect(countCash(const {}), Money.zero);
      expect(countCash({Denomination.note500: 0}), Money.zero);
    });
    test('a negative count is refused', () {
      expect(() => countCash({Denomination.note500: -1}), throwsArgumentError);
    });
    test('an absurd count is refused (typing mistake)', () {
      expect(
        () => countCash({Denomination.note500: maxCountPerDenomination + 1}),
        throwsArgumentError,
      );
      expect(
        countCash({Denomination.note500: maxCountPerDenomination}),
        Money.rupees(500 * maxCountPerDenomination),
      );
    });
  });

  group('expectedCash', () {
    test('opening cash plus cash kept from sales minus cash refunds', () {
      expect(
        expectedCash(
          opening: Money.rupees(2000),
          cashSales: Money.rupees(15000),
          cashRefunds: Money.rupees(499),
        ),
        Money.rupees(16501),
      );
    });
    test('a quiet shift expects exactly the opening cash', () {
      expect(
        expectedCash(
          opening: Money.rupees(2000),
          cashSales: Money.zero,
          cashRefunds: Money.zero,
        ),
        Money.rupees(2000),
      );
    });
    test('amounts must not be negative', () {
      for (final bad in [
        () => expectedCash(
          opening: Money(-1),
          cashSales: Money.zero,
          cashRefunds: Money.zero,
        ),
        () => expectedCash(
          opening: Money.zero,
          cashSales: Money(-1),
          cashRefunds: Money.zero,
        ),
        () => expectedCash(
          opening: Money.zero,
          cashSales: Money.zero,
          cashRefunds: Money(-1),
        ),
      ]) {
        expect(bad, throwsArgumentError);
      }
    });
  });

  group('CashVariance', () {
    test('exact', () {
      final v = CashVariance(
        expected: Money.rupees(500),
        counted: Money.rupees(500),
      );
      expect(v.difference, Money.zero);
      expect(v.kind, VarianceKind.exact);
    });
    test('short: counted less than expected, difference is negative', () {
      final v = CashVariance(
        expected: Money.rupees(500),
        counted: Money(49900),
      );
      expect(v.difference, Money(-100));
      expect(v.kind, VarianceKind.short);
    });
    test('over: counted more than expected, difference is positive', () {
      final v = CashVariance(
        expected: Money.rupees(500),
        counted: Money(50001),
      );
      expect(v.difference, Money(1));
      expect(v.kind, VarianceKind.over);
    });
    test(
      'any difference counts, even one paisa (no tolerance, owner choice)',
      () {
        expect(
          CashVariance(expected: Money(100), counted: Money(101)).kind,
          VarianceKind.over,
        );
      },
    );
    test('the counted amount must not be negative', () {
      expect(
        () => CashVariance(expected: Money.zero, counted: Money(-1)),
        throwsArgumentError,
      );
    });
  });

  group('the blind close shows no expected amount (E-SHIFT-1)', () {
    test('what the cashier gets back has no expected or variance field', () {
      // The cashier-facing result type carries only identifiers and times.
      const closed = ShiftCloseReceipt(shiftId: 's1');
      expect(closed.shiftId, 's1');
      expect(closed.toString(), isNot(contains('expected')));
      expect(closed.toString(), isNot(contains('variance')));
    });
    test('viewing a variance needs the daybook permission', () {
      expect(can(Role.cashier, Permission.viewDaybook), isFalse);
      expect(can(Role.owner, Permission.viewDaybook), isTrue);
      expect(can(Role.cashier, Permission.closeShift), isTrue);
    });
  });
}
