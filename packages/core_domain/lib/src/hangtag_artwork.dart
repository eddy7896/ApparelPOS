// Where each bar and line of text goes on one hangtag. Pure geometry in whole
// micrometres (no PDF, no fonts): the PDF writer only draws what this says.
// Sizes and spacing are the assistant's defaults (owner has not chosen them).

import 'code128.dart';
import 'label_layout.dart';

/// One line of text and the box it must fit in.
final class TextItem {
  const TextItem({
    required this.text,
    required this.box,
    required this.fontSizePt,
    this.bold = false,
  });

  final String text;
  final Rect box;
  final int fontSizePt;
  final bool bold;
}

/// The drawing for one label: bars (black rectangles) and text lines.
final class HangtagArtwork {
  const HangtagArtwork({
    required this.bars,
    required this.texts,
    required this.moduleWidth,
    required this.innerArea,
  });

  final List<Rect> bars;
  final List<TextItem> texts;

  /// Width of the thinnest bar, in micrometres.
  final int moduleWidth;

  /// The label cell without its padding.
  final Rect innerArea;
}

const int _padding = 2000;
const int _quietModules = 10;
const int _minModuleWidth = 190; // 0.19 mm
const int _barHeight = 8500;

/// Lays out [content] inside [cell]. Throws [ArgumentError] if the cell is too
/// small for a barcode that can be scanned.
HangtagArtwork layoutHangtag(Rect cell, LabelContent content) {
  final inner = Rect(
    left: cell.left + _padding,
    top: cell.top + _padding,
    width: cell.width - 2 * _padding,
    height: cell.height - 2 * _padding,
  );
  const shopTop = 0;
  const styleTop = 4000;
  const detailTop = 8500;
  const mrpTop = 12500;
  const barsTop = 19000;
  const digitsTop = barsTop + _barHeight + 300;
  const digitsHeight = 3500;
  const neededHeight = digitsTop + digitsHeight;

  final runs = code128CRuns(content.barcodeDigits);
  final modules = runs.fold<int>(0, (a, b) => a + b);
  final unit = inner.width ~/ (modules + 2 * _quietModules);
  if (inner.width <= 0 ||
      unit < _minModuleWidth ||
      inner.height < neededHeight) {
    throw ArgumentError('the label cell is too small for a scannable barcode');
  }

  var x = inner.left + (inner.width - modules * unit) ~/ 2;
  final barTop = inner.top + barsTop;
  final bars = <Rect>[];
  for (var i = 0; i < runs.length; i++) {
    final width = runs[i] * unit;
    if (i.isEven) {
      bars.add(Rect(left: x, top: barTop, width: width, height: _barHeight));
    }
    x += width;
  }

  Rect line(int top, int height) => Rect(
    left: inner.left,
    top: inner.top + top,
    width: inner.width,
    height: height,
  );

  return HangtagArtwork(
    bars: bars,
    moduleWidth: unit,
    innerArea: inner,
    texts: [
      TextItem(text: content.shopName, box: line(shopTop, 4000), fontSizePt: 8),
      TextItem(text: content.style, box: line(styleTop, 4500), fontSizePt: 9),
      TextItem(
        text: 'Size ${content.size}   Color ${content.color}',
        box: line(detailTop, 4000),
        fontSizePt: 8,
      ),
      TextItem(
        text: content.mrpText,
        box: line(mrpTop, 6000),
        fontSizePt: 14,
        bold: true,
      ),
      TextItem(
        text: content.barcodeDigits,
        box: line(digitsTop, digitsHeight),
        fontSizePt: 7,
      ),
    ],
  );
}

/// Text after fitting: possibly smaller, possibly cut with three dots.
final class FittedText {
  const FittedText(this.text, this.sizePt);
  final String text;
  final double sizePt;
}

/// Fits [text] into [maxWidthPt]: first shrinks from [startSizePt] down to
/// [minSizePt] in half-point steps, then cuts the end and adds "...".
/// [widthAt] measures a string at a size (from the real font).
FittedText fitText(
  String text, {
  required double maxWidthPt,
  required double startSizePt,
  required double minSizePt,
  required double Function(String text, double sizePt) widthAt,
}) {
  var size = startSizePt;
  while (size > minSizePt && widthAt(text, size) > maxWidthPt) {
    size -= 0.5;
  }
  if (size < minSizePt) {
    size = minSizePt;
  }
  if (widthAt(text, size) <= maxWidthPt) {
    return FittedText(text, size);
  }
  var cut = text.length;
  while (cut > 0 &&
      widthAt('${text.substring(0, cut)}...', size) > maxWidthPt) {
    cut--;
  }
  return FittedText('${text.substring(0, cut)}...', size);
}
