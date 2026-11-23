import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('cleanCustomerName', () {
    test('trims, and refuses blank or too long', () {
      expect(cleanCustomerName('  Ravi Kumar '), 'Ravi Kumar');
      expect(cleanCustomerName(null), isNull);
      expect(cleanCustomerName('   '), isNull);
      expect(cleanCustomerName('a' * 80), 'a' * 80);
      expect(cleanCustomerName('a' * 81), isNull);
    });
  });

  group('customerPhoneKey', () {
    test('digits are the key', () {
      expect(customerPhoneKey('9876543210'), '9876543210');
      expect(customerPhoneKey('98765-43210'), '9876543210');
      expect(customerPhoneKey(' 98765 43210 '), '9876543210');
    });
    test('a country code does not make another customer', () {
      expect(customerPhoneKey('+91 98765 43210'), '9876543210');
      expect(customerPhoneKey('919876543210'), '9876543210');
    });
    test('a short number keeps all its digits', () {
      expect(customerPhoneKey('1234567'), '1234567');
      expect(customerPhoneKey('123456789'), '123456789');
    });
    test('7 to 15 digits only, and only phone characters', () {
      expect(customerPhoneKey('123456'), isNull);
      expect(customerPhoneKey('1' * 15), '1' * 10);
      expect(customerPhoneKey('1' * 16), isNull);
      expect(customerPhoneKey('98765abc10'), isNull);
      expect(customerPhoneKey(''), isNull);
      expect(customerPhoneKey(null), isNull);
    });
  });

  group('returnOffset', () {
    test('takes the smaller of the refund and what is owed', () {
      expect(
        returnOffset(refundShare: Money(99900), owed: Money(150000)),
        Money(99900),
      );
      expect(
        returnOffset(refundShare: Money(99900), owed: Money(50100)),
        Money(50100),
      );
      expect(
        returnOffset(refundShare: Money(500), owed: Money(500)),
        Money(500),
      );
      expect(
        returnOffset(refundShare: Money(500), owed: Money.zero),
        Money.zero,
      );
      expect(
        returnOffset(refundShare: Money.zero, owed: Money(500)),
        Money.zero,
      );
    });
    test('a negative amount is refused', () {
      expect(
        () => returnOffset(refundShare: Money(-1), owed: Money(5)),
        throwsArgumentError,
      );
      expect(
        () => returnOffset(refundShare: Money(1), owed: Money(-5)),
        throwsArgumentError,
      );
    });
  });

  group('allocateDues', () {
    final bills = [
      DueBill('a', Money(30000)),
      DueBill('b', Money(20000)),
      DueBill('c', Money(10000)),
    ];
    List<(String, int)> plain(List<DueShare> s) => [
      for (final x in s) (x.billId, x.amount.paise),
    ];

    test('the oldest bill is settled first', () {
      expect(plain(allocateDues(bills, Money(30000))), [('a', 30000)]);
      expect(plain(allocateDues(bills, Money(40000))), [
        ('a', 30000),
        ('b', 10000),
      ]);
      expect(plain(allocateDues(bills, Money(60000))), [
        ('a', 30000),
        ('b', 20000),
        ('c', 10000),
      ]);
    });
    test('a part payment stays on the oldest bill', () {
      expect(plain(allocateDues(bills, Money(1))), [('a', 1)]);
    });
    test('bills with nothing outstanding are skipped', () {
      expect(
        plain(
          allocateDues([
            DueBill('x', Money.zero),
            DueBill('y', Money(500)),
          ], Money(500)),
        ),
        [('y', 500)],
      );
    });
    test('the shares add up to the amount', () {
      for (final p in [1, 29999, 30000, 30001, 59999, 60000]) {
        final s = allocateDues(bills, Money(p));
        expect(s.fold<int>(0, (a, b) => a + b.amount.paise), p);
      }
    });
    test('more than is owed, or nothing, is refused', () {
      expect(() => allocateDues(bills, Money(60001)), throwsArgumentError);
      expect(() => allocateDues(bills, Money.zero), throwsArgumentError);
      expect(() => allocateDues([], Money(1)), throwsArgumentError);
    });
  });

  test('totalOwed adds the bills', () {
    expect(
      totalOwed([DueBill('a', Money(100)), DueBill('b', Money(250))]),
      Money(350),
    );
    expect(totalOwed([]), Money.zero);
  });

  group('expectedCash with dues taken', () {
    test('dues taken in cash add to the drawer', () {
      expect(
        expectedCash(
          opening: Money(200000),
          cashSales: Money(100000),
          cashRefunds: Money(20000),
          cashDues: Money(50000),
        ),
        Money(330000),
      );
    });
    test('without dues it is as before', () {
      expect(
        expectedCash(
          opening: Money(200000),
          cashSales: Money(100000),
          cashRefunds: Money(20000),
        ),
        Money(280000),
      );
    });
    test('negative dues are refused', () {
      expect(
        () => expectedCash(
          opening: Money.zero,
          cashSales: Money.zero,
          cashRefunds: Money.zero,
          cashDues: Money(-1),
        ),
        throwsArgumentError,
      );
    });
  });
}
