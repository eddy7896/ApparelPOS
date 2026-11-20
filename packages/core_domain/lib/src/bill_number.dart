// Bill numbers look like 2026-27/C1/000123: financial year (April to March,
// India time), the counter's number, then that counter's own running number.
// Each counter numbers its own bills, so two counters never clash even when
// both are offline (owner, 2026-11-20).

import 'shop_time.dart';

/// The financial year label for [utc], such as `2026-27`, by India time.
String financialYearLabel(DateTime utc) {
  final local = utc.toUtc().add(shopUtcOffset);
  final start = local.month >= 4 ? local.year : local.year - 1;
  final end = (start + 1) % 100;
  return '$start-${end.toString().padLeft(2, '0')}';
}

final RegExp _billPattern = RegExp(
  r'^(\d{4})-(\d{2})/C([1-9]\d{0,1})/(\d{6})$',
);

/// One bill's number. The first serial of a year on a counter is 1.
final class BillNumber {
  /// Throws [ArgumentError] for a malformed year label, a counter number
  /// outside 1 to 99 or a serial outside 1 to 999999.
  BillNumber({
    required this.yearLabel,
    required this.counterNo,
    required this.serial,
  }) {
    final m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(yearLabel);
    if (m == null ||
        (int.parse(m.group(1)!) + 1) % 100 != int.parse(m.group(2)!)) {
      throw ArgumentError.value(yearLabel, 'yearLabel', 'must be like 2026-27');
    }
    if (counterNo < 1 || counterNo > 99) {
      throw ArgumentError.value(counterNo, 'counterNo', 'must be 1 to 99');
    }
    if (serial < 1 || serial > 999999) {
      throw ArgumentError.value(serial, 'serial', 'must be 1 to 999999');
    }
  }

  final String yearLabel;
  final int counterNo;
  final int serial;

  /// Text such as `2026-27/C1/000123`.
  String format() =>
      '$yearLabel/C$counterNo/${serial.toString().padLeft(6, '0')}';

  /// The next bill on the same counter and year. Throws [StateError] after
  /// serial 999999.
  BillNumber next() {
    if (serial >= 999999) {
      throw StateError('Bill serial is used up for $yearLabel on C$counterNo');
    }
    return BillNumber(
      yearLabel: yearLabel,
      counterNo: counterNo,
      serial: serial + 1,
    );
  }

  /// Reads text made by [format]; null if it is not exactly that shape.
  static BillNumber? parse(String text) {
    final m = _billPattern.firstMatch(text);
    if (m == null) {
      return null;
    }
    try {
      return BillNumber(
        yearLabel: '${m.group(1)}-${m.group(2)}',
        counterNo: int.parse(m.group(3)!),
        serial: int.parse(m.group(4)!),
      );
    } on ArgumentError {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is BillNumber &&
      other.yearLabel == yearLabel &&
      other.counterNo == counterNo &&
      other.serial == serial;

  @override
  int get hashCode => Object.hash(yearLabel, counterNo, serial);

  @override
  String toString() => 'BillNumber(${format()})';
}
