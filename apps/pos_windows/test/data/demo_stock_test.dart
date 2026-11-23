// Demo stock for development builds (ADR-0016). Tests run in debug mode, so
// the debug-only guard is on; the release guard is a kDebugMode check.
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/demo_stock.dart';
import 'package:pos_windows/data/gst_repository.dart';
import 'package:pos_windows/data/gst_report_repository.dart';
import 'package:pos_windows/data/sales_repository.dart';
import 'package:pos_windows/data/stock_lookup_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late StockRepository stock;
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    stock = StockRepository(db, newId: newId);
    await stock.ensureCounter();
  });
  tearDown(() => db.close());

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle())
          .read<int>('c');

  final expected = demoStyles.values.fold<int>(
    0,
    (a, lines) => a + lines.fold<int>(0, (b, l) => b + l.$3),
  );

  test('adds the demo styles, each garment with its own barcode', () async {
    expect(await seedDemoStock(db, stock), expected);
    expect(await count('products'), demoStyles.length);
    expect(await count('articles'), expected);
    final codes = await db
        .customSelect('SELECT COUNT(DISTINCT barcode_value) AS c FROM articles')
        .getSingle();
    expect(codes.read<int>('c'), expected);
    final inStock = await count("articles WHERE status = 'IN_STOCK'");
    expect(inStock, expected);
  });

  test('the stock lookup finds it right away', () async {
    await seedDemoStock(db, stock);
    final r = await StockLookupRepository(db)
        .search(role: Role.cashier, query: 'kurta');
    expect(r.single.name, 'Cotton Kurta');
    expect(r.single.has(size: 'M', color: 'Blue'), isTrue);
    expect(r.single.has(size: 'S', color: 'Black'), isFalse);
  });

  test('does nothing when the shop already has a style', () async {
    expect(await seedDemoStock(db, stock), expected);
    expect(await seedDemoStock(db, stock), 0);
    expect(await count('articles'), expected);
  });

  test('does nothing on a shop with real stock', () async {
    await stock.seedDefaultOptions();
    await stock.receivePurchase(
      role: Role.owner,
      draft: PurchaseDraft(
        supplier: 'Real',
        style: 'My Style',
        lines: [
          PurchaseLine(
            size: 'M',
            color: 'Blue',
            quantity: 1,
            cost: Money(10000),
            mrp: Money(20000),
          ),
        ],
      ),
    );
    expect(await seedDemoStock(db, stock), 0);
    expect(await count('products'), 1);
  });

  group('test GST details', () {
    late GstRepository gst;
    setUp(() => gst = GstRepository(db, newId: newId));

    test('without the GST service nothing about GST is seeded', () async {
      await seedDemoStock(db, stock);
      expect((await gst.settings(role: Role.owner)).enabled, isFalse);
      expect(
        (await db
                .customSelect(
                  'SELECT COUNT(*) AS c FROM products WHERE hsn IS NOT NULL',
                )
                .getSingle())
            .read<int>('c'),
        0,
      );
      expect(
        (await db
                .customSelect('SELECT SUM(input_tax_paise) AS s FROM batches')
                .getSingle())
            .read<int>('s'),
        0,
      );
    });

    test('with it, GST is on with a made-up GSTIN and address', () async {
      await seedDemoStock(db, stock, gst: gst);
      final s = await gst.settings(role: Role.owner);
      expect(s.enabled, isTrue);
      expect(s.gstin, demoShopGstin);
      expect(isGstinShaped(demoShopGstin), isTrue);
      expect(isGstinShaped(demoBusinessGstin), isTrue);
      expect(isGstinShaped(demoSupplierGstin), isTrue);
      expect(s.address, contains('test data'));
      expect(s.rateBp, 500);
    });

    test('each demo style has its HSN code, and jeans their own 12%', () async {
      await seedDemoStock(db, stock, gst: gst);
      final styles = {
        for (final x in await gst.styles(role: Role.owner)) x.name: x,
      };
      expect(styles['Cotton Kurta']!.hsn, '6104');
      expect(styles['Cotton Kurta']!.rateBp, isNull);
      expect(styles['Denim Jeans']!.hsn, '6203');
      expect(styles['Denim Jeans']!.rateBp, 1200);
      expect(styles['Linen Shirt']!.hsn, '6205');
    });

    test(
      'each purchase has a supplier GSTIN, an invoice number and 5% input tax',
      () async {
        await seedDemoStock(db, stock, gst: gst);
        final r = await GstReportRepository(db).report(
          role: Role.owner,
          from: ShopDay.fromUtc(DateTime.now().toUtc()),
          to: ShopDay.fromUtc(DateTime.now().toUtc()),
        );
        expect(r.purchases.length, 3);
        expect(
          r.purchases.every((p) => p.supplierGstin == demoSupplierGstin),
          isTrue,
        );
        expect(r.purchases.map((p) => p.invoiceNo).toSet(), {
          'DEMO/001',
          'DEMO/002',
          'DEMO/003',
        });
        // Cotton Kurta: 12 garments x 220.00 = 2,640.00; 5% = 132.00
        expect(r.purchases.first.goodsValue, Money(264000));
        expect(r.purchases.first.inputTax, Money(13200));
        expect(r.inputTax.paise, greaterThan(0));
      },
    );

    test('a first bill is taxed at the shop rate, a jeans bill at 12%', () async {
      await seedDemoStock(db, stock, gst: gst);
      final codes = [
        for (final r
            in await db
                .customSelect(
                  "SELECT a.barcode_value AS b, p.name AS n FROM articles a JOIN variants v ON v.id = a.variant_id JOIN products p ON p.id = v.product_id WHERE p.name IN ('Cotton Kurta', 'Denim Jeans') GROUP BY p.name",
                )
                .get())
          (r.read<String>('n'), r.read<String>('b')),
      ];
      final sales = SalesRepository(db, newId: newId);
      final kurta = codes.firstWhere((c) => c.$1 == 'Cotton Kurta').$2;
      final jeans = codes.firstWhere((c) => c.$1 == 'Denim Jeans').$2;
      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              id: 'c1',
              name: 'C',
              role: 'CASHIER',
              credentialHash: 'x',
              createdAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
            ),
          );
      await db.customStatement(
        "INSERT INTO shifts (id, cashier_id, counter_id, opened_at, opening_paise, opening_count) SELECT 's1', 'c1', id, ${DateTime.now().millisecondsSinceEpoch ~/ 1000}, 0, '{}' FROM counters",
      );
      final bill = await sales.saveBill(
        role: Role.cashier,
        cashierId: 'c1',
        lines: [BillLineInput(kurta), BillLineInput(jeans)],
        payments: [Payment(PaymentMode.cash, Money(49900 + 129900))],
        customerName: 'Shah Traders',
        customerGstin: demoBusinessGstin,
      );
      expect(bill.tax.lines[0].rateBp, 500);
      expect(bill.tax.lines[1].rateBp, 1200);
      expect(bill.customerGstin, demoBusinessGstin);
      expect(bill.hsns, ['6104', '6203']);
    });

    test('does nothing on a shop that already has a style', () async {
      await seedDemoStock(db, stock);
      expect(await seedDemoStock(db, stock, gst: gst), 0);
      expect((await gst.settings(role: Role.owner)).enabled, isFalse);
    });
  });

  test('the release guard is in place: nothing is added unless kDebugMode', () {
    // Windows checks files out with CRLF line endings; compare with LF.
    final source = File('lib/data/demo_stock.dart')
        .readAsStringSync()
        .replaceAll('\r\n', '\n');
    expect(source, contains('if (!kDebugMode) {\n    return 0;'));
  });
}
