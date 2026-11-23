// GST reports (P3-4 second step, Manager Mode): the invoice register, returns
// register, tax by rate and by day for a range of days, and an export of CSV
// files for the owner's CA. UNVERIFIED until the CA confirms which reports and
// columns they need. Data: GstReportRepository.
import 'dart:convert';
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/gst_report_repository.dart';
import '../services.dart';
import '../session_controller.dart';
import 'ui_tokens.dart';

class GstReportScreen extends StatefulWidget {
  const GstReportScreen({
    super.key,
    required this.session,
    required this.services,
    this.today,
  });

  final SessionController session;
  final AppServices services;

  /// The shop's today (tests fix it); the real clock when null.
  final ShopDay? today;

  @override
  State<GstReportScreen> createState() => _GstReportScreenState();
}

class _GstReportScreenState extends State<GstReportScreen> {
  late final ShopDay _today =
      widget.today ?? ShopDay.fromUtc(DateTime.now().toUtc());
  late final _from = TextEditingController(
    text: shopDayText(ShopDay(_today.year, _today.month, 1)),
  );
  late final _to = TextEditingController(text: shopDayText(_today));
  GstReport? _report;
  String? _message;
  bool _good = false;

  GstReportRepository get _repo => widget.services.gstReports!;
  Role? get _role => widget.session.user?.role;

  @override
  void initState() {
    super.initState();
    _show();
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  void _say(String t, {bool good = false}) => setState(() {
    _message = t;
    _good = good;
  });

  Future<void> _show() async {
    final a = parseShopDay(_from.text);
    final b = parseShopDay(_to.text);
    if (a == null || b == null) {
      _say('Type both days as day/month/year, like 01/11/2026.');
      return;
    }
    if (b.compareTo(a) < 0) {
      _say('The last day is before the first day.');
      return;
    }
    try {
      final r = await _repo.report(role: _role, from: a, to: b);
      if (mounted) {
        setState(() {
          _report = r;
          _message = null;
        });
      }
    } on PermissionDenied {
      _say('You may not see this.');
    }
  }

  void _range(ShopDay a, ShopDay b) {
    _from.text = shopDayText(a);
    _to.text = shopDayText(b);
    _show();
  }

  String _stamp(ShopDay d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  Future<void> _export() async {
    final r = _report;
    if (r == null) {
      return;
    }
    final folder = await widget.services.pickers.folder();
    if (folder == null) {
      return;
    }
    final span = '${_stamp(r.from)}-to-${_stamp(r.to)}';
    final files = {
      'gst-invoices-$span.csv': r.invoicesCsv(),
      'gst-returns-$span.csv': r.returnsCsv(),
      'gst-summary-$span.csv': r.summaryCsv(),
    };
    try {
      for (final e in files.entries) {
        // A byte order mark so a spreadsheet reads the names as UTF-8.
        await File('$folder${Platform.pathSeparator}${e.key}')
            .writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode('${e.value}\r\n')]);
      }
      _say('Saved ${files.length} files in $folder.', good: true);
    } on Object catch (e) {
      _say('Could not save the files: $e');
    }
  }

