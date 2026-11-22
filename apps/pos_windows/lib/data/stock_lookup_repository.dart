// Stock lookup: does the shop have this style in this size and color, and at
// what MRP? Open to cashiers (viewStockAndPrices), so it never reads the cost
// table (E-AUTHZ-1). Counts only garments that are in stock.
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';

/// One size and color of a style.
final class VariantStock {
  const VariantStock({
    required this.size,
    required this.color,
    required this.mrp,
    required this.inStock,
  });
  final String size;
  final String color;
  final Money mrp;

  /// Garments of this size and color that can be sold now.
  final int inStock;
}

/// One style with all its sizes and colors.
final class StyleStock {
  const StyleStock({required this.name, required this.variants});
  final String name;
  final List<VariantStock> variants;

  int get inStock => variants.fold(0, (a, v) => a + v.inStock);

  /// True when this size and color has at least one garment in stock.
  bool has({required String size, required String color}) =>
      variants.any((v) => v.size == size && v.color == color && v.inStock > 0);
}

class StockLookupRepository {
  StockLookupRepository(this._db);

  final AppDatabase _db;

  /// Styles matching [query] (part of the name, any capitals) or the style of a
  /// 12-digit barcode; an empty query lists every style. Needs
  /// `viewStockAndPrices`. Throws [PermissionDenied].
  Future<List<StyleStock>> search({
    required Role? role,
    required String query,
  }) async {
    require(role, Permission.viewStockAndPrices);
    final q = query.trim();
    final isBarcode = RegExp(r'^\d{12}$').hasMatch(q);
    final escaped = q
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    final where = isBarcode
        ? 'p.id IN (SELECT v2.product_id FROM articles a2 JOIN variants v2 '
              'ON v2.id = a2.variant_id WHERE a2.barcode_value = ?)'
        : q.isEmpty
        ? '1 = 1'
        : "p.name LIKE ? ESCAPE '\\'";
    final rows = await _db
        .customSelect(
          'SELECT p.name AS name, v.size AS size, v.color AS color, '
          'v.mrp_paise AS mrp, '
          "(SELECT COUNT(*) FROM articles a WHERE a.variant_id = v.id AND a.status = 'IN_STOCK') AS n "
          'FROM products p JOIN variants v ON v.product_id = p.id '
          'WHERE $where ORDER BY p.name, v.size, v.color',
          variables: [
            if (isBarcode) Variable<String>(q),
            if (!isBarcode && q.isNotEmpty) Variable<String>('%$escaped%'),
          ],
        )
        .get();
    final byName = <String, List<VariantStock>>{};
    for (final r in rows) {
      byName
          .putIfAbsent(r.read<String>('name'), () => [])
          .add(
            VariantStock(
              size: r.read<String>('size'),
              color: r.read<String>('color'),
              mrp: Money(r.read<int>('mrp')),
              inStock: r.read<int>('n'),
            ),
          );
    }
    return [
      for (final e in byName.entries)
        StyleStock(name: e.key, variants: e.value),
    ];
  }
}
