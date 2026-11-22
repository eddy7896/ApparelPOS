// The owner's analytics: sales day by day against the period before, bills by
// hour, money by payment mode, best sellers, sell-through and slow movers, and
// the last shift closes. Needs `viewReports` (manager, owner); profit needs
// `viewMargins` as well and is the only place here that reads cost (E-AUTHZ-1).
// Days are India calendar days (ADR-0007). Integer paise only (E-MONEY-1).
// The numbers use the same definitions as the daily report.
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';

/// One style's sell-through since it came into the shop.
final class StyleThrough {
  const StyleThrough({
    required this.name,
    required this.bought,
    required this.sold,
    required this.firstBought,
    required this.slow,
    this.categoryId,
  });
  final String name;
  final int bought;
  final int sold;
  final DateTime firstBought;
  final bool slow;

  /// The category of the style, or null.
  final String? categoryId;

  int get percent => sellThroughPercent(bought: bought, sold: sold);
  int get unsold => bought - sold;
}

/// One shift close for the cash over and short chart.
final class CloseSummary {
  const CloseSummary({
    required this.cashierName,
    required this.closedAt,
    required this.variance,
  });
  final String cashierName;
  final DateTime closedAt;

  /// Counted minus expected: negative is short.
  final Money variance;
}

final class AnalyticsOverview {
  const AnalyticsOverview({
    required this.range,
    required this.current,
    required this.previous,
    required this.billsByHour,
    required this.moneyIn,
    required this.styles,
    required this.sellThrough,
    required this.recentCloses,
    required this.returnCount,
    required this.profit,
    required this.insights,
    this.categoryValue = const {},
    this.categoryValuePrevious = const {},
    this.categoryQuantity = const {},
  });

  final AnalyticsRange range;

  /// Sales (paise) and garments by category id (null for none) in the range,
  /// and the sales in the period before.
  final Map<String?, int> categoryValue;
  final Map<String?, int> categoryValuePrevious;
  final Map<String?, int> categoryQuantity;

  /// The days of the range, oldest first, then the same number of days before.
  final List<DayTotal> current;
  final List<DayTotal> previous;

  /// Bills made in each hour (0 to 23) of the shop's day, over the range.
  final List<int> billsByHour;
  final Map<PaymentMode, Money> moneyIn;

  /// Every style sold in the range (the screen ranks them).
  final List<StyleSales> styles;
  final List<StyleThrough> sellThrough;

  /// The last shift closes, oldest first.
  final List<CloseSummary> recentCloses;
  final int returnCount;

  /// Null unless the person may see margins.
  final Money? profit;
  final TrendInsights insights;

  Money get netTotal => current.fold(Money.zero, (a, d) => a + d.net);
  Money get previousNetTotal => previous.fold(Money.zero, (a, d) => a + d.net);
  int get billCount => current.fold(0, (a, d) => a + d.bills);
  int? get change => changeBp(netTotal, previousNetTotal);
}

class AnalyticsRepository {
  AnalyticsRepository(this._db, {DateTime Function()? now})
    : _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _db;
  final DateTime Function() _now;

  /// India local time is UTC plus this many seconds; stored times are UTC
  /// seconds, so grouping by shop day shifts them first.
  static final int _offsetSeconds = shopUtcOffset.inSeconds;

  Future<Map<String, int>> _byDay(
    String sql,
    DateTime from,
    DateTime until,
  ) async {
    final rows = await _db
        .customSelect(
          sql,
          variables: [Variable<DateTime>(from), Variable<DateTime>(until)],
        )
        .get();
    return {for (final r in rows) r.read<String>('d'): r.read<int>('v')};
  }

