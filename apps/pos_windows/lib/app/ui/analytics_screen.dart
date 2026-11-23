// Analytics for the manager and owner (the mock-up's board 8): sales each day
// against the period before, a plain reading of the trend, the busiest hours,
// how customers paid, best sellers, how much of each style has sold (with slow
// movers), and cash over and short. Everything comes from AnalyticsRepository;
// profit shows only when the repository filled it in (manager and owner).
// Charts are drawn here with no extra package. Colors come from ChartColors.
import 'dart:math' as math;

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/analytics_repository.dart';
import '../services.dart';
import '../session_controller.dart';
import 'chart_colors.dart';
import 'daily_report_screen.dart' show signedRupees;

const List<String> _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _dayText(ShopDay d, {bool withMonth = true}) {
  final wd = DateTime.utc(d.year, d.month, d.day).weekday;
  final short = _weekdays[wd - 1].substring(0, 3);
  return withMonth
      ? '$short ${d.day} ${_months[d.month - 1]}'
      : '$short ${d.day}';
}

const Map<PaymentMode, String> _modeNames = {
  PaymentMode.cash: 'Cash',
  PaymentMode.upi: 'UPI',
  PaymentMode.card: 'Card',
  PaymentMode.creditNote: 'Credit note',
};

/// A whole-rupee amount for a chart axis: "₹20k" from 20,000 rupees up.
String _axisRupees(int paise) {
  final rupees = paise ~/ 100;
  if (rupees >= 1000) {
    final k = rupees / 1000;
    return '₹${k == k.roundToDouble() ? k.round() : k.toStringAsFixed(1)}k';
  }
  return '₹$rupees';
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
    required this.session,
    required this.services,
  });

  final SessionController session;
  final AppServices services;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsRange _range = AnalyticsRange.week;
  AnalyticsOverview? _data;
  String? _error;
  int? _hoverDay;
  int? _hoverHour;
  bool _byQuantity = true;
  bool _table = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = widget.services.analytics;
    if (repo == null) {
      return;
    }
    try {
      final o = await repo.overview(
        role: widget.session.user?.role,
        range: _range,
      );
      if (mounted) {
        setState(() {
          _data = o;
          _error = null;
        });
      }
    } on PermissionDenied {
      if (mounted) {
        setState(() => _error = 'You may not see analytics.');
      }
    }
  }

  void _setRange(AnalyticsRange r) {
    if (r == _range) {
      return;
    }
    setState(() {
      _range = r;
      _hoverDay = null;
      _hoverHour = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: _error != null
          ? Center(child: Text(_error!, key: const Key('analytics-error')))
          : data == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _rangeRow(context, data),
                const SizedBox(height: 16),
                _kpis(context, data),
                const SizedBox(height: 16),
                _trendCard(context, data),
                const SizedBox(height: 16),
                _insights(context, data),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _sized(context, _hoursCard(context, data)),
                    _sized(context, _modesCard(context, data)),
                    _sized(context, _sellersCard(context, data)),
                    _sized(context, _throughCard(context, data)),
                  ],
                ),
                const SizedBox(height: 16),
                _closesCard(context, data),
              ],
            ),
    );
  }

  /// Two cards a row on a wide window, one on a narrow one.
  Widget _sized(BuildContext context, Widget child) {
    final w = MediaQuery.sizeOf(context).width - 48;
    return SizedBox(width: w >= 900 ? (w - 16) / 2 : w, child: child);
  }

  Widget _card(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? trailing,
    required Widget child,
  }) {
    final t = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                ?trailing,
              ],
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(subtitle, style: t.bodyMedium),
              ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  // ---- filter and headline numbers ---------------------------------------------

  Widget _rangeRow(BuildContext context, AnalyticsOverview d) {
    final first = d.current.first.day;
    final last = d.current.last.day;
    final prevFirst = d.previous.first.day;
    final prevLast = d.previous.last.day;
    Widget chip(String key, String label, AnalyticsRange r) => ChoiceChip(
      key: Key(key),
      label: Text(label),
      selected: _range == r,
      onSelected: (_) => _setRange(r),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            chip('range-week', 'Last 7 days', AnalyticsRange.week),
            chip('range-month', 'Last 30 days', AnalyticsRange.month),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${_dayText(first)} to ${_dayText(last)}, compared with '
          '${_dayText(prevFirst)} to ${_dayText(prevLast)}',
          key: const Key('range-text'),
        ),
      ],
    );
  }

  Widget _kpis(BuildContext context, AnalyticsOverview d) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final w = MediaQuery.sizeOf(context).width - 48;
    final cols = w >= 900 ? 4 : 2;
    final cardW = (w - 14 * (cols - 1)) / cols;
    final bills = d.billCount;
    final avg = bills == 0 ? Money.zero : Money(d.netTotal.paise ~/ bills);
    final returnsTenths = bills == 0 ? 0 : d.returnCount * 1000 ~/ bills;
    final up = (d.change ?? 0) >= 0;
    Widget tile(Widget child, {Color? color, Color? border}) => SizedBox(
      width: cardW,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color ?? scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border ?? scheme.outlineVariant),
        ),
        child: child,
      ),
    );
    Widget label(String s, {Color? color}) =>
        Text(s, style: t.bodyMedium?.copyWith(color: color));
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        tile(
          color: scheme.primary,
          border: scheme.primary,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label('Net sales', color: scheme.onPrimary),
              Text(
                signedRupees(d.netTotal),
                key: const Key('kpi-net'),
                style: t.displaySmall?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                children: [
                  if (d.change != null)
                    Icon(
                      up ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color: scheme.onPrimary,
                    ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${changeText(d.change)}'
                      '${d.change == null ? '' : ' on the ${_range == AnalyticsRange.week ? 'week' : 'month'} before'}',
                      key: const Key('kpi-change'),
                      style: t.bodyMedium?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        tile(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label('Bills'),
              Text(
                '$bills',
                key: const Key('kpi-bills'),
                style: t.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                'average bill ${formatRupees(avg)}',
                key: const Key('kpi-avg'),
              ),
            ],
          ),
        ),
        tile(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label('Returns'),
              Text(
                '${returnsTenths ~/ 10}.${returnsTenths % 10}%',
                key: const Key('kpi-returns'),
                style: t.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text('${d.returnCount} returns of $bills bills'),
            ],
          ),
        ),
        if (d.profit != null)
          tile(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label('Profit (manager and owner only)'),
                Text(
                  signedRupees(d.profit!),
                  key: const Key('kpi-profit'),
                  style: t.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  d.netTotal.paise <= 0
                      ? 'cost of goods not shown'
                      : '${d.profit!.paise * 100 ~/ d.netTotal.paise}% of net sales',
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ---- sales each day ----------------------------------------------------------

  Widget _trendCard(BuildContext context, AnalyticsOverview d) {
    final scheme = Theme.of(context).colorScheme;
    final word = _range == AnalyticsRange.week ? 'week' : 'month';
    return _card(
      context,
      title: 'Sales each day',
      trailing: OutlinedButton(
        key: const Key('trend-table-toggle'),
        onPressed: () => setState(() => _table = !_table),
        child: Text(_table ? 'Show the chart' : 'Show as a table'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 20,
            runSpacing: 6,
            children: [
              _legendLine(ChartColors.series, 'This $word', false),
              _legendLine(ChartColors.previous, 'The $word before', true),
            ],
          ),
          const SizedBox(height: 12),
          if (_table)
            _trendTable(context, d)
          else
            SizedBox(
              height: 280,
              child: _TrendChart(
                key: const Key('trend-chart'),
                current: d.current,
                previous: d.previous,
                hover: _hoverDay,
                onHover: (i) => setState(() => _hoverDay = i),
                gridColor: scheme.outlineVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _legendLine(Color color, String text, bool dashed) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 26,
        height: 2,
        child: dashed
            ? Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    Container(width: 6, height: 2, color: color),
                    if (i < 2) const SizedBox(width: 4),
                  ],
                ],
              )
            : ColoredBox(color: color),
      ),
      const SizedBox(width: 8),
      Text(text),
    ],
  );

  Widget _trendTable(BuildContext context, AnalyticsOverview d) {
    final rows = <TableRow>[
      TableRow(
        children: [
          for (final h in ['Day', 'Net sales', 'Bills', 'Period before'])
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                h,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      for (var i = d.current.length - 1; i >= 0; i--)
        TableRow(
          children: [
            _cell(_dayText(d.current[i].day)),
            _cell(signedRupees(d.current[i].net), bold: true),
            _cell('${d.current[i].bills}'),
            _cell(signedRupees(d.previous[i].net)),
          ],
        ),
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: SingleChildScrollView(
        child: Table(
          key: const Key('trend-table'),
          columnWidths: const {0: FlexColumnWidth(1.4)},
          children: rows,
        ),
      ),
    );
  }

  Widget _cell(String s, {bool bold = false}) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(
      s,
      style: TextStyle(fontWeight: bold ? FontWeight.w600 : FontWeight.w400),
    ),
  );

  // ---- what the days say -----------------------------------------------------

  Widget _insights(BuildContext context, AnalyticsOverview d) {
    final i = d.insights;
    final lines = <(String, String)>[];
    final word = _range == AnalyticsRange.week ? 'week' : 'month';
    if (d.billCount == 0) {
      lines.add(('insight-none', 'No bills in this $word yet.'));
    } else {
      lines.add((
        'insight-trend',
        switch (i.direction) {
          TrendDirection.rising =>
            'Sales are rising: the later days of this $word sold more than the earlier days.',
          TrendDirection.falling =>
            'Sales are falling: the later days of this $word sold less than the earlier days.',
          TrendDirection.steady => 'Sales are steady across this $word.',
        },
      ));
      final best = i.bestDay!;
      lines.add((
        'insight-best-day',
        'Best day: ${_dayText(best.day)}, ${signedRupees(best.net)}.',
      ));
      if (i.strongestWeekday != null &&
          i.strongestWeekday != i.weakestWeekday) {
        lines.add((
          'insight-weekday',
          '${_weekdays[i.strongestWeekday! - 1]}s are your strongest day '
              '(about ${signedRupees(i.strongestWeekdayAverage!)} net); '
              '${_weekdays[i.weakestWeekday! - 1]}s are the quietest '
              '(about ${signedRupees(i.weakestWeekdayAverage!)}).',
        ));
      }
      final peak = peakHour(d.billsByHour);
      if (peak != null) {
        lines.add((
          'insight-hour',
          'Busiest time: ${hourText(peak)} to ${hourText((peak + 1) % 24)}.',
        ));
      }
      final slow = d.sellThrough.where((s) => s.slow).toList();
      if (slow.isNotEmpty) {
        lines.add((
          'insight-slow',
          '${slow.length} ${slow.length == 1 ? 'style is a slow mover' : 'styles are slow movers'}: '
              '${slow.map((s) => s.name).join(', ')}.',
        ));
      }
    }
    return _card(
      context,
      title: 'What the days say',
      subtitle: 'Worked out from the bills; nothing is guessed.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (key, text) in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(text, key: Key(key)),
            ),
        ],
      ),
    );
  }

  // ---- busiest hours -----------------------------------------------------------

  Widget _hoursCard(BuildContext context, AnalyticsOverview d) {
    final counts = d.billsByHour;
    var from = 9;
    var to = 21;
    for (var h = 0; h < 24; h++) {
      if (counts[h] > 0) {
        from = math.min(from, h);
        to = math.max(to, h);
      }
    }
    final most = counts.reduce(math.max);
    final peak = peakHour(counts);
    final shown = _hoverHour ?? peak;
    final readout = shown == null
        ? 'No bills yet.'
        : _hoverHour == null
        ? 'Busiest: ${hourText(shown)} to ${hourText((shown + 1) % 24)}, ${counts[shown]} bills. Tap a column for any hour.'
        : '${hourText(shown)} to ${hourText((shown + 1) % 24)}: ${counts[shown]} bills';
    return _card(
      context,
      title: 'Busiest hours',
      subtitle: 'Number of bills in each hour of the day',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(readout, key: const Key('hours-readout')),
          const SizedBox(height: 10),
          SizedBox(
            key: const Key('hours-chart'),
            height: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var h = from; h <= to; h++)
                  Expanded(
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _hoverHour = h),
                      onExit: (_) => setState(() => _hoverHour = null),
                      child: GestureDetector(
                        key: Key('hour-$h'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _hoverHour = h),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 18,
                                child:
                                    counts[h] > 0 &&
                                        (h == peak || h == _hoverHour)
                                    ? FittedBox(
                                        child: Text(
                                          '${counts[h]}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              Flexible(
                                child: FractionallySizedBox(
                                  heightFactor: most == 0
                                      ? 0
                                      : counts[h] / most,
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    width: 30,
                                    decoration: BoxDecoration(
                                      color: h == peak
                                          ? ChartColors.seriesDark
                                          : ChartColors.seriesLight,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                      border: h == _hoverHour
                                          ? Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: ChartColors.axis),
          Row(
            children: [
              for (var h = from; h <= to; h++)
                Expanded(
                  child: Center(
                    child: Text(
                      '${h % 12 == 0 ? 12 : h % 12}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ChartColors.mutedText,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Hour of the day, shop time (am until 11, pm from 12).',
              style: TextStyle(fontSize: 12, color: ChartColors.mutedText),
            ),
          ),
        ],
      ),
    );
  }

  // ---- how customers paid ------------------------------------------------------

  Widget _modesCard(BuildContext context, AnalyticsOverview d) {
    final entries = d.moneyIn.entries.where((e) => e.value.paise > 0).toList()
      ..sort((a, b) => b.value.paise.compareTo(a.value.paise));
    final total = entries.fold<int>(0, (a, e) => a + e.value.paise);
    return _card(
      context,
      title: 'How customers paid',
      subtitle: 'Money taken in the range, from the daybook',
      child: entries.isEmpty
          ? const Text('No money taken yet.', key: Key('modes-empty'))
          : Column(
              children: [
                for (final e in entries)
                  _rankedBar(
                    key: 'mode-${_modeNames[e.key]}',
                    label: _modeNames[e.key]!,
                    value: formatRupees(e.value),
                    extra: '${e.value.paise * 100 ~/ total}%',
                    fraction: e.value.paise / entries.first.value.paise,
                  ),
              ],
            ),
    );
  }

  Widget _rankedBar({
    required String key,
    required String label,
    required String value,
    String? extra,
    required double fraction,
  }) => Padding(
    key: Key(key),
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (extra != null) ...[const SizedBox(width: 8), Text(extra)],
          ],
        ),
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, c) => Container(
            width: c.maxWidth * fraction.clamp(0.0, 1.0),
            height: 12,
            decoration: const BoxDecoration(
              color: ChartColors.series,
              borderRadius: BorderRadius.horizontal(right: Radius.circular(6)),
            ),
          ),
        ),
      ],
    ),
  );

  // ---- best sellers -------------------------------------------------------------

  Widget _sellersCard(BuildContext context, AnalyticsOverview d) {
    final styles = [...d.styles]
      ..sort(
        (a, b) => _byQuantity
            ? b.quantity.compareTo(a.quantity)
            : b.value.paise.compareTo(a.value.paise),
      );
    final top = styles.take(6).toList();
    double scale(StyleSales s) =>
        _byQuantity ? s.quantity.toDouble() : s.value.paise.toDouble();
    final biggest = top.isEmpty ? 1.0 : math.max(scale(top.first), 1.0);
    return _card(
      context,
      title: 'Best sellers',
      trailing: Wrap(
        spacing: 6,
        children: [
          ChoiceChip(
            key: const Key('sellers-by-quantity'),
            label: const Text('Garments'),
            selected: _byQuantity,
            onSelected: (_) => setState(() => _byQuantity = true),
          ),
          ChoiceChip(
            key: const Key('sellers-by-value'),
            label: const Text('Sales'),
            selected: !_byQuantity,
            onSelected: (_) => setState(() => _byQuantity = false),
          ),
        ],
      ),
      child: top.isEmpty
          ? const Text('Nothing sold yet.', key: Key('sellers-empty'))
          : Column(
              children: [
                for (final s in top)
                  _rankedBar(
                    key: 'seller-${s.name}',
                    label: s.name,
                    value: _byQuantity
                        ? '${s.quantity} sold'
                        : formatRupees(s.value),
                    fraction: scale(s) / biggest,
                  ),
              ],
            ),
    );
  }

  // ---- how much of each style has sold ---------------------------------------

  Widget _throughCard(BuildContext context, AnalyticsOverview d) {
    final rows = [...d.sellThrough]
      ..sort((a, b) {
        if (a.slow != b.slow) {
          return a.slow ? -1 : 1;
        }
        return b.percent.compareTo(a.percent);
      });
    return _card(
      context,
      title: 'How much of each style has sold',
      subtitle:
          'Sold out of all bought, since it came in. Slow mover: '
          'in the shop $slowMoverMinDays days or more with under '
          '$slowMoverBelowPercent% sold.',
      child: rows.isEmpty
          ? const Text('No stock yet.', key: Key('through-empty'))
          : Column(
              children: [
                for (final s in rows)
                  Padding(
                    key: Key('through-${s.name}'),
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${s.percent}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${s.sold} of ${s.bought}'),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: s.percent / 100,
                            minHeight: 10,
                            color: ChartColors.series,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                        ),
                        if (s.slow)
                          Padding(
                            key: Key('slow-${s.name}'),
                            padding: const EdgeInsets.only(top: 5),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: ChartColors.caution,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Slow mover: ${s.unsold} left. Think about a markdown.',
                                    style: const TextStyle(
                                      color: ChartColors.caution,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  // ---- cash over and short -------------------------------------------------------

  Widget _closesCard(BuildContext context, AnalyticsOverview d) {
    final closes = d.recentCloses;
    final biggest = closes.fold<int>(
      0,
      (a, c) => math.max(a, c.variance.paise.abs()),
    );
    const half = 80.0;
    return _card(
      context,
      title: 'Cash over and short at shift close',
      subtitle:
          'The last ${closes.length} closes. Only managers and the owner see this; the cashier counted blind.',
      child: closes.isEmpty
          ? const Text('No shift closed yet.', key: Key('closes-empty'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 18,
                  runSpacing: 6,
                  children: [
                    _swatch(ChartColors.over, 'Over (more cash than expected)'),
                    _swatch(
                      ChartColors.short,
                      'Short (less cash than expected)',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < closes.length; i++)
                      Expanded(
                        child: Column(
                          key: Key('close-$i'),
                          children: [
                            SizedBox(
                              height: half + 20,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (closes[i].variance.paise > 0)
                                    Text(
                                      '+${formatRupees(closes[i].variance)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  if (closes[i].variance.paise > 0)
                                    Container(
                                      width: 32,
                                      height:
                                          half *
                                          closes[i].variance.paise /
                                          biggest,
                                      decoration: const BoxDecoration(
                                        color: ChartColors.over,
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(4),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(height: 1, color: ChartColors.axis),
                            SizedBox(
                              height: half + 20,
                              child: Column(
                                children: [
                                  if (closes[i].variance.paise < 0)
                                    Container(
                                      width: 32,
                                      height:
                                          half *
                                          -closes[i].variance.paise /
                                          biggest,
                                      decoration: const BoxDecoration(
                                        color: ChartColors.short,
                                        borderRadius: BorderRadius.vertical(
                                          bottom: Radius.circular(4),
                                        ),
                                      ),
                                    ),
                                  if (closes[i].variance.paise < 0)
                                    Text(
                                      '-${formatRupees(Money(-closes[i].variance.paise))}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  if (closes[i].variance.paise == 0)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Exact',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              closes[i].cashierName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _dayText(
                                ShopDay.fromUtc(closes[i].closedAt),
                                withMonth: false,
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: ChartColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _swatch(Color color, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 8),
      Text(text),
    ],
  );
}

// ---- the line chart --------------------------------------------------------------

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    super.key,
    required this.current,
    required this.previous,
    required this.hover,
    required this.onHover,
    required this.gridColor,
  });

  final List<DayTotal> current;
  final List<DayTotal> previous;
  final int? hover;
  final ValueChanged<int?> onHover;
  final Color gridColor;

  static const double left = 56;
  static const double right = 12;
  static const double top = 12;
  static const double bottom = 30;

  int get _niceMax {
    var m = 0;
    for (final d in [...current, ...previous]) {
      m = math.max(m, d.net.paise);
    }
    const step = 1000000; // ₹10,000 in paise
    return math.max(step, (m + step - 1) ~/ step * step);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final plotW = box.maxWidth - left - right;
        final n = current.length;
        double x(int i) => left + (n <= 1 ? plotW / 2 : i / (n - 1) * plotW);
        int? indexAt(Offset p) {
          if (n == 0) {
            return null;
          }
          final f = (p.dx - left) / (plotW <= 0 ? 1 : plotW);
          return (f * (n - 1)).round().clamp(0, n - 1);
        }

        final h = hover;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: MouseRegion(
                onHover: (e) => onHover(indexAt(e.localPosition)),
                onExit: (_) => onHover(null),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => onHover(indexAt(d.localPosition)),
                  onPanUpdate: (d) => onHover(indexAt(d.localPosition)),
                  child: CustomPaint(
                    painter: _TrendPainter(
                      current: current,
                      previous: previous,
                      niceMax: _niceMax,
                      hover: h,
                      gridColor: gridColor,
                      textColor: ChartColors.mutedText,
                    ),
                  ),
                ),
              ),
            ),
            if (h != null && h < n)
              Positioned(
                top: top,
                left: x(h) > box.maxWidth * 0.55 ? null : x(h) + 14,
                right: x(h) > box.maxWidth * 0.55
                    ? box.maxWidth - x(h) + 14
                    : null,
                child: IgnorePointer(
                  child: Material(
                    key: const Key('trend-tooltip'),
                    elevation: 4,
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _dayText(current[h].day),
                            key: const Key('tip-day'),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 2,
                                color: ChartColors.series,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                signedRupees(current[h].net),
                                key: const Key('tip-net'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text('  net sales'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 2,
                                color: ChartColors.previous,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                signedRupees(previous[h].net),
                                key: const Key('tip-previous'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text('  ${_dayText(previous[h].day)}'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${current[h].bills} bills',
                            key: const Key('tip-bills'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.current,
    required this.previous,
    required this.niceMax,
    required this.hover,
    required this.gridColor,
    required this.textColor,
  });

  final List<DayTotal> current;
  final List<DayTotal> previous;
  final int niceMax;
  final int? hover;
  final Color gridColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = _TrendChart.left;
    const right = _TrendChart.right;
    const top = _TrendChart.top;
    const bottom = _TrendChart.bottom;
    final plotW = size.width - left - right;
    final plotH = size.height - top - bottom;
    final n = current.length;
    if (n == 0 || plotW <= 0 || plotH <= 0) {
      return;
    }
    double x(int i) => left + (n <= 1 ? plotW / 2 : i / (n - 1) * plotW);
    double y(int paise) =>
        top + plotH - paise.clamp(0, niceMax) / niceMax * plotH;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    void text(String s, Offset at, {TextAlign align = TextAlign.left}) {
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(fontSize: 12, color: textColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = switch (align) {
        TextAlign.right => at.dx - tp.width,
        TextAlign.center => at.dx - tp.width / 2,
        _ => at.dx,
      };
      tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
    }

    // gridlines and the money scale
    for (var k = 0; k <= 4; k++) {
      final gy = top + plotH - plotH * k / 4;
      canvas.drawLine(
        Offset(left, gy),
        Offset(left + plotW, gy),
        k == 0 ? (Paint()..color = ChartColors.axis) : grid,
      );
      text(
        _axisRupees(niceMax * k ~/ 4),
        Offset(left - 8, gy),
        align: TextAlign.right,
      );
    }

    // day names under the line: every day for a week, every fifth for longer
    for (var i = 0; i < n; i++) {
      if (n <= 7 || (n - 1 - i) % 5 == 0) {
        text(
          _dayText(current[i].day, withMonth: n > 7),
          Offset(x(i), top + plotH + 16),
          align: TextAlign.center,
        );
      }
    }

    Path linePath(List<DayTotal> days) {
      final p = Path();
      for (var i = 0; i < days.length; i++) {
        final pt = Offset(x(i), y(days[i].net.paise));
        i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      return p;
    }

    // the area under this period's line
    final area = linePath(current)
      ..lineTo(x(n - 1), top + plotH)
      ..lineTo(x(0), top + plotH)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = ChartColors.series.withValues(alpha: 0.10),
    );

    // the period before, dashed
    final dashed = Paint()
      ..color = ChartColors.previous
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    for (final metric in linePath(previous).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 6, metric.length)),
          dashed,
        );
        d += 11;
      }
    }

    canvas.drawPath(
      linePath(current),
      Paint()
        ..color = ChartColors.series
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final h = hover;
    if (h != null && h < n) {
      canvas.drawLine(
        Offset(x(h), top),
        Offset(x(h), top + plotH),
        Paint()
          ..color = ChartColors.previous
          ..strokeWidth = 1,
      );
      final c = Offset(x(h), y(current[h].net.paise));
      canvas.drawCircle(c, 6, Paint()..color = Colors.white);
      canvas.drawCircle(c, 4.5, Paint()..color = ChartColors.series);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.hover != hover ||
      old.current != current ||
      old.previous != previous ||
      old.niceMax != niceMax;
}
