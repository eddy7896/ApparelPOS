// The owner's daily report (P2-7c): one India day at a time with previous and
// next arrows, starting on today. It only shows what ReportRepository returns;
// profit appears only when the repository filled it in (manager and owner).
// If the daybook disagrees with the bills and returns, a warning says so.
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/report_repository.dart';
import '../../data/shift_repository.dart';
import '../services.dart';
import '../session_controller.dart';

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

  ShopDay get _today => ShopDay.fromUtc(widget.session.now);

  @override
  void initState() {
    super.initState();
    _load();
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
    appBar: AppBar(title: const Text('Daily report')),
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
    return ListView(
      key: const Key('report-list'),
      padding: const EdgeInsets.all(16),
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
        _section(context, 'Sales', [
          _line('Sales total', formatRupees(r.salesTotal), 'sales-total'),
          _line('Bills', '${r.billCount}', 'bill-count'),
          _line('Garments sold', '${r.garmentsSold}', 'garments-sold'),
          _line('Discounts given', formatRupees(r.discountsTotal), 'discounts'),
          _line('Markdowns', formatRupees(r.markdownsTotal), 'markdowns'),
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
    );
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
          Text(label, key: Key('close-variance-${c.shiftId}')),
        ],
      ),
    );
  }
}
