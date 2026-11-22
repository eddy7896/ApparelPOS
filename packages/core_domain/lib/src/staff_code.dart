// Each person who signs in at the counter (cashier, manager or owner) has an
// operator ID, "OP001", "OP002" and so on. It is printed on the bill in place
// of their name, so a customer's bill never carries a staff member's name
// (owner, 2026-11-23). Numbers are given in order, never reused, and stay with
// the person when they are turned off.

/// "OP001": OP and the number with at least three digits.
String formatStaffCode(int number) {
  if (number < 1) {
    throw ArgumentError.value(number, 'number', 'must be 1 or more');
  }
  return 'OP${number.toString().padLeft(3, '0')}';
}

/// The number in [code], or null when it is not an operator ID.
int? parseStaffCode(String code) {
  final m = RegExp(r'^OP(\d{3,})$').firstMatch(code);
  if (m == null) {
    return null;
  }
  final n = int.parse(m.group(1)!);
  return n < 1 ? null : n;
}

/// The next number: one more than the highest used (1 when none are).
int nextStaffNumber(Iterable<int> used) {
  var highest = 0;
  for (final n in used) {
    if (n > highest) {
      highest = n;
    }
  }
  return highest + 1;
}

/// The line printed on a bill: the operator ID, never a name.
String billServedByLine(String staffCode) => 'Served by: $staffCode';
