// Shifts and the blind cash close (SSOT 17). The cashier opens a shift with the
// cash in the drawer and ends it with a count by notes and coins; the count is
// blind: the cashier is never shown the expected amount or the variance. The
// variance goes to the owner. Expected cash is opening cash plus cash kept from
// sales minus cash refunds; UPI, card and credit note money is not in the
// drawer (owner, 2026-11-21). Integer paise only (E-MONEY-1).

import 'money.dart';

/// The notes and coins the count screen lists (owner, 2026-11-21), biggest
/// first. A 10 rupee note and a 10 rupee coin are separate entries.
enum Denomination {
  note500('note500', 50000, true),
  note200('note200', 20000, true),
  note100('note100', 10000, true),
  note50('note50', 5000, true),
  note20('note20', 2000, true),
  note10('note10', 1000, true),
  coin10('coin10', 1000, false),
  coin5('coin5', 500, false),
  coin2('coin2', 200, false),
  coin1('coin1', 100, false);

  const Denomination(this.dbValue, this._paise, this.isNote);

  /// The text stored in the database.
  final String dbValue;
  final int _paise;
  final bool isNote;

  Money get value => Money(_paise);

  static Denomination? fromDb(String value) {
    for (final d in values) {
      if (d.dbValue == value) {
        return d;
      }
    }
    return null;
  }
}

/// A count above this for one denomination is taken as a typing mistake.
const int maxCountPerDenomination = 100000;

/// The cash in [counts]: each count times its value. A negative count, or one
/// above [maxCountPerDenomination], is refused.
Money countCash(Map<Denomination, int> counts) {
  var total = Money.zero;
  for (final e in counts.entries) {
    final n = e.value;
    if (n < 0 || n > maxCountPerDenomination) {
      throw ArgumentError.value(
        n,
        e.key.dbValue,
        'must be 0 to $maxCountPerDenomination',
      );
    }
    total += e.key.value.times(n);
  }
  return total;
}

/// What should be in the drawer: [opening] cash, plus [cashSales] kept (after
/// change), plus [cashDues] taken from customers paying what they owe, minus
/// [cashRefunds]. No amount may be negative.
Money expectedCash({
  required Money opening,
  required Money cashSales,
  required Money cashRefunds,
  Money cashDues = Money.zero,
}) {
  for (final (name, m) in [
    ('opening', opening),
    ('cashSales', cashSales),
    ('cashRefunds', cashRefunds),
    ('cashDues', cashDues),
  ]) {
    if (m.paise < 0) {
      throw ArgumentError.value(m, name, 'must not be negative');
    }
  }
  return opening + cashSales + cashDues - cashRefunds;
}

enum VarianceKind { exact, short, over }

/// Expected against counted cash. Any difference counts, even one paisa (no
/// tolerance; owner, 2026-11-21).
final class CashVariance {
  CashVariance({required this.expected, required this.counted}) {
    if (counted.paise < 0) {
      throw ArgumentError.value(counted, 'counted', 'must not be negative');
    }
  }

  final Money expected;
  final Money counted;

  /// Counted minus expected: negative when short, positive when over.
  Money get difference => counted - expected;

  VarianceKind get kind => difference.paise == 0
      ? VarianceKind.exact
      : difference.paise < 0
      ? VarianceKind.short
      : VarianceKind.over;
}

/// What the cashier gets back from a blind close: that it was recorded, and
/// nothing about the expected amount or the variance (E-SHIFT-1).
final class ShiftCloseReceipt {
  const ShiftCloseReceipt({required this.shiftId});
  final String shiftId;

  @override
  String toString() => 'ShiftCloseReceipt($shiftId)';
}

/// One break inside a shift (the Pause button). [end] is null while it goes on.
final class BreakSpan {
  const BreakSpan({required this.start, this.end});
  final DateTime start;
  final DateTime? end;
}

/// All the break time in [spans]; a break still going counts up to [now]. A
/// clock that went backwards never makes a break negative.
Duration totalBreakTime(List<BreakSpan> spans, DateTime now) {
  var total = Duration.zero;
  for (final s in spans) {
    final d = (s.end ?? now).difference(s.start);
    if (!d.isNegative) {
      total += d;
    }
  }
  return total;
}

/// "12 min", or "2 h 15 min" from an hour up. Whole minutes, rounded down.
String breakMinutesText(Duration d) {
  final minutes = d.inMinutes;
  if (minutes < 60) {
    return '$minutes min';
  }
  return '${minutes ~/ 60} h ${minutes % 60} min';
}

/// A running break as a clock: "06:12", or "1:02:03" from an hour on. A clock
/// that went backwards shows "00:00".
String breakClockText(Duration d) {
  final total = d.isNegative ? 0 : d.inSeconds;
  String two(int n) => n.toString().padLeft(2, '0');
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}
