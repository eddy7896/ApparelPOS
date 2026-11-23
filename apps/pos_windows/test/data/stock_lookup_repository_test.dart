// Stock lookup: "does the shop have this style in this size and color?". Open
// to everyone who may see stock and prices (cashiers too), so it never reads
// cost (E-AUTHZ-1). Counts only garments that are in stock.
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/stock_lookup_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late StockRepository stock;
  late StockLookupRepository lookup;
  var n = 0;
  String newId() => 'id-${++n}';

  Future<List<String>> buy(
    String style,
    List<(String, String, int, int)> lines,
  ) async {
    final r = await stock.receivePurchase(
      role: Role.owner,
      draft: PurchaseDraft(
        supplier: 'S',
        style: style,
        lines: [
          for (final (size, color, qty, mrp) in lines)
            PurchaseLine(
              size: size,
              color: color,
              quantity: qty,
              cost: Money(10000),
              mrp: Money(mrp * 100),
            ),
        ],
      ),
    );
    final rows = await db
        .customSelect(
          'SELECT barcode_value FROM articles WHERE batch_id = ? ORDER BY barcode_value',
          variables: [Variable<String>(r.batchId)],
        )
        .get();
    return [for (final x in rows) x.read<String>('barcode_value')];
  }

  Future<void> setStatus(String barcode, String status) => db.customStatement(
    "UPDATE articles SET status = '$status' WHERE barcode_value = '$barcode'",
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    stock = StockRepository(db, newId: newId);
    lookup = StockLookupRepository(db);
    await stock.ensureCounter();
  });
  tearDown(() => db.close());

  StyleStock only(List<StyleStock> r) => r.single;
  VariantStock variant(StyleStock s, String size, String color) =>
      s.variants.singleWhere((v) => v.size == size && v.color == color);

  group('what it shows', () {
    test(
      'a style with its sizes and colors, MRP and how many are in stock',
      () async {
        await buy('Cotton Kurta', [
          ('M', 'Blue', 3, 499),
          ('L', 'Blue', 1, 549),
        ]);
        final s = only(await lookup.search(role: Role.cashier, query: 'kurta'));
        expect(s.name, 'Cotton Kurta');
        expect(s.inStock, 4);
        expect(variant(s, 'M', 'Blue').inStock, 3);
        expect(variant(s, 'M', 'Blue').mrp, Money(49900));
        expect(variant(s, 'L', 'Blue').inStock, 1);
        expect(variant(s, 'L', 'Blue').mrp, Money(54900));
      },
    );

    test('only garments in stock are counted', () async {
      final codes = await buy('Denim Jeans', [('L', 'Black', 4, 1299)]);
      await setStatus(codes[0], 'SOLD');
      await setStatus(codes[1], 'DAMAGED');
      await setStatus(codes[2], 'RETURNED');
      final s = only(await lookup.search(role: Role.cashier, query: 'denim'));
      expect(variant(s, 'L', 'Black').inStock, 1);
      expect(s.inStock, 1);
    });

    test(
      'a size and color that is all sold shows with zero, not missing',
      () async {
        final codes = await buy('Linen Shirt', [
          ('M', 'White', 1, 899),
          ('L', 'White', 2, 899),
        ]);
        await setStatus(codes[0], 'SOLD');
        final s = only(await lookup.search(role: Role.cashier, query: 'linen'));
        final out = s.variants.where((v) => v.inStock == 0).toList();
        expect(out.length, 1);
        expect(s.inStock, 2);
      },
    );

    test('an exact size and color check answers yes or no', () async {
      await buy('Cotton Kurta', [('M', 'Blue', 2, 499)]);
      final s = only(
        await lookup.search(role: Role.cashier, query: 'Cotton Kurta'),
      );
      expect(
        s.variants.any((v) => v.size == 'XL' && v.color == 'Blue'),
        isFalse,
      );
      expect(s.has(size: 'M', color: 'Blue'), isTrue);
      expect(s.has(size: 'XL', color: 'Blue'), isFalse);
    });
  });

  group('which garments can be picked', () {
    test(
      'each size and color lists its in-stock barcodes, lowest first',
      () async {
        final codes = await buy('Cotton Kurta', [('M', 'Blue', 3, 499)]);
        final s = only(await lookup.search(role: Role.cashier, query: 'kurta'));
        expect(variant(s, 'M', 'Blue').barcodes, codes);
        expect(variant(s, 'M', 'Blue').barcodes.length, 3);
      },
    );

    test('sold, damaged and returned garments are not offered', () async {
      final codes = await buy('Denim Jeans', [('L', 'Black', 4, 1299)]);
      await setStatus(codes[0], 'SOLD');
      await setStatus(codes[1], 'DAMAGED');
      await setStatus(codes[2], 'RETURNED');
      final s = only(await lookup.search(role: Role.cashier, query: 'denim'));
      expect(variant(s, 'L', 'Black').barcodes, [codes[3]]);
    });

    test('a used-up size and color has no barcodes', () async {
      final codes = await buy('Linen Shirt', [('M', 'White', 1, 899)]);
      await setStatus(codes[0], 'SOLD');
      final s = only(await lookup.search(role: Role.cashier, query: 'linen'));
      expect(variant(s, 'M', 'White').barcodes, isEmpty);
    });

    test('at most 50 are listed, the count is still the real number', () async {
      await buy('Cotton Kurta', [('M', 'Blue', 60, 499)]);
      final s = only(await lookup.search(role: Role.cashier, query: 'kurta'));
      expect(variant(s, 'M', 'Blue').barcodes.length, 50);
      expect(variant(s, 'M', 'Blue').inStock, 60);
    });
  });

  group('the category of a style', () {
    test('a style comes back with its category, or none', () async {
      await buy('Cotton Kurta', [('M', 'Blue', 1, 499)]);
      await buy('Denim Jeans', [('L', 'Black', 1, 1299)]);
      await db.customStatement(
        "INSERT INTO categories (id, name, created_at, updated_at) VALUES ('c1', 'Men', 1700000000, 1700000000)",
      );
      await db.customStatement(
        "UPDATE products SET category_id = 'c1' WHERE name = 'Cotton Kurta'",
      );
      final r = await lookup.search(role: Role.cashier, query: '');
      expect(r.singleWhere((s) => s.name == 'Cotton Kurta').categoryId, 'c1');
      expect(r.singleWhere((s) => s.name == 'Denim Jeans').categoryId, isNull);
    });
  });

  group('finding it', () {
    setUp(() async {
      await buy('Cotton Kurta', [('M', 'Blue', 1, 499)]);
      await buy('Denim Jeans', [('L', 'Black', 1, 1299)]);
      await buy('Linen Kurta Set', [('M', 'Cream', 1, 1599)]);
    });

    test('part of a name finds it, ignoring capitals', () async {
      final r = await lookup.search(role: Role.cashier, query: 'KURTA');
      expect(r.map((s) => s.name), ['Cotton Kurta', 'Linen Kurta Set']);
    });

    test('an empty search lists every style with its stock, by name', () async {
      final r = await lookup.search(role: Role.cashier, query: '  ');
      expect(r.map((s) => s.name), [
        'Cotton Kurta',
        'Denim Jeans',
        'Linen Kurta Set',
      ]);
    });

    test('nothing matching gives an empty list', () async {
      expect(await lookup.search(role: Role.cashier, query: 'saree'), isEmpty);
    });

    test('a barcode finds its style', () async {
      final code =
          (await db
                  .customSelect(
                    "SELECT a.barcode_value AS b FROM articles a JOIN variants v ON v.id = a.variant_id JOIN products p ON p.id = v.product_id WHERE p.name = 'Denim Jeans'",
                  )
                  .getSingle())
              .read<String>('b');
      final r = await lookup.search(role: Role.cashier, query: code);
      expect(r.single.name, 'Denim Jeans');
    });

    test('% and _ are letters, not wildcards', () async {
      expect(await lookup.search(role: Role.cashier, query: '%'), isEmpty);
      expect(
        await lookup.search(role: Role.cashier, query: 'Cotton_Kurta'),
        isEmpty,
      );
    });
  });

  group('who may look', () {
    test('a cashier, manager and owner may; nobody may not', () async {
      await buy('Cotton Kurta', [('M', 'Blue', 1, 499)]);
      for (final role in [Role.cashier, Role.manager, Role.owner]) {
        expect(await lookup.search(role: role, query: ''), hasLength(1));
      }
      await expectLater(
        lookup.search(role: null, query: ''),
        throwsA(isA<PermissionDenied>()),
      );
    });
  });

  group('never reads cost (E-AUTHZ-1)', () {
    test('stock_lookup_repository.dart does not mention the cost table', () {
      final source = File('lib/data/stock_lookup_repository.dart')
          .readAsStringSync();
      for (final banned in [
        'batch_lines',
        'batchLines',
        'unit_cost',
        'unitCost',
      ]) {
        expect(
          RegExp(
            '^(?!\\s*//).*${RegExp.escape(banned)}',
            multiLine: true,
          ).hasMatch(source),
          isFalse,
          reason: banned,
        );
      }
    });
  });
}
