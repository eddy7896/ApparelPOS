// Paying a bill. Release 1 takes payment in full at the counter: cash, UPI,
// card, or a mix. Change is only ever given out of cash. Integer paise only
// (E-MONEY-1). Credit notes (P2-5) and pay-later (udhaar) are later tasks.

import 'money.dart';

enum PaymentMode {
  cash('cash'),
  upi('upi'),
  card('card');

  const PaymentMode(this.dbValue);

  /// The text stored in the database.
  final String dbValue;

  /// The mode for [value], or null if unknown.
  static PaymentMode? fromDb(String value) {
    for (final m in values) {
      if (m.dbValue == value) {
        return m;
      }
    }
    return null;
  }
}

/// Money received in one mode. The amount must be above zero.
final class Payment {
  Payment(this.mode, this.amount) {
    if (amount.paise <= 0) {
      throw ArgumentError.value(amount, 'amount', 'must be above zero');
    }
  }

  final PaymentMode mode;
  final Money amount;
}

/// Thrown when UPI or card money is more than what is left to pay.
final class NonCashOverpayment implements Exception {
  NonCashOverpayment(this.total, this.nonCash);
  final Money total;
  final Money nonCash;
  @override
  String toString() =>
      'NonCashOverpayment: $nonCash by UPI or card is more than $total';
}

/// How a bill stands after payments.
final class Settlement {
  const Settlement({
    required this.total,
    required this.byMode,
    required this.change,
    required this.due,
  });

  final Money total;

  /// What each mode actually paid toward the bill (cash is net of change).
  /// Modes that paid nothing are absent.
  final Map<PaymentMode, Money> byMode;

  /// Cash handed back to the customer.
  final Money change;

  /// Still owed; zero when paid.
  final Money due;

  bool get isPaid => due == Money.zero;

  /// Cash that stays in the till for this bill.
  Money get cashKept => byMode[PaymentMode.cash] ?? Money.zero;
}

/// Works out what the payments cover. Throws [ArgumentError] for a negative
/// [total] and [NonCashOverpayment] when UPI and card together exceed it.
Settlement settle(Money total, List<Payment> payments) {
  if (total.paise < 0) {
    throw ArgumentError.value(total, 'total', 'must not be negative');
  }
  var cash = Money.zero;
  final nonCash = <PaymentMode, Money>{};
  var nonCashTotal = Money.zero;
  for (final p in payments) {
    if (p.mode == PaymentMode.cash) {
      cash += p.amount;
    } else {
      nonCash[p.mode] = (nonCash[p.mode] ?? Money.zero) + p.amount;
      nonCashTotal += p.amount;
    }
  }
  if (nonCashTotal > total) {
    throw NonCashOverpayment(total, nonCashTotal);
  }
  final left = total - nonCashTotal;
  final cashApplied = cash < left ? cash : left;
  final byMode = <PaymentMode, Money>{...nonCash};
  if (cashApplied > Money.zero) {
    byMode[PaymentMode.cash] = cashApplied;
  }
  return Settlement(
    total: total,
    byMode: byMode,
    change: cash - cashApplied,
    due: left - cashApplied,
  );
}
