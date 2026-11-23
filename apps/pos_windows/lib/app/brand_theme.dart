import 'package:flutter/material.dart';

import '../data/brand.dart';

Color _color(int rgb) => Color(0xFF000000 | rgb);

/// The app theme built from the shop's one main color (Material 3). The palette
/// keeps text on the main color white and readable; see core_domain's brand rules.
ThemeData brandTheme(Brand brand) {
  final p = brand.palette;
  final scheme = ColorScheme.fromSeed(seedColor: _color(p.primary)).copyWith(
    primary: _color(p.primary),
    onPrimary: _color(p.onPrimary),
    primaryContainer: _color(p.soft),
    onPrimaryContainer: _color(p.ink),
  );
  const target = Size(64, 48); // owner, Q1: touch targets at least 48 dp
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: target),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: target),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: target),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
  );
}
