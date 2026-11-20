// Draws sheets of hangtags into a PDF using the fonts given (Noto Sans, SIL OFL
// 1.1, so the rupee sign prints). Geometry comes from hangtag_artwork.dart.

import 'dart:typed_data';

import 'package:pdf/pdf.dart';

import 'hangtag_artwork.dart';
import 'label_layout.dart';

/// Thrown when the font has no picture for a character, so it would print as a box.
final class MissingGlyph implements Exception {
  MissingGlyph(this.text, this.character);
  final String text;
  final String character;
  @override
  String toString() =>
      'MissingGlyph: the font cannot draw "$character" in "$text"';
}

/// Whether [fontBytes] (a TrueType file) can draw every character of [text].
bool fontHasGlyphs(Uint8List fontBytes, String text) =>
    _missing(TtfParser(ByteData.sublistView(fontBytes)), text) == null;

String? _missing(TtfParser parser, String text) {
  for (final rune in text.runes) {
    if (!parser.charToGlyphIndexMap.containsKey(rune)) {
      return String.fromCharCode(rune);
    }
  }
  return null;
}

double _pt(int micrometres) => micrometres * 72 / 25400;

/// Builds a PDF with [labels] placed on sheets of [layout]. The first page
/// starts at [startCell]; later pages start at the first cell. Throws
/// [ArgumentError] for no labels, [RangeError] for a bad [startCell] and
/// [MissingGlyph] if a character cannot be drawn. [compress] is for tests.
Future<Uint8List> buildHangtagPdf({
  required SheetLayout layout,
  required List<LabelContent> labels,
  required Uint8List regularFont,
  required Uint8List boldFont,
  int startCell = 0,
  bool compress = true,
}) async {
  if (labels.isEmpty) {
    throw ArgumentError.value(labels, 'labels', 'nothing to print');
  }
  final placements = paginate(
    layout,
    labelCount: labels.length,
    startCell: startCell,
  );

  // Lay out everything and check every character before drawing anything.
  final regularParser = TtfParser(ByteData.sublistView(regularFont));
  final boldParser = TtfParser(ByteData.sublistView(boldFont));
  final artworks = <HangtagArtwork>[];
  for (final placement in placements) {
    final art = layoutHangtag(placement.rect, labels[placement.labelIndex]);
    for (final t in art.texts) {
      final bad = _missing(t.bold ? boldParser : regularParser, t.text);
      if (bad != null) {
        throw MissingGlyph(t.text, bad);
      }
    }
    artworks.add(art);
  }

  final document = PdfDocument(compress: compress);
  final regular = PdfTtfFont(document, ByteData.sublistView(regularFont));
  final bold = PdfTtfFont(document, ByteData.sublistView(boldFont));
  final pageHeight = _pt(layout.pageHeight);
  final format = PdfPageFormat(_pt(layout.pageWidth), pageHeight);

  PdfGraphics? graphics;
  var currentPage = -1;
  for (var i = 0; i < placements.length; i++) {
    if (placements[i].page != currentPage) {
      currentPage = placements[i].page;
      graphics = PdfPage(document, pageFormat: format).getGraphics();
    }
    final g = graphics!;
    final art = artworks[i];

    g.setFillColor(PdfColors.black);
    for (final bar in art.bars) {
      g.drawRect(
        _pt(bar.left),
        pageHeight - _pt(bar.top + bar.height),
        _pt(bar.width),
        _pt(bar.height),
      );
      g.fillPath();
    }
    for (final t in art.texts) {
      final font = t.bold ? bold : regular;
      final fitted = fitText(
        t.text,
        maxWidthPt: _pt(t.box.width),
        startSizePt: t.fontSizePt.toDouble(),
        minSizePt: t.fontSizePt * 0.7,
        widthAt: (s, size) => font.stringMetrics(s).width * size,
      );
      final width = font.stringMetrics(fitted.text).width * fitted.sizePt;
      // Centre in the box; baseline a little above the bottom of the box.
      final x = _pt(t.box.left) + (_pt(t.box.width) - width) / 2;
      final y =
          pageHeight - _pt(t.box.top + t.box.height) + fitted.sizePt * 0.25;
      g.setFillColor(PdfColors.black);
      g.drawString(font, fitted.sizePt, fitted.text, x, y);
    }
  }
  return document.save();
}
