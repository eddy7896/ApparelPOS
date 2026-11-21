// A credit note is a barcode with an expiry date (SSOT 16). Its code is 12
// digits: 9900, the counter (2 digits), a serial (5 digits) and a Luhn check
// digit. Month 00 means it can never be read as a garment barcode. The balance
// stays on the same note until it is used up or expires (owner, 2026-11-21);
// it lasts 180 days (owner, 2026-11-21).

import 'barcode.dart';
import 'money.dart';
import 'shop_time.dart';

/// The default life of a credit note (owner, 2026-11-21).
const int defaultCreditNoteDays = 180;

final class CreditNoteCode {
  /// Counter 1 to 99, serial 1 to 99999; otherwise [ArgumentError].
  CreditNoteCode({required this.counterNo, required this.serial}) {
    if (counterNo < 1 || counterNo > 99) {
      throw ArgumentError.value(counterNo, 'counterNo', 'must be 1 to 99');
    }
    if (serial < 1 || serial > 99999) {
      throw ArgumentError.value(serial, 'serial', 'must be 1 to 99999');
    }
  }

  final int counterNo;
  final int serial;

  /// The 12 digits printed and scanned.
  String get value {
    final body =
        '9900${counterNo.toString().padLeft(2, '0')}${serial.toString().padLeft(5, '0')}';
    return '$body${luhnCheckDigit(body)}';
  }

  /// Reads a scanned value, or null if it is not a credit note code.
  static CreditNoteCode? tryParse(String text) {
    if (!RegExp(r'^9900[0-9]{8}$').hasMatch(text)) {
      return null;
    }
    if (luhnCheckDigit(text.substring(0, 11)) !=
        int.parse(text.substring(11))) {
      return null;
    }
    final counter = int.parse(text.substring(4, 6));
    final serial = int.parse(text.substring(6, 11));
    if (counter < 1 || serial < 1) {
      return null;
    }
    return CreditNoteCode(counterNo: counter, serial: serial);
  }

  @override
  bool operator ==(Object other) =>
      other is CreditNoteCode &&
      other.counterNo == counterNo &&
      other.serial == serial;

  @override
  int get hashCode => Object.hash(counterNo, serial);

  @override
  String toString() => 'CreditNoteCode($value)';
}

/// The last shop day (India date, as a UTC midnight) a note issued at
/// [issuedAt] can be used.
DateTime creditNoteLastDay(
  DateTime issuedAt, {
  int validDays = defaultCreditNoteDays,
}) {
  if (validDays < 0) {
    throw ArgumentError.value(validDays, 'validDays', 'must not be negative');
  }
  final local = issuedAt.toUtc().add(shopUtcOffset);
  return DateTime.utc(local.year, local.month, local.day + validDays);
}

/// True while [now] is on or before the note's last day, India time.
bool isCreditNoteValid(
  DateTime issuedAt,
  DateTime now, {
  int validDays = defaultCreditNoteDays,
}) {
  final local = now.toUtc().add(shopUtcOffset);
  final today = DateTime.utc(local.year, local.month, local.day);
  return !today.isAfter(creditNoteLastDay(issuedAt, validDays: validDays));
}

/// What using a note against a bill does.
final class CreditUse {
  const CreditUse({required this.used, required this.left});
  final Money used;
  final Money left;
}

/// Uses the smaller of [balance] and [due]; the rest stays on the note.
CreditUse useCredit({required Money balance, required Money due}) {
  if (balance.paise < 0) {
    throw ArgumentError.value(balance, 'balance', 'must not be negative');
  }
  if (due.paise < 0) {
    throw ArgumentError.value(due, 'due', 'must not be negative');
  }
  final used = balance < due ? balance : due;
  return CreditUse(used: used, left: balance - used);
}
