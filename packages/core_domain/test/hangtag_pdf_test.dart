// The PDF writer: real Noto Sans fonts (SIL OFL 1.1) so the rupee sign prints.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:core_domain/core_domain.dart';
import 'package:core_domain/hangtag_pdf.dart';
import 'package:test/test.dart';

Uint8List font(String name) => File('assets/fonts/$name').readAsBytesSync();

LabelContent label(int serial, {String style = 'Cotton Kurta'}) => LabelContent(
  shopName: 'Sample Apparel',
  style: style,
  size: 'M',
  color: 'Blue',
  mrp: const Money(49900),
  barcode: Barcode(year: 26, month: 11, lot: 1, serial: serial),
);

String text(Uint8List b) => latin1.decode(b);
int pageCount(Uint8List b) =>
    RegExp(r'/Type\s*/Page(?![a-z])').allMatches(text(b)).length;

void main() {
  final regular = font('NotoSans-Regular.ttf');
  final bold = font('NotoSans-Bold.ttf');
  final sheet = SheetLayout.a4ThreeByEight();

  Future<Uint8List> build(
    List<LabelContent> labels, {
    int startCell = 0,
    bool compress = true,
  }) => buildHangtagPdf(
    layout: sheet,
    labels: labels,
    startCell: startCell,
    regularFont: regular,
    boldFont: bold,
    compress: compress,
  );

  test('the bundled fonts have a licence file and the rupee sign', () {
    expect(
      File('assets/fonts/OFL.txt').readAsStringSync(),
      contains('SIL OPEN FONT LICENSE'),
    );
    expect(fontHasGlyphs(regular, '₹0123456789.,'), isTrue);
    expect(fontHasGlyphs(bold, '₹0123456789.,'), isTrue);
  });

  test('one sheet of 24 labels is a single A4 page', () async {
    final pdf = await build([for (var i = 0; i < 24; i++) label(i)]);
    expect(text(pdf).startsWith('%PDF-'), isTrue);
    expect(pageCount(pdf), 1);
    expect(
      text(pdf),
      matches(RegExp(r'/MediaBox\s*\[\s*0\s+0\s+595\.2\d*\s+841\.8\d*\s*\]')),
    );
  });

  test(
    '30 labels need 2 pages; a start cell of 20 with 10 labels needs 2 pages',
    () async {
      expect(
        pageCount(await build([for (var i = 0; i < 30; i++) label(i)])),
        2,
      );
      expect(
        pageCount(
          await build([for (var i = 0; i < 10; i++) label(i)], startCell: 20),
        ),
        2,
      );
      expect(
        pageCount(
          await build([for (var i = 0; i < 4; i++) label(i)], startCell: 20),
        ),
        1,
      );
    },
  );

  test('the fonts are embedded in the file', () async {
    final pdf = await build([label(1)]);
    expect(text(pdf), contains('NotoSans'));
    expect(text(pdf), contains('/FontFile2'));
  });

  test(
    'every bar becomes one rectangle in the page (uncompressed check)',
    () async {
      final labels = [label(1), label(2), label(3)];
      final pdf = await build(labels, compress: false);
      final expectedBars = labels
          .map((l) => layoutHangtag(sheet.cellRect(0), l).bars.length)
          .reduce((a, b) => a + b);
      final rects = RegExp(r'\bre\b').allMatches(text(pdf)).length;
      expect(rects, expectedBars);
    },
  );

  test(
    'a character the font cannot draw is refused, not printed as a box',
    () async {
      await expectLater(
        build([label(1, style: 'कुर्ता')]),
        throwsA(isA<MissingGlyph>()),
      );
    },
  );

  test('nothing to print is refused', () async {
    await expectLater(build([]), throwsArgumentError);
  });

  test('a start cell outside the sheet is refused', () async {
    await expectLater(build([label(1)], startCell: 24), throwsRangeError);
  });

  test('a very long style name still builds (it is shrunk or cut)', () async {
    final pdf = await build([
      label(
        1,
        style: 'Extra long hand block printed cotton kurta with mirror work and tassels',
      ),
    ]);
    expect(pageCount(pdf), 1);
  });
}
