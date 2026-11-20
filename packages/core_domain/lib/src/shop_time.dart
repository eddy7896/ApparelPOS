// The shop's calendar is India time, Asia/Kolkata (ADR-0007 point 9). India has
// had no daylight saving since 1945, so it is a fixed offset of 5 hours 30
// minutes from UTC. Times are stored in UTC; this turns one into the two-digit
// year and month printed in a barcode.

const Duration shopUtcOffset = Duration(hours: 5, minutes: 30);

/// The two-digit year (0 to 99) and the month (1 to 12) in India for [utc].
(int, int) shopYearMonth(DateTime utc) {
  final local = utc.toUtc().add(shopUtcOffset);
  return (local.year % 100, local.month);
}
