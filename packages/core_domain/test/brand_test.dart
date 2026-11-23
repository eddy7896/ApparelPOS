import 'dart:typed_data';

import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

/// A PNG header of the given size (signature, IHDR length and name, width, height).
Uint8List png(int w, int h, {int extra = 0}) {
  final b = BytesBuilder();
  b.add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  b.add([0, 0, 0, 13]);
  b.add('IHDR'.codeUnits);
  b.add([w >> 24, (w >> 16) & 255, (w >> 8) & 255, w & 255]);
  b.add([h >> 24, (h >> 16) & 255, (h >> 8) & 255, h & 255]);
  b.add([8, 6, 0, 0, 0]);
  b.add(List.filled(extra, 0));
  return b.toBytes();
}

/// A JPEG with one APP0 segment and a baseline frame header of the given size.
Uint8List jpeg(int w, int h, {int extra = 0}) {
  final b = BytesBuilder();
  b.add([0xFF, 0xD8]);
  b.add([
    0xFF,
    0xE0,
    0,
    16,
    0x4A,
    0x46,
    0x49,
    0x46,
    0,
    1,
    1,
    0,
    0,
    1,
    0,
    1,
    0,
    0,
  ]);
  b.add([
    0xFF,
    0xC0,
    0,
    17,
    8,
    h >> 8,
    h & 255,
    w >> 8,
    w & 255,
    3,
    1,
    0x22,
    0,
    2,
    0x11,
    1,
    3,
    0x11,
    1,
  ]);
  b.add(List.filled(extra, 0));
  return b.toBytes();
}

