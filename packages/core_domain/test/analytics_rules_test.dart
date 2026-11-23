import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

DayTotal day(int d, int netRupees, {int bills = 1}) => DayTotal(
  day: ShopDay(2026, 11, d),
  sales: Money.rupees(netRupees),
  refunds: Money.zero,
  bills: bills,
);

void main() {
  group('AnalyticsRange and the days in it', () {
    test('a week is 7 days and a month is 30', () {
      expect(AnalyticsRange.week.days, 7);
      expect(AnalyticsRange.month.days, 30);
    });

    test(
      'daysEndingAt lists the days oldest first, ending on the last day',
      () {
        final days = daysEndingAt(ShopDay(2026, 11, 22), 7);
        expect(days.length, 7);
        expect(days.first, ShopDay(2026, 11, 16));
        expect(days.last, ShopDay(2026, 11, 22));
      },
    );

    test('it crosses a month end', () {
      final days = daysEndingAt(ShopDay(2026, 12, 2), 4);
      expect(days.first, ShopDay(2026, 11, 29));
      expect(days[1], ShopDay(2026, 11, 30));
      expect(days[2], ShopDay(2026, 12, 1));
    });
  });

  group('DayTotal', () {
    test('net is sales minus refunds', () {
      final d = DayTotal(
        day: ShopDay(2026, 11, 22),
        sales: Money.rupees(1000),
        refunds: Money.rupees(300),
        bills: 2,
      );
      expect(d.net, Money.rupees(700));
    });
  });

  group('changeBp (change against the period before)', () {
    test('up 10% is 1000 basis points', () {
      expect(changeBp(Money.rupees(110), Money.rupees(100)), 1000);
    });
    test('down 12.5% is -1250', () {
      expect(changeBp(Money.rupees(875), Money.rupees(1000)), -1250);
    });
    test('no change is 0', () {
      expect(changeBp(Money.rupees(5), Money.rupees(5)), 0);
    });
    test('nothing to compare with is null, not infinity', () {
      expect(changeBp(Money.rupees(5), Money.zero), isNull);
    });
    test('works on paise with no floating point drift', () {
      expect(changeBp(const Money(103), const Money(100)), 300);
    });
  });

  group('changeText', () {
    test('up, down, steady and nothing to compare', () {
      expect(changeText(340), 'Up 3.4%');
      expect(changeText(-1250), 'Down 12.5%');
      expect(changeText(0), 'No change');
      expect(changeText(null), 'No earlier sales to compare with');
    });
    test('under a tenth of a percent shows as 0.0%', () {
      expect(changeText(4), 'Up 0.0%');
    });
  });

  group('sellThroughPercent', () {
    test('rounds half up', () {
      expect(sellThroughPercent(bought: 24, sold: 17), 71); // 70.83
      expect(sellThroughPercent(bought: 8, sold: 1), 13); // 12.5 -> 13
    });
    test('nothing bought is 0', () {
      expect(sellThroughPercent(bought: 0, sold: 0), 0);
    });
    test('everything sold is 100', () {
      expect(sellThroughPercent(bought: 5, sold: 5), 100);
    });
  });

  group('isSlowMover (assistant\'s rule, to be confirmed by the owner)', () {
    final now = DateTime.utc(2026, 11, 22);
    DateTime ago(int days) => now.subtract(Duration(days: days));

    test('thresholds are 30 days in stock and under 25% sold', () {
      expect(slowMoverMinDays, 30);
      expect(slowMoverBelowPercent, 25);
    });
    test('old, barely sold and stock left is slow', () {
      expect(
        isSlowMover(bought: 12, sold: 2, firstBought: ago(45), now: now),
        isTrue,
      );
    });
    test('exactly 25% sold is not slow', () {
      expect(
        isSlowMover(bought: 20, sold: 5, firstBought: ago(45), now: now),
        isFalse,
      );
    });
    test('just under 25% is slow', () {
      expect(
        isSlowMover(bought: 20, sold: 4, firstBought: ago(45), now: now),
        isTrue,
      );
    });
    test('too new to judge: under 30 days', () {
      expect(
        isSlowMover(bought: 12, sold: 0, firstBought: ago(29), now: now),
        isFalse,
      );
      expect(
        isSlowMover(bought: 12, sold: 0, firstBought: ago(30), now: now),
        isTrue,
      );
    });
    test('nothing bought is never slow', () {
      expect(
        isSlowMover(bought: 0, sold: 0, firstBought: ago(90), now: now),
        isFalse,
      );
    });
    test('sold out is never slow', () {
      expect(
        isSlowMover(bought: 3, sold: 3, firstBought: ago(90), now: now),
        isFalse,
      );
    });
  });

  group('analyseTrend', () {
    test('an empty list gives no insight', () {
      final t = analyseTrend(const []);
      expect(t.bestDay, isNull);
      expect(t.direction, TrendDirection.steady);
    });

    test('finds the best and the weakest day', () {
      final t = analyseTrend([
        day(16, 100),
        day(17, 500),
        day(18, 50),
        day(19, 200),
      ]);
      expect(t.bestDay!.day, ShopDay(2026, 11, 17));
      expect(t.weakestDay!.day, ShopDay(2026, 11, 18));
    });

    test(
      'rising: the later half sells at least 5% more than the earlier half',
      () {
        final t = analyseTrend([
          day(16, 100),
          day(17, 100),
          day(18, 120),
          day(19, 120),
        ]);
        expect(t.direction, TrendDirection.rising);
      },
    );

    test('falling: at least 5% less', () {
      final t = analyseTrend([
        day(16, 120),
        day(17, 120),
        day(18, 100),
        day(19, 100),
      ]);
      expect(t.direction, TrendDirection.falling);
    });

    test('steady inside 5%', () {
      final t = analyseTrend([
        day(16, 100),
        day(17, 100),
        day(18, 104),
        day(19, 104),
      ]);
      expect(t.direction, TrendDirection.steady);
    });

    test(
      'with an odd number of days the middle day belongs to neither half',
      () {
        final t = analyseTrend([day(16, 100), day(17, 9999), day(18, 120)]);
        expect(t.direction, TrendDirection.rising);
      },
    );

    test('exactly 5% more is rising; just under is steady', () {
      expect(
        analyseTrend([day(16, 100), day(17, 105)]).direction,
        TrendDirection.rising,
      );
      expect(
        analyseTrend([day(16, 1000), day(17, 1049)]).direction,
        TrendDirection.steady,
      );
    });

    test('exactly 5% less is falling; just over is steady', () {
      expect(
        analyseTrend([day(16, 100), day(17, 95)]).direction,
        TrendDirection.falling,
      );
      expect(
        analyseTrend([day(16, 1000), day(17, 951)]).direction,
        TrendDirection.steady,
      );
    });

    test('on a tie the earlier day is the best and the weakest', () {
      final t = analyseTrend([day(16, 100), day(17, 100)]);
      expect(t.bestDay!.day, ShopDay(2026, 11, 16));
      expect(t.weakestDay!.day, ShopDay(2026, 11, 16));
    });

    test('one day alone is steady', () {
      expect(analyseTrend([day(16, 100)]).direction, TrendDirection.steady);
    });

    test('strongest and weakest weekday by average net sales', () {
      // 2026-11-21 is a Saturday, 2026-11-14 the Saturday before; 22 and 15 are Sundays
      final t = analyseTrend([
        day(14, 300),
        day(15, 100),
        day(21, 500),
        day(22, 140),
      ]);
      expect(t.strongestWeekday, DateTime.saturday);
      expect(t.strongestWeekdayAverage, Money.rupees(400));
      expect(t.weakestWeekday, DateTime.sunday);
      expect(t.weakestWeekdayAverage, Money.rupees(120));
    });

    test('weekdays with no data are not named', () {
      final t = analyseTrend([day(21, 500)]);
      expect(t.strongestWeekday, DateTime.saturday);
      expect(t.weakestWeekday, DateTime.saturday);
    });
  });

  group('peakHour', () {
    test('the hour with most bills, earliest on a tie', () {
      final hours = List<int>.filled(24, 0);
      hours[11] = 9;
      hours[15] = 12;
      hours[18] = 12;
      expect(peakHour(hours), 15);
    });
    test('no bills at all is null', () {
      expect(peakHour(List<int>.filled(24, 0)), isNull);
    });
  });

  group('hourText', () {
    test('12 hour clock with am and pm', () {
      expect(hourText(0), '12 am');
      expect(hourText(9), '9 am');
      expect(hourText(12), '12 pm');
      expect(hourText(18), '6 pm');
      expect(hourText(23), '11 pm');
    });
  });
}
