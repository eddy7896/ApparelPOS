// The printable credit note slip: shop name, amount, a Code 128C barcode that
// scans at the register, the valid-till date and the note number (owner,
// 2026-11-21). What it says is worked out first as text ([CreditNoteSlip]) so
// it can be tested exactly; the PDF only draws it. A4, like the bill.
import 'dart:typed_data';

import 'package:core_domain/core_domain.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/returns_repository.dart';
import 'bill_pdf.dart' show billDateText;
import 'label_printer.dart';

final class CreditNoteSlip {
  const CreditNoteSlip({
    required this.shopName,
    required this.amountText,
    required this.code,
    required this.noteNumber,
    required this.issuedText,
    required this.validTillText,
  });

  /// Null when the shop name has not been set.
  final String? shopName;
  final String amountText;

  /// The 12 digits that are printed as the barcode.
  final String code;

  /// For example `C1-00012`.
  final String noteNumber;
  final String issuedText;

  /// For example `19-05-2027`.
  final String validTillText;
}

String _dateOnly(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}-${two(d.month)}-${d.year}';
}

CreditNoteSlip describeSlip({
  required IssuedCreditNote note,
  required String? shopName,
}) {
  final parsed = CreditNoteCode.tryParse(note.code);
  if (parsed == null) {
    throw ArgumentError.value(note.code, 'note', 'is not a credit note code');
  }
  return CreditNoteSlip(
    shopName: shopName,
    amountText: formatRupees(note.amount),
    code: note.code,
    noteNumber:
        'C${parsed.counterNo}-${parsed.serial.toString().padLeft(5, '0')}',
    issuedText: billDateText(note.issuedAt),
    validTillText: _dateOnly(note.lastDay),
  );
}

/// Draws [slip] on one A4 page.
Future<Uint8List> buildCreditNoteSlipPdf(
  CreditNoteSlip slip,
  LabelFonts fonts,
) async {
  final theme = pw.ThemeData.withFont(
    base: pw.Font.ttf(ByteData.sublistView(fonts.regular)),
    bold: pw.Font.ttf(ByteData.sublistView(fonts.bold)),
  );
  final doc = pw.Document(theme: theme);
  final runs = code128CRuns(slip.code);
  final modules = runs.fold<int>(0, (a, b) => a + b);
  const unit = 2.2; // points per module: wide enough to scan reliably
  const quiet = 12.0; // quiet zone, in modules
  final barcodeWidth = (modules + 2 * quiet) * unit;
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (_) => pw.Align(
        alignment: pw.Alignment.topCenter,
        child: pw.Container(
          width: 360,
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (slip.shopName != null)
                pw.Text(
                  slip.shopName!,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              pw.SizedBox(height: 6),
              pw.Text('CREDIT NOTE', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 10),
              pw.Text(
                slip.amountText,
                style: pw.TextStyle(
                  fontSize: 30,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.SizedBox(
                width: barcodeWidth,
                height: 60,
                child: pw.CustomPaint(
                  painter: (canvas, size) {
                    var x = quiet * unit;
                    for (var i = 0; i < runs.length; i++) {
                      final w = runs[i] * unit;
                      if (i.isEven) {
                        canvas
                          ..setFillColor(PdfColors.black)
                          ..drawRect(x, 0, w, size.y)
                          ..fillPath();
                      }
                      x += w;
                    }
                  },
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(slip.code, style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 12),
              pw.Text('Note ${slip.noteNumber}'),
              pw.Text('Issued ${slip.issuedText}'),
              pw.Text(
                'Valid till ${slip.validTillText}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Whatever is not used stays on this note until it is used up or expires.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return doc.save();
}
