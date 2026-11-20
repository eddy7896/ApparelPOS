import 'package:flutter/material.dart';

/// Shows the A4 sticker sheet as a grid so the user can pick the first free
/// cell (cells are numbered 1 to 24, left to right, top to bottom).
class StartCellPicker extends StatelessWidget {
  const StartCellPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.columns = 3,
    this.rows = 8,
  });

  /// The chosen cell, counted from 1.
  final int selected;
  final ValueChanged<int> onSelected;
  final int columns;
  final int rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows; r++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var c = 0; c < columns; c++)
                _cell(context, scheme, r * columns + c + 1),
            ],
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, ColorScheme scheme, int number) {
    final used = number < selected; // earlier cells are skipped
    final chosen = number == selected;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: SizedBox(
        width: 64,
        height: 34,
        child: Material(
          color: chosen
              ? scheme.primary
              : used
              ? scheme.surfaceContainerHighest
              : scheme.primaryContainer,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            key: Key('cell-$number'),
            borderRadius: BorderRadius.circular(4),
            onTap: () => onSelected(number),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: chosen ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: chosen ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
