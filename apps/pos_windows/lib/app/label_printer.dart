import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:printing/printing.dart';

/// Sends a finished PDF to a printer. The app uses the system print preview
/// and printer dialog; tests use a fake that just records the bytes.
abstract class LabelPrinter {
  Future<void> printSheet(Uint8List pdf, {required String name});
}

class SystemLabelPrinter implements LabelPrinter {
  const SystemLabelPrinter();

  @override
  Future<void> printSheet(Uint8List pdf, {required String name}) async {
    await Printing.layoutPdf(
      name: name,
      format: PdfPageFormat.a4,
      onLayout: (_) async => pdf,
    );
  }
}

/// The two font files the hangtags are drawn with (ADR-0017).
class LabelFonts {
  const LabelFonts({required this.regular, required this.bold});
  final Uint8List regular;
  final Uint8List bold;
}

/// Reads the fonts bundled in the app's assets.
Future<LabelFonts> loadBundledLabelFonts() async {
  final regular = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
  final bold = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
  return LabelFonts(
    regular: regular.buffer.asUint8List(
      regular.offsetInBytes,
      regular.lengthInBytes,
    ),
    bold: bold.buffer.asUint8List(bold.offsetInBytes, bold.lengthInBytes),
  );
}
