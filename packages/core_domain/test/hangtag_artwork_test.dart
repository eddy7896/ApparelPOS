// Hangtag artwork: where each bar and line of text goes inside one label cell.
// All lengths are whole micrometres. The PDF writer only draws what this says.
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

const barcode = Barcode(year: 26, month: 11, lot: 123, serial: 4567);

LabelContent content({
  String style = 'Cotton Kurta',
  Money mrp = const Money(49900),
}) => LabelContent(
  shopName: 'Sample Apparel',
  style: style,
  size: 'M',
  color: 'Blue',
  mrp: mrp,
  barcode: barcode,
);

void main() {
  final cell = SheetLayout.a4ThreeByEight().cellRect(0);
  final art = layoutHangtag(cell, content());

  group('bars', () {
    test('black bars reproduce the Code 128 runs exactly', () {
      final runs = code128CRuns(barcode.value);
      final unit = art.moduleWidth;
      var x = art.bars.first.left;
      final expected = <Rect>[];
      for (var i = 0; i < runs.length; i++) {
        if (i.isEven) {
          expected.add(
            Rect(
              left: x,
              top: art.bars.first.top,
              width: runs[i] * unit,
              height: art.bars.first.height,
            ),
          );
        }
        x += runs[i] * unit;
      }
      expect(art.bars, expected);
    });

    test('bars never overlap and are in left-to-right order', () {
      for (var i = 1; i < art.bars.length; i++) {
        final a = art.bars[i - 1];
        expect(a.left + a.width < art.bars[i].left, isTrue, reason: 'bar $i');
      }
    });

    test('quiet zone of at least 10 modules on each side inside the label', () {
      final first = art.bars.first;
      final last = art.bars.last;
      final cellInner = art.innerArea;
      expect(first.left - cellInner.left >= 10 * art.moduleWidth, isTrue);
      expect(
        cellInner.left + cellInner.width - (last.left + last.width) >=
            10 * art.moduleWidth,
        isTrue,
      );
    });

    test('module is wide enough to scan (at least 0.19 mm) and a whole micrometre count', () {
      expect(art.moduleWidth >= 190, isTrue);
      expect(art.moduleWidth, isA<int>());
    });

    test(
      'bars are tall enough to scan (at least 8 mm) and inside the label',
      () {
        for (final b in art.bars) {
          expect(b.height >= 8000, isTrue);
          expect(
            b.top >= cell.top && b.top + b.height <= cell.top + cell.height,
            isTrue,
          );
        }
      },
    );
  });

  group('text', () {
    test('has shop, style, size and color, MRP and the barcode digits', () {
      expect(art.texts.map((t) => t.text), [
        'Sample Apparel',
        'Cotton Kurta',
        'Size M   Color Blue',
        '₹499.00',
        barcode.value,
      ]);
    });

    test('MRP is bold and the biggest text', () {
      final mrp = art.texts.firstWhere((t) => t.text == '₹499.00');
      expect(mrp.bold, isTrue);
      for (final t in art.texts) {
        expect(mrp.fontSizePt >= t.fontSizePt, isTrue);
      }
    });

    test('every text box is inside the label and none touches a bar or another box', () {
      for (final t in art.texts) {
        expect(t.box.left >= cell.left && t.box.top >= cell.top, isTrue);
        expect(t.box.left + t.box.width <= cell.left + cell.width, isTrue);
        expect(t.box.top + t.box.height <= cell.top + cell.height, isTrue);
        for (final b in art.bars) {
          expect(t.box.overlaps(b), isFalse, reason: t.text);
        }
      }
      for (var i = 0; i < art.texts.length; i++) {
        for (var j = i + 1; j < art.texts.length; j++) {
          expect(art.texts[i].box.overlaps(art.texts[j].box), isFalse);
        }
      }
    });
  });

  group('placement', () {
    test('another cell gives the same artwork moved by the cell offset', () {
      final other = SheetLayout.a4ThreeByEight().cellRect(5);
      final moved = layoutHangtag(other, content());
      final dx = other.left - cell.left;
      final dy = other.top - cell.top;
      expect(moved.bars.length, art.bars.length);
      for (var i = 0; i < art.bars.length; i++) {
        expect(moved.bars[i].left, art.bars[i].left + dx);
        expect(moved.bars[i].top, art.bars[i].top + dy);
      }
      for (var i = 0; i < art.texts.length; i++) {
        expect(moved.texts[i].box.left, art.texts[i].box.left + dx);
        expect(moved.texts[i].box.top, art.texts[i].box.top + dy);
      }
    });

    test('a cell too small to scan is refused', () {
      const tiny = Rect(left: 0, top: 0, width: 25000, height: 37125);
      expect(() => layoutHangtag(tiny, content()), throwsArgumentError);
      const flat = Rect(left: 0, top: 0, width: 70000, height: 20000);
      expect(() => layoutHangtag(flat, content()), throwsArgumentError);
    });
  });

  group('fitText', () {
    double widthAt(String s, double size) => s.length * size * 0.5;

    test('keeps the size when it fits', () {
      final f = fitText(
        'Kurta',
        maxWidthPt: 100,
        startSizePt: 10,
        minSizePt: 6,
        widthAt: widthAt,
      );
      expect((f.text, f.sizePt), ('Kurta', 10.0));
    });

    test('shrinks (down to the minimum) before cutting', () {
      // 20 chars at 10pt = 100pt; limit 80 -> 8pt fits.
      final f = fitText(
        'abcdefghijklmnopqrst',
        maxWidthPt: 80,
        startSizePt: 10,
        minSizePt: 6,
        widthAt: widthAt,
      );
      expect(f.text, 'abcdefghijklmnopqrst');
      expect(f.sizePt <= 8.0 && f.sizePt >= 6.0, isTrue);
      expect(widthAt(f.text, f.sizePt) <= 80, isTrue);
    });

    test('cuts with three dots when even the minimum size is too wide', () {
      final f = fitText(
        'a' * 60,
        maxWidthPt: 50,
        startSizePt: 10,
        minSizePt: 6,
        widthAt: widthAt,
      );
      expect(f.sizePt, 6.0);
      expect(f.text.endsWith('...'), isTrue);
      expect(widthAt(f.text, f.sizePt) <= 50, isTrue);
      expect(f.text.length < 60, isTrue);
    });

    test('empty text stays empty', () {
      final f = fitText(
        '',
        maxWidthPt: 50,
        startSizePt: 10,
        minSizePt: 6,
        widthAt: widthAt,
      );
      expect(f.text, '');
    });
  });
}