void main() {
  group('cleanShopName', () {
    test('trims and squeezes spaces', () {
      expect(
        cleanShopName('  Sri   Lakshmi  Textiles '),
        'Sri Lakshmi Textiles',
      );
    });
    test('blank is refused', () {
      expect(cleanShopName(''), isNull);
      expect(cleanShopName('   '), isNull);
    });
    test(
      'longer than $maxShopNameLength characters is refused, exactly that is fine',
      () {
        expect(cleanShopName('a' * maxShopNameLength), 'a' * maxShopNameLength);
        expect(cleanShopName('a' * (maxShopNameLength + 1)), isNull);
      },
    );
    test(
      'control characters are refused; letters from any script are fine',
      () {
        expect(cleanShopName('Shop\u0000Name'), isNull);
        expect(cleanShopName('Shop\nName'), isNull);
        expect(cleanShopName('Ünïcode Straße'), 'Ünïcode Straße');
      },
    );
  });

  group('BrandColor', () {
    test('parses #RRGGBB in any case, with or without the #', () {
      expect(BrandColor.tryParse('#2B3A9F')!.rgb, 0x2B3A9F);
      expect(BrandColor.tryParse('2b3a9f')!.rgb, 0x2B3A9F);
      expect(BrandColor.tryParse(' #2b3A9f ')!.rgb, 0x2B3A9F);
    });
    test('prints as upper case #RRGGBB', () {
      expect(BrandColor.tryParse('2b3a9f')!.hex, '#2B3A9F');
      expect(BrandColor(0x0000FF).hex, '#0000FF');
      expect(BrandColor(0x00000A).hex, '#00000A');
    });
    test('anything else is not a color', () {
      for (final bad in [
        '',
        '#fff',
        '2B3A9',
        '#2B3A9FF',
        'blue',
        '#GGGGGG',
        '##2B3A9F',
        '0x2B3A9F',
      ]) {
        expect(BrandColor.tryParse(bad), isNull, reason: bad);
      }
    });
    test('the constructor refuses values outside 24 bits', () {
      expect(() => BrandColor(-1), throwsArgumentError);
      expect(() => BrandColor(0x1000000), throwsArgumentError);
    });
    test('contrast follows the WCAG formula: black on white is 21, #767676 on white is 4.54', () {
      expect(contrastRatio(0xFFFFFF, 0x000000), closeTo(21.0, 0.001));
      expect(contrastRatio(0x000000, 0xFFFFFF), closeTo(21.0, 0.001));
      expect(contrastRatio(0x767676, 0xFFFFFF), closeTo(4.54, 0.01));
      expect(contrastRatio(0x777777, 0xFFFFFF), closeTo(4.48, 0.01));
      expect(contrastRatio(0x123456, 0x123456), closeTo(1.0, 0.0001));
    });
    test('readable means white text on it has contrast of at least 4.5', () {
      expect(BrandColor(0x767676).isReadable, isTrue);
      expect(BrandColor(0x777777).isReadable, isFalse);
      expect(BrandColor.tryParse('#FFEB3B')!.isReadable, isFalse); // yellow
      expect(BrandColor.tryParse('#FFFFFF')!.isReadable, isFalse);
      expect(BrandColor.tryParse('#000000')!.isReadable, isTrue);
    });
  });

  group('the tested colors', () {
    test('every one is readable with white text', () {
      expect(testedBrandColors.length, greaterThanOrEqualTo(8));
      for (final c in testedBrandColors) {
        expect(c.color.isReadable, isTrue, reason: '${c.name} ${c.color.hex}');
        expect(contrastRatio(0xFFFFFF, c.color.rgb), greaterThanOrEqualTo(4.5));
      }
    });
    test('names and colors are unique', () {
      expect(
        {for (final c in testedBrandColors) c.name}.length,
        testedBrandColors.length,
      );
      expect(
        {for (final c in testedBrandColors) c.color.rgb}.length,
        testedBrandColors.length,
      );
    });
    test('the placeholder color is one of them', () {
      expect(
        testedBrandColors.map((c) => c.color.hex),
        contains(placeholderBrandColorHex),
      );
    });
  });

  group('Palette', () {
    final p = Palette.fromPrimary(BrandColor(0x2B3A9F));
    test('primary is the chosen color and text on it is white', () {
      expect(p.primary, 0x2B3A9F);
      expect(p.onPrimary, 0xFFFFFF);
    });
    test('the soft tint is mostly white but still tinted', () {
      expect(p.soft, isNot(0xFFFFFF));
      expect(contrastRatio(p.soft, 0xFFFFFF), lessThan(1.5));
      // dark text stays readable on the soft tint
      expect(contrastRatio(p.ink, p.soft), greaterThan(7));
    });
    test('the deep shade is darker than the primary', () {
      expect(
        contrastRatio(p.deep, 0xFFFFFF),
        greaterThan(contrastRatio(p.primary, 0xFFFFFF)),
      );
    });
    test('every tested color gives a palette whose text stays readable', () {
      for (final c in testedBrandColors) {
        final q = Palette.fromPrimary(c.color);
        expect(
          contrastRatio(q.onPrimary, q.primary),
          greaterThanOrEqualTo(4.5),
          reason: c.name,
        );
        expect(
          contrastRatio(q.ink, q.soft),
          greaterThanOrEqualTo(7),
          reason: c.name,
        );
      }
    });
    test('an unreadable color is refused, not quietly fixed', () {
      expect(
        () => Palette.fromPrimary(BrandColor(0xFFEB3B)),
        throwsArgumentError,
      );
    });
  });

  group('checkLogo', () {
    test('a small PNG and a small JPEG are fine, and report their size', () {
      final a = checkLogo(png(200, 120));
      expect(a.ok, isTrue);
      expect((a.format, a.width, a.height), (LogoFormat.png, 200, 120));
      final b = checkLogo(jpeg(300, 300));
      expect(b.ok, isTrue);
      expect((b.format, b.width, b.height), (LogoFormat.jpeg, 300, 300));
    });
    test('the largest allowed picture is $maxLogoSide by $maxLogoSide', () {
      expect(checkLogo(png(maxLogoSide, maxLogoSide)).ok, isTrue);
      expect(checkLogo(png(maxLogoSide + 1, 100)).problem, LogoProblem.tooWide);
      expect(checkLogo(png(100, maxLogoSide + 1)).problem, LogoProblem.tooWide);
      expect(
        checkLogo(jpeg(maxLogoSide + 1, 100)).problem,
        LogoProblem.tooWide,
      );
    });
    test('very small pictures are refused', () {
      expect(checkLogo(png(15, 100)).problem, LogoProblem.tooSmall);
      expect(checkLogo(png(100, 15)).problem, LogoProblem.tooSmall);
      expect(checkLogo(png(minLogoSide, minLogoSide)).ok, isTrue);
    });
    test('a file bigger than $maxLogoBytes bytes is refused', () {
      expect(
        checkLogo(png(100, 100, extra: maxLogoBytes)).problem,
        LogoProblem.tooBig,
      );
      expect(
        checkLogo(png(100, 100, extra: maxLogoBytes - 29)).ok,
        isTrue,
      ); // exactly the limit
    });
    test('other kinds of file are not pictures we accept', () {
      expect(checkLogo(Uint8List(0)).problem, LogoProblem.notAPicture);
      expect(
        checkLogo(Uint8List.fromList('GIF89a'.codeUnits + List.filled(40, 0)))
            .problem,
        LogoProblem.notAPicture,
      );
      expect(
        checkLogo(Uint8List.fromList('<svg xmlns="x"></svg>'.codeUnits))
            .problem,
        LogoProblem.notAPicture,
      );
      expect(
        checkLogo(Uint8List.fromList(List.filled(100, 7))).problem,
        LogoProblem.notAPicture,
      );
    });
    test('a cut-off PNG or JPEG is refused instead of crashing', () {
      expect(
        checkLogo(png(100, 100).sublist(0, 20)).problem,
        LogoProblem.notAPicture,
      );
      expect(
        checkLogo(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 16, 1]))
            .problem,
        LogoProblem.notAPicture,
      );
      expect(
        checkLogo(Uint8List.fromList([0xFF, 0xD8])).problem,
        LogoProblem.notAPicture,
      );
    });
    test('a JPEG with the frame header after other segments is still read', () {
      final b = BytesBuilder()
        ..add([0xFF, 0xD8])
        ..add([0xFF, 0xE1, 0, 8, 1, 2, 3, 4, 5, 6])
        ..add([0xFF, 0xDB, 0, 5, 1, 2, 3])
        ..add([
          0xFF,
          0xC2,
          0,
          17,
          8,
          0,
          64,
          0,
          96,
          3,
          1,
          0x22,
          0,
          2,
          0x11,
          1,
          3,
          0x11,
          1,
        ]);
      final r = checkLogo(b.toBytes());
      expect(r.ok, isTrue);
      expect((r.width, r.height), (96, 64));
    });
    test('a Huffman table segment (FFC4) before the frame header is skipped, not read as the size', () {
      final b = BytesBuilder()
        ..add([0xFF, 0xD8])
        ..add([0xFF, 0xC4, 0, 8, 0, 1, 2, 3, 4, 5])
        ..add([
          0xFF,
          0xC0,
          0,
          17,
          8,
          0,
          80,
          0,
          90,
          3,
          1,
          0x22,
          0,
          2,
          0x11,
          1,
          3,
          0x11,
          1,
        ]);
      final r = checkLogo(b.toBytes());
      expect((r.width, r.height), (90, 80));
    });
    test('a PNG with a wrong first chunk is refused', () {
      final bytes = png(100, 100);
      bytes[12] = 'X'.codeUnitAt(0);
      expect(checkLogo(bytes).problem, LogoProblem.notAPicture);
    });
    test('zero size is refused', () {
      expect(checkLogo(png(0, 100)).ok, isFalse);
    });
  });

  group('the placeholder', () {
    test('has a name, a readable color and no logo', () {
      expect(placeholderShopName, isNotEmpty);
      expect(cleanShopName(placeholderShopName), placeholderShopName);
      expect(BrandColor.tryParse(placeholderBrandColorHex)!.isReadable, isTrue);
    });
  });

  group('who may change the look', () {
    test('manager and owner, never a cashier', () {
      expect(can(Role.cashier, Permission.manageSettings), isFalse);
      expect(can(Role.manager, Permission.manageSettings), isTrue);
      expect(can(Role.owner, Permission.manageSettings), isTrue);
    });
  });
}
