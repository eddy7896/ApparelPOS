import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('CreditNoteCode', () {
    test('is 12 digits: 9900, counter, serial, check digit', () {
      final code = CreditNoteCode(counterNo: 1, serial: 123).value;
      expect(code.length, 12);
      expect(code.startsWith('9900'), isTrue);
      expect(code.substring(4, 6), '01');
      expect(code.substring(6, 11), '00123');
      expect(int.parse(code[11]), luhnCheckDigit(code.substring(0, 11)));
    });
    test('parses what it makes', () {
      final c = CreditNoteCode.tryParse(
        CreditNoteCode(counterNo: 12, serial: 99999).value,
      )!;
      expect(c.counterNo, 12);
      expect(c.serial, 99999);
    });
    test('a garment barcode is never a credit note, and the reverse', () {
      final garment = const Barcode(
        year: 26,
        month: 11,
        lot: 0,
        serial: 5,
      ).value;
      expect(CreditNoteCode.tryParse(garment), isNull);
      expect(
        Barcode.tryParse(CreditNoteCode(counterNo: 1, serial: 1).value),
        isNull,
      );
    });
    test('a wrong check digit, wrong length or letters is not a code', () {
      final good = CreditNoteCode(counterNo: 1, serial: 1).value;
      final bad = '${good.substring(0, 11)}${(int.parse(good[11]) + 1) % 10}';
      for (final t in [
        bad,
        good.substring(1),
        '${good}0',
        '99001000001A',
        '',
      ]) {
        expect(CreditNoteCode.tryParse(t), isNull, reason: t);
      }
    });
    test('counter 1 to 99, serial 1 to 99999', () {
      expect(
        () => CreditNoteCode(counterNo: 0, serial: 1),
        throwsArgumentError,
      );
      expect(
        () => CreditNoteCode(counterNo: 100, serial: 1),
        throwsArgumentError,
      );
      expect(
        () => CreditNoteCode(counterNo: 1, serial: 0),
        throwsArgumentError,
      );
      expect(
        () => CreditNoteCode(counterNo: 1, serial: 100000),
        throwsArgumentError,
      );
    });
    test('different notes have different codes', () {
      final a = CreditNoteCode(counterNo: 1, serial: 1).value;
      expect(
        {
          a,
          CreditNoteCode(counterNo: 2, serial: 1).value,
          CreditNoteCode(counterNo: 1, serial: 2).value,
        }.length,
        3,
      );
    });
  });

  group('credit note expiry (180 shop days)', () {
    // issued 2026-11-20 12:00 IST
    final issued = DateTime.utc(2026, 11, 20, 6, 30);
    test('the last valid day is 180 days after issue, local', () {
      expect(creditNoteLastDay(issued), DateTime.utc(2027, 5, 19));
    });
    test('valid through the end of that day, India time', () {
      // 2027-05-19 23:59 IST = 18:29 UTC
      expect(
        isCreditNoteValid(issued, DateTime.utc(2027, 5, 19, 18, 29)),
        isTrue,
      );
      expect(
        isCreditNoteValid(issued, DateTime.utc(2027, 5, 19, 18, 30)),
        isFalse,
      );
    });
    test('valid straight after issue', () {
      expect(isCreditNoteValid(issued, issued), isTrue);
    });
    test('the validity can be changed', () {
      expect(
        creditNoteLastDay(issued, validDays: 90),
        DateTime.utc(2027, 2, 18),
      );
    });
    test('a negative validity is refused', () {
      expect(
        () => creditNoteLastDay(issued, validDays: -1),
        throwsArgumentError,
      );
    });
  });

  group('using a credit note', () {
    test('uses the smaller of the balance and what is due', () {
      final u = useCredit(balance: Money(50000), due: Money(30000));
      expect(u.used, Money(30000));
      expect(u.left, Money(20000));
    });
    test('a bigger bill uses the whole note', () {
      final u = useCredit(balance: Money(50000), due: Money(80000));
      expect(u.used, Money(50000));
      expect(u.left, Money.zero);
    });
    test('nothing due uses nothing', () {
      final u = useCredit(balance: Money(50000), due: Money.zero);
      expect(u.used, Money.zero);
      expect(u.left, Money(50000));
    });
    test('negative amounts are refused', () {
      expect(
        () => useCredit(balance: Money(-1), due: Money(1)),
        throwsArgumentError,
      );
      expect(
        () => useCredit(balance: Money(1), due: Money(-1)),
        throwsArgumentError,
      );
    });
  });

  group('a credit note as a payment mode', () {
    test('counts as non-cash: no change, cannot exceed the total', () {
      final s = settle(Money(30000), [
        Payment(PaymentMode.creditNote, Money(30000)),
      ]);
      expect(s.isPaid, isTrue);
      expect(s.byMode[PaymentMode.creditNote], Money(30000));
      expect(
        () => settle(Money(30000), [
          Payment(PaymentMode.creditNote, Money(30001)),
        ]),
        throwsA(isA<NonCashOverpayment>()),
      );
    });
    test('mixes with cash', () {
      final s = settle(Money(80000), [
        Payment(PaymentMode.creditNote, Money(50000)),
        Payment(PaymentMode.cash, Money(30000)),
      ]);
      expect(s.isPaid, isTrue);
      expect(s.change, Money.zero);
    });
  });
}
