// Entering a purchase (GRN) in a Size x Color grid. Owner decisions,
// 2026-11-20: every cell has its own quantity, cost and MRP; the counter keeps
// filling its current lot and moves to the next only when a purchase does not
// fit (a purchase is never split across lots: the assistant's rule, please
// confirm). The database part is `StockRepository` in the app.

import 'barcode.dart';
import 'money.dart';

/// One cell of the grid.
final class PurchaseLine {
  const PurchaseLine({
    required this.size,
    required this.color,
    required this.quantity,
    required this.cost,
    required this.mrp,
  });

  final String size;
  final String color;
  final int quantity;

  /// What the owner paid for one garment. Sensitive: never shown to cashiers.
  final Money cost;

  /// The price printed on the tag of each of these garments.
  final Money mrp;
}

final class PurchaseDraft {
  const PurchaseDraft({
    required this.supplier,
    required this.style,
    required this.lines,
  });

  final String supplier;
  final String style;
  final List<PurchaseLine> lines;
}

enum PurchaseProblem {
  blankSupplier,
  blankStyle,
  noLines,
  blankSize,
  blankColor,
  badQuantity,
  duplicateLine,
  negativeMoney,
  tooManyForOneLot,

  /// A warning, not a problem: the owner may still sell below cost.
  mrpBelowCost,
}

final class PurchaseIssue {
  const PurchaseIssue(this.problem, {this.lineIndex});

  final PurchaseProblem problem;

  /// The grid line the issue is about, if any.
  final int? lineIndex;

  bool get isWarning => problem == PurchaseProblem.mrpBelowCost;

  @override
  String toString() => 'PurchaseIssue($problem, line $lineIndex)';
}

/// The most garments one lot can hold (serials 0000 to 9999).
const int garmentsPerLot = Barcode.maxSerial + 1;

String _clean(String text) => text.trim();
String _key(String text) => text.trim().toLowerCase();

/// Checks a purchase. An empty result means it is fine; entries with
/// `isWarning` do not stop it being saved.
List<PurchaseIssue> checkPurchase(PurchaseDraft draft) {
  final issues = <PurchaseIssue>[];
  if (_clean(draft.supplier).isEmpty) {
    issues.add(const PurchaseIssue(PurchaseProblem.blankSupplier));
  }
  if (_clean(draft.style).isEmpty) {
    issues.add(const PurchaseIssue(PurchaseProblem.blankStyle));
  }
  if (draft.lines.isEmpty) {
    issues.add(const PurchaseIssue(PurchaseProblem.noLines));
  }
  final seen = <String>{};
  var total = 0;
  for (var i = 0; i < draft.lines.length; i++) {
    final l = draft.lines[i];
    if (_clean(l.size).isEmpty) {
      issues.add(PurchaseIssue(PurchaseProblem.blankSize, lineIndex: i));
    }
    if (_clean(l.color).isEmpty) {
      issues.add(PurchaseIssue(PurchaseProblem.blankColor, lineIndex: i));
    }
    if (l.quantity < 1) {
      issues.add(PurchaseIssue(PurchaseProblem.badQuantity, lineIndex: i));
    } else {
      total += l.quantity;
    }
    if (_clean(l.size).isNotEmpty &&
        _clean(l.color).isNotEmpty &&
        !seen.add('${_key(l.size)}|${_key(l.color)}')) {
      issues.add(PurchaseIssue(PurchaseProblem.duplicateLine, lineIndex: i));
    }
    if (l.cost.paise < 0 || l.mrp.paise < 0) {
      issues.add(PurchaseIssue(PurchaseProblem.negativeMoney, lineIndex: i));
    } else if (l.mrp < l.cost) {
      issues.add(PurchaseIssue(PurchaseProblem.mrpBelowCost, lineIndex: i));
    }
  }
  if (total > garmentsPerLot) {
    issues.add(const PurchaseIssue(PurchaseProblem.tooManyForOneLot));
  }
  return issues;
}

/// One garment to create, with its barcode.
final class PlannedArticle {
  const PlannedArticle({
    required this.lineIndex,
    required this.size,
    required this.color,
    required this.mrp,
    required this.barcode,
  });

  final int lineIndex;
  final String size;
  final String color;
  final Money mrp;
  final Barcode barcode;
}

/// What saving a purchase will create, with names cleaned of extra spaces.
final class PurchasePlan {
  const PurchasePlan({
    required this.supplier,
    required this.style,
    required this.lot,
    required this.lines,
    required this.articles,
    required this.cursor,
  });

  final String supplier;
  final String style;

  /// The lot all of this purchase's barcodes come from.
  final int lot;
  final List<PurchaseLine> lines;
  final List<PlannedArticle> articles;

  /// Where the counter is after this purchase; save it with the purchase.
  final LotCursor cursor;
}

/// Plans a purchase: issues barcodes from [cursor] for [year] and [month].
/// Throws [ArgumentError] if the purchase has problems (warnings are fine),
/// and [RangeExhausted] if the counter has no lots left. Pure: nothing is saved.
PurchasePlan planPurchase(
  PurchaseDraft draft,
  LotCursor cursor, {
  required int year,
  required int month,
}) {
  final problems = checkPurchase(draft).where((i) => !i.isWarning).toList();
  if (problems.isNotEmpty) {
    throw ArgumentError('the purchase has problems: $problems');
  }
  final lines = [
    for (final l in draft.lines)
      PurchaseLine(
        size: _clean(l.size),
        color: _clean(l.color),
        quantity: l.quantity,
        cost: l.cost,
        mrp: l.mrp,
      ),
  ];
  final total = lines.fold<int>(0, (sum, l) => sum + l.quantity);
  var from = cursor;
  if (total > garmentsPerLot - from.nextSerial) {
    from = from.nextLot();
  }
  final issued = from.issue(total, year: year, month: month);
  final articles = <PlannedArticle>[];
  var next = 0;
  for (var i = 0; i < lines.length; i++) {
    for (var n = 0; n < lines[i].quantity; n++) {
      articles.add(
        PlannedArticle(
          lineIndex: i,
          size: lines[i].size,
          color: lines[i].color,
          mrp: lines[i].mrp,
          barcode: issued.barcodes[next++],
        ),
      );
    }
  }
  return PurchasePlan(
    supplier: _clean(draft.supplier),
    style: _clean(draft.style),
    lot: from.lot,
    lines: lines,
    articles: articles,
    cursor: issued.cursor,
  );
}
