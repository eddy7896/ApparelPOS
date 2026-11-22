// Demo stock for development builds (ADR-0016). Tests run in debug mode, so
// the debug-only guard is on; the release guard is a kDebugMode check.
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/demo_stock.dart';
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

  test('the release guard is in place: nothing is added unless kDebugMode', () {
    final source = File('lib/data/demo_stock.dart').readAsStringSync();
    expect(source, contains('if (!kDebugMode) {\n    return 0;'));
  });
}
