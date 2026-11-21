// Returns. A return needs a SOLD barcode and refunds the exact net price paid
// (SSOT 15, E-RETURN-1). Inside the window a cashier may take it; after it a
// manager or owner must approve (owner, 2026-11-21). Days are shop-calendar
// days in India time, so day 8 starts at India midnight.

import 'money.dart';
import 'shop_time.dart';

/// The default return window (owner, 2026-11-21).
const int defaultReturnWindowDays = 7;

enum ReturnTiming { withinWindow, needsApproval }

DateTime _shopDate(DateTime utc) {
  final local = utc.toUtc().add(shopUtcOffset);
  return DateTime.utc(local.year, local.month, local.day);
}

/// Whether a garment sold at [soldAt] can be returned at [now] without a
/// manager. Day of sale is day 0; day [windowDays] is still inside. Throws
/// [ArgumentError] for a negative window or a [now] before [soldAt].
ReturnTiming returnTiming(
  DateTime soldAt,
  DateTime now, {
  int windowDays = defaultReturnWindowDays,
}) {
  if (windowDays < 0) {
    throw ArgumentError.value(windowDays, 'windowDays', 'must not be negative');
  }
  if (now.isBefore(soldAt)) {
    throw ArgumentError.value(now, 'now', 'is before the sale');
  }
  final days = _shopDate(now).difference(_shopDate(soldAt)).inDays;
  return days <= windowDays
      ? ReturnTiming.withinWindow
      : ReturnTiming.needsApproval;
}

/// The refund for garments whose net prices paid are [netPrices]: exactly their
/// sum. A negative price is refused.
Money refundTotal(List<Money> netPrices) {
  var total = Money.zero;
  for (final p in netPrices) {
    if (p.paise < 0) {
      throw ArgumentError.value(p, 'netPrices', 'must not be negative');
    }
    total += p;
  }
  return total;
}

/// How a refund is paid out. An exchange is a return paid out as a credit note
/// that the register applies to the new bill at once.
enum RefundMode {
  cash('cash'),
  upi('upi'),
  card('card'),
  creditNote('credit_note');

  const RefundMode(this.dbValue);

  /// The text stored in the database.
  final String dbValue;

  static RefundMode? fromDb(String value) {
    for (final m in values) {
      if (m.dbValue == value) {
        return m;
      }
    }
    return null;
  }
}
