// The owner's daily report: which day, and how profit and the top styles are
// worked out (owner, 2026-11-21). A day is an India calendar day, midnight to
// midnight (ADR-0007 point 10). Integer paise only (E-MONEY-1).
//
// Definitions (assistant's, to be confirmed): net sales = sales minus refunds
// of that day; cost of goods = cost of garments sold that day minus the cost of
// garments returned that day and put back in stock (a damaged return keeps its
// cost, it is a loss); profit = net sales minus cost of goods.

import 'money.dart';
import 'shop_time.dart';

/// One India calendar day.
final class ShopDay implements Comparable<ShopDay> {
  /// Throws [ArgumentError] for a date that does not exist.
  ShopDay(this.year, this.month, this.day) {
    final check = DateTime.utc(year, month, day);
    if (month < 1 ||
        month > 12 ||
        day < 1 ||
        check.year != year ||
        check.month != month ||
        check.day != day) {
      throw ArgumentError('$year-$month-$day is not a date');
    }
  }

  /// The India day that [utc] falls in.
  factory ShopDay.fromUtc(DateTime utc) {
    final l = utc.toUtc().add(shopUtcOffset);
    return ShopDay(l.year, l.month, l.day);
  }

  final int year;
  final int month;
  final int day;

  /// India midnight at the start of this day, as a UTC instant.
  DateTime get startUtc =>
      DateTime.utc(year, month, day).subtract(shopUtcOffset);

  /// India midnight at the end of this day (the start of the next).
  DateTime get endUtc => next.startUtc;

  ShopDay get next {
    final d = DateTime.utc(year, month, day + 1);
    return ShopDay(d.year, d.month, d.day);
  }

  ShopDay get previous {
    final d = DateTime.utc(year, month, day - 1);
    return ShopDay(d.year, d.month, d.day);
  }

  /// True when [utc] is in this day: from its start, before the next start.
  bool contains(DateTime utc) {
    final t = utc.toUtc();
    return !t.isBefore(startUtc) && t.isBefore(endUtc);
  }

  /// `dd-mm-yyyy`.
  String format() =>
      '${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-$year';

  @override
  int compareTo(ShopDay other) {
    final a = DateTime.utc(year, month, day);
    final b = DateTime.utc(other.year, other.month, other.day);
    return a.compareTo(b);
  }

  @override
  bool operator ==(Object other) =>
      other is ShopDay &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => 'ShopDay($year-$month-$day)';
}

void _nonNegative(String name, Money m) {
  if (m.paise < 0) {
    throw ArgumentError.value(m, name, 'must not be negative');
  }
}

/// Sales minus refunds.
Money netSales({required Money sales, required Money refunds}) {
  _nonNegative('sales', sales);
  _nonNegative('refunds', refunds);
  return sales - refunds;
}

/// What the garments sold cost, less the cost of those returned and restocked.
Money costOfGoods({required Money sold, required Money restockedReturns}) {
  _nonNegative('sold', sold);
  _nonNegative('restockedReturns', restockedReturns);
  return sold - restockedReturns;
}

/// Net sales minus cost of goods; negative is a loss.
Money grossProfit({required Money netSales, required Money costOfGoods}) =>
    netSales - costOfGoods;

/// One style's sales for a period.
final class StyleSales {
  StyleSales({
    required this.name,
    required this.quantity,
    required this.value,
  }) {
    if (quantity < 0) {
      throw ArgumentError.value(quantity, 'quantity', 'must not be negative');
    }
    _nonNegative('value', value);
  }

  final String name;
  final int quantity;
  final Money value;
}

/// The best [n] styles: most garments first, then most money, then by name.
/// Does not change [rows]. [n] must be above zero.
List<StyleSales> topStyles(List<StyleSales> rows, {int n = 5}) {
  if (n < 1) {
    throw ArgumentError.value(n, 'n', 'must be above zero');
  }
  final sorted = [...rows]
    ..sort((a, b) {
      final q = b.quantity.compareTo(a.quantity);
      if (q != 0) {
        return q;
      }
      final v = b.value.compareTo(a.value);
      if (v != 0) {
        return v;
      }
      return a.name.compareTo(b.name);
    });
  return sorted.take(n).toList();
}
