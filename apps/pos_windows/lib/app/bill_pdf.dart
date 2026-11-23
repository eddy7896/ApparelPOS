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
    this.taxable = '',
    this.rate = '',
    this.tax = '',
  });
  final String description;
  final String mrp;

  /// Markdown plus discount, as text; empty when there is none.
  final String off;
  final String price;

  /// GST columns (only filled for a GST invoice, and only the ones the owner
  /// switched on).
  final String taxable;
  final String rate;
  final String tax;
}

/// Everything the bill says, as text.
final class BillSheet {
  const BillSheet({
    required this.shopName,
    required this.billNo,
    required this.dateText,
    required this.operatorCode,
    required this.customer,
    required this.rows,
    required this.totalText,
    required this.payments,
    required this.changeText,
    this.balanceDueText,
    this.title,
    this.topLines = const [],
    this.showServedBy = true,
    this.showMrp = true,
    this.showOff = true,
    this.showTaxable = false,
    this.showRate = false,
    this.showTax = false,
    this.taxLines = const [],
    this.wordsLine,
    this.termsLine,
    this.signatureLine = false,
  });

  /// Null when the shop name has not been set.
  final String? shopName;
  final String billNo;
  final String dateText;

  /// The operator ID of whoever made the bill (never a name).
  final String operatorCode;

  /// Name and phone as typed, or null.
  final String? customer;
  final List<BillSheetRow> rows;
  final String totalText;

  /// For example `Cash ₹500.00`.
  final List<String> payments;

  /// Null when no change was given.
  final String? changeText;

  /// What the customer still has to pay (pay later), or null for a bill paid
  /// in full.
  final String? balanceDueText;

  // GST invoice (P3-4; UNVERIFIED until the CA confirms). A bill made with GST
  // off keeps the plain look: none of these are set.
  /// "TAX INVOICE", or null.
  final String? title;

  /// Shop address and GSTIN, above the bill number.
  final List<String> topLines;
  final bool showServedBy;
  final bool showMrp;
  final bool showOff;
  final bool showTaxable;
  final bool showRate;
  final bool showTax;

  /// Taxable value, CGST, SGST and total tax lines above the total.
  final List<String> taxLines;

