// The shop's look as data, not code (owner, 2026-11-22): a shop name, one main
// color and a logo are settings; the app ships with a placeholder. The owner's
// mobile app sets them in Release 2; until then there is no settings screen.
// This file holds the rules only: what a valid name, color and logo are, and the
// palette built from the one color. Colors are 24-bit RGB integers (no Flutter).
//
// Contrast uses the WCAG 2.1 relative luminance formula (ratio of (L1 + 0.05) to
// (L2 + 0.05)); it is the only place doubles appear, and none of it is money.

import 'dart:math' as math;
import 'dart:typed_data';

/// The name shown until the owner sets one.
const String placeholderShopName = 'Your Shop';

/// The main color used until the owner sets one: an indigo that is readable
/// with white text.
const String placeholderBrandColorHex = '#2B3A9F';

/// A shop name is at most this many characters (hangtags and bills shorten it
/// further to fit).
const int maxShopNameLength = 40;

/// The cleaned shop name, or null when [raw] is not a usable name: surrounding
/// and repeated spaces are removed; blank, longer than [maxShopNameLength], or
/// holding control characters (such as a new line) is refused.
String? cleanShopName(String raw) {
  for (final unit in raw.runes) {
    if (unit < 0x20 && unit != 0x20 || (unit >= 0x7F && unit <= 0x9F)) {
      return null;
    }
  }
  final clean = raw.trim().replaceAll(RegExp(r' {2,}'), ' ');
  if (clean.isEmpty || clean.runes.length > maxShopNameLength) {
    return null;
  }
  return clean;
}

