// Demo stock for development builds only (ADR-0016): when the practice users
// are made, the shop also gets a few styles so billing, returns and the stock
// lookup can be tried straight away. Never runs in a release build, and never
// when the shop already has any style. The figures are made up.
import 'package:core_domain/core_domain.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'app_database.dart';
import 'stock_repository.dart';

/// One purchase per style: (size, color, how many, cost in rupees, MRP in rupees).
const Map<String, List<(String, String, int, int, int)>> demoStyles = {
  'Cotton Kurta': [
    ('M', 'Blue', 3, 220, 499),
    ('L', 'Blue', 3, 220, 499),
    ('XL', 'Blue', 2, 220, 499),
    ('M', 'White', 2, 220, 499),
    ('L', 'White', 2, 220, 499),
  ],
  'Denim Jeans': [
    ('M', 'Black', 2, 650, 1299),
    ('L', 'Black', 2, 650, 1299),
    ('XL', 'Black', 1, 650, 1299),
    ('L', 'Blue', 2, 650, 1299),
  ],
  'Linen Shirt': [
    ('S', 'White', 2, 420, 899),
    ('M', 'White', 2, 420, 899),
    ('L', 'White', 2, 420, 899),
    ('M', 'Blue', 1, 420, 899),
  ],
};

/// Adds the demo styles. Returns how many garments were added; 0 when this is
/// not a development build or the shop already has a style.
Future<int> seedDemoStock(AppDatabase db, StockRepository stock) async {
  if (!kDebugMode) {
    return 0;
  }
  final existing = await db
      .customSelect('SELECT COUNT(*) AS c FROM products')
      .getSingle();
  if (existing.read<int>('c') > 0) {
    return 0;
  }
  await stock.seedDefaultOptions();
  var garments = 0;
  for (final entry in demoStyles.entries) {
    await stock.receivePurchase(
      role: Role.owner,
      draft: PurchaseDraft(
        supplier: 'Demo supplier',
        style: entry.key,
        lines: [
          for (final (size, color, qty, cost, mrp) in entry.value)
            PurchaseLine(
              size: size,
              color: color,
              quantity: qty,
              cost: Money.rupees(cost),
              mrp: Money.rupees(mrp),
            ),
        ],
      ),
    );
    garments += entry.value.fold(0, (a, l) => a + l.$3);
  }
  return garments;
}