  String _key(ShopDay d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// The overview for the [range] ending on today. Needs `viewReports`; profit
  /// only with `viewMargins`. Throws [PermissionDenied] otherwise.
  Future<AnalyticsOverview> overview({
    required Role? role,
    required AnalyticsRange range,
  }) async {
    require(role, Permission.viewReports);
    final now = _now();
    final today = ShopDay.fromUtc(now);
    final all = daysEndingAt(today, range.days * 2);
    final from = all.first.startUtc;
    final until = today.endUtc;
    final cutoff = all[range.days].startUtc;

    final salesByDay = await _byDay(
      'SELECT strftime(\'%Y-%m-%d\', billed_at + $_offsetSeconds, \'unixepoch\') AS d, '
      'COALESCE(SUM(total_paise), 0) AS v FROM bills '
      'WHERE billed_at >= ? AND billed_at < ? GROUP BY d',
      from,
      until,
    );
    final billsByDay = await _byDay(
      'SELECT strftime(\'%Y-%m-%d\', billed_at + $_offsetSeconds, \'unixepoch\') AS d, '
      'COUNT(*) AS v FROM bills WHERE billed_at >= ? AND billed_at < ? GROUP BY d',
      from,
      until,
    );
    final refundsByDay = await _byDay(
      'SELECT strftime(\'%Y-%m-%d\', returned_at + $_offsetSeconds, \'unixepoch\') AS d, '
      'COALESCE(SUM(total_paise), 0) AS v FROM returns '
      'WHERE returned_at >= ? AND returned_at < ? GROUP BY d',
      from,
      until,
    );
    final totals = [
      for (final d in all)
        DayTotal(
          day: d,
          sales: Money(salesByDay[_key(d)] ?? 0),
          refunds: Money(refundsByDay[_key(d)] ?? 0),
          bills: billsByDay[_key(d)] ?? 0,
        ),
    ];
    final previous = totals.sublist(0, range.days);
    final current = totals.sublist(range.days);

    // Bills by hour of the shop's day, over the range only.
    final hourRows = await _db
        .customSelect(
          'SELECT CAST(strftime(\'%H\', billed_at + $_offsetSeconds, \'unixepoch\') AS INTEGER) AS h, '
          'COUNT(*) AS v FROM bills WHERE billed_at >= ? AND billed_at < ? GROUP BY h',
          variables: [Variable<DateTime>(cutoff), Variable<DateTime>(until)],
        )
        .get();
    final byHour = List<int>.filled(24, 0);
    for (final r in hourRows) {
      byHour[r.read<int>('h')] = r.read<int>('v');
    }

    // Money taken by each mode, from the daybook.
    final moneyIn = <PaymentMode, Money>{};
    final modeRows = await _db
        .customSelect(
          "SELECT kind, SUM(amount_paise) AS total FROM daybook "
          "WHERE at >= ? AND at < ? AND kind LIKE 'SALE_%' GROUP BY kind",
          variables: [Variable<DateTime>(cutoff), Variable<DateTime>(until)],
        )
        .get();
    for (final r in modeRows) {
      final kind = r.read<String>('kind');
      final mode = PaymentMode.fromDb(
        kind.substring(kind.indexOf('_') + 1).toLowerCase(),
      );
      if (mode != null) {
        moneyIn[mode] = Money(r.read<int>('total'));
      }
    }

    // Best sellers in the range.
    final styleRows = await _db
        .customSelect(
          'SELECT l.product_name AS name, COUNT(*) AS qty, SUM(l.final_paise) AS val '
          'FROM bill_lines l JOIN bills b ON b.id = l.bill_id '
          'WHERE b.billed_at >= ? AND b.billed_at < ? GROUP BY l.product_name',
          variables: [Variable<DateTime>(cutoff), Variable<DateTime>(until)],
        )
        .get();
    final styles = [
      for (final r in styleRows)
        StyleSales(
          name: r.read<String>('name'),
          quantity: r.read<int>('qty'),
          value: Money(r.read<int>('val')),
        ),
    ];

    Future<(Map<String?, int>, Map<String?, int>)> byCategory(
      DateTime a,
      DateTime b,
    ) async {
      final rows = await _db
          .customSelect(
            'SELECT p.category_id AS c, COUNT(*) AS q, SUM(l.final_paise) AS v '
            'FROM bill_lines l JOIN bills bl ON bl.id = l.bill_id '
            'JOIN articles a ON a.id = l.article_id '
            'JOIN variants vr ON vr.id = a.variant_id '
            'JOIN products p ON p.id = vr.product_id '
            'WHERE bl.billed_at >= ? AND bl.billed_at < ? GROUP BY p.category_id',
            variables: [Variable<DateTime>(a), Variable<DateTime>(b)],
          )
          .get();
      return (
        {for (final r in rows) r.read<String?>('c'): r.read<int>('v')},
        {for (final r in rows) r.read<String?>('c'): r.read<int>('q')},
      );
    }

    final (catValue, catQty) = await byCategory(cutoff, until);
    final (catValuePrev, _) = await byCategory(from, cutoff);

    final returnCount =
        (await _db
                .customSelect(
                  'SELECT COUNT(*) AS v FROM returns WHERE returned_at >= ? AND returned_at < ?',
                  variables: [
                    Variable<DateTime>(cutoff),
                    Variable<DateTime>(until),
                  ],
                )
                .getSingle())
            .read<int>('v');

    // Sell-through since each style came in (all time, not the range).
    final throughRows = await _db
        .customSelect(
          'SELECT p.name AS name, p.category_id AS cat, COUNT(*) AS bought, '
          "SUM(CASE WHEN a.status = 'SOLD' THEN 1 ELSE 0 END) AS sold, "
          'MIN(b.purchased_at) AS first '
          'FROM articles a JOIN variants v ON v.id = a.variant_id '
          'JOIN products p ON p.id = v.product_id '
          'JOIN batches b ON b.id = a.batch_id GROUP BY p.id, p.name '
          'ORDER BY p.name',
        )
        .get();
    final through = [
      for (final r in throughRows)
        () {
          final bought = r.read<int>('bought');
          final sold = r.read<int>('sold');
          final first = r.read<DateTime>('first').toUtc();
          return StyleThrough(
            name: r.read<String>('name'),
            bought: bought,
            sold: sold,
            firstBought: first,
            categoryId: r.read<String?>('cat'),
            slow: isSlowMover(
              bought: bought,
              sold: sold,
              firstBought: first,
              now: now,
            ),
          );
        }(),
    ];

    final closeRows = await _db
        .customSelect(
          'SELECT u.name AS name, c.closed_at AS at, c.variance_paise AS v '
          'FROM shift_closes c JOIN shifts s ON s.id = c.shift_id '
          'JOIN users u ON u.id = s.cashier_id '
          'ORDER BY c.closed_at DESC, c.id DESC LIMIT 8',
        )
        .get();
    final closes = [
      for (final r in closeRows.reversed)
        CloseSummary(
          cashierName: r.read<String>('name'),
          closedAt: r.read<DateTime>('at').toUtc(),
          variance: Money(r.read<int>('v')),
        ),
    ];

    Money? profit;
    if (can(role, Permission.viewMargins)) {
      profit = await _profit(cutoff, until, current);
    }

    return AnalyticsOverview(
      range: range,
      current: current,
      previous: previous,
      billsByHour: byHour,
      moneyIn: moneyIn,
      styles: styles,
      sellThrough: through,
      recentCloses: closes,
      returnCount: returnCount,
      profit: profit,
      insights: analyseTrend(current),
      categoryValue: catValue,
      categoryValuePrevious: catValuePrev,
      categoryQuantity: catQty,
    );
  }

  /// Net sales less the cost of goods sold in the range, as in the daily
  /// report. Reads cost: call only after the margin check.
  Future<Money> _profit(
    DateTime from,
    DateTime until,
    List<DayTotal> current,
  ) async {
    Future<int> sum(String sql) async =>
        (await _db
                .customSelect(
                  sql,
                  variables: [
                    Variable<DateTime>(from),
                    Variable<DateTime>(until),
                  ],
                )
                .getSingle())
            .read<int>('v');
    final sold = await sum(
      'SELECT COALESCE(SUM(c.unit_cost_paise), 0) AS v '
      'FROM bill_lines l JOIN bills b ON b.id = l.bill_id '
      'JOIN articles a ON a.id = l.article_id '
      'JOIN batch_lines c ON c.batch_id = a.batch_id AND c.variant_id = a.variant_id '
      'WHERE b.billed_at >= ? AND b.billed_at < ?',
    );
    final restocked = await sum(
      'SELECT COALESCE(SUM(c.unit_cost_paise), 0) AS v '
      'FROM return_lines rl JOIN returns r ON r.id = rl.return_id '
      'JOIN articles a ON a.id = rl.article_id '
      'JOIN batch_lines c ON c.batch_id = a.batch_id AND c.variant_id = a.variant_id '
      "WHERE rl.outcome = 'RESTOCK' AND r.returned_at >= ? AND r.returned_at < ?",
    );
    final net = current.fold(Money.zero, (a, d) => a + d.net);
    return grossProfit(
      netSales: net,
      costOfGoods: costOfGoods(
        sold: Money(sold),
        restockedReturns: Money(restocked),
      ),
    );
  }
}
