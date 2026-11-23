import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('returnTiming (7 shop-calendar days, India time)', () {
    // 2026-11-10 12:00 IST = 06:30 UTC
    final sold = DateTime.utc(2026, 11, 10, 6, 30);
    test('same day is inside the window', () {
      expect(
        returnTiming(sold, DateTime.utc(2026, 11, 10, 9)),
        ReturnTiming.withinWindow,
      );
    });
    test('day 7 is inside, even late at night', () {
      // 2026-11-17 23:59 IST = 18:29 UTC
      expect(
        returnTiming(sold, DateTime.utc(2026, 11, 17, 18, 29)),
        ReturnTiming.withinWindow,
      );
    });
    test('day 8 needs approval from the first minute (India midnight)', () {
      // 2026-11-18 00:00 IST = 2026-11-17 18:30 UTC
      expect(
        returnTiming(sold, DateTime.utc(2026, 11, 17, 18, 30)),
        ReturnTiming.needsApproval,
      );
    });
    test('the sale late at night counts as that India day', () {
      // sold 2026-11-10 23:50 IST = 18:20 UTC; day 7 ends 2026-11-17 23:59 IST
      final late = DateTime.utc(2026, 11, 10, 18, 20);
      expect(
        returnTiming(late, DateTime.utc(2026, 11, 17, 18, 29)),
        ReturnTiming.withinWindow,
      );
      expect(
        returnTiming(late, DateTime.utc(2026, 11, 17, 18, 30)),
        ReturnTiming.needsApproval,
      );
    });
    test('the window can be changed (owner setting later)', () {
      expect(
        returnTiming(sold, DateTime.utc(2026, 11, 25, 6), windowDays: 15),
        ReturnTiming.withinWindow,
      );
      expect(
        returnTiming(sold, DateTime.utc(2026, 11, 26, 6), windowDays: 15),
        ReturnTiming.needsApproval,
      );
    });
    test('a return before the sale is a mistake', () {
      expect(
        () => returnTiming(sold, sold.subtract(const Duration(days: 1))),
        throwsArgumentError,
      );
    });
    test('a negative window is refused', () {
      expect(
        () => returnTiming(sold, sold, windowDays: -1),
        throwsArgumentError,
      );
    });
  });

  group('refundTotal', () {
    test('is exactly the sum of the net prices paid', () {
      expect(refundTotal([Money(44910), Money(99900)]), Money(144810));
    });
    test('nothing returned refunds nothing', () {
      expect(refundTotal(const []), Money.zero);
    });
    test('a negative price is refused', () {
      expect(() => refundTotal([Money(-1)]), throwsArgumentError);
    });
  });

  group('RefundMode', () {
    test('db values round trip; unknown is null', () {
      for (final m in RefundMode.values) {
        expect(RefundMode.fromDb(m.dbValue), m);
      }
      expect(RefundMode.fromDb('cheque'), isNull);
    });
  });

  group('permissions for returns', () {
    test('a cashier may take a return; nobody anonymous', () {
      expect(can(Role.cashier, Permission.takeReturn), isTrue);
      expect(can(null, Permission.takeReturn), isFalse);
    });
  });
}
