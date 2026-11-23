// Stock categories (owner, 2026-11-23): a shop sets up groups and categories
// inside them (Men > Shirts), two levels at most. Each style is put in one
// category; a group with categories under it is not assigned directly, a group
// with none can be used as a category itself. Categories drive the quick
// lookup filter and the analytics. Only the rules are here, no database.

const int maxCategoryNameLength = 40;

/// A category name: trimmed, spaces squeezed, 1 to 40 characters, no control
/// characters. Null when it is not acceptable.
String? cleanCategoryName(String raw) {
  for (final unit in raw.runes) {
    if (unit < 0x20 || (unit >= 0x7F && unit <= 0x9F)) {
      return null;
    }
  }
  final clean = raw.trim().replaceAll(RegExp(r' {2,}'), ' ');
  if (clean.isEmpty || clean.runes.length > maxCategoryNameLength) {
    return null;
  }
  return clean;
}

/// One group or category. A group has no parent.
final class CategoryNode {
  const CategoryNode({required this.id, required this.name, this.parentId});
  final String id;
  final String name;
  final String? parentId;
}

/// Only a group can have categories under it (two levels at most).
bool canHaveChildren(CategoryNode node) => node.parentId == null;

CategoryNode? _find(List<CategoryNode> all, String? id) {
  if (id == null) {
    return null;
  }
  for (final n in all) {
    if (n.id == id) {
      return n;
    }
  }
  return null;
}

/// "Men › Shirts" for a category, "Kids" for a group, "No category" for none
/// (or for a category that no longer exists).
String categoryPath(List<CategoryNode> all, String? id) {
  final node = _find(all, id);
  if (node == null) {
    return 'No category';
  }
  final parent = _find(all, node.parentId);
  return parent == null ? node.name : '${parent.name} › ${node.name}';
}

/// True when a style can be put straight into [id]: it exists and has no
/// categories under it.
bool isAssignable(List<CategoryNode> all, String id) {
  final node = _find(all, id);
  if (node == null) {
    return false;
  }
  return !all.any((n) => n.parentId == id);
}

/// True when [name] (capitals ignored) is already used by another node with
/// the same parent. [exceptId] is the node being renamed.
bool nameTaken(
  List<CategoryNode> all,
  String name, {
  required String? parentId,
  String? exceptId,
}) {
  final lower = name.toLowerCase();
  return all.any(
    (n) =>
        n.parentId == parentId &&
        n.id != exceptId &&
        n.name.toLowerCase() == lower,
  );
}

/// The id of the top-level group [id] rolls up into: its parent, or itself when
/// it is a group. Null for none or an unknown id.
String? groupOf(List<CategoryNode> all, String? id) {
  final node = _find(all, id);
  if (node == null) {
    return null;
  }
  return node.parentId ?? node.id;
}

/// Groups by name, each followed by its categories by name.
List<CategoryNode> sortedTree(List<CategoryNode> all) {
  int byName(CategoryNode a, CategoryNode b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
  final groups = all.where((n) => n.parentId == null).toList()..sort(byName);
  final out = <CategoryNode>[];
  for (final g in groups) {
    out.add(g);
    out.addAll(all.where((n) => n.parentId == g.id).toList()..sort(byName));
  }
  return out;
}

/// The "styles with no category" choice in a filter.
const String noCategoryFilter = '__none__';

/// True when a style in [styleCategoryId] passes the filter [selected]: no
/// filter keeps everything; a group keeps the categories inside it (and styles
/// put in the group itself); a category keeps only its own styles;
/// [noCategoryFilter] keeps styles with none (or whose category was removed).
bool categoryMatches(
  List<CategoryNode> all,
  String? selected,
  String? styleCategoryId,
) {
  if (selected == null) {
    return true;
  }
  final styleNode = _find(all, styleCategoryId);
  if (selected == noCategoryFilter) {
    return styleNode == null;
  }
  if (styleNode == null) {
    return false;
  }
  return styleNode.id == selected || styleNode.parentId == selected;
}

/// Adds up [byCategory] (a number for each category id, or null for none) into
/// one number for each group ([byGroup]) or each category. A category that was
/// removed counts as none. The total never changes.
Map<String?, int> sumByCategory(
  List<CategoryNode> all,
  Map<String?, int> byCategory, {
  required bool byGroup,
}) {
  final out = <String?, int>{};
  byCategory.forEach((id, value) {
    final node = _find(all, id);
    final key = node == null ? null : (byGroup ? groupOf(all, id) : node.id);
    out[key] = (out[key] ?? 0) + value;
  });
  return out;
}
