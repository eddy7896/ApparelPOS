// Plain CSV text for a spreadsheet (the GST export for the CA, P3-4). One field
// is quoted when it holds a comma, a quote or a line break; quotes are doubled.
// A field that starts with = + - or @ gets a leading apostrophe so a
// spreadsheet never runs it as a formula. Money is written as plain rupees.
import 'money.dart';

String csvField(String text) {
  var t = text;
  if (t.isNotEmpty && '=+-@'.contains(t[0])) {
    t = "'$t";
  }
  if (t.contains(',') ||
      t.contains('"') ||
      t.contains('\n') ||
      t.contains('\r')) {
    return '"${t.replaceAll('"', '""')}"';
  }
  return t;
}

/// One CSV line (no line break at the end).
String csvRow(List<String> fields) => fields.map(csvField).join(',');

/// Rupees with two decimals and no symbol or commas: `1499.00`, `-20.50`.
String plainRupees(Money m) {
  final a = m.paise.abs();
  final s = '${a ~/ 100}.${(a % 100).toString().padLeft(2, '0')}';
  return m.paise < 0 ? '-$s' : s;
}
