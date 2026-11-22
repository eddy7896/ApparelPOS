// Manager Mode home (UX-4): a left rail with every place a manager or owner
// goes, and a "Today" page with a greeting, the backup warning, the day so far
// and the shifts. Everything here comes from the daily report and the shifts;
// no cost or profit is shown on this page (the daily report screen has those
// for the people allowed to see them).
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/report_repository.dart';
import '../bill_pdf.dart' show billDateText;
import '../services.dart';
import '../session_controller.dart';
import 'backup_banner.dart';
import 'backup_screen.dart';
import 'brand_preview_dialog.dart';
import 'daily_report_screen.dart';
import 'register_screen.dart';
import 'returns_screen.dart';
import 'shift_closes_screen.dart';
import 'stock_entry_screen.dart';

class ManagerHome extends StatefulWidget {
  const ManagerHome({super.key, required this.session, required this.services});

  final SessionController session;
  final AppServices services;

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  DailyReport? _today;
  int _openShifts = 0;

  SessionController get _session => widget.session;
  AppServices get _s => widget.services;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final report = await _s.reports.dailyReport(
        role: _session.user?.role,
        day: ShopDay.fromUtc(_session.now),
      );
      final open = await _s.shifts.openShiftCount();
      if (mounted) {
        setState(() {
          _today = report;
          _openShifts = open;
        });
      }
    } on PermissionDenied {
      // nothing to show
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    await _load(); // numbers may have changed
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 900;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _rail(context, narrow),
        const VerticalDivider(width: 1),
        Expanded(child: _page(context)),
      ],
    );
  }

  // ---- the rail ----------------------------------------------------------------

  Widget _rail(BuildContext context, bool narrow) {
    final items = <_NavItem>[
      _NavItem('nav-today', Icons.home, 'Today', null),
      _NavItem(
        'billing-button',
        Icons.point_of_sale,
        'Billing',
        () => _open(RegisterScreen(session: _session, services: _s)),
      ),
      _NavItem(
        'returns-button',
        Icons.assignment_return,
        'Returns',
        () => _open(ReturnsScreen(session: _session, services: _s)),
      ),
      _NavItem(
        'stock-entry-button',
        Icons.inventory_2,
        'Stock entry',
        () => _open(StockEntryScreen(session: _session, services: _s)),
      ),
      _NavItem(
        'daily-report-button',
        Icons.bar_chart,
        'Daily report',
        () => _open(DailyReportScreen(session: _session, services: _s)),
      ),
      _NavItem(
        'shift-closes-button',
        Icons.fact_check,
        'Shift closes',
        () => _open(ShiftClosesScreen(session: _session, services: _s)),
      ),
      _NavItem(
        'backups-button',
        Icons.backup,
        'Backups',
        () => _open(BackupScreen(session: _session, services: _s)),
      ),
    ];
    return SizedBox(
      width: narrow ? 84 : 232,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final i in items) _navTile(context, i, narrow),
          if (_s.brandPreview && _s.brand != null)
            _navTile(
              context,
              _NavItem(
                'brand-preview-button',
                Icons.palette,
                'Try a look (development only)',
                () => showDialog<void>(
                  context: context,
                  builder: (_) =>
                      BrandPreviewDialog(session: _session, services: _s),
                ),
              ),
              narrow,
            ),
        ],
      ),
    );
  }

  Widget _navTile(BuildContext context, _NavItem item, bool narrow) {
    final scheme = Theme.of(context).colorScheme;
    final selected = item.onTap == null;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: Material(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            key: Key(item.key),
            borderRadius: BorderRadius.circular(10),
            onTap: item.onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: narrow ? 8 : 14),
                child: Row(
                  mainAxisAlignment: narrow
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Icon(item.icon, color: fg, size: 22),
                    if (!narrow) ...[
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          item.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fg,
                            fontSize: 16,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- the Today page -------------------------------------------------------------

  Widget _page(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final local = _session.now.toUtc().add(shopUtcOffset);
    final name = _session.user!.name;
    return Column(
      children: [
        BackupBanner(session: _session, services: _s),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                '${greetingFor(_session.now)}, $name',
                key: const Key('home-greeting'),
                style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                _dateText(local),
                key: const Key('home-date'),
                style: t.titleMedium,
              ),
              const SizedBox(height: 20),
              Text('So far today', style: t.titleSmall),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth >= 720 ? 4 : 2;
                  return _stats(context, (c.maxWidth - 14 * (cols - 1)) / cols);
                },
              ),
              const SizedBox(height: 20),
              _shiftsCard(context),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  key: const Key('home-open-report'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    textStyle: t.titleMedium,
                  ),
                  onPressed: () =>
                      _open(DailyReportScreen(session: _session, services: _s)),
                  child: const Text("Open today's report"),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
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

  String _dateText(DateTime local) =>
      '${_days[local.weekday - 1]} ${local.day} ${_months[local.month - 1]} ${local.year}';

  Widget _stats(BuildContext context, double cardWidth) {
    final r = _today;
    Widget card(String key, String label, String value) => SizedBox(
      width: cardWidth,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                value,
                key: Key(key),
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
    final dash = r == null;
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        card('stat-sales', 'Sales', dash ? '…' : formatRupees(r.salesTotal)),
        card('stat-bills', 'Bills', dash ? '…' : '${r.billCount}'),
        card(
          'stat-garments',
          'Garments sold',
          dash ? '…' : '${r.garmentsSold}',
        ),
        card('stat-returns', 'Returns', dash ? '…' : '${r.returnCount}'),
      ],
    );
  }

  Widget _shiftsCard(BuildContext context) {
    final r = _today;
    final t = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shifts', style: t.titleLarge),
            const SizedBox(height: 8),
            Text(
              _openShifts == 0
                  ? 'No shift is open now.'
                  : '$_openShifts ${_openShifts == 1 ? 'shift is' : 'shifts are'} open now.',
              key: const Key('home-open-shifts'),
            ),
            if (r != null)
              for (final c in r.shiftCloses)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${c.cashierName}: closed ${billDateText(c.closedAt)}, '
                    '${switch (c.variance.kind) {
                      VarianceKind.exact => 'exact',
                      VarianceKind.short => 'short ${formatRupees(Money(c.variance.difference.paise.abs()))}',
                      VarianceKind.over => 'over ${formatRupees(Money(c.variance.difference.paise.abs()))}',
                    }}',
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  _NavItem(this.key, this.icon, this.label, this.onTap);
  final String key;
  final IconData icon;
  final String label;

  /// Null for the page that is showing now.
  final VoidCallback? onTap;
}
