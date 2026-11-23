// Hangtag sheet geometry and label text. Every length is a whole number of
// micrometres (1 mm = 1000), so there is no floating point. Owner choice
// (2026-11-18): A4 sheet, 3 columns x 8 rows, MRP written as the rupee sign.

import 'barcode.dart';
import 'money.dart';

/// A rectangle in micrometres, measured from the top-left of the page.
final class Rect {
  const Rect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final int left;
  final int top;
  final int width;
  final int height;

  bool overlaps(Rect other) =>
      left < other.left + other.width &&
      other.left < left + width &&
      top < other.top + other.height &&
      other.top < top + height;

  @override
  bool operator ==(Object other) =>
      other is Rect &&
      other.left == left &&
      other.top == top &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() => 'Rect($left, $top, $width x $height)';
}

/// A sheet of sticker cells laid out row by row.
final class SheetLayout {
  SheetLayout({
    required this.pageWidth,
    required this.pageHeight,
    required this.columns,
    required this.rows,
    required this.cellWidth,
    required this.cellHeight,
    this.marginLeft = 0,
    this.marginTop = 0,
    this.gapX = 0,
    this.gapY = 0,
  }) {
    if (columns < 1 || rows < 1) {
      throw ArgumentError('columns and rows must be at least 1');
    }
    if (cellWidth < 1 || cellHeight < 1 || pageWidth < 1 || pageHeight < 1) {
      throw ArgumentError('sizes must be positive');
    }
    if (marginLeft < 0 || marginTop < 0 || gapX < 0 || gapY < 0) {
      throw ArgumentError('margins and gaps must not be negative');
    }
    final usedWidth = marginLeft + columns * cellWidth + (columns - 1) * gapX;
    final usedHeight = marginTop + rows * cellHeight + (rows - 1) * gapY;
    if (usedWidth > pageWidth || usedHeight > pageHeight) {
      throw ArgumentError('the cells do not fit on the page');
    }
  }

  /// A4 (210 x 297 mm) with 3 columns x 8 rows of 70 x 37.125 mm and no margins.
  factory SheetLayout.a4ThreeByEight() => SheetLayout(
    pageWidth: 210000,
    pageHeight: 297000,
    columns: 3,
    rows: 8,
    cellWidth: 70000,
    cellHeight: 37125,
  );

  final int pageWidth;
  final int pageHeight;
  final int columns;
  final int rows;
  final int cellWidth;
  final int cellHeight;
  final int marginLeft;
  final int marginTop;
  final int gapX;
  final int gapY;

  int get cellCount => columns * rows;

  /// The rectangle of cell [index], counted left to right, then top to bottom.
  Rect cellRect(int index) {
    RangeError.checkValidIndex(
      index,
      List<void>.filled(cellCount, null),
      'index',
    );
    final column = index % columns;
    final row = index ~/ columns;
    return Rect(
      left: marginLeft + column * (cellWidth + gapX),
      top: marginTop + row * (cellHeight + gapY),
      width: cellWidth,
      height: cellHeight,
    );
  }
}

/// Where one label goes: page number (from 0), cell and rectangle.
final class LabelPlacement {
  const LabelPlacement({
    required this.labelIndex,
    required this.page,
    required this.cellIndex,
    required this.rect,
  });

  final int labelIndex;
  final int page;
  final int cellIndex;
  final Rect rect;
}

/// Places [labelCount] labels on sheets. The first page starts at
/// [startCell] (to reuse a partly used sheet); later pages start at cell 0.
List<LabelPlacement> paginate(
  SheetLayout layout, {
  required int labelCount,
  int startCell = 0,
}) {
  if (labelCount < 0) {
    throw ArgumentError.value(labelCount, 'labelCount', 'must not be negative');
  }
  if (startCell < 0 || startCell >= layout.cellCount) {
    throw RangeError.range(startCell, 0, layout.cellCount - 1, 'startCell');
  }
  final placements = <LabelPlacement>[];
  var page = 0;
  var cell = startCell;
  for (var i = 0; i < labelCount; i++) {
    placements.add(
      LabelPlacement(
        labelIndex: i,
        page: page,
        cellIndex: cell,
        rect: layout.cellRect(cell),
      ),
    );
    cell++;
    if (cell == layout.cellCount) {
      cell = 0;
      page++;
    }
  }
  return placements;
}

/// "₹1,499.50": rupee sign, Indian digit grouping (1,00,000), two decimals.
/// Negative amounts are refused (an MRP on a tag is never negative).
String formatRupees(Money amount) {
  if (amount.paise < 0) {
    throw ArgumentError.value(amount, 'amount', 'must not be negative');
  }
  final rupees = (amount.paise ~/ 100).toString();
  final paise = (amount.paise % 100).toString().padLeft(2, '0');
  final grouped = StringBuffer();
  if (rupees.length <= 3) {
    grouped.write(rupees);
  } else {
    final head = rupees.substring(0, rupees.length - 3);
    final tail = rupees.substring(rupees.length - 3);
    for (var i = 0; i < head.length; i++) {
      if (i > 0 && (head.length - i).isEven) {
        grouped.write(',');
      }
      grouped.write(head[i]);
    }
    grouped.write(',$tail');
  }
  return '₹$grouped.$paise';
}

/// What is printed on one hangtag.
final class LabelContent {
  const LabelContent({
    required this.shopName,
    required this.style,
    required this.size,
    required this.color,
    required this.mrp,
    required this.barcode,
  });

  final String shopName;
  final String style;
  final String size;
  final String color;
  final Money mrp;
  final Barcode barcode;

  String get mrpText => formatRupees(mrp);
  String get barcodeDigits => barcode.value;
}
