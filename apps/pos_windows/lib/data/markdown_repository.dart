// Markdowns set ahead of time on a whole style (owner, 2026-11-23). A manager
// or owner (`setMarkdown`) sets a percentage or a fixed amount and a last day;
// the register applies it to every unsold garment of the style (SalesRepository
// reads the table). Nobody types a markdown at the counter. Only MRPs are read
// here, never cost (E-AUTHZ-1). Past bills keep what they were charged.
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';

/// Thrown when the markdown cannot be set; [problem] says why.
final class InvalidMarkdown implements Exception {
  InvalidMarkdown(this.problem);
  final MarkdownProblem problem;
  @override
  String toString() => 'InvalidMarkdown: ${problem.name}';
}

/// Thrown when the style does not exist or has no garments to price.
final class UnknownStyle implements Exception {
  @override
  String toString() => 'UnknownStyle';
}

/// A markdown that is set on a style.
final class StyleMarkdown {
  const StyleMarkdown({
    required this.cut,
    required this.endsBefore,
    required this.lastDay,
    required this.active,
    required this.setBy,
  });
  final PriceCut cut;
  final DateTime endsBefore;

  /// The last India day it applies.
  final ShopDay lastDay;

  /// False once the last day is over (the row stays until removed).
  final bool active;
  final String setBy;
}

/// A style with its stock and its markdown, if any.
final class MarkdownStyleEntry {
  const MarkdownStyleEntry({
    required this.id,
    required this.name,
    required this.inStock,
    required this.lowestMrp,
    required this.highestMrp,
    required this.markdown,
  });
  final String id;
  final String name;

  /// Unsold garments of the style.
  final int inStock;

  /// Null when none is in stock.
  final Money? lowestMrp;
  final Money? highestMrp;
  final StyleMarkdown? markdown;
}

class MarkdownRepository {
  MarkdownRepository(
    this._db, {
    required String Function() newId,
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc()),
       _writer = AuditedWriter(_db, now: now, newId: newId);

  final AppDatabase _db;
  final DateTime Function() _now;
  final AuditedWriter _writer;

  /// Every style, by name, with its stock, price range and markdown. Needs
  /// `setMarkdown` (manager, owner).
  Future<List<MarkdownStyleEntry>> list({required Role? role}) async {
    require(role, Permission.setMarkdown);
    final now = _now();
    final stock = {
      for (final r
          in await _db
              .customSelect(
                'SELECT v.product_id AS p, COUNT(*) AS n, '
                'MIN(a.mrp_paise) AS lo, MAX(a.mrp_paise) AS hi '
                'FROM articles a JOIN variants v ON v.id = a.variant_id '
                "WHERE a.status = 'IN_STOCK' GROUP BY v.product_id",
              )
              .get())
        r.read<String>('p'): (
          n: r.read<int>('n'),
          lo: r.read<int>('lo'),
          hi: r.read<int>('hi'),
        ),
    };
    final marks = {
      for (final m in await _db.select(_db.styleMarkdowns).get())
        m.productId: m,
    };
    final products = await (_db.select(
      _db.products,
    )..orderBy([(p) => OrderingTerm.asc(p.name)])).get();
    return [
      for (final p in products)
        MarkdownStyleEntry(
          id: p.id,
          name: p.name,
          inStock: stock[p.id]?.n ?? 0,
          lowestMrp: stock[p.id] == null ? null : Money(stock[p.id]!.lo),
          highestMrp: stock[p.id] == null ? null : Money(stock[p.id]!.hi),
          markdown: marks[p.id] == null ? null : _toMarkdown(marks[p.id]!, now),
        ),
    ];
  }

  StyleMarkdown _toMarkdown(StyleMarkdownRow r, DateTime now) {
    final bp = r.percentBp;
    final ends = r.endsBefore.toUtc();
    return StyleMarkdown(
      cut: bp != null
          ? PriceCut.percentBp(bp)
          : PriceCut.amount(Money(r.amountPaise!)),
      endsBefore: ends,
      lastDay: ShopDay.fromUtc(ends.subtract(const Duration(milliseconds: 1))),
      active: markdownActive(ends, now),
      setBy: r.setBy,
    );
  }

  /// Sets (or changes) the markdown of a style. Needs `setMarkdown`. Throws
  /// [PermissionDenied], [UnknownStyle] or [InvalidMarkdown].
  Future<void> set({
    required Role? role,
    required String actorId,
    required String productId,
    required PriceCut cut,
    required ShopDay lastDay,
  }) async {
    require(role, Permission.setMarkdown);
    final at = _now();
    await _writer.run<void>(
      action: 'markdown.set',
      entityType: 'style_markdown',
      entityId: productId,
      actor: actorId,
      details: {
        'percentBp': cut.basisPoints,
        'amountPaise': cut.amountOff?.paise,
        'lastDay': shopDayText(lastDay),
      },
      body: () async {
        final exists = await (_db.select(
          _db.products,
        )..where((p) => p.id.equals(productId))).getSingleOrNull();
        if (exists == null) {
          throw UnknownStyle();
        }
        // The cheapest unsold garment; with none in stock, the cheapest price
        // the style was ever given.
        final inStock = await _db
            .customSelect(
              'SELECT MIN(a.mrp_paise) AS lo FROM articles a '
              'JOIN variants v ON v.id = a.variant_id '
              "WHERE v.product_id = ? AND a.status = 'IN_STOCK'",
              variables: [Variable<String>(productId)],
            )
            .getSingle();
        var lowest = inStock.read<int?>('lo');
        lowest ??=
            (await _db
                    .customSelect(
                      'SELECT MIN(mrp_paise) AS lo FROM variants WHERE product_id = ?',
                      variables: [Variable<String>(productId)],
                    )
                    .getSingle())
                .read<int?>('lo');
        if (lowest == null) {
          throw UnknownStyle();
        }
        final problem = markdownProblem(
          cut: cut,
          lastDay: lastDay,
          today: ShopDay.fromUtc(at),
          lowestMrp: Money(lowest),
        );
        if (problem != null) {
          throw InvalidMarkdown(problem);
        }
        final previous = await (_db.select(
          _db.styleMarkdowns,
        )..where((m) => m.productId.equals(productId))).getSingleOrNull();
        await _db
            .into(_db.styleMarkdowns)
            .insertOnConflictUpdate(
              StyleMarkdownsCompanion(
                productId: Value(productId),
                percentBp: Value(cut.basisPoints),
                amountPaise: Value(cut.amountOff?.paise),
                endsBefore: Value(markdownEndsBefore(lastDay)),
                setBy: Value(actorId),
                createdAt: Value(previous?.createdAt ?? at),
                updatedAt: Value(at),
              ),
            );
      },
    );
  }

  /// Takes the markdown off a style (the full MRP applies again). Needs
  /// `setMarkdown`. Does nothing when there is none.
  Future<void> remove({
    required Role? role,
    required String actorId,
    required String productId,
  }) async {
    require(role, Permission.setMarkdown);
    await _writer.run<void>(
      action: 'markdown.remove',
      entityType: 'style_markdown',
      entityId: productId,
      actor: actorId,
      body: () async {
        await (_db.delete(
          _db.styleMarkdowns,
        )..where((m) => m.productId.equals(productId))).go();
      },
    );
  }
}
