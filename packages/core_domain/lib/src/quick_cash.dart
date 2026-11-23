// Quick cash amounts at the register: the round amounts a customer is likely to
// hand over, so the cashier taps one instead of typing. Integer paise only
// (E-MONEY-1). The exact amount has its own button and is never listed here.

import 'money.dart';

/// Three amounts strictly above [due], smallest first: the next 100 rupees, then
/// the next two multiples of 500 above that. Nothing when nothing is due.
List<Money> quickCashAmounts(Money due) {
  if (due.paise <= 0) {
    return const [];
  }
  final first =
      ((due.paise ~/ 10000) + 1) * 100; // next 100 rupees, strictly above
  final second = ((first ~/ 500) + 1) * 500;
  final third = second + 500;
  return [Money.rupees(first), Money.rupees(second), Money.rupees(third)];
}
