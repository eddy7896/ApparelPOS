import 'package:flutter/material.dart';

/// Chart colors (the validated data-visualisation palette). They are data
/// colors, not the shop's brand color: a shop's look does not recolor a chart.
/// One blue family carries magnitude; red and blue carry short and over.
abstract final class ChartColors {
  /// The main series: this period's line, ranked bars.
  static const Color series = Color(0xFF2A78D6);

  /// A light step of the same blue for columns that are not the emphasis.
  static const Color seriesLight = Color(0xFF86B6EF);

  /// A dark step of the same blue for the emphasis (the peak hour, today).
  static const Color seriesDark = Color(0xFF1C5CAB);

  /// The period before: a quiet grey dashed line.
  static const Color previous = Color(0xFF898781);

  /// Cash over (more than expected) and short (less than expected).
  static const Color over = Color(0xFF256ABF);
  static const Color short = Color(0xFFD03B3B);

  static const Color grid = Color(0xFFE1E0D9);
  static const Color axis = Color(0xFFC3C2B7);
  static const Color mutedText = Color(0xFF7A7872);

  /// A slow mover warning: dark amber text with an icon (never color alone).
  static const Color caution = Color(0xFF8A5A00);
}
