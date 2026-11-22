// The owner's daily report for one India day: sales, bills and garments, money
// by payment mode and refunds by mode (from the daybook), discounts and
// returns, cash variance per shift, the top styles, and profit. Needs
// `viewReports`; profit needs `viewMargins` as well, and it is the only place
// here that reads cost (manager and owner only, E-AUTHZ-1). Rules are in
// core_domain (ShopDay, netSales, costOfGoods, grossProfit, topStyles).
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';
import 'shift_repository.dart';

/// One day's report.
final class DailyReport {
  const DailyReport({
    required this.day,
    required this.billCount,
    required this.garmentsSold,
    required this.salesTotal,
    required this.moneyIn,
    required this.refundsByMode,
    required this.returnCount,
    required this.garmentsReturned,
    required this.refundsTotal,
    required this.discountsTotal,
    required this.markdownsTotal,
    required this.netSales,
    required this.shiftCloses,
    required this.topStyles,
    required this.costOfGoods,
    required this.profit,
    required this.billsByHour,
    required this.salesByHour,
    this.categoryValue = const {},
    this.categoryQuantity = const {},
  });

  final ShopDay day;
  final int billCount;
  final int garmentsSold;

  /// What bills came to (after markdown and discount).
  final Money salesTotal;

  /// Money taken by each payment mode (cash is after change given).
  final Map<PaymentMode, Money> moneyIn;

  /// Refunds paid out by each refund mode (positive amounts).
  final Map<RefundMode, Money> refundsByMode;
  final int returnCount;
  final int garmentsReturned;

  /// What returns came to.
  final Money refundsTotal;

  /// Cashier discounts given, and markdowns applied.
  final Money discountsTotal;
  final Money markdownsTotal;
  final Money netSales;

  /// Shifts closed during the day, with their variance.
  final List<ShiftCloseReport> shiftCloses;
  final List<StyleSales> topStyles;

  /// What was sold in the day by category id (null for none): paise and
  /// garments. They add up to the day's sales.
  final Map<String?, int> categoryValue;
  final Map<String?, int> categoryQuantity;

  /// Bills made and what they came to in each hour (0 to 23) of the day.
  final List<int> billsByHour;
  final List<Money> salesByHour;

  /// Null unless the person may see margins.
  final Money? costOfGoods;
  final Money? profit;

  Money get moneyInTotal =>
      moneyIn.values.fold<Money>(Money.zero, (a, b) => a + b);
  Money get refundsPaidTotal =>
      refundsByMode.values.fold<Money>(Money.zero, (a, b) => a + b);

  /// True when the daybook agrees with the bills and returns: money taken
  /// equals sales, and refunds paid equal what returns came to.
  bool get matchesDaybook =>
      moneyInTotal == salesTotal && refundsPaidTotal == refundsTotal;
}

class ReportRepository {
  ReportRepository(this._db);

  final AppDatabase _db;

  Future<int> _int(String sql, ShopDay day) async {
    final r = await _db
        .customSelect(
          sql,
          variables: [
            Variable<DateTime>(day.startUtc),
            Variable<DateTime>(day.endUtc),
          ],
        )
        .getSingle();
    return r.read<int>('v');
  }

