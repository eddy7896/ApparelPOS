// Hangtag sheet geometry. All lengths are whole micrometres (1 mm = 1000), so
// there is no floating point. Owner choice (2026-11-18): A4, 3 columns x 8 rows.
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  final sheet = SheetLayout.a4ThreeByEight();

  group('SheetLayout A4 3 x 8', () {
    test('has 24 cells of 70 mm x 37.125 mm filling the page', () {
      expect(sheet.cellCount, 24);
      expect(
        sheet.cellRect(0),
        const Rect(left: 0, top: 0, width: 70000, height: 37125),
      );
      expect(sheet.cellRect(1).left, 70000);
      expect(sheet.cellRect(2).left, 140000);
      expect(
        sheet.cellRect(3),
        const Rect(left: 0, top: 37125, width: 70000, height: 37125),
      );
      final last = sheet.cellRect(23);
      expect(last.left + last.width, 210000);
      expect(last.top + last.height, 297000);
    });

    test('cells are inside the page and never overlap', () {
      for (var i = 0; i < sheet.cellCount; i++) {
        final a = sheet.cellRect(i);
        expect(a.left >= 0 && a.top >= 0, isTrue);
        expect(a.left + a.width <= sheet.pageWidth, isTrue);
        expect(a.top + a.height <= sheet.pageHeight, isTrue);
        for (var j = i + 1; j < sheet.cellCount; j++) {
          expect(a.overlaps(sheet.cellRect(j)), isFalse, reason: '$i vs $j');
        }
      }
    });

    test('cell index outside the sheet is refused', () {
      expect(() => sheet.cellRect(-1), throwsRangeError);
      expect(() => sheet.cellRect(24), throwsRangeError);
    });
  });

  group('SheetLayout custom', () {
    test('margins and gaps move the cells', () {
      final s = SheetLayout(
        pageWidth: 210000,
        pageHeight: 297000,
        columns: 2,
        rows: 2,
        cellWidth: 90000,
        cellHeight: 100000,
        marginLeft: 10000,
        marginTop: 5000,
        gapX: 10000,
        gapY: 20000,
      );
      expect(
        s.cellRect(0),
        const Rect(left: 10000, top: 5000, width: 90000, height: 100000),
      );
      expect(s.cellRect(1).left, 110000);
      expect(s.cellRect(2).top, 125000);
    });

    test('a layout that does not fit the page is refused', () {
      expect(
        () => SheetLayout(
          pageWidth: 210000,
          pageHeight: 297000,
          columns: 3,
          rows: 8,
          cellWidth: 71000,
          cellHeight: 37000,
        ),
        throwsArgumentError,
      );
      expect(
        () => SheetLayout(
          pageWidth: 210000,
          pageHeight: 297000,
          columns: 0,
          rows: 1,
          cellWidth: 1,
          cellHeight: 1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('paginate', () {
    test('nothing to print gives nothing', () {
      expect(paginate(sheet, labelCount: 0), isEmpty);
    });

    test('fills a sheet from the first cell, then starts a new page', () {
      final p = paginate(sheet, labelCount: 30);
      expect(p.length, 30);
      expect(p.where((x) => x.page == 0).length, 24);
      expect(p.where((x) => x.page == 1).length, 6);
      expect(p[0].cellIndex, 0);
      expect(p[24].page, 1);
      expect(p[24].cellIndex, 0);
      expect(p.map((x) => x.labelIndex), List.generate(30, (i) => i));
    });

    test('a chosen start cell skips used stickers on the first page only', () {
      final p = paginate(sheet, labelCount: 10, startCell: 20);
      expect(p.take(4).map((x) => (x.page, x.cellIndex)), [
        (0, 20),
        (0, 21),
        (0, 22),
        (0, 23),
      ]);
      expect(p[4].page, 1);
      expect(p[4].cellIndex, 0);
      expect(p.last.cellIndex, 5);
    });

    test('each placement carries the cell rectangle', () {
      final p = paginate(sheet, labelCount: 2, startCell: 1);
      expect(p[0].rect, sheet.cellRect(1));
      expect(p[1].rect, sheet.cellRect(2));
    });

    test('no two labels share a cell on the same page', () {
      final p = paginate(sheet, labelCount: 100, startCell: 7);
      final seen = <(int, int)>{};
      for (final x in p) {
        expect(seen.add((x.page, x.cellIndex)), isTrue);
      }
    });

    test('bad inputs are refused', () {
      expect(() => paginate(sheet, labelCount: -1), throwsArgumentError);
      expect(
        () => paginate(sheet, labelCount: 1, startCell: 24),
        throwsRangeError,
      );
      expect(
        () => paginate(sheet, labelCount: 1, startCell: -1),
        throwsRangeError,
      );
    });
  });

  group('rupee text', () {
    test('rupees and paise with the rupee sign', () {
      expect(formatRupees(const Money(49900)), '₹499.00');
      expect(formatRupees(const Money(49950)), '₹499.50');
      expect(formatRupees(const Money(5)), '₹0.05');
      expect(formatRupees(Money.zero), '₹0.00');
    });

    test('Indian digit grouping (thousands, then lakhs and crores)', () {
      expect(formatRupees(const Money(149950)), '₹1,499.50');
      expect(formatRupees(const Money(10000000)), '₹1,00,000.00');
      expect(formatRupees(const Money(1234567800)), '₹1,23,45,678.00');
    });

    test('a negative amount is refused on a tag', () {
      expect(() => formatRupees(const Money(-1)), throwsArgumentError);
    });
  });

  test('label content exposes the printed MRP and barcode digits', () {
    const barcode = Barcode(year: 26, month: 11, lot: 1, serial: 1);
    final c = LabelContent(
      shopName: 'Shop',
      style: 'Kurta',
      size: 'M',
      color: 'Blue',
      mrp: const Money(49900),
      barcode: barcode,
    );
    expect(c.mrpText, '₹499.00');
    expect(c.barcodeDigits, '261100100013');
  });
}
