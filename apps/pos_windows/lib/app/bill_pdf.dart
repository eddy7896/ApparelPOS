// The printable bill: A4, drawn with the bundled Noto Sans (ADR-0017). What the
// bill says is worked out first in plain text ([BillSheet]) so it can be tested
// exactly; the PDF only draws it. Thermal receipts wait for the printer model.
import 'dart:typed_data';

import 'package:core_domain/core_domain.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/sales_repository.dart';
import 'label_printer.dart';

/// One garment row on the bill.
final class BillSheetRow {
  const BillSheetRow({
    required this.description,
    required this.mrp,
    required this.off,
    required this.price,
  });
  final String description;
  final String mrp;

  /// Markdown plus discount, as text; empty when there is none.
  final String off;
  final String price;
}

/// Everything the bill says, as text.
final class BillSheet {
  const BillSheet({
    required this.shopName,
    required this.billNo,
    required this.dateText,
    required this.cashierName,
    required this.customer,
    required this.rows,
    required this.totalText,
    required this.payments,
    required this.changeText,
  });

  /// Null when the shop name has not been set.
  final String? shopName;
  final String billNo;
  final String dateText;
  final String cashierName;

  /// Name and phone as typed, or null.
  final String? customer;
  final List<BillSheetRow> rows;
  final String totalText;

  /// For example `Cash ₹500.00`.
  final List<String> payments;

  /// Null when no change was given.
  final String? changeText;
}

/// "20-11-2026 15:30" in India time.
String billDateText(DateTime utc) {
  final l = utc.toUtc().add(shopUtcOffset);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.day)}-${two(l.month)}-${l.year} ${two(l.hour)}:${two(l.minute)}';
}

const Map<PaymentMode, String> _modeNames = {
  PaymentMode.cash: 'Cash',
  PaymentMode.upi: 'UPI',
  PaymentMode.card: 'Card',
  PaymentMode.creditNote: 'Credit note',
};

BillSheet describeBill({
  required SavedBill bill,
  required String? shopName,
  required String cashierName,
  String? customerName,
  String? customerPhone,
}) {
  final who = [
    if (customerName != null && customerName.trim().isNotEmpty)
      customerName.trim(),
    if (customerPhone != null && customerPhone.trim().isNotEmpty)
      customerPhone.trim(),
  ];
  final change = bill.settlement.change;
  return BillSheet(
    shopName: shopName,
    billNo: bill.billNumber.format(),
    dateText: billDateText(bill.billedAt),
    cashierName: cashierName,
    customer: who.isEmpty ? null : who.join(', '),
    rows: [
      for (final l in bill.lines)
        BillSheetRow(
          description: '${l.productName} ${l.size} ${l.color}',
          mrp: formatRupees(l.priced.mrp),
          off: (l.priced.markdownAmount + l.priced.discountAmount).paise == 0
              ? ''
              : '-${formatRupees(l.priced.markdownAmount + l.priced.discountAmount)}',
          price: formatRupees(l.priced.finalPrice),
        ),
    ],
    totalText: formatRupees(bill.total),
    payments: [
      for (final mode in PaymentMode.values)
        if (bill.settlement.byMode[mode] != null)
          '${_modeNames[mode]} ${formatRupees(bill.settlement.byMode[mode]!)}',
    ],
    changeText: change.paise == 0 ? null : formatRupees(change),
  );
}

/// Draws [sheet] on A4 pages (more pages if there are many garments).
Future<Uint8List> buildBillPdf(BillSheet sheet, LabelFonts fonts) async {
  final theme = pw.ThemeData.withFont(
    base: pw.Font.ttf(ByteData.sublistView(fonts.regular)),
    bold: pw.Font.ttf(ByteData.sublistView(fonts.bold)),
  );
  final doc = pw.Document(theme: theme);
  pw.Widget cell(String text, {bool right = false, bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: pw.Text(
          text,
          textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
          style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
        ),
      );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (_) => [
        if (sheet.shopName != null)
          pw.Text(
            sheet.shopName!,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
        pw.SizedBox(height: 6),
        pw.Text('Bill no: ${sheet.billNo}'),
        pw.Text('Date: ${sheet.dateText}'),
        pw.Text('Cashier: ${sheet.cashierName}'),
        if (sheet.customer != null) pw.Text('Customer: ${sheet.customer}'),
        pw.SizedBox(height: 14),
        pw.Table(
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(width: 0.3),
            bottom: pw.BorderSide(width: 0.6),
            top: pw.BorderSide(width: 0.6),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(5),
            1: pw.FlexColumnWidth(2),
            2: pw.FlexColumnWidth(2),
            3: pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              children: [
                cell('Item', bold: true),
                cell('MRP', right: true, bold: true),
                cell('Off', right: true, bold: true),
                cell('Price', right: true, bold: true),
              ],
            ),
            for (final r in sheet.rows)
              pw.TableRow(
                children: [
                  cell(r.description),
                  cell(r.mrp, right: true),
                  cell(r.off, right: true),
                  cell(r.price, right: true),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Total ${sheet.totalText}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ),
        for (final p in sheet.payments)
          pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(p)),
        if (sheet.changeText != null)
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Change given ${sheet.changeText}'),
          ),
      ],
    ),
  );
  return doc.save();
}