  /// The report for [day]. Needs `viewReports`; profit is filled in only when
  /// [role] also has `viewMargins`. Throws [PermissionDenied] otherwise.
  Future<DailyReport> dailyReport({
    required Role? role,
    required ShopDay day,
  }) async {
    require(role, Permission.viewReports);
    final billCount = await _int(
      'SELECT COUNT(*) AS v FROM bills WHERE billed_at >= ? AND billed_at < ?',
      day,
    );
    final salesTotal = Money(
      await _int(
        'SELECT COALESCE(SUM(total_paise), 0) AS v FROM bills '
        'WHERE billed_at >= ? AND billed_at < ?',
        day,
      ),
    );
    Future<int> lineSum(String expr) => _int(
      'SELECT COALESCE(SUM($expr), 0) AS v FROM bill_lines l '
      'JOIN bills b ON b.id = l.bill_id WHERE b.billed_at >= ? AND b.billed_at < ?',
      day,
    );
    final garmentsSold = await _int(
      'SELECT COUNT(*) AS v FROM bill_lines l JOIN bills b ON b.id = l.bill_id '
      'WHERE b.billed_at >= ? AND b.billed_at < ?',
      day,
    );
    final discounts = Money(await lineSum('l.discount_paise'));
    final markdowns = Money(await lineSum('l.markdown_paise'));

    final returnCount = await _int(
      'SELECT COUNT(*) AS v FROM returns WHERE returned_at >= ? AND returned_at < ?',
      day,
    );
    final refundsTotal = Money(
      await _int(
        'SELECT COALESCE(SUM(total_paise), 0) AS v FROM returns '
        'WHERE returned_at >= ? AND returned_at < ?',
        day,
      ),
    );
    final garmentsReturned = await _int(
      'SELECT COUNT(*) AS v FROM return_lines rl JOIN returns r ON r.id = rl.return_id '
      'WHERE r.returned_at >= ? AND r.returned_at < ?',
      day,
    );

    final moneyIn = <PaymentMode, Money>{};
    final refundsByMode = <RefundMode, Money>{};
    final rows = await _db
        .customSelect(
          'SELECT kind, SUM(amount_paise) AS total FROM daybook '
          'WHERE at >= ? AND at < ? GROUP BY kind',
          variables: [
            Variable<DateTime>(day.startUtc),
            Variable<DateTime>(day.endUtc),
          ],
        )
        .get();
    for (final r in rows) {
      final kind = r.read<String>('kind');
      final total = r.read<int>('total');
      final text = kind.substring(kind.indexOf('_') + 1).toLowerCase();
      if (kind.startsWith('SALE_')) {
        final mode = PaymentMode.fromDb(text);
        if (mode != null) {
          moneyIn[mode] = Money(total);
        }
      } else if (kind.startsWith('REFUND_')) {
        final mode = RefundMode.fromDb(text);
        if (mode != null) {
          refundsByMode[mode] = Money(-total);
        }
      }
    }

    final styleRows = await _db
        .customSelect(
          'SELECT l.product_name AS name, COUNT(*) AS qty, SUM(l.final_paise) AS val '
          'FROM bill_lines l JOIN bills b ON b.id = l.bill_id '
          'WHERE b.billed_at >= ? AND b.billed_at < ? GROUP BY l.product_name',
          variables: [
            Variable<DateTime>(day.startUtc),
            Variable<DateTime>(day.endUtc),
          ],
        )
        .get();
    final top = topStyles([
      for (final r in styleRows)
        StyleSales(
          name: r.read<String>('name'),
          quantity: r.read<int>('qty'),
          value: Money(r.read<int>('val')),
        ),
    ]);

    // Bills and sales in each hour of the shop day (India time).
    final hourRows = await _db
        .customSelect(
          'SELECT CAST(strftime(\'%H\', billed_at + ${shopUtcOffset.inSeconds}, \'unixepoch\') AS INTEGER) AS h, '
          'COUNT(*) AS n, COALESCE(SUM(total_paise), 0) AS t FROM bills '
          'WHERE billed_at >= ? AND billed_at < ? GROUP BY h',
          variables: [
            Variable<DateTime>(day.startUtc),
            Variable<DateTime>(day.endUtc),
          ],
        )
        .get();
    final billsByHour = List<int>.filled(24, 0);
    final salesByHour = List<Money>.filled(24, Money.zero);
    for (final r in hourRows) {
      billsByHour[r.read<int>('h')] = r.read<int>('n');
      salesByHour[r.read<int>('h')] = Money(r.read<int>('t'));
    }

    final catRows = await _db
        .customSelect(
          'SELECT p.category_id AS c, COUNT(*) AS q, SUM(l.final_paise) AS v '
          'FROM bill_lines l JOIN bills bl ON bl.id = l.bill_id '
          'JOIN articles a ON a.id = l.article_id '
          'JOIN variants vr ON vr.id = a.variant_id '
          'JOIN products p ON p.id = vr.product_id '
          'WHERE bl.billed_at >= ? AND bl.billed_at < ? GROUP BY p.category_id',
          variables: [
            Variable<DateTime>(day.startUtc),
            Variable<DateTime>(day.endUtc),
          ],
        )
        .get();

    final closes = await _closesOn(day);
    final net = netSales(sales: salesTotal, refunds: refundsTotal);

    Money? cost;
    Money? profit;
    if (can(role, Permission.viewMargins)) {
      cost = await _costOfGoods(day);
      profit = grossProfit(netSales: net, costOfGoods: cost);
    }

    return DailyReport(
      day: day,
      billCount: billCount,
      garmentsSold: garmentsSold,
      salesTotal: salesTotal,
      moneyIn: moneyIn,
      refundsByMode: refundsByMode,
      returnCount: returnCount,
      garmentsReturned: garmentsReturned,
      refundsTotal: refundsTotal,
      discountsTotal: discounts,
      markdownsTotal: markdowns,
      netSales: net,
      shiftCloses: closes,
      topStyles: top,
      costOfGoods: cost,
      profit: profit,
      billsByHour: billsByHour,
      salesByHour: salesByHour,
      categoryValue: {
        for (final r in catRows) r.read<String?>('c'): r.read<int>('v'),
      },
      categoryQuantity: {
        for (final r in catRows) r.read<String?>('c'): r.read<int>('q'),
      },
    );
  }

