// P2-3a: saving a purchase in one transaction (barcodes, articles, batch lines,
// counter position, audit and outbox), size and color lists, shop name, and
// the labels for a batch. E-SERIAL-1, E-AUDIT-1, E-AUTHZ-2.
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/stock_repository.dart';

PurchaseLine line(
  String size,
  String color,
  int qty, {
  int cost = 20000,
  int mrp = 49900,
}) => PurchaseLine(
  size: size,
  color: color,
  quantity: qty,
  cost: Money(cost),
  mrp: Money(mrp),
);

PurchaseDraft draft(
  List<PurchaseLine> lines, {
  String style = 'Cotton Kurta',
  String supplier = 'Sample Supplier',
}) => PurchaseDraft(supplier: supplier, style: style, lines: lines);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late StockRepository stock;
  late DateTime now;
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 11, 20, 10);
    n = 0;
    stock = StockRepository(db, newId: newId, now: () => now);
    await stock.ensureCounter();
  });
  tearDown(() => db.close());

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle())
          .read<int>('c');

  group('the counter', () {
    test('Counter 1 owns lots 000-499 and starts at lot 0, serial 0', () async {
      final rows = await db.customSelect('SELECT * FROM counters').get();
      expect(rows.length, 1);
      final r = rows.single;
      expect(r.read<String>('name'), 'Counter 1');
      expect((r.read<int>('lot_first'), r.read<int>('lot_last')), (0, 499));
      expect((r.read<int>('current_lot'), r.read<int>('next_serial')), (0, 0));
    });

    test('ensureCounter does not make a second one', () async {
      final a = await stock.ensureCounter();
      final b = await stock.ensureCounter();
      expect(a, b);
      expect(await count('counters'), 1);
    });
  });

  group('saving a purchase', () {
    test(
      'creates the style, variants, batch, lines and one article per garment',
      () async {
        final r = await stock.receivePurchase(
          role: Role.owner,
          draft: draft([line('M', 'Blue', 3), line('L', 'Blue', 2)]),
          actor: 'owner-1',
        );
        expect(r.garments, 5);
        expect(await count('products'), 1);
        expect(await count('variants'), 2);
        expect(await count('batches'), 1);
        expect(await count('batch_lines'), 2);
        expect(await count('articles'), 5);
        final b = await db
            .customSelect('SELECT supplier, lot FROM batches')
            .getSingle();
        expect(
          (b.read<String>('supplier'), b.read<int>('lot')),
          ('Sample Supplier', 0),
        );
      },
    );

    test('every garment gets a valid, unique 12-digit barcode from lot 0, status IN_STOCK', () async {
      await stock.receivePurchase(
        role: Role.owner,
        draft: draft([line('M', 'Blue', 40), line('L', 'Red', 10)]),
      );
      final rows = await db
          .customSelect(
            'SELECT barcode_value, status FROM articles ORDER BY barcode_value',
          )
          .get();
      final values = rows.map((r) => r.read<String>('barcode_value')).toList();
      expect(values.toSet().length, 50);
      for (final v in values) {
        final b = Barcode.parse(v);
        expect(b.lot, 0);
        expect((b.year, b.month), (26, 11));
      }
      expect(rows.every((r) => r.read<String>('status') == 'IN_STOCK'), isTrue);
    });

    test(
      'each garment keeps the MRP of its own line; costs live in batch lines',
      () async {
        await stock.receivePurchase(
          role: Role.owner,
          draft: draft([
            line('M', 'Blue', 1, cost: 20000, mrp: 49900),
            line('XL', 'Blue', 1, cost: 26000, mrp: 59900),
          ]),
        );
        final a = await db
            .customSelect(
              'SELECT v.size, a.mrp_paise FROM articles a JOIN variants v ON v.id = a.variant_id ORDER BY v.size',
            )
            .get();
        expect(
          a.map((r) => (r.read<String>('size'), r.read<int>('mrp_paise'))),
          [('M', 49900), ('XL', 59900)],
        );
        final l = await db
            .customSelect(
              'SELECT v.size, l.quantity, l.unit_cost_paise FROM batch_lines l JOIN variants v ON v.id = l.variant_id ORDER BY v.size',
            )
            .get();
        expect(
          l.map(
            (r) => (
              r.read<String>('size'),
              r.read<int>('quantity'),
              r.read<int>('unit_cost_paise'),
            ),
          ),
          [('M', 1, 20000), ('XL', 1, 26000)],
        );
      },
    );

    test('the counter moves on, and the next purchase continues after the last serial', () async {
      await stock.receivePurchase(
        role: Role.owner,
        draft: draft([line('M', 'Blue', 5)]),
      );
      var c = await db
          .customSelect('SELECT current_lot, next_serial FROM counters')
          .getSingle();
      expect((c.read<int>('current_lot'), c.read<int>('next_serial')), (0, 5));
      await stock.receivePurchase(
        role: Role.owner,
        draft: draft([line('M', 'Blue', 2)], style: 'Shirt'),
      );
      final serials =
          (await db.customSelect('SELECT barcode_value FROM articles').get())
              .map((r) => Barcode.parse(r.read<String>('barcode_value')).serial)
              .toList()
            ..sort();
      expect(serials, [0, 1, 2, 3, 4, 5, 6]);
      c = await db.customSelect('SELECT next_serial FROM counters').getSingle();
      expect(c.read<int>('next_serial'), 7);
    });

    test('buying the same style again reuses it, and updates the variant MRP but not old garments', () async {
      await stock.receivePurchase(
        role: Role.owner,
        draft: draft([line('M', 'Blue', 1, mrp: 49900)]),
      );
      await stock.receivePurchase(
        role: Role.owner,
        draft: draft([line('m', 'blue', 1, mrp: 54900)], style: 'cotton kurta'),
      );
      expect(await count('products'), 1);
      expect(await count('variants'), 1);
      expect(await count('batches'), 2);
      final v = await db
          .customSelect('SELECT mrp_paise FROM variants')
          .getSingle();
      expect(v.read<int>('mrp_paise'), 54900);
      final a = await db
          .customSelect(
            'SELECT mrp_paise FROM articles ORDER BY created_at, barcode_value',
          )
          .get();
      expect(a.map((r) => r.read<int>('mrp_paise')).toSet(), {49900, 54900});
    });

    test('a purchase that does not fit the current lot goes whole into the next lot', () async {
      await db.customStatement('UPDATE counters SET next_serial = 9990');
      await stock.receivePurchase(
        role: Role.owner,
        draft: draft([line('M', 'Blue', 20)]),
      );
      final lots =
          (await db.customSelect('SELECT barcode_value FROM articles').get())
              .map((r) => Barcode.parse(r.read<String>('barcode_value')).lot)
              .toSet();
      expect(lots, {1});
      final c = await db
          .customSelect('SELECT current_lot, next_serial FROM counters')
          .getSingle();
      expect((c.read<int>('current_lot'), c.read<int>('next_serial')), (1, 20));
    });

    test('the barcode month follows India time, not UTC', () async {
      now = DateTime.utc(2026, 11, 30, 20); // 1 December in India
      await stock.receivePurchase(
        role: Role.owner,
        draft: draft([line('M', 'Blue', 1)]),
      );
      final v = await db
          .customSelect('SELECT barcode_value FROM articles')
          .getSingle();
      expect(Barcode.parse(v.read<String>('barcode_value')).month, 12);
    });

    test('writes one audit row and one outbox row, without any cost', () async {
      await stock.receivePurchase(
        role: Role.owner,
        draft: draft([line('M', 'Blue', 3, cost: 123456)]),
        actor: 'owner-1',
      );
      final audit = await db
          .customSelect(
            "SELECT * FROM audit_log WHERE action = 'stock.receive'",
          )
          .getSingle();
      expect(audit.read<String>('actor'), 'owner-1');
      expect(
        audit.read<String>('details'),
        allOf(contains('Sample Supplier'), contains('Cotton Kurta')),
      );
      final out = await db
          .customSelect(
            "SELECT * FROM outbox WHERE operation = 'stock.receive'",
          )
          .getSingle();
      for (final text in [
        audit.read<String>('details'),
        out.read<String>('payload'),
      ]) {
        expect(text.contains('123456'), isFalse);
        expect(text.toLowerCase().contains('cost'), isFalse);
      }
    });
  });

  group('refusals leave nothing behind', () {
    Future<void> expectUntouched() async {
      expect(await count('products'), 0);
      expect(await count('batches'), 0);
      expect(await count('articles'), 0);
      expect(await count('batch_lines'), 0);
      final c = await db
          .customSelect('SELECT current_lot, next_serial FROM counters')
          .getSingle();
      expect((c.read<int>('current_lot'), c.read<int>('next_serial')), (0, 0));
      expect(await count('outbox'), 0);
    }

    test('a cashier may not enter stock', () async {
      await expectLater(
        stock.receivePurchase(
          role: Role.cashier,
          draft: draft([line('M', 'Blue', 1)]),
        ),
        throwsA(isA<PermissionDenied>()),
      );
      await expectUntouched();
    });

    test('nobody signed in may not enter stock', () async {
      await expectLater(
        stock.receivePurchase(role: null, draft: draft([line('M', 'Blue', 1)])),
        throwsA(isA<PermissionDenied>()),
      );
      await expectUntouched();
    });

    test(
      'a purchase with problems is refused and says what is wrong',
      () async {
        await expectLater(
          stock.receivePurchase(
            role: Role.owner,
            draft: draft([line('M', 'Blue', 0)]),
          ),
          throwsA(
            isA<InvalidPurchase>().having(
              (e) => e.issues.map((i) => i.problem),
              'problems',
              contains(PurchaseProblem.badQuantity),
            ),
          ),
        );
        await expectUntouched();
      },
    );

    test(
      'if saving fails half way, nothing is saved and no serial is used up',
      () async {
        var calls = 0;
        final shaky = StockRepository(
          db,
          newId: () =>
              (++calls == 12) ? throw StateError('disk full') : 'x$calls',
          now: () => now,
        );
        await expectLater(
          shaky.receivePurchase(
            role: Role.owner,
            draft: draft([line('M', 'Blue', 10)]),
          ),
          throwsStateError,
        );
        await expectUntouched();
      },
    );

    test('running out of lots is reported and nothing is saved', () async {
      await db.customStatement(
        'UPDATE counters SET lot_last = 0, next_serial = 10000',
      );
      await expectLater(
        stock.receivePurchase(
          role: Role.owner,
          draft: draft([line('M', 'Blue', 1)]),
        ),
        throwsA(isA<RangeExhausted>()),
      );
      expect(await count('articles'), 0);
    });
  });

  group('size and color lists', () {
    test('start with sizes S to XXL and some common colors, once', () async {
      await stock.seedDefaultOptions();
      await stock.seedDefaultOptions();
      expect(await stock.sizes(), ['S', 'M', 'L', 'XL', 'XXL']);
      expect(
        await stock.colors(),
        containsAll(['Black', 'White', 'Blue', 'Red']),
      );
      expect(
        (await stock.colors()).toSet().length,
        (await stock.colors()).length,
      );
    });

    test('a new size or color can be added; spelling differences do not make a duplicate', () async {
      await stock.seedDefaultOptions();
      await stock.addSize(role: Role.owner, name: '3XL');
      await stock.addSize(role: Role.owner, name: ' 3xl ');
      await stock.addColor(role: Role.owner, name: 'Navy Blue');
      await stock.addColor(role: Role.owner, name: 'navy blue');
      expect((await stock.sizes()).last, '3XL');
      expect(
        (await stock.sizes()).where((s) => s.toLowerCase() == '3xl').length,
        1,
      );
      expect(
        (await stock.colors())
            .where((c) => c.toLowerCase() == 'navy blue')
            .length,
        1,
      );
    });

    test('blank names are refused and a cashier cannot add', () async {
      await expectLater(
        stock.addSize(role: Role.owner, name: '  '),
        throwsArgumentError,
      );
      await expectLater(
        stock.addSize(role: Role.cashier, name: 'XS'),
        throwsA(isA<PermissionDenied>()),
      );
      await expectLater(
        stock.addColor(role: Role.cashier, name: 'Pink'),
        throwsA(isA<PermissionDenied>()),
      );
    });
  });

  group('shop name and labels', () {
    test('the shop name is saved and read back', () async {
      expect(await stock.shopName(), isNull);
      await stock.setShopName(role: Role.owner, name: '  Sample Apparel ');
      expect(await stock.shopName(), 'Sample Apparel');
      await expectLater(
        stock.setShopName(role: Role.cashier, name: 'X'),
        throwsA(isA<PermissionDenied>()),
      );
      await expectLater(
        stock.setShopName(role: Role.owner, name: ' '),
        throwsArgumentError,
      );
    });

    test(
      'labels for a batch carry shop, style, size, color, own MRP and barcode',
      () async {
        await stock.setShopName(role: Role.owner, name: 'Sample Apparel');
        final r = await stock.receivePurchase(
          role: Role.owner,
          draft: draft([
            line('M', 'Blue', 2, mrp: 49900),
            line('XL', 'Red', 1, mrp: 59900),
          ]),
        );
        final labels = await stock.labelsForBatch(
          role: Role.owner,
          batchId: r.batchId,
        );
        expect(labels.length, 3);
        expect(
          labels.every(
            (l) => l.shopName == 'Sample Apparel' && l.style == 'Cotton Kurta',
          ),
          isTrue,
        );
        expect(labels.map((l) => (l.size, l.color, l.mrp.paise)).toSet(), {
          ('M', 'Blue', 49900),
          ('XL', 'Red', 59900),
        });
        expect(labels.map((l) => l.barcodeDigits).toSet().length, 3);
        expect(
          labels.map((l) => l.barcodeDigits),
          orderedEquals(labels.map((l) => l.barcodeDigits).toList()..sort()),
        );
      },
    );

    test('labels need the shop name and the print permission', () async {
      final r = await stock.receivePurchase(
        role: Role.owner,
        draft: draft([line('M', 'Blue', 1)]),
      );
      await expectLater(
        stock.labelsForBatch(role: Role.owner, batchId: r.batchId),
        throwsA(isA<ShopNameMissing>()),
      );
      await stock.setShopName(role: Role.owner, name: 'Sample Apparel');
      await expectLater(
        stock.labelsForBatch(role: Role.cashier, batchId: r.batchId),
        throwsA(isA<PermissionDenied>()),
      );
      expect(
        await stock.labelsForBatch(role: Role.manager, batchId: r.batchId),
        hasLength(1),
      );
    });

    test('an unknown batch gives no labels', () async {
      await stock.setShopName(role: Role.owner, name: 'S');
      expect(
        await stock.labelsForBatch(role: Role.owner, batchId: 'nope'),
        isEmpty,
      );
    });
  });

  test('saving 500 garments takes well under 5 seconds (sanity, not the 50 ms target)', () async {
    final sw = Stopwatch()..start();
    await stock.receivePurchase(
      role: Role.owner,
      draft: draft([
        for (final s in ['S', 'M', 'L', 'XL', 'XXL']) line(s, 'Blue', 100),
      ]),
    );
    expect(sw.elapsedMilliseconds, lessThan(5000));
    expect(await count('articles'), 500);
  });
}
