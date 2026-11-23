// Category chips for the quick lookup and the billing search: All, each group,
// and No category; when a group (or a category in it) is chosen, a second row
// shows the categories inside it. Hidden when the shop has set none up.
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.nodes,
    required this.selected,
    required this.onChanged,
  });

  final List<CategoryNode> nodes;

  /// null for All, [noCategoryFilter], a group id or a category id.
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return const SizedBox.shrink();
    }
    final groups = sortedTree(nodes).where((n) => n.parentId == null).toList();
    final openGroup = selected == null || selected == noCategoryFilter
        ? null
        : groupOf(nodes, selected);
    final inside = openGroup == null
        ? const <CategoryNode>[]
        : sortedTree(nodes).where((n) => n.parentId == openGroup).toList();
    Widget chip(String key, String label, String? value) => ChoiceChip(
      key: Key(key),
      label: Text(label),
      selected: selected == value,
      onSelected: (_) => onChanged(value),
    );
    return Column(
      key: const Key('category-chips'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip('cat-all', 'All categories', null),
            for (final g in groups)
              ChoiceChip(
                key: Key('cat-${g.name}'),
                label: Text(g.name),
                selected: openGroup == g.id,
                onSelected: (_) => onChanged(g.id),
              ),
            chip('cat-none', 'No category', noCategoryFilter),
          ],
        ),
        if (inside.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            key: const Key('category-chips-inside'),
            spacing: 8,
            runSpacing: 8,
            children: [
              chip(
                'cat-all-in-${categoryPath(nodes, openGroup)}',
                'All in ${categoryPath(nodes, openGroup)}',
                openGroup,
              ),
              for (final c in inside)
                chip('cat-${categoryPath(nodes, c.id)}', c.name, c.id),
            ],
          ),
        ],
      ],
    );
  }
}
