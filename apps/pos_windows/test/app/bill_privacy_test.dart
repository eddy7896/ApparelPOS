// A customer's bill never carries a staff member's name: it says "Served by:"
// and the operator ID (owner, 2026-11-23). These read the source, like the cost
// checks, because the printed text is inside a PDF.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String code(String path) =>
    File(path)
        .readAsLinesSync()
        .where((l) => !l.trimLeft().startsWith('//'))
        .join('\n');

void main() {
  test(
    'the register prints the bill with the operator ID, not the signed-in name',
    () {
      final src = code('lib/app/ui/register_screen.dart');
      final call = RegExp(
        r'describeBill\(.*?\n\s*\);',
        dotAll: true,
      ).firstMatch(src)!.group(0)!;
      expect(call, contains('operatorCode: widget.session.user!.staffCode'));
      expect(call, isNot(contains('.name')));
    },
  );

  test('the bill sheet and PDF have no cashier name field', () {
    final src = code('lib/app/bill_pdf.dart');
    expect(src, isNot(contains('cashierName')));
    expect(src, isNot(contains('Cashier:')));
    expect(src, contains('billServedByLine'));
  });

  test('the credit note slip prints no staff name either', () {
    final src = code('lib/app/credit_note_slip.dart');
    expect(src.toLowerCase(), isNot(contains('cashier')));
    expect(src, isNot(contains('user!.name')));
  });
}
