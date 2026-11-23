// The owner's daily report (P2-7c): one India day at a time with previous and
// next arrows, starting on today. It only shows what ReportRepository returns;
// profit appears only when the repository filled it in (manager and owner).
// If the daybook disagrees with the bills and returns, a warning says so.
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/report_repository.dart';
import '../../data/shift_repository.dart';
import '../bill_pdf.dart' show billDateText;
import '../services.dart';
import '../session_controller.dart';
import 'chart_parts.dart';
import 'ui_tokens.dart';

/// "₹1,499.50", or "-₹200.00" for a loss (formatRupees refuses negatives).
String signedRupees(Money m) =>
    m.paise < 0 ? '-${formatRupees(Money(-m.paise))}' : formatRupees(m);

const Map<PaymentMode, String> _paymentNames = {
  PaymentMode.cash: 'Cash',
  PaymentMode.upi: 'UPI',
  PaymentMode.card: 'Card',
  PaymentMode.creditNote: 'Credit note',
};

const Map<RefundMode, String> _refundNames = {
  RefundMode.cash: 'Cash',
  RefundMode.upi: 'UPI',
  RefundMode.card: 'Card',
  RefundMode.creditNote: 'Credit note',
};

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({
    super.key,
    required this.session,
    required this.services,
  });

  final SessionController session;
  final AppServices services;

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  late ShopDay _day = _today;
  DailyReport? _report;
  String? _error;
  int? _hoverHour;
  bool _asTable = false;
  List<CategoryNode> _nodes = const [];

  ShopDay get _today => ShopDay.fromUtc(widget.session.now);

  @override
  void initState() {
    super.initState();
    _load();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = widget.services.categories;
    if (cats == null) {
      return;
    }
    try {
      final list = await cats.list(role: widget.session.user?.role);
      if (mounted) {
        setState(() => _nodes = [for (final e in list) e.node]);
      }
    } on PermissionDenied {
      // no category card
    }
  }

  Future<void> _load() async {
    setState(() {
      _report = null;
      _error = null;
    });
    final day = _day;
    try {
      final r = await widget.services.reports.dailyReport(
        role: widget.session.user!.role,
        day: day,
      );
      if (mounted && day == _day) {
        setState(() => _report = r);
      }
    } on PermissionDenied {
      if (mounted) {
        setState(
          () => _error = 'Only the manager or the owner can see reports.',
        );
      }
    }
  }

  void _go(ShopDay day) {
    widget.session.noteActivity();
    _day = day;
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        'Daily report · ${widget.services.currentBrand.displayName}',
        key: const Key('report-title'),
      ),
    ),
    body: Column(
      children: [
        _dayBar(context),
        Expanded(child: _body(context)),
      ],
    ),
  );

  Widget _dayBar(BuildContext context) {
    final isToday = !_day.compareTo(_today).isNegative;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            key: const Key('day-prev'),
            tooltip: 'Previous day',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _go(_day.previous),
          ),
          SizedBox(
            width: 160,
            child: Text(
              _day.format(),
              key: const Key('day-text'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            key: const Key('day-next'),
            tooltip: 'Next day',
            icon: const Icon(Icons.chevron_right),
            onPressed: isToday ? null : () => _go(_day.next),
          ),
          const SizedBox(width: 12),
          TextButton(
            key: const Key('day-today'),
            onPressed: isToday ? null : () => _go(_today),
            child: const Text('Today'),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_error != null) {
      return Center(child: Text(_error!, key: const Key('report-error')));
    }
    final r = _report;
    if (r == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      key: const Key('report-list'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!r.matchesDaybook)
            Container(
              key: const Key('mismatch-warning'),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              color: scheme.errorContainer,
              child: Text(
                'The daybook does not agree with the bills and returns for this day. '
                'Do not rely on these totals until this is checked.',
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ..._charts(context, r),
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              'The numbers',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          _section(context, 'Sales', [
            _line('Sales total', formatRupees(r.salesTotal), 'sales-total'),
            _line('Bills', '${r.billCount}', 'bill-count'),
            _line('Garments sold', '${r.garmentsSold}', 'garments-sold'),
            _line(
              'Discounts given',
              formatRupees(r.discountsTotal),
              'discounts',
            ),
            _line('Markdowns', formatRupees(r.markdownsTotal), 'markdowns'),
            if (r.gstOnSales.paise > 0 || r.gstOnReturns.paise > 0) ...[
              _line(
                'GST in these sales (unverified)',
                formatRupees(r.gstOnSales),
                'gst-on-sales',
              ),
              _line(
                'GST in garments returned',
                formatRupees(r.gstOnReturns),
                'gst-on-returns',
              ),
              _line('GST to pass on', formatRupees(r.netGst), 'gst-net'),
            ],
          ]),
          _section(context, 'Returns', [
            _line('Returns taken', '${r.returnCount}', 'return-count'),
            _line(
              'Garments returned',
              '${r.garmentsReturned}',
              'garments-returned',
            ),
            _line('Refunded', formatRupees(r.refundsTotal), 'refunds-total'),
            _line('Net sales', formatRupees(r.netSales), 'net-sales'),
          ]),
          _section(context, 'Money taken', [
            for (final m in PaymentMode.values)
              if (r.moneyIn[m] != null)
                _line(
                  _paymentNames[m]!,
                  formatRupees(r.moneyIn[m]!),
                  'money-${m.dbValue}',
                ),
            _line('Total taken', formatRupees(r.moneyInTotal), 'money-total'),
          ]),
          _section(context, 'Refunds paid out', [
            if (r.refundsByMode.isEmpty)
              const Text('No refunds.', key: Key('no-refunds')),
            for (final m in RefundMode.values)
              if (r.refundsByMode[m] != null)
                _line(
                  _refundNames[m]!,
                  formatRupees(r.refundsByMode[m]!),
                  'refund-${m.dbValue}',
                ),
          ]),
          if (r.owedNew.paise > 0 ||
              r.duesReceived.isNotEmpty ||
              r.returnOffsets.paise > 0 ||
              r.writtenOff.paise > 0 ||
              r.totalOwedNow.paise > 0)
            _section(context, 'Pay later', [
              _line(
                'Left to pay later today',
                formatRupees(r.owedNew),
                'dues-new',
              ),
              for (final m in [
                PaymentMode.cash,
                PaymentMode.upi,
                PaymentMode.card,
              ])
                if (r.duesReceived[m] != null)
                  _line(
                    'Paid against dues: ${_paymentNames[m]!}',
                    formatRupees(r.duesReceived[m]!),
                    'dues-paid-${m.dbValue}',
                  ),
              if (r.returnOffsets.paise > 0)
                _line(
                  'Taken off what is owed by returns',
                  formatRupees(r.returnOffsets),
                  'dues-offsets',
                ),
              if (r.writtenOff.paise > 0)
                _line(
                  'Written off',
                  formatRupees(r.writtenOff),
                  'dues-written-off',
                ),
              _line(
                'Everyone owes now',
                formatRupees(r.totalOwedNow),
                'dues-owed-now',
              ),
            ]),
          _section(context, 'Cash count at shift close', [
            if (r.shiftCloses.isEmpty)
              const Text('No shift closed on this day.', key: Key('no-closes')),
            for (final c in r.shiftCloses) _closeLine(context, c),
          ]),
          _section(context, 'Top styles', [
            if (r.topStyles.isEmpty)
              const Text('No sales this day.', key: Key('no-sales')),
            for (var i = 0; i < r.topStyles.length; i++)
              _line(
                '${i + 1}. ${r.topStyles[i].name}',
                '${r.topStyles[i].quantity} sold, ${formatRupees(r.topStyles[i].value)}',
                'style-$i',
              ),
          ]),
          if (r.profit != null)
            _section(context, 'Profit', [
              _line(
                'Cost of goods',
                signedRupees(r.costOfGoods!),
                'cost-of-goods',
              ),
              _line(
                r.profit!.paise < 0 ? 'Loss' : 'Profit',
                signedRupees(r.profit!),
                'profit',
              ),
            ]),
        ],
      ),
    );
  }

  // ---- charts, with the same numbers as tables ------------------------------------

  Widget _chartCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? badge,
    required Widget child,
  }) {
    final t = Theme.of(context).textTheme;
    final w = MediaQuery.sizeOf(context).width - 32;
    return SizedBox(
      width: w >= 900 ? (w - 16) / 2 : w,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle, style: t.bodyMedium),
                ),
              const SizedBox(height: 14),
              child,
              ?badge,
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpis(BuildContext context, DailyReport r) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final w = MediaQuery.sizeOf(context).width - 32;
    final cols = w >= 900 ? 4 : 2;
    final cardW = (w - 14 * (cols - 1)) / cols;
    Widget tile(
      String label,
      String key,
      String value,
      String sub, {
      bool hero = false,
    }) {
      final fg = hero ? scheme.onPrimary : null;
      return SizedBox(
        width: cardW,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: hero ? scheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: hero ? scheme.primary : UiColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: t.bodyMedium?.copyWith(color: fg)),
              Text(
                value,
                key: Key(key),
                style: (hero ? t.headlineLarge : t.headlineMedium)?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
              Text(sub, style: t.bodySmall?.copyWith(color: fg)),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        tile(
          'Net sales',
          'kpi-net',
          signedRupees(r.netSales),
          'after returns',
          hero: true,
        ),
        tile(
          'Sales',
          'kpi-sales',
          formatRupees(r.salesTotal),
          '${r.billCount} bills, ${r.garmentsSold} garments',
        ),
        tile(
          'Refunded',
          'kpi-refunded',
          formatRupees(r.refundsTotal),
          '${r.returnCount} returns',
        ),
        if (r.profit != null)
          tile(
            'Profit (manager and owner only)',
            'kpi-profit',
            signedRupees(r.profit!),
            'cost of goods ${signedRupees(r.costOfGoods!)}',
          ),
      ],
    );
  }

  List<Widget> _charts(BuildContext context, DailyReport r) {
    final modes = [
      for (final m in PaymentMode.values)
        if ((r.moneyIn[m]?.paise ?? 0) > 0) (m, r.moneyIn[m]!),
    ]..sort((a, b) => b.$2.paise.compareTo(a.$2.paise));
    final moneyTotal = modes.fold<int>(0, (a, e) => a + e.$2.paise);
    final refunds = [
      for (final m in RefundMode.values)
        if ((r.refundsByMode[m]?.paise ?? 0) > 0) (m, r.refundsByMode[m]!),
    ]..sort((a, b) => b.$2.paise.compareTo(a.$2.paise));
    final styles = r.topStyles;
    final billsTotal = r.billsByHour.fold<int>(0, (a, b) => a + b);
    final hoursWithBills = [
      for (var h = 0; h < 24; h++)
        if (r.billsByHour[h] > 0) h,
    ];

    Widget empty(String text, String key) => Text(text, key: Key(key));

    final hoursCard = _chartCard(
      context,
      title: 'Bills through the day',
      subtitle: 'Number of bills in each hour',
      child: billsTotal == 0
          ? empty('No bills this day.', 'chart-no-bills')
          : _asTable
          ? ChartTable(
              key: const Key('table-hours'),
              headers: const ['Hour', 'Bills', 'Sales'],
              rows: [
                for (final h in hoursWithBills)
                  [
                    '${hourText(h)} to ${hourText((h + 1) % 24)}',
                    '${r.billsByHour[h]}',
                    formatRupees(r.salesByHour[h]),
                  ],
              ],
            )
          : HourColumns(
              counts: r.billsByHour,
              hover: _hoverHour,
              onHover: (h) => setState(() => _hoverHour = h),
              extraReadout: (h) => ', ${formatRupees(r.salesByHour[h])}',
            ),
    );

    final moneyCard = _chartCard(
      context,
      title: 'Money taken',
      subtitle: 'By how the customer paid, from the daybook',
      badge: r.matchesDaybook && modes.isNotEmpty
          ? Container(
              key: const Key('chart-daybook-ok'),
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: UiColors.successSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 16, color: UiColors.successInk),
                  SizedBox(width: 8),
                  Text(
                    'Matches the daybook',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: UiColors.successInk,
                    ),
                  ),
                ],
              ),
            )
          : null,
      child: modes.isEmpty
          ? empty('No money taken.', 'chart-no-money')
          : _asTable
          ? ChartTable(
              key: const Key('table-money'),
              headers: const ['How paid', 'Amount', 'Share'],
              rows: [
                for (final e in modes)
                  [
                    _paymentNames[e.$1]!,
                    formatRupees(e.$2),
                    '${e.$2.paise * 100 ~/ moneyTotal}%',
                  ],
                ['Total taken', formatRupees(r.moneyInTotal), '100%'],
              ],
            )
          : Column(
              children: [
                for (final e in modes)
                  RankedBarRow(
                    key: Key('chart-money-${e.$1.dbValue}'),
                    label: _paymentNames[e.$1]!,
                    value: formatRupees(e.$2),
                    extra: '${e.$2.paise * 100 ~/ moneyTotal}%',
                    fraction: e.$2.paise / modes.first.$2.paise,
                  ),
              ],
            ),
    );

    final refundsCard = _chartCard(
      context,
      title: 'Refunds paid out',
      subtitle: 'By how they were paid back',
      child: refunds.isEmpty
          ? empty('No refunds.', 'chart-no-refunds')
          : _asTable
          ? ChartTable(
              key: const Key('table-refunds'),
              headers: const ['Paid back by', 'Amount'],
              rows: [
                for (final e in refunds)
                  [_refundNames[e.$1]!, formatRupees(e.$2)],
                ['Total refunded', formatRupees(r.refundsPaidTotal)],
              ],
            )
          : Column(
              children: [
                for (final e in refunds)
                  RankedBarRow(
                    key: Key('chart-refund-${e.$1.dbValue}'),
                    label: _refundNames[e.$1]!,
                    value: formatRupees(e.$2),
                    fraction: e.$2.paise / refunds.first.$2.paise,
                  ),
              ],
            ),
    );

    final stylesCard = _chartCard(
      context,
      title: 'Best sellers',
      subtitle: 'Garments sold, by style',
      child: styles.isEmpty
          ? empty('No sales this day.', 'chart-no-sales')
          : _asTable
          ? ChartTable(
              key: const Key('table-styles'),
              headers: const ['Style', 'Sold', 'Sales'],
              rows: [
                for (final s in styles)
                  [s.name, '${s.quantity}', formatRupees(s.value)],
              ],
            )
          : Column(
              children: [
                for (final s in styles)
                  RankedBarRow(
                    key: Key('chart-style-${s.name}'),
                    label: s.name,
                    value: '${s.quantity} sold',
                    extra: formatRupees(s.value),
                    fraction: s.quantity / styles.first.quantity,
                  ),
              ],
            ),
    );

    // Sales by category (owner, 2026-11-23): shown once the shop has set some up.
    final catSums = sumByCategory(_nodes, r.categoryValue, byGroup: false);
    final catQty = sumByCategory(_nodes, r.categoryQuantity, byGroup: false);
    final catRows = catSums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final catTotal = catSums.values.fold<int>(0, (a, b) => a + b);
    String catLabel(String? id) =>
        id == null ? 'No category' : categoryPath(_nodes, id);
    final categoriesCard = _nodes.isEmpty
        ? null
        : _chartCard(
            context,
            title: 'Sales by category',
            subtitle: 'What sold today, by the category of the style',
            child: catRows.isEmpty
                ? empty('No sales this day.', 'chart-no-category-sales')
                : _asTable
                ? ChartTable(
                    key: const Key('table-categories'),
                    headers: const ['Category', 'Sold', 'Sales', 'Share'],
                    rows: [
                      for (final e in catRows)
                        [
                          catLabel(e.key),
                          '${catQty[e.key] ?? 0}',
                          formatRupees(Money(e.value)),
                          '${e.value * 100 ~/ catTotal}%',
                        ],
                    ],
                  )
                : Column(
                    children: [
                      for (final e in catRows)
                        RankedBarRow(
                          key: Key('chart-category-${catLabel(e.key)}'),
                          label: catLabel(e.key),
                          value: formatRupees(Money(e.value)),
                          extra: '${e.value * 100 ~/ catTotal}%',
                          fraction: e.value / catRows.first.value,
                        ),
                    ],
                  ),
          );

    final closes = r.shiftCloses;
    final closesCard = _chartCard(
      context,
      title: 'Cash over and short',
      subtitle: 'Shifts closed this day. Only managers and the owner see this; the cashier counted blind.',
      child: closes.isEmpty
          ? empty('No shift closed on this day.', 'chart-no-closes')
          : _asTable
          ? ChartTable(
              key: const Key('table-closes'),
              headers: const ['Cashier', 'Expected', 'Counted', 'Result'],
              rows: [
                for (final c in closes)
                  [
                    c.cashierName,
                    formatRupees(c.expected),
                    formatRupees(c.counted),
                    switch (c.variance.kind) {
                      VarianceKind.exact => 'Exact',
                      VarianceKind.short =>
                        'Short ${formatRupees(Money(c.variance.difference.paise.abs()))}',
                      VarianceKind.over =>
                        'Over ${formatRupees(Money(c.variance.difference.paise.abs()))}',
                    },
                  ],
              ],
            )
          : CashCloseBars(
              closes: [
                for (final c in closes.reversed)
                  CloseBar(
                    name: c.cashierName,
                    sub: billDateText(c.closedAt).substring(11),
                    variance: c.variance.difference,
                  ),
              ],
            ),
    );

    return [
      _kpis(context, r),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          key: const Key('report-table-toggle'),
          onPressed: () => setState(() => _asTable = !_asTable),
          icon: Icon(_asTable ? Icons.bar_chart : Icons.table_rows),
          label: Text(_asTable ? 'Show the charts' : 'Show charts as tables'),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          hoursCard,
          moneyCard,
          stylesCard,
          ?categoriesCard,
          refundsCard,
          closesCard,
        ],
      ),
      const SizedBox(height: 20),
    ];
  }

  Widget _section(BuildContext context, String title, List<Widget> children) =>
      Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      );

  Widget _line(String label, String value, String key) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, key: Key(key)),
      ],
    ),
  );

  Widget _closeLine(BuildContext context, ShiftCloseReport c) {
    final abs = Money(c.variance.difference.paise.abs());
    final label = switch (c.variance.kind) {
      VarianceKind.exact => 'Exact',
      VarianceKind.short => 'Short ${formatRupees(abs)}',
      VarianceKind.over => 'Over ${formatRupees(abs)}',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${c.cashierName}: expected ${formatRupees(c.expected)}, '
              'counted ${formatRupees(c.counted)}',
            ),
          ),
          Text(
            'Breaks ${breakMinutesText(c.breakTime)}',
            key: Key('close-breaks-${c.shiftId}'),
            style: const TextStyle(color: UiColors.inkSoft),
          ),
          const SizedBox(width: 16),
          Text(label, key: Key('close-variance-${c.shiftId}')),
        ],
      ),
    );
  }
}
