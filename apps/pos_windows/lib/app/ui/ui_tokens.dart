import 'package:flutter/material.dart';

/// The neutral colors of the redesign mock-up (the shop's design artifact):
/// page background, hairlines, ink and the status tints. They are not the
/// shop's brand color, which comes from the settings (`brandTheme`).
abstract final class UiColors {
  /// The page behind cards.
  static const Color canvas = Color(0xFFF4F6FA);

  /// A hairline around a card, and a stronger one around a button.
  static const Color line = Color(0xFFE3E6EC);
  static const Color lineStrong = Color(0xFFCBD0DA);
  static const Color lineSoft = Color(0xFFEEF0F4);

  /// Text: main, secondary and muted.
  static const Color ink = Color(0xFF18202F);
  static const Color inkSoft = Color(0xFF4A5366);
  static const Color inkMuted = Color(0xFF5B6475);

  /// Done and "give this back" (white text on it passes 4.5), and its tint.
  static const Color success = Color(0xFF136B3F);
  static const Color successSoft = Color(0xFFE3F5EA);
  static const Color successInk = Color(0xFF0F5C35);

  /// A notice, a break: amber tints with dark amber text.
  static const Color amberSoft = Color(0xFFFFF1D6);
  static const Color amberPage = Color(0xFFFFF8E6);
  static const Color amberChip = Color(0xFFFFE7AD);
  static const Color amberLine = Color(0xFFB7791F);
  static const Color amberBorder = Color(0xFFE8D9AE);
  static const Color amberInk = Color(0xFF6E3B00);

  /// The dimmed backdrop behind a popup.
  static const Color scrim = Color(0x8C18202F);
}
