// The owner's analytics: the ranges, per-day totals, the change against the
// period before, sell-through and slow movers, and a plain trend reading.
// Integer paise only (E-MONEY-1): changes are whole basis points.
//
// Definitions (assistant's, to be confirmed by the owner, 2026-11-22):
// - a style is a slow mover when its first purchase is at least 30 days old,
//   less than 25% of what was bought has sold, and some is still unsold;
// - the trend is rising or falling when the later half of the days sells at
//   least 5% more or less than the earlier half.

import 'money.dart';
import 'report_rules.dart';

/// How far back the analytics look.
enum AnalyticsRange {
  week(7),
  month(30);

  const AnalyticsRange(this.days);
  final int days;
}

/// [count] shop days, oldest first, ending on [last].
List<ShopDay> daysEndingAt(ShopDay last, int count) {
  final days = <ShopDay>[];
  var d = last;
  for (var i = 0; i < count; i++) {
    days.add(d);
    d = d.previous;
  }
  return days.reversed.toList();
}

/// What one shop day came to.
final class DayTotal {
  const DayTotal({
    required this.day,
    required this.sales,
    required this.refunds,
    required this.bills,
  });
  final ShopDay day;

  /// What the bills came to.
  final Money sales;

  /// What returns of that day came to.
  final Money refunds;
  final int bills;

  Money get net => sales - refunds;
}

/// The change from [previous] to [current] in basis points (100 = 1%), rounded
/// toward zero; null when there is nothing to compare with.
int? changeBp(Money current, Money previous) {
  if (previous.paise == 0) {
    return null;
  }
  return (current.paise - previous.paise) * 10000 ~/ previous.paise;
}

/// "Up 3.4%", "Down 12.5%", "No change", or a note when there is nothing to
/// compare with.
String changeText(int? bp) {
  if (bp == null) {
    return 'No earlier sales to compare with';
  }
  if (bp == 0) {
    return 'No change';
  }
  final abs = bp.abs();
  final text = '${abs ~/ 100}.${((abs % 100) ~/ 10)}%';
  return bp > 0 ? 'Up $text' : 'Down $text';
}

/// The percent of what was bought that has sold, rounded half up; 0 when
/// nothing was bought.
int sellThroughPercent({required int bought, required int sold}) {
  if (bought <= 0) {
    return 0;
  }
  return (sold * 100 * 2 + bought) ~/ (bought * 2);
}

const int slowMoverMinDays = 30;
const int slowMoverBelowPercent = 25;

/// True for a style that has been in the shop a while, has sold little, and
/// still has stock.
bool isSlowMover({
  required int bought,
  required int sold,
  required DateTime firstBought,
  required DateTime now,
}) {
  if (bought <= 0) {
    return false;
  }
  if (now.difference(firstBought).inDays < slowMoverMinDays) {
    return false;
  }
  return sold * 100 < slowMoverBelowPercent * bought;
}

enum TrendDirection { rising, falling, steady }

/// What the days say, in plain terms.
final class TrendInsights {
  const TrendInsights({
    required this.direction,
    this.bestDay,
    this.weakestDay,
    this.strongestWeekday,
    this.strongestWeekdayAverage,
    this.weakestWeekday,
    this.weakestWeekdayAverage,
  });
  final TrendDirection direction;
  final DayTotal? bestDay;
  final DayTotal? weakestDay;

  /// `DateTime.monday` to `DateTime.sunday`.
  final int? strongestWeekday;
  final Money? strongestWeekdayAverage;
  final int? weakestWeekday;
  final Money? weakestWeekdayAverage;
}

/// Reads [days] (oldest first): the best and weakest day, which weekday sells
/// most and least on average, and whether sales are rising or falling.
TrendInsights analyseTrend(List<DayTotal> days) {
  if (days.isEmpty) {
    return const TrendInsights(direction: TrendDirection.steady);
  }
  var best = days.first;
  var weakest = days.first;
  for (final d in days) {
    if (d.net > best.net) {
      best = d;
    }
    if (d.net < weakest.net) {
      weakest = d;
    }
  }

  final half = days.length ~/ 2;
  var direction = TrendDirection.steady;
  if (half > 0) {
    var early = 0;
    var late = 0;
    for (var i = 0; i < half; i++) {
      early += days[i].net.paise;
      late += days[days.length - 1 - i].net.paise;
    }
    if (early > 0) {
      if (late * 100 >= early * 105) {
        direction = TrendDirection.rising;
      } else if (late * 100 <= early * 95) {
        direction = TrendDirection.falling;
      }
    }
  }

  final totals = <int, int>{};
  final counts = <int, int>{};
  for (final d in days) {
    final wd = DateTime.utc(d.day.year, d.day.month, d.day.day).weekday;
    totals[wd] = (totals[wd] ?? 0) + d.net.paise;
    counts[wd] = (counts[wd] ?? 0) + 1;
  }
  int? strongest;
  int? weakestWd;
  int strongestAvg = 0;
  int weakestAvg = 0;
  for (final wd in totals.keys.toList()..sort()) {
    final avg = totals[wd]! ~/ counts[wd]!;
    if (strongest == null || avg > strongestAvg) {
      strongest = wd;
      strongestAvg = avg;
    }
    if (weakestWd == null || avg < weakestAvg) {
      weakestWd = wd;
      weakestAvg = avg;
    }
  }
  return TrendInsights(
    direction: direction,
    bestDay: best,
    weakestDay: weakest,
    strongestWeekday: strongest,
    strongestWeekdayAverage: strongest == null ? null : Money(strongestAvg),
    weakestWeekday: weakestWd,
    weakestWeekdayAverage: weakestWd == null ? null : Money(weakestAvg),
  );
}

/// The hour (0 to 23) with the most bills, the earliest on a tie; null when
/// there are none.
int? peakHour(List<int> billsByHour) {
  int? peak;
  var most = 0;
  for (var h = 0; h < billsByHour.length; h++) {
    if (billsByHour[h] > most) {
      most = billsByHour[h];
      peak = h;
    }
  }
  return peak;
}

/// "9 am", "12 pm", "6 pm".
String hourText(int hour) {
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$h12 ${hour < 12 ? 'am' : 'pm'}';
}