  Future<List<ShiftCloseReport>> _closesOn(ShopDay day) async {
    final rows = await _db
        .customSelect(
          'SELECT s.id AS id, u.name AS name, s.opened_at AS opened_at, '
          's.opening_paise AS opening, c.closed_at AS closed_at, '
          'c.counted_paise AS counted, c.expected_paise AS expected '
          'FROM shift_closes c JOIN shifts s ON s.id = c.shift_id '
          'JOIN users u ON u.id = s.cashier_id '
          'WHERE c.closed_at >= ? AND c.closed_at < ? '
          'ORDER BY c.closed_at DESC, c.id DESC',
          variables: [
            Variable<DateTime>(day.startUtc),
            Variable<DateTime>(day.endUtc),
          ],
        )
        .get();
    return [
      for (final r in rows)
        ShiftCloseReport(
          shiftId: r.read<String>('id'),
          cashierName: r.read<String>('name'),
          openedAt: r.read<DateTime>('opened_at').toUtc(),
          closedAt: r.read<DateTime>('closed_at').toUtc(),
          opening: Money(r.read<int>('opening')),
          expected: Money(r.read<int>('expected')),
          counted: Money(r.read<int>('counted')),
          variance: CashVariance(
            expected: Money(r.read<int>('expected')),
            counted: Money(r.read<int>('counted')),
          ),
        ),
    ];
  }

  /// Cost of the garments sold on [day], less the cost of those returned that
  /// day and put back in stock. Reads cost: call only after the margin check.
  Future<Money> _costOfGoods(ShopDay day) async {
    final sold = await _int(
      'SELECT COALESCE(SUM(c.unit_cost_paise), 0) AS v '
      'FROM bill_lines l JOIN bills b ON b.id = l.bill_id '
      'JOIN articles a ON a.id = l.article_id '
      'JOIN batch_lines c ON c.batch_id = a.batch_id AND c.variant_id = a.variant_id '
      'WHERE b.billed_at >= ? AND b.billed_at < ?',
      day,
    );
    final restocked = await _int(
      'SELECT COALESCE(SUM(c.unit_cost_paise), 0) AS v '
      'FROM return_lines rl JOIN returns r ON r.id = rl.return_id '
      'JOIN articles a ON a.id = rl.article_id '
      'JOIN batch_lines c ON c.batch_id = a.batch_id AND c.variant_id = a.variant_id '
      "WHERE rl.outcome = 'RESTOCK' AND r.returned_at >= ? AND r.returned_at < ?",
      day,
    );
    return costOfGoods(sold: Money(sold), restockedReturns: Money(restocked));
  }
}
