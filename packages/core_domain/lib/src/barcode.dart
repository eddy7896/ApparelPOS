// Garment barcodes: YYMM + 3-digit lot + 4-digit serial + 1 check digit
// (12 digits, so Code 128 Subset C can encode them as pairs). E-SERIAL-1.
// The check digit is not in the original 11-digit spec: owner approved adding
// one on 2026-11-18; the Luhn algorithm is the assistant's pick (see ADR-0006).

/// The Luhn check digit for a string of digits.
int luhnCheckDigit(String digits) {
  if (digits.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(digits)) {
    throw ArgumentError.value(digits, 'digits', 'must be one or more digits');
  }
  var sum = 0;
  for (var i = 0; i < digits.length; i++) {
    var d = digits.codeUnitAt(digits.length - 1 - i) - 0x30;
    if (i.isEven) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    sum += d;
  }
  return (10 - sum % 10) % 10;
}

/// One garment barcode.
final class Barcode {
  const Barcode({
    required this.year,
    required this.month,
    required this.lot,
    required this.serial,
  });

  /// Two-digit year (0 to 99).
  final int year;

  /// Month, 1 to 12.
  final int month;

  /// Lot number, 0 to 999.
  final int lot;

  /// Serial inside the lot, 0 to 9999.
  final int serial;

  static const int maxLot = 999;
  static const int maxSerial = 9999;

  /// The 12-digit value printed and scanned.
  String get value {
    _check();
    final body =
        '${_pad(year, 2)}${_pad(month, 2)}${_pad(lot, 3)}${_pad(serial, 4)}';
    return '$body${luhnCheckDigit(body)}';
  }

  /// Parses a scanned value, or returns null if it is not a valid barcode.
  static Barcode? tryParse(String text) {
    if (text.length != 12 || !RegExp(r'^[0-9]{12}$').hasMatch(text)) {
      return null;
    }
    final body = text.substring(0, 11);
    if (luhnCheckDigit(body) != int.parse(text.substring(11))) return null;
    final month = int.parse(body.substring(2, 4));
    if (month < 1 || month > 12) return null;
    return Barcode(
      year: int.parse(body.substring(0, 2)),
      month: month,
      lot: int.parse(body.substring(4, 7)),
      serial: int.parse(body.substring(7, 11)),
    );
  }

  /// Like [tryParse] but throws a [FormatException] on a bad value.
  static Barcode parse(String text) =>
      tryParse(text) ?? (throw FormatException('Not a valid barcode', text));

  void _check() {
    if (year < 0 || year > 99) {
      throw ArgumentError.value(year, 'year');
    }
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month');
    }
    if (lot < 0 || lot > maxLot) {
      throw ArgumentError.value(lot, 'lot');
    }
    if (serial < 0 || serial > maxSerial) {
      throw ArgumentError.value(serial, 'serial');
    }
  }

  static String _pad(int n, int width) => n.toString().padLeft(width, '0');

  @override
  bool operator ==(Object other) =>
      other is Barcode &&
      other.year == year &&
      other.month == month &&
      other.lot == lot &&
      other.serial == serial;

  @override
  int get hashCode => Object.hash(year, month, lot, serial);

  @override
  String toString() => 'Barcode($value)';
}

/// An inclusive range of lot numbers reserved for one counter.
final class LotRange {
  LotRange(this.first, this.last) {
    if (first < 0 || last < first || last > Barcode.maxLot) {
      throw ArgumentError(
        'lot range $first-$last must satisfy '
        '0 <= first <= last <= ${Barcode.maxLot}',
      );
    }
  }

  final int first;
  final int last;

  bool contains(int lot) => lot >= first && lot <= last;

  bool overlaps(LotRange other) => first <= other.last && other.first <= last;

  @override
  String toString() => 'LotRange($first-$last)';
}

/// Thrown when two counters were given overlapping lot ranges.
final class RangeOverlap implements Exception {
  RangeOverlap(this.message);
  final String message;
  @override
  String toString() => 'RangeOverlap: $message';
}

/// Thrown when the current lot has no serials left.
final class LotFull implements Exception {
  @override
  String toString() => 'LotFull: no serials left in this lot';
}

/// Thrown when the counter has used every lot in its range.
final class RangeExhausted implements Exception {
  @override
  String toString() => 'RangeExhausted: no lots left in this counter\'s range';
}

/// Throws [RangeOverlap] unless every counter's range is disjoint from the others.
void checkCounterRanges(Map<String, LotRange> ranges) {
  final names = ranges.keys.toList();
  for (var i = 0; i < names.length; i++) {
    for (var j = i + 1; j < names.length; j++) {
      if (ranges[names[i]]!.overlaps(ranges[names[j]]!)) {
        throw RangeOverlap(
          'counters ${names[i]} (${ranges[names[i]]}) and ${names[j]} (${ranges[names[j]]}) overlap',
        );
      }
    }
  }
}

/// What [LotCursor.issue] returns: the new barcodes and the moved-on cursor.
final class Issued {
  Issued(this.barcodes, this.cursor);
  final List<Barcode> barcodes;
  final LotCursor cursor;
}

/// One counter's position: the lot it is issuing from and the next serial.
/// Immutable; persist the returned cursor in the same transaction as the articles.
final class LotCursor {
  const LotCursor._(this.range, this.lot, this.nextSerial);

  /// Starts at the first lot of [range], serial 0.
  factory LotCursor.start(LotRange range) => LotCursor._(range, range.first, 0);

  /// Restores a saved position; [lot] must be inside [range].
  factory LotCursor.resume(LotRange range, int lot, int nextSerial) {
    if (!range.contains(lot)) {
      throw ArgumentError.value(lot, 'lot', 'outside $range');
    }
    if (nextSerial < 0 || nextSerial > Barcode.maxSerial + 1) {
      throw ArgumentError.value(nextSerial, 'nextSerial');
    }
    return LotCursor._(range, lot, nextSerial);
  }

  final LotRange range;
  final int lot;
  final int nextSerial;

  /// Issues [count] barcodes from the current lot. All or nothing: throws
  /// [LotFull] and issues nothing if they do not all fit.
  Issued issue(int count, {required int year, required int month}) {
    if (count < 1) {
      throw ArgumentError.value(count, 'count', 'must be at least 1');
    }
    if (nextSerial + count > Barcode.maxSerial + 1) {
      throw LotFull();
    }
    final codes = [
      for (var i = 0; i < count; i++)
        Barcode(year: year, month: month, lot: lot, serial: nextSerial + i),
    ];
    return Issued(codes, LotCursor._(range, lot, nextSerial + count));
  }

  /// Moves to the next lot in the range, serial 0. Throws [RangeExhausted] at the end.
  LotCursor nextLot() {
    if (lot >= range.last) {
      throw RangeExhausted();
    }
    return LotCursor._(range, lot + 1, 0);
  }
}
