import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

Money r(int rupees, [int paise = 0]) => Money.rupees(rupees, paise);

void main() {
  group('settle', () {
    test('exact cash pays the bill, no change', () {
      final s = settle(r(500), [Payment(PaymentMode.cash, r(500))]);
      expect(s.isPaid, isTrue);
      expect(s.change, Money.zero);
      expect(s.due, Money.zero);
    });
    test('cash over the total gives change', () {
      final s = settle(r(499), [Payment(PaymentMode.cash, r(500))]);
      expect(s.isPaid, isTrue);
      expect(s.change, r(1));
      expect(s.cashKept, r(499));
    });
    test('short payment leaves a due amount and is not paid', () {
      final s = settle(r(500), [Payment(PaymentMode.upi, r(300))]);
      expect(s.isPaid, isFalse);
      expect(s.due, r(200));
      expect(s.change, Money.zero);
    });
    test('split cash and UPI', () {
      final s = settle(r(1000), [
        Payment(PaymentMode.upi, r(600)),
        Payment(PaymentMode.cash, r(500)),
      ]);
      expect(s.isPaid, isTrue);
      expect(s.cashKept, r(400));
      expect(s.change, r(100));
      expect(s.byMode[PaymentMode.upi], r(600));
      expect(s.byMode[PaymentMode.cash], r(400));
    });
    test('UPI or card above the total is refused (no change from a card)', () {
      expect(
        () => settle(r(500), [Payment(PaymentMode.card, r(501))]),
        throwsA(isA<NonCashOverpayment>()),
      );
      expect(
        () => settle(r(500), [
          Payment(PaymentMode.upi, r(300)),
          Payment(PaymentMode.card, r(300)),
        ]),
        throwsA(isA<NonCashOverpayment>()),
      );
    });
    test('change is never taken out of non-cash money', () {
      final s = settle(r(500), [
        Payment(PaymentMode.upi, r(500)),
        Payment(PaymentMode.cash, r(100)),
      ]);
      expect(s.cashKept, Money.zero);
      expect(s.change, r(100));
      expect(s.byMode.containsKey(PaymentMode.cash), isFalse);
    });
    test('no payments on a positive total is unpaid', () {
      final s = settle(r(500), const []);
      expect(s.isPaid, isFalse);
      expect(s.due, r(500));
    });
    test('zero total with no payments is paid', () {
      expect(settle(Money.zero, const []).isPaid, isTrue);
    });
    test('paise are exact', () {
      final s = settle(Money(49950), [Payment(PaymentMode.cash, Money(50000))]);
      expect(s.change, Money(50));
    });
    test('payment amount must be positive', () {
      expect(() => Payment(PaymentMode.cash, Money.zero), throwsArgumentError);
      expect(() => Payment(PaymentMode.cash, Money(-1)), throwsArgumentError);
    });
    test('negative total is refused', () {
      expect(() => settle(Money(-1), const []), throwsArgumentError);
    });
  });

  group('PaymentMode db values', () {
    test('round trip and unknown is null', () {
      for (final m in PaymentMode.values) {
        expect(PaymentMode.fromDb(m.dbValue), m);
      }
      expect(PaymentMode.fromDb('cheque'), isNull);
    });
  });
}