  /// The total in words, or null.
  final String? wordsLine;
  final String? termsLine;
  final bool signatureLine;
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

/// The lines under the shop name: bill number, date, who served (by operator
/// ID, never a name) and the customer if given. The PDF prints exactly these.
List<String> billHeaderLines(BillSheet sheet) => [
  ...sheet.topLines,
  'Bill no: ${sheet.billNo}',
  'Date: ${sheet.dateText}',
  if (sheet.showServedBy) billServedByLine(sheet.operatorCode),
  if (sheet.customer != null) 'Customer: ${sheet.customer}',
];

BillSheet describeBill({
  required SavedBill bill,
  required String? shopName,
  required String operatorCode,
  String? customerName,
  String? customerPhone,
}) {
  final g = bill.gst;
  final tax = bill.tax;
  // A GST invoice follows the fields the owner switched on; a bill made with
  // GST off is the plain bill it always was.
  bool prints(GstInvoiceField f) => !g.enabled || g.prints(f);
  final who = [
    if (customerName != null &&
        customerName.trim().isNotEmpty &&
        prints(GstInvoiceField.customerName))
      customerName.trim(),
    if (customerPhone != null &&
        customerPhone.trim().isNotEmpty &&
        prints(GstInvoiceField.customerPhone))
      customerPhone.trim(),
  ];
  final change = bill.settlement.change;
  final showOff = prints(GstInvoiceField.discount);
  final showMrp = !g.enabled || g.prints(GstInvoiceField.unitPrice);
  final showTaxable = g.enabled && g.prints(GstInvoiceField.taxableValue);
  final showRate = g.enabled && g.prints(GstInvoiceField.gstRate);
  final showTax = g.enabled && g.prints(GstInvoiceField.taxPerItem);
  String rateText(int bp) => markdownLabel(PriceCut.percentBp(bp));
  return BillSheet(
    shopName: shopName,
    billNo: bill.billNumber.format(),
    dateText: billDateText(bill.billedAt),
    operatorCode: operatorCode,
    customer: who.isEmpty ? null : who.join(', '),
    rows: [
      for (var i = 0; i < bill.lines.length; i++)
        () {
          final l = bill.lines[i];
          final t = tax.lines[i];
          return BillSheetRow(
            description: '${l.productName} ${l.size} ${l.color}',
            mrp: formatRupees(l.priced.mrp),
            off: (l.priced.markdownAmount + l.priced.discountAmount).paise == 0
                ? ''
                : '-${formatRupees(l.priced.markdownAmount + l.priced.discountAmount)}',
            // What this garment cost the customer: with tax added on top it
            // includes the tax.
            price: formatRupees(t.paid),
            taxable: showTaxable ? formatRupees(t.taxable) : '',
            rate: showRate ? rateText(t.rateBp) : '',
            tax: showTax ? formatRupees(t.tax) : '',
          );
        }(),
    ],
    totalText: formatRupees(bill.total),
    payments: [
      if (prints(GstInvoiceField.paymentMode))
        for (final mode in PaymentMode.values)
          if (bill.settlement.byMode[mode] != null)
            '${_modeNames[mode]} ${formatRupees(bill.settlement.byMode[mode]!)}',
    ],
    changeText: change.paise == 0 ? null : formatRupees(change),
    balanceDueText: bill.owed.paise > 0 ? formatRupees(bill.owed) : null,
    title: g.enabled ? 'TAX INVOICE' : null,
    topLines: [
      if (g.enabled && g.prints(GstInvoiceField.shopAddress)) g.address,
      if (g.enabled && g.prints(GstInvoiceField.shopGstin)) 'GSTIN: ${g.gstin}',
    ],
    showServedBy: prints(GstInvoiceField.servedBy),
    showMrp: showMrp,
    showOff: showOff,
    showTaxable: showTaxable,
    showRate: showRate,
    showTax: showTax,
    taxLines: [
      if (g.enabled && g.prints(GstInvoiceField.taxableValue))
        'Taxable value ${formatRupees(tax.totalTaxable)}',
      if (g.enabled && g.prints(GstInvoiceField.cgstSgst)) ...[
        'CGST ${formatRupees(tax.totalCgst)}',
        'SGST ${formatRupees(tax.totalSgst)}',
      ],
      if (g.enabled && g.prints(GstInvoiceField.totalTax))
        'Total tax ${formatRupees(tax.totalTax)}',
    ],
    wordsLine: g.enabled && g.prints(GstInvoiceField.amountInWords)
        ? amountInWords(bill.total)
        : null,
    termsLine: g.enabled && g.prints(GstInvoiceField.termsLine)
        ? 'Goods may be returned within $defaultReturnWindowDays days with this bill.'
        : null,
    signatureLine: g.enabled && g.prints(GstInvoiceField.signatureLine),
  );
}

/// Draws [sheet] on A4 pages (more pages if there are many garments).
Future<Uint8List> buildBillPdf(
  BillSheet sheet,
  LabelFonts fonts, {
  Uint8List? logo,
}) async {
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
  // The columns follow the sheet: a plain bill is Item, MRP, Off and Price; a
  // GST invoice adds the tax columns the owner switched on.
  final columns =
      <({String title, double flex, String Function(BillSheetRow) of})>[
        (title: 'Item', flex: 5, of: (r) => r.description),
        if (sheet.showMrp) (title: 'MRP', flex: 2, of: (r) => r.mrp),
        if (sheet.showOff) (title: 'Off', flex: 2, of: (r) => r.off),
        if (sheet.showTaxable)
          (title: 'Taxable', flex: 2, of: (r) => r.taxable),
        if (sheet.showRate) (title: 'GST', flex: 1.4, of: (r) => r.rate),
        if (sheet.showTax) (title: 'Tax', flex: 2, of: (r) => r.tax),
        (title: 'Price', flex: 2, of: (r) => r.price),
      ];
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (_) => [
        if (logo != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Image(
              pw.MemoryImage(logo),
              height: 48,
              fit: pw.BoxFit.contain,
              alignment: pw.Alignment.centerLeft,
            ),
          ),
        if (sheet.shopName != null)
          pw.Text(
            sheet.shopName!,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
        if (sheet.title != null)
          pw.Text(
            sheet.title!,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
        pw.SizedBox(height: 6),
        for (final line in billHeaderLines(sheet)) pw.Text(line),
        pw.SizedBox(height: 14),
        pw.Table(
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(width: 0.3),
            bottom: pw.BorderSide(width: 0.6),
            top: pw.BorderSide(width: 0.6),
          ),
          columnWidths: {
            for (var c = 0; c < columns.length; c++)
              c: pw.FlexColumnWidth(columns[c].flex),
          },
          children: [
            pw.TableRow(
              children: [
                for (var c = 0; c < columns.length; c++)
                  cell(columns[c].title, right: c > 0, bold: true),
              ],
            ),
            for (final r in sheet.rows)
              pw.TableRow(
                children: [
                  for (var c = 0; c < columns.length; c++)
                    cell(columns[c].of(r), right: c > 0),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 10),
        for (final t in sheet.taxLines)
          pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(t)),
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
        if (sheet.balanceDueText != null)
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Balance to pay later ${sheet.balanceDueText}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        if (sheet.wordsLine != null) ...[
          pw.SizedBox(height: 6),
          pw.Text(sheet.wordsLine!),
        ],
        if (sheet.termsLine != null) ...[
          pw.SizedBox(height: 10),
          pw.Text(sheet.termsLine!),
        ],
        if (sheet.signatureLine) ...[
          pw.SizedBox(height: 40),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Authorised signatory'),
          ),
        ],
      ],
    ),
  );
  return doc.save();
}
