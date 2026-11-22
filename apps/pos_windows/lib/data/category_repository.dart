// Stock categories (owner, 2026-11-23): groups and categories inside them, set
// up by the owner or a manager (`manageSettings`), and the styles put in them.
// Everyone who may see stock and prices (cashiers too) can read the list for
// the quick lookup filter. The rules (two levels, names, which nodes can take
// styles) are in core_domain. No cost is read here (E-AUTHZ-1).
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';

/// Thrown when a name is blank, too long or has odd characters.
final class InvalidCategoryName implements Exception {
  @override
  String toString() => 'InvalidCategoryName';
}

/// Thrown when another group or category in the same place has that name.
final class CategoryNameTaken implements Exception {
  CategoryNameTaken(this.name);
  final String name;
  @override
  String toString() => 'CategoryNameTaken: $name';
}

/// Thrown when the group or category does not exist.
final class UnknownCategory implements Exception {
  @override
  String toString() => 'UnknownCategory';
}

/// Thrown when a category would be put inside a category (two levels only).
final class TooDeep implements Exception {
  @override
  String toString() => 'TooDeep';
}

/// Thrown when a category is added to a group that already has styles in it:
/// move those styles first.
final class GroupHasStyles implements Exception {
  @override
  String toString() => 'GroupHasStyles';
}

/// Thrown when a group or category still has styles or categories in it.
final class CategoryInUse implements Exception {
  @override
  String toString() => 'CategoryInUse';
}

/// Thrown when a style cannot be put there: it does not exist, or it is a group
/// that has categories under it.
final class NotAssignable implements Exception {
  @override
  String toString() => 'NotAssignable';
}

/// A group or category with how many styles are directly in it.
final class CategoryEntry {
  const CategoryEntry({required this.node, required this.styleCount});
  final CategoryNode node;
  final int styleCount;
}

/// A style and the category it is in (null for none).
final class StyleEntry {
  const StyleEntry({
    required this.id,
    required this.name,
    required this.categoryId,
  });
  final String id;
  final String name;
  final String? categoryId;
}

class CategoryRepository {
  CategoryRepository(
    this._db, {
    required String Function() newId,
    DateTime Function()? now,
  }) : _newId = newId,
       _now = now ?? (() => DateTime.now().toUtc()),
       _writer = AuditedWriter(_db, now: now, newId: newId);

  final AppDatabase _db;
  final String Function() _newId;
  final DateTime Function() _now;
  final AuditedWriter _writer;

  Future<List<CategoryNode>> _nodes() async => [
    for (final r in await _db.select(_db.categories).get())
      CategoryNode(id: r.id, name: r.name, parentId: r.parentId),
  ];

  /// Groups and categories in order (groups by name, each followed by its
  /// categories), with how many styles are directly in each. Needs
  /// `viewStockAndPrices`.
  Future<List<CategoryEntry>> list({required Role? role}) async {
    require(role, Permission.viewStockAndPrices);
    final nodes = sortedTree(await _nodes());
    final counts = {
      for (final r
          in await _db
              .customSelect(
                'SELECT category_id AS c, COUNT(*) AS n FROM products '
                'WHERE category_id IS NOT NULL GROUP BY category_id',
              )
              .get())
        r.read<String>('c'): r.read<int>('n'),
    };
    return [
      for (final n in nodes)
        CategoryEntry(node: n, styleCount: counts[n.id] ?? 0),
    ];
  }

  /// Every style with its category, by name. Needs `viewStockAndPrices`.
  Future<List<StyleEntry>> styles({required Role? role}) async {
    require(role, Permission.viewStockAndPrices);
    final rows = await (_db.select(
      _db.products,
    )..orderBy([(p) => OrderingTerm.asc(p.name)])).get();
    return [
      for (final p in rows)
        StyleEntry(id: p.id, name: p.name, categoryId: p.categoryId),
    ];
  }

  /// The category the style called [name] (capitals ignored) is in, or null.
  Future<String?> categoryOfStyleNamed({
    required Role? role,
    required String name,
  }) async {
    require(role, Permission.viewStockAndPrices);
    final rows = await _db
        .customSelect(
          'SELECT category_id FROM products WHERE lower(name) = lower(?)',
          variables: [Variable<String>(name.trim())],
        )
        .get();
    return rows.isEmpty ? null : rows.first.read<String?>('category_id');
  }

