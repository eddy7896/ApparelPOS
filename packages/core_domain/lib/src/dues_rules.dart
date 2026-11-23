// Pay later (udhaar), owner 2026-11-23: a manager or the owner may let a
// customer take clothes and pay later (all or part). The customer's name and
// phone are required. Later payments (cash, UPI, card) settle the oldest bill
// first. A return from an unpaid bill first reduces what is still owed on that
// bill; only the rest is refunded. Only the owner may write a debt off. Pure
// rules, no database. Integer paise (E-MONEY-1).
import 'money.dart';

const int maxCustomerNameLength = 80;

/// The customer's name trimmed, or null when it is blank or too long.
String? cleanCustomerName(String? text) {
  final t = (text ?? '').trim();
  if (t.isEmpty || t.length > maxCustomerNameLength) {
    return null;
  }
  return t;
}

/// The key that finds the same customer again: the digits of the phone number,
/// and when there are 10 or more only the last 10 (so +91 98765 43210 and
/// 98765 43210 are one customer). Null when the text is not a phone number of
/// 7 to 15 digits.
String? customerPhoneKey(String? text) {
  final t = (text ?? '').trim();
  if (t.isEmpty || !RegExp(r'^[0-9+\- ]+$').hasMatch(t)) {
    return null;
  }
  final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 7 || digits.length > 15) {
    return null;
  }
  return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
}

/// What a return takes off what is still [owed] on the bill: the smaller of
/// the refund for that bill's garments and the amount still owed. Neither may
/// be negative.
Money returnOffset({required Money refundShare, required Money owed}) {
  if (refundShare.paise < 0 || owed.paise < 0) {
    throw ArgumentError('amounts must not be negative');
  }
  return refundShare < owed ? refundShare : owed;
}

/// A bill with something still owed on it.
final class DueBill {
  const DueBill(this.billId, this.outstanding);
  final String billId;
  final Money outstanding;
}

/// How much of a payment goes to which bill.
final class DueShare {
  const DueShare(this.billId, this.amount);
  final String billId;
  final Money amount;
}

/// Spreads [amount] over [oldestFirst] bills, the oldest first, never more than
/// a bill's outstanding amount. Throws [ArgumentError] when [amount] is not
/// above zero or is more than everything outstanding.
List<DueShare> allocateDues(List<DueBill> oldestFirst, Money amount) {
  if (amount.paise <= 0) {
    throw ArgumentError.value(amount, 'amount', 'must be above zero');
  }
  var left = amount;
  final out = <DueShare>[];
  for (final b in oldestFirst) {
    if (left.paise == 0) {
      break;
    }
    if (b.outstanding.paise <= 0) {
      continue;
    }
    final take = left < b.outstanding ? left : b.outstanding;
    out.add(DueShare(b.billId, take));
    left -= take;
  }
  if (left.paise > 0) {
    throw ArgumentError.value(amount, 'amount', 'is more than is owed');
  }
  return out;
}

/// Everything outstanding on [bills].
Money totalOwed(List<DueBill> bills) =>
    bills.fold<Money>(Money.zero, (sum, b) => sum + b.outstanding);
