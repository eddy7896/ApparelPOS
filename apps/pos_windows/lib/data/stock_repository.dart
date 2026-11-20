// Entering stock: saves a purchase in ONE transaction (style, variants, batch,
// costs, one article per garment with its own MRP and barcode, the counter's new
// position, audit and outbox), keeps the size and color lists and the shop name,
// and rebuilds the labels of a batch. Rules are in core_domain (checkPurchase,
// planPurchase, the permission matrix). E-SERIAL-1, E-AUDIT-1, E-AUTHZ-2.
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';

/// Thrown when a purchase has problems; [issues] says which.
final class InvalidPurchase implements Exception {
  InvalidPurchase(this.issues);
  final List<PurchaseIssue> issues;
  @override
  String toString() => 'InvalidPurchase: $issues';
}

/// Thrown when labels are asked for before the shop name has been set.
final class ShopNameMissing implements Exception {
  @override
  String toString() => 'ShopNameMissing: set the shop name first';
}

/// What saving a purchase made.
final class PurchaseResult {
  const PurchaseResult({
    required this.batchId,
    required this.lot,
    required this.garments,
  });
  final String batchId;
  final int lot;
  final int garments;
}

const List<String> _defaultSizes = ['S', 'M', 'L', 'XL', 'XXL'];
const List<String> _defaultColors = [
  'Black',
  'White',
  'Blue',
  'Red',
  'Green',
  'Yellow',
  'Grey',
  'Pink',
  'Brown',
];