  Widget _tile(String label, String value, String key) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: UiColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: UiColors.inkSoft)),
        Text(
          value,
          key: Key(key),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );

  Widget _section(String title, List<Widget> rows, {String? key}) => Card(
    margin: const EdgeInsets.only(top: 16),
    child: Padding(
      key: key == null ? null : Key(key),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    ),
  );

  Widget _row(List<String> cells, {String? key, bool head = false}) => Padding(
    key: key == null ? null : Key(key),
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(
            flex: i == 0 ? 3 : 2,
            child: Text(
              cells[i],
              textAlign: i == 0 ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                fontWeight: head ? FontWeight.w700 : FontWeight.w400,
                color: head ? UiColors.inkSoft : UiColors.ink,
              ),
            ),
          ),
      ],
    ),
  );

  String _rate(int? bp) =>
      bp == null ? 'mixed' : markdownLabel(PriceCut.percentBp(bp));

  @override
  Widget build(BuildContext context) {
    final r = _report;
    return Scaffold(
      appBar: AppBar(title: const Text('GST reports')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            key: const Key('gst-report-unverified'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: UiColors.amberSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'These figures come from the tax kept on each bill. Which reports '
              'and columns your CA needs is unverified: show them this page and '
              'the exported files before you rely on them. Not built yet: sales '
              'by HSN code, sales to business customers with a GSTIN, purchases '
              'and input tax.',
              style: TextStyle(color: UiColors.amberInk),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 170,
                child: TextField(
                  key: const Key('gst-from'),
                  controller: _from,
                  decoration: const InputDecoration(labelText: 'From (d/m/y)'),
                  onSubmitted: (_) => _show(),
                ),
              ),
              SizedBox(
                width: 170,
                child: TextField(
                  key: const Key('gst-to'),
                  controller: _to,
                  decoration: const InputDecoration(labelText: 'To (d/m/y)'),
                  onSubmitted: (_) => _show(),
                ),
              ),
              FilledButton(
                key: const Key('gst-show'),
                onPressed: _show,
                child: const Text('Show'),
              ),
              ActionChip(
                key: const Key('gst-range-today'),
                label: const Text('Today'),
                onPressed: () => _range(_today, _today),
              ),
              ActionChip(
                key: const Key('gst-range-month'),
                label: const Text('This month'),
                onPressed: () =>
                    _range(ShopDay(_today.year, _today.month, 1), _today),
              ),
              ActionChip(
                key: const Key('gst-range-last'),
                label: const Text('Last month'),
                onPressed: () {
                  final first = ShopDay(_today.year, _today.month, 1);
                  final lastDay = first.previous;
                  _range(ShopDay(lastDay.year, lastDay.month, 1), lastDay);
                },
              ),
              OutlinedButton.icon(
                key: const Key('gst-export'),
                onPressed: r == null ? null : _export,
                icon: const Icon(Icons.download),
                label: const Text('Export for the CA'),
              ),
            ],
          ),
          if (_message != null)
            Container(
              key: const Key('gst-report-message'),
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _good ? UiColors.successSoft : UiColors.dangerSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _message!,
                style: TextStyle(
                  color: _good ? UiColors.successInk : UiColors.dangerInk,
                ),
              ),
            ),
          if (r == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _tile('GST invoices', '${r.invoices.length}', 'tile-invoices'),
                _tile('Taxable value', formatRupees(r.taxable), 'tile-taxable'),
                _tile('Tax charged', formatRupees(r.tax), 'tile-tax'),
                _tile(
                  'Tax returned',
                  formatRupees(r.returnedTax),
                  'tile-returned',
                ),
                _tile('Net tax', formatRupees(r.netTax), 'tile-net'),
              ],
            ),
            if (r.billsWithoutGst > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${r.billsWithoutGst} ${r.billsWithoutGst == 1 ? 'bill was' : 'bills were'} '
                  'made while GST was off (no tax; not listed below).',
                  key: const Key('bills-without-gst'),
                ),
              ),
            _section('Tax by rate', [
              if (r.byRate.isEmpty)
                const Text('No tax in this range.', key: Key('no-rates')),
              if (r.byRate.isNotEmpty)
                _row([
                  'Rate',
                  'Taxable',
                  'Tax',
                  'Returned',
                  'Net tax',
                ], head: true),
              for (final x in r.byRate)
                _row([
                  _rate(x.rateBp),
                  formatRupees(x.taxable),
                  formatRupees(x.tax),
                  formatRupees(x.returnedTax),
                  formatRupees(x.netTax),
                ], key: 'rate-${x.rateBp}'),
            ]),
            _section('Day by day', [
              if (r.byDay.isEmpty)
                const Text('No days with tax.', key: Key('no-days')),
              if (r.byDay.isNotEmpty)
                _row([
                  'Day',
                  'Invoices',
                  'Tax',
                  'Returned',
                  'Net tax',
                ], head: true),
              for (final d in r.byDay)
                _row([
                  shopDayText(d.day),
                  '${d.invoices}',
                  formatRupees(d.tax),
                  formatRupees(d.returnedTax),
                  formatRupees(d.netTax),
                ], key: 'day-${shopDayText(d.day)}'),
            ]),
            _section('Invoice register', [
              if (r.invoices.isEmpty)
                const Text(
                  'No GST invoices in this range.',
                  key: Key('no-invoices'),
                ),
              if (r.invoices.isNotEmpty)
                _row([
                  'Invoice',
                  'Taxable',
                  'CGST',
                  'SGST',
                  'Total',
                ], head: true),
              for (final i in r.invoices)
                _row([
                  '${i.billNo}  ${shopDayText(i.day)}'
                      '${i.customer.isEmpty ? '' : '  ${i.customer}'}',
                  formatRupees(i.taxable),
                  formatRupees(i.cgst),
                  formatRupees(i.sgst),
                  formatRupees(i.total),
                ], key: 'invoice-${i.billNo}'),
            ]),
            _section('Returns register', [
              if (r.returns.isEmpty)
                const Text(
                  'No returns with tax in this range.',
                  key: Key('no-returns'),
                ),
              if (r.returns.isNotEmpty)
                _row([
                  'Return',
                  'Taxable',
                  'CGST',
                  'SGST',
                  'Refund',
                ], head: true),
              for (var i = 0; i < r.returns.length; i++)
                _row([
                  '${shopDayText(r.returns[i].day)}  of ${r.returns[i].billNos}',
                  formatRupees(r.returns[i].taxable),
                  formatRupees(r.returns[i].cgst),
                  formatRupees(r.returns[i].sgst),
                  formatRupees(r.returns[i].refund),
                ], key: 'return-$i'),
            ]),
          ],
        ],
      ),
    );
  }
}