  /// Adds a group (no [parentId]) or a category inside a group. Needs
  /// `manageSettings`. Returns the new id. Throws [InvalidCategoryName],
  /// [CategoryNameTaken], [UnknownCategory], [TooDeep] or [GroupHasStyles].
  Future<String> add({
    required Role? role,
    required String actorId,
    required String name,
    String? parentId,
  }) async {
    require(role, Permission.manageSettings);
    final clean = cleanCategoryName(name);
    if (clean == null) {
      throw InvalidCategoryName();
    }
    final id = _newId();
    final at = _now();
    await _writer.run<void>(
      action: 'category.create',
      entityType: 'category',
      entityId: id,
      actor: actorId,
      details: {'name': clean, 'parentId': parentId},
      body: () async {
        final nodes = await _nodes();
        if (parentId != null) {
          final parent = nodes.where((n) => n.id == parentId).firstOrNull;
          if (parent == null) {
            throw UnknownCategory();
          }
          if (!canHaveChildren(parent)) {
            throw TooDeep();
          }
          final styles =
              (await _db
                      .customSelect(
                        'SELECT COUNT(*) AS n FROM products WHERE category_id = ?',
                        variables: [Variable<String>(parentId)],
                      )
                      .getSingle())
                  .read<int>('n');
          if (styles > 0) {
            throw GroupHasStyles();
          }
        }
        if (nameTaken(nodes, clean, parentId: parentId)) {
          throw CategoryNameTaken(clean);
        }
        await _db
            .into(_db.categories)
            .insert(
              CategoriesCompanion.insert(
                id: id,
                name: clean,
                parentId: Value(parentId),
                createdAt: at,
                updatedAt: at,
              ),
            );
      },
    );
    return id;
  }

  Future<void> rename({
    required Role? role,
    required String actorId,
    required String id,
    required String name,
  }) async {
    require(role, Permission.manageSettings);
    final clean = cleanCategoryName(name);
    if (clean == null) {
      throw InvalidCategoryName();
    }
    final at = _now();
    await _writer.run<void>(
      action: 'category.rename',
      entityType: 'category',
      entityId: id,
      actor: actorId,
      details: {'name': clean},
      body: () async {
        final nodes = await _nodes();
        final node = nodes.where((n) => n.id == id).firstOrNull;
        if (node == null) {
          throw UnknownCategory();
        }
        if (nameTaken(nodes, clean, parentId: node.parentId, exceptId: id)) {
          throw CategoryNameTaken(clean);
        }
        await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
          CategoriesCompanion(name: Value(clean), updatedAt: Value(at)),
        );
      },
    );
  }

  /// Removes an empty group or category. Throws [CategoryInUse] when styles or
  /// categories are still in it.
  Future<void> delete({
    required Role? role,
    required String actorId,
    required String id,
  }) async {
    require(role, Permission.manageSettings);
    await _writer.run<void>(
      action: 'category.delete',
      entityType: 'category',
      entityId: id,
      actor: actorId,
      body: () async {
        final nodes = await _nodes();
        if (!nodes.any((n) => n.id == id)) {
          throw UnknownCategory();
        }
        final styles =
            (await _db
                    .customSelect(
                      'SELECT COUNT(*) AS n FROM products WHERE category_id = ?',
                      variables: [Variable<String>(id)],
                    )
                    .getSingle())
                .read<int>('n');
        if (styles > 0 || nodes.any((n) => n.parentId == id)) {
          throw CategoryInUse();
        }
        await (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
      },
    );
  }

  /// Puts a style in [categoryId], or takes it out of its category when null.
  /// Needs `manageSettings`. Throws [NotAssignable] for a group that has
  /// categories under it or an id that does not exist.
  Future<void> assignStyle({
    required Role? role,
    required String actorId,
    required String styleId,
    required String? categoryId,
  }) async {
    require(role, Permission.manageSettings);
    final at = _now();
    await _writer.run<void>(
      action: 'style.categorize',
      entityType: 'product',
      entityId: styleId,
      actor: actorId,
      details: {'categoryId': categoryId},
      body: () async {
        await setCategoryInTransaction(styleId, categoryId, at);
      },
    );
  }

  /// Checks and sets the category of a style inside a caller's transaction
  /// (also used when stock is received).
  Future<void> setCategoryInTransaction(
    String styleId,
    String? categoryId,
    DateTime at,
  ) async {
    if (categoryId != null && !isAssignable(await _nodes(), categoryId)) {
      throw NotAssignable();
    }
    await (_db.update(_db.products)..where((p) => p.id.equals(styleId))).write(
      ProductsCompanion(categoryId: Value(categoryId), updatedAt: Value(at)),
    );
  }
}