double _channel(int c) {
  final s = c / 255;
  return s <= 0.03928
      ? s / 12.92
      : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(int rgb) =>
    0.2126 * _channel((rgb >> 16) & 255) +
    0.7152 * _channel((rgb >> 8) & 255) +
    0.0722 * _channel(rgb & 255);

/// The WCAG contrast ratio between two 24-bit RGB colors: 1 (same) to 21
/// (black on white). Order does not matter.
double contrastRatio(int a, int b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

int _mix(int from, int to, double toShare) {
  int part(int shift) {
    final f = (from >> shift) & 255;
    final t = (to >> shift) & 255;
    return (f + (t - f) * toShare).round().clamp(0, 255);
  }

  return (part(16) << 16) | (part(8) << 8) | part(0);
}

/// One color, as 24-bit RGB.
final class BrandColor {
  BrandColor(this.rgb) {
    if (rgb < 0 || rgb > 0xFFFFFF) {
      throw ArgumentError.value(rgb, 'rgb', 'must be 0 to 0xFFFFFF');
    }
  }

  /// Reads `#RRGGBB` (any case, the `#` optional, spaces around ignored), or
  /// null.
  static BrandColor? tryParse(String text) {
    final m = RegExp(r'^#?([0-9A-Fa-f]{6})$').firstMatch(text.trim());
    return m == null ? null : BrandColor(int.parse(m.group(1)!, radix: 16));
  }

  final int rgb;

  /// `#RRGGBB`, upper case.
  String get hex => '#${rgb.toRadixString(16).toUpperCase().padLeft(6, '0')}';

  /// True when white text on this color has a contrast ratio of at least 4.5.
  bool get isReadable => contrastRatio(0xFFFFFF, rgb) >= 4.5;

  @override
  bool operator ==(Object other) => other is BrandColor && other.rgb == rgb;

  @override
  int get hashCode => rgb.hashCode;

  @override
  String toString() => 'BrandColor($hex)';
}

/// A named color the owner can pick without worrying about readability.
final class NamedBrandColor {
  const NamedBrandColor(this.name, this.hexText);
  final String name;
  final String hexText;
  BrandColor get color => BrandColor.tryParse(hexText)!;
}

/// Colors tested to be readable with white text (a test checks each one).
const List<NamedBrandColor> testedBrandColors = [
  NamedBrandColor('Indigo', '#2B3A9F'),
  NamedBrandColor('Ocean blue', '#0B5CAB'),
  NamedBrandColor('Navy', '#1B3A6B'),
  NamedBrandColor('Teal', '#0F6B6B'),
  NamedBrandColor('Forest green', '#1F6B3A'),
  NamedBrandColor('Maroon', '#8B1E2D'),
  NamedBrandColor('Plum', '#6A2C70'),
  NamedBrandColor('Rust', '#A0410D'),
  NamedBrandColor('Charcoal', '#2F3640'),
];

/// The few colors the screens use, built from the one main color.
final class Palette {
  Palette._(this.primary, this.onPrimary, this.soft, this.deep, this.ink);

  /// Builds the palette for [color]. Throws [ArgumentError] if white text on it
  /// would be hard to read (the app asks the owner for another color, it does
  /// not quietly change it).
  factory Palette.fromPrimary(BrandColor color) {
    if (!color.isReadable) {
      throw ArgumentError.value(
        color.hex,
        'color',
        'is too light for white text',
      );
    }
    return Palette._(
      color.rgb,
      0xFFFFFF,
      _mix(color.rgb, 0xFFFFFF, 0.90),
      _mix(color.rgb, 0x000000, 0.25),
      0x18202F,
    );
  }

  /// Buttons and bars.
  final int primary;

  /// Text and icons on [primary] (white).
  final int onPrimary;

  /// A light tint for selected rows and chips.
  final int soft;

  /// A darker shade of [primary] for pressed states.
  final int deep;

  /// Body text.
  final int ink;
}

enum LogoFormat { png, jpeg }

enum LogoProblem { notAPicture, tooBig, tooSmall, tooWide }

/// The largest logo file accepted (256 KB).
const int maxLogoBytes = 256 * 1024;

/// The largest logo side in pixels.
const int maxLogoSide = 512;

/// The smallest logo side in pixels.
const int minLogoSide = 16;

/// What [checkLogo] found.
final class LogoCheck {
  const LogoCheck.ok(this.format, this.width, this.height) : problem = null;
  const LogoCheck.bad(this.problem)
    : format = null,
      width = null,
      height = null;

  final LogoFormat? format;
  final int? width;
  final int? height;
  final LogoProblem? problem;

  bool get ok => problem == null;
}

(int, int)? _pngSize(Uint8List b) {
  const signature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  if (b.length < 24) {
    return null;
  }
  for (var i = 0; i < 8; i++) {
    if (b[i] != signature[i]) {
      return null;
    }
  }
  if (String.fromCharCodes(b.sublist(12, 16)) != 'IHDR') {
    return null;
  }
  int word(int at) =>
      (b[at] << 24) | (b[at + 1] << 16) | (b[at + 2] << 8) | b[at + 3];
  return (word(16), word(20));
}

(int, int)? _jpegSize(Uint8List b) {
  if (b.length < 4 || b[0] != 0xFF || b[1] != 0xD8) {
    return null;
  }
  var i = 2;
  while (i + 4 <= b.length) {
    if (b[i] != 0xFF) {
      return null;
    }
    final marker = b[i + 1];
    if (marker == 0xFF) {
      i++;
      continue;
    }
    final length = (b[i + 2] << 8) | b[i + 3];
    final isFrame =
        marker >= 0xC0 &&
        marker <= 0xCF &&
        marker != 0xC4 &&
        marker != 0xC8 &&
        marker != 0xCC;
    if (isFrame) {
      if (i + 9 > b.length) {
        return null;
      }
      return ((b[i + 7] << 8) | b[i + 8], (b[i + 5] << 8) | b[i + 6]);
    }
    if (length < 2) {
      return null;
    }
    i += 2 + length;
  }
  return null;
}

/// Checks a picture for use as the shop logo: a PNG or JPEG, at most
/// [maxLogoBytes], each side from [minLogoSide] to [maxLogoSide]. It reads only
/// the header; it never decodes the picture.
LogoCheck checkLogo(Uint8List bytes) {
  final png = _pngSize(bytes);
  final jpeg = png == null ? _jpegSize(bytes) : null;
  final size = png ?? jpeg;
  if (size == null) {
    return const LogoCheck.bad(LogoProblem.notAPicture);
  }
  if (bytes.length > maxLogoBytes) {
    return const LogoCheck.bad(LogoProblem.tooBig);
  }
  final (w, h) = size;
  if (w < minLogoSide || h < minLogoSide) {
    return const LogoCheck.bad(LogoProblem.tooSmall);
  }
  if (w > maxLogoSide || h > maxLogoSide) {
    return const LogoCheck.bad(LogoProblem.tooWide);
  }
  return LogoCheck.ok(png != null ? LogoFormat.png : LogoFormat.jpeg, w, h);
}
