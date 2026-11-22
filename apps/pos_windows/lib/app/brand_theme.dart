import 'package:flutter/material.dart';

import '../data/brand.dart';
import 'ui/ui_tokens.dart';

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
  final radius = BorderRadius.circular(12);
  const hairline = BorderSide(color: UiColors.line);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: UiColors.canvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: UiColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      shape: Border(bottom: hairline),
      titleTextStyle: TextStyle(
        color: UiColors.ink,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: hairline,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: UiColors.lineStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: UiColors.lineStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: target,
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: target,
        foregroundColor: UiColors.ink,
        side: const BorderSide(color: UiColors.lineStrong),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: target),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
  );
}