class StockRepository {
  StockRepository(
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

  /// This counter: lots 000-499, starting at lot 0 serial 0 (owner, 2026-11-20;
  /// lots 500-999 stay free for a second counter). Made once; returns its id.
  Future<String> ensureCounter() async {
    final existing = await _db.select(_db.counters).get();
    if (existing.isNotEmpty) {
      return existing.first.id;
    }
    final id = _newId();
    final at = _now();
    await _db
        .into(_db.counters)
        .insert(
          CountersCompanion.insert(
            id: id,
            name: 'Counter 1',
            lotFirst: 0,
            lotLast: 499,
            currentLot: 0,
            nextSerial: 0,
            createdAt: at,
            updatedAt: at,
          ),
        );
    return id;
  }

  // ---- size and color lists -------------------------------------------------

  Future<void> seedDefaultOptions() async {
    if ((await sizes()).isEmpty) {
      for (final s in _defaultSizes) {
        await _addOption(_db.sizeOptions, s);
      }
    }
    if ((await colors()).isEmpty) {
      for (final c in _defaultColors) {
        await _addOption(_db.colorOptions, c);
      }
    }
  }

  Future<List<String>> sizes() async => [
    for (final r in await (_db.select(
      _db.sizeOptions,
    )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get())
      r.name,
  ];

  Future<List<String>> colors() async => [
    for (final r in await (_db.select(
      _db.colorOptions,
    )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get())
      r.name,
  ];

  Future<void> addSize({required Role? role, required String name}) async {
    require(role, Permission.enterStock);
    await _addOption(_db.sizeOptions, name);
  }

  Future<void> addColor({required Role? role, required String name}) async {
    require(role, Permission.enterStock);
    await _addOption(_db.colorOptions, name);
  }

  Future<void> _addOption(
    TableInfo<Table, dynamic> table,
    String rawName,
  ) async {
    final name = rawName.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(rawName, 'name', 'must not be blank');
    }
    final t = table.actualTableName;
    final taken = await _db
        .customSelect(
          'SELECT 1 FROM $t WHERE name = ? COLLATE NOCASE',
          variables: [Variable<String>(name)],
        )
        .get();
    if (taken.isNotEmpty) {
      return;
    }
    final next =
        (await _db
                .customSelect(
                  'SELECT COALESCE(MAX(sort_order), 0) + 1 AS n FROM $t',
                )
                .getSingle())
            .read<int>('n');
    await _db.customInsert(
      'INSERT INTO $t (id, name, sort_order) VALUES (?, ?, ?)',
      variables: [
        Variable<String>(_newId()),
        Variable<String>(name),
        Variable<int>(next),
      ],
    );
  }

  // ---- shop name ------------------------------------------------------------

  Future<String?> shopName() async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((s) => s.name.equals('shop_name'))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setShopName({required Role? role, required String name}) async {
    require(role, Permission.manageSettings);
    final clean = name.trim();
    if (clean.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be blank');
    }
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(name: 'shop_name', value: clean),
        );
  }

  // ---- purchases ------------------------------------------------------------

  /// Saves a purchase. Needs the `enterStock` permission. Throws
  /// [PermissionDenied], [InvalidPurchase] or [RangeExhausted]; on any failure
  /// nothing at all is saved.
  Future<PurchaseResult> receivePurchase({
    required Role? role,
    required PurchaseDraft draft,
    String? actor,
  }) async {
    require(role, Permission.enterStock);
    final problems = checkPurchase(draft).where((i) => !i.isWarning).toList();
    if (problems.isNotEmpty) {
      throw InvalidPurchase(problems);
    }
    final batchId = _newId();
    final at = _now();
    final (year, month) = shopYearMonth(at);

    return _writer.run<PurchaseResult>(
      action: 'stock.receive',
      entityType: 'batch',
      entityId: batchId,
      actor: actor,
      body: () async {
        final counter = (await _db.select(_db.counters).get()).first;
        final cursor = LotCursor.resume(
          LotRange(counter.lotFirst, counter.lotLast),
          counter.currentLot,
          counter.nextSerial,
        );
        final plan = planPurchase(draft, cursor, year: year, month: month);

        final productId = await _findOrCreateProduct(plan.style, actor, at);
        final variantIds = <int, String>{};
        for (var i = 0; i < plan.lines.length; i++) {
          variantIds[i] = await _upsertVariant(productId, plan.lines[i], at);
        }

        await _db
            .into(_db.batches)
            .insert(
              BatchesCompanion.insert(
                id: batchId,
                supplier: plan.supplier,
                lot: plan.lot,
                purchasedAt: at,
                createdBy: Value(actor),
                createdAt: at,
                updatedAt: at,
              ),
            );
        for (var i = 0; i < plan.lines.length; i++) {
          await _db
              .into(_db.batchLines)
              .insert(
                BatchLinesCompanion.insert(
                  id: _newId(),
                  batchId: batchId,
                  variantId: variantIds[i]!,
                  quantity: plan.lines[i].quantity,
                  unitCostPaise: plan.lines[i].cost.paise,
                ),
              );
        }
        await _db.batch((b) {
          b.insertAll(_db.articles, [
            for (final a in plan.articles)
              ArticlesCompanion.insert(
                id: _newId(),
                barcodeValue: a.barcode.value,
                variantId: variantIds[a.lineIndex]!,
                batchId: batchId,
                mrpPaise: a.mrp.paise,
                status: ArticleStatus.inStock.dbValue,
                createdAt: at,
                updatedAt: at,
              ),
          ]);
        });
        await (_db.update(
          _db.counters,
        )..where((c) => c.id.equals(counter.id))).write(
          CountersCompanion(
            currentLot: Value(plan.cursor.lot),
            nextSerial: Value(plan.cursor.nextSerial),
            updatedAt: Value(at),
          ),
        );
        return PurchaseResult(
          batchId: batchId,
          lot: plan.lot,
          garments: plan.articles.length,
        );
      },
      // Costs are deliberately not in the audit or outbox details.
      details: {
        'supplier': draft.supplier.trim(),
        'style': draft.style.trim(),
        'garments': draft.lines.fold<int>(0, (sum, l) => sum + l.quantity),
      },
    );
  }

  Future<String> _findOrCreateProduct(
    String style,
    String? actor,
    DateTime at,
  ) async {
    final found = await _db
        .customSelect(
          'SELECT id FROM products WHERE name = ? COLLATE NOCASE',
          variables: [Variable<String>(style)],
        )
        .get();
    if (found.isNotEmpty) {
      return found.first.read<String>('id');
    }
    final id = _newId();
    await _db
        .into(_db.products)
        .insert(
          ProductsCompanion.insert(
            id: id,
            name: style,
            createdBy: Value(actor),
            createdAt: at,
            updatedAt: at,
          ),
        );
    return id;
  }

  /// Finds the variant (style, size, color) or makes it, and sets its current
  /// MRP to this line's. Garments already in stock keep their own MRP.
  Future<String> _upsertVariant(
    String productId,
    PurchaseLine line,
    DateTime at,
  ) async {
    final found = await _db
        .customSelect(
          'SELECT id FROM variants WHERE product_id = ? AND size = ? COLLATE NOCASE AND color = ? COLLATE NOCASE',
          variables: [
            Variable<String>(productId),
            Variable<String>(line.size),
            Variable<String>(line.color),
          ],
        )
        .get();
    if (found.isNotEmpty) {
      final id = found.first.read<String>('id');
      await (_db.update(_db.variants)..where((v) => v.id.equals(id))).write(
        VariantsCompanion(
          mrpPaise: Value(line.mrp.paise),
          updatedAt: Value(at),
        ),
      );
      return id;
    }
    final id = _newId();
    await _db
        .into(_db.variants)
        .insert(
          VariantsCompanion.insert(
            id: id,
            productId: productId,
            size: line.size,
            color: line.color,
            mrpPaise: line.mrp.paise,
            createdAt: at,
            updatedAt: at,
          ),
        );
    return id;
  }

  // ---- labels ---------------------------------------------------------------

  /// The hangtag contents for every garment of [batchId], in barcode order. Needs
  /// the `printLabels` permission and a shop name. Costs are never read.
  Future<List<LabelContent>> labelsForBatch({
    required Role? role,
    required String batchId,
  }) async {
    require(role, Permission.printLabels);
    final shop = await shopName();
    if (shop == null) {
      throw ShopNameMissing();
    }
    final rows = await _db
        .customSelect(
          'SELECT a.barcode_value, a.mrp_paise, v.size, v.color, p.name AS style '
          'FROM articles a JOIN variants v ON v.id = a.variant_id JOIN products p ON p.id = v.product_id '
          'WHERE a.batch_id = ? ORDER BY a.barcode_value',
          variables: [Variable<String>(batchId)],
        )
        .get();
    return [
      for (final r in rows)
        LabelContent(
          shopName: shop,
          style: r.read<String>('style'),
          size: r.read<String>('size'),
          color: r.read<String>('color'),
          mrp: Money(r.read<int>('mrp_paise')),
          barcode: Barcode.parse(r.read<String>('barcode_value')),
        ),
    ];
  }
}
