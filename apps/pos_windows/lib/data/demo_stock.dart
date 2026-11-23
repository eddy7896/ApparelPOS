// Demo stock for development builds only (ADR-0016): when the practice users
// are made, the shop also gets a few styles so billing, returns and the stock
// lookup can be tried straight away. Never runs in a release build, and never
// when the shop already has any style. The figures are made up. With the GST
// service it also seeds TEST GST details (GST switched on, a made-up GSTIN, HSN
// codes, one style with its own rate, supplier GSTIN and input tax) so the GST
// bill, the register's customer GSTIN box and the GST reports can be tried at
// once. None of it is real; every GST rule is unverified until the CA confirms.
import 'package:core_domain/core_domain.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'app_database.dart';
import 'gst_repository.dart';
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

/// Test GST details: a made-up shop GSTIN and a made-up business customer
/// GSTIN to type at the register (both are the right shape, neither is real).
const String demoShopGstin = '27AAAAA0000A1Z5';
const String demoBusinessGstin = '29BBBBB1111B1Z5';
const String demoSupplierGstin = '24CCCCC2222C1Z5';

/// HSN code and own rate (basis points; null uses the shop's 5%) of each demo
/// style. The codes and the 12% on jeans are made up for testing.
const Map<String, (String, int?)> demoStyleGst = {
  'Cotton Kurta': ('6104', null),
  'Denim Jeans': ('6203', 1200),
  'Linen Shirt': ('6205', null),
};

/// Adds the demo styles. Returns how many garments were added; 0 when this is
/// not a development build or the shop already has a style. With [gst] it also
/// seeds the test GST details described above.
Future<int> seedDemoStock(
  AppDatabase db,
  StockRepository stock, {
  GstRepository? gst,
}) async {
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
  var invoice = 0;
  for (final entry in demoStyles.entries) {
    final codes = gst == null ? null : demoStyleGst[entry.key];
    final goods = entry.value.fold<int>(0, (a, l) => a + l.$3 * l.$4 * 100);
    invoice++;
    await stock.receivePurchase(
      role: Role.owner,
      draft: PurchaseDraft(
        supplier: 'Demo supplier',
        style: entry.key,
        hsn: codes?.$1 ?? '',
        styleGstBp: codes?.$2,
        supplierGstin: gst == null ? '' : demoSupplierGstin,
        invoiceNo: gst == null ? '' : 'DEMO/00$invoice',
        // 5% of the goods value as the tax paid on the purchase
        inputTax: gst == null ? Money.zero : Money(goods).percentBp(500),
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
  if (gst != null) {
    await gst.save(
      role: Role.owner,
      actorId: 'demo',
      settings: const GstSettings(
        enabled: true,
        gstin: demoShopGstin,
        address: 'Demo Shop (test data), 12 Market Road, Pune',
      ),
    );
  }
  return garments;
}
