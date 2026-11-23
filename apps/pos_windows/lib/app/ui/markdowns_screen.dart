// Markdowns (Manager Mode, owner 2026-11-23): a manager or the owner sets a
// percentage or a fixed amount off a whole style, until a last day. The
// register applies it to every unsold garment of the style and cashiers cannot
// change it. Rules are in core_domain (markdown_rules); data in
// MarkdownRepository. Only prices are shown here, never cost.
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/markdown_repository.dart';
import '../services.dart';
import '../session_controller.dart';
import 'ui_tokens.dart';

class MarkdownsScreen extends StatefulWidget {
  const MarkdownsScreen({
    super.key,
    required this.session,
    required this.services,
  });

  final SessionController session;
  final AppServices services;

  @override
  State<MarkdownsScreen> createState() => _MarkdownsScreenState();
}

class _MarkdownsScreenState extends State<MarkdownsScreen> {
  List<MarkdownStyleEntry>? _entries;
  String? _message;
  bool _good = false;
  bool _onlyMarked = false;
  String _search = '';

  MarkdownRepository? get _repo => widget.services.markdowns;
  Role? get _role => widget.session.user?.role;
  String get _me => widget.session.user!.userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) {
      return;
    }
    try {
      final entries = await repo.list(role: _role);
      if (mounted) {
        setState(() => _entries = entries);
      }
    } on PermissionDenied {
      if (mounted) {
        setState(() => _message = 'You may not set markdowns.');
      }
    }
  }

  void _say(String text, {bool good = false}) {
    if (mounted) {
      setState(() {
        _message = text;
        _good = good;
      });
    }
  }

  Future<void> _set(MarkdownStyleEntry e) async {
    final result = await showDialog<(PriceCut, ShopDay)>(
      context: context,
      builder: (_) => _MarkdownDialog(entry: e),
    );
    if (result == null) {
      return;
    }
    try {
      await _repo!.set(
        role: _role,
        actorId: _me,
        productId: e.id,
        cut: result.$1,
        lastDay: result.$2,
      );
      await _load();
      _say(
        '${e.name}: ${markdownLabel(result.$1)} off until '
        '${shopDayText(result.$2)}.',
        good: true,
      );
    } on InvalidMarkdown catch (x) {
      _say(markdownProblemText(x.problem));
    } on UnknownStyle {
      _say('That style is no longer there.');
      await _load();
    } on PermissionDenied {
      _say('You may not do that.');
    }
  }

  Future<void> _remove(MarkdownStyleEntry e) async {
    try {
      await _repo!.remove(role: _role, actorId: _me, productId: e.id);
      await _load();
      _say('${e.name} is back at its MRP.', good: true);
    } on PermissionDenied {
      _say('You may not do that.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    return Scaffold(
      appBar: AppBar(title: const Text('Markdowns')),
      body: entries == null
          ? Center(
              child: _message != null
                  ? Text(_message!, key: const Key('markdowns-message'))
                  : const CircularProgressIndicator(),
            )
          : _body(context, entries),
    );
  }

  Widget _body(BuildContext context, List<MarkdownStyleEntry> entries) {
    final q = _search.trim().toLowerCase();
    final shown = [
      for (final e in entries)
        if ((!_onlyMarked || e.markdown != null) &&
            (q.isEmpty || e.name.toLowerCase().contains(q)))
          e,
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (_message != null)
          Container(
            key: const Key('markdowns-message'),
            margin: const EdgeInsets.only(bottom: 16),
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
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Markdowns',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'A markdown takes a percentage or an amount off every unsold '
                  'garment of a style, up to a last day. The register applies it '
                  'by itself; cashiers cannot change it, and a marked-down '
                  'garment takes no cashier discount. Bills already made never '
                  'change.',
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('markdown-search'),
                        decoration: const InputDecoration(
                          labelText: 'Find a style',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilterChip(
                      key: const Key('markdown-only'),
                      label: const Text('Only marked down'),
                      selected: _onlyMarked,
                      onSelected: (v) => setState(() => _onlyMarked = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  const Text(
                    'No styles yet. Enter stock first.',
                    key: Key('markdowns-empty'),
                  )
                else if (shown.isEmpty)
                  const Text('No style matches.', key: Key('markdowns-none')),
                for (final e in shown) _row(context, e),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, MarkdownStyleEntry e) {
    final m = e.markdown;
    final range = e.lowestMrp == null
        ? 'none in stock'
        : '${e.inStock} in stock, '
              '${e.lowestMrp == e.highestMrp ? formatRupees(e.lowestMrp!) : '${formatRupees(e.lowestMrp!)} to ${formatRupees(e.highestMrp!)}'}';
    return Container(
      key: Key('markdown-row-${e.name}'),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: UiColors.lineSoft)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(range, style: const TextStyle(color: UiColors.inkMuted)),
              ],
            ),
          ),
          if (m != null)
            Container(
              key: Key('markdown-label-${e.name}'),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: m.active ? UiColors.amberSoft : UiColors.lineSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                m.active
                    ? '${markdownLabel(m.cut)} off until ${shopDayText(m.lastDay)}'
                    : 'Ended ${shopDayText(m.lastDay)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: m.active ? UiColors.amberInk : UiColors.inkSoft,
                ),
              ),
            ),
          OutlinedButton(
            key: Key('markdown-set-${e.name}'),
            onPressed: () => _set(e),
            child: Text(m == null ? 'Set markdown' : 'Change'),
          ),
          if (m != null) ...[
            const SizedBox(width: 8),
            OutlinedButton(
              key: Key('markdown-remove-${e.name}'),
              onPressed: () => _remove(e),
              child: const Text('Remove'),
            ),
          ],
        ],
      ),
    );
  }
}

class _MarkdownDialog extends StatefulWidget {
  const _MarkdownDialog({required this.entry});
  final MarkdownStyleEntry entry;

  @override
  State<_MarkdownDialog> createState() => _MarkdownDialogState();
}

class _MarkdownDialogState extends State<_MarkdownDialog> {
  late final ShopDay _today = ShopDay.fromUtc(DateTime.now().toUtc());
  late bool _percent = widget.entry.markdown?.cut.amountOff == null;
  late final _value = TextEditingController(
    text: _initialValue(widget.entry.markdown?.cut),
  );
  late final _last = TextEditingController(
    text: widget.entry.markdown?.active ?? false
        ? shopDayText(widget.entry.markdown!.lastDay)
        : '',
  );
  String? _error;

  static String _initialValue(PriceCut? c) {
    if (c == null) {
      return '';
    }
    final label = markdownLabel(c);
    return label.replaceAll('%', '').replaceAll('₹', '');
  }

  @override
  void dispose() {
    _value.dispose();
    _last.dispose();
    super.dispose();
  }

  PriceCut? get _cut {
    final text = _value.text.trim();
    if (text.isEmpty) {
      return null;
    }
    return parsePriceCut(_percent ? '${text.replaceAll('%', '')}%' : text);
  }

  ShopDay? get _lastDay => parseShopDay(_last.text);

  /// Cheapest price to check an amount against: what is in stock, or a high
  /// number when nothing is (the shop then checks again when it saves).
  Money get _lowest => widget.entry.lowestMrp ?? Money(100000000);

  void _save() {
    final cut = _cut;
    final day = _lastDay;
    if (cut == null) {
      setState(
        () => _error = _percent
            ? 'Type a percentage such as 20.'
            : 'Type an amount in rupees such as 100.',
      );
      return;
    }
    if (day == null) {
      setState(
        () => _error = 'Type the last day as day/month/year, like 30/11/2026.',
      );
      return;
    }
    final problem = markdownProblem(
      cut: cut,
      lastDay: day,
      today: _today,
      lowestMrp: _lowest,
    );
    if (problem != null) {
      setState(() => _error = markdownProblemText(problem));
      return;
    }
    Navigator.of(context).pop((cut, day));
  }

  /// "₹499.00 becomes ₹399.20" for the cheapest and dearest garment in stock.
  String? get _preview {
    final cut = _cut;
    final e = widget.entry;
    if (cut == null || cut.isZero || e.lowestMrp == null) {
      return null;
    }
    String one(Money mrp) {
      final eff = effectiveMarkdown(cut, mrp);
      final off = eff?.of(mrp) ?? Money.zero;
      return '${formatRupees(mrp)} becomes ${formatRupees(mrp - off)}';
    }

    return e.lowestMrp == e.highestMrp
        ? one(e.lowestMrp!)
        : '${one(e.lowestMrp!)}; ${one(e.highestMrp!)}';
  }

  void _pick(ShopDay d) => setState(() {
    _last.text = shopDayText(d);
    _error = null;
  });

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return AlertDialog(
      title: Text('Markdown for ${widget.entry.name}'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Percent', key: Key('md-kind-percent')),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Amount', key: Key('md-kind-amount')),
                  ),
                ],
                selected: {_percent},
                onSelectionChanged: (s) => setState(() {
                  _percent = s.first;
                  _error = null;
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('md-value'),
                controller: _value,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _percent
                      ? 'Percent off (for example 20)'
                      : 'Rupees off (for example 100)',
                  suffixText: _percent ? '%' : null,
                  prefixText: _percent ? null : '₹',
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('md-last-day'),
                controller: _last,
                decoration: const InputDecoration(
                  labelText: 'Last day (day/month/year)',
                  hintText: '30/11/2026',
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    key: const Key('md-week'),
                    label: const Text('In a week'),
                    onPressed: () => _pick(shopDayPlus(_today, 7)),
                  ),
                  ActionChip(
                    key: const Key('md-30'),
                    label: const Text('In 30 days'),
                    onPressed: () => _pick(shopDayPlus(_today, 30)),
                  ),
                  ActionChip(
                    key: const Key('md-month-end'),
                    label: const Text('End of this month'),
                    onPressed: () => _pick(endOfMonth(_today)),
                  ),
                ],
              ),
              if (preview != null) ...[
                const SizedBox(height: 12),
                Text(preview, key: const Key('md-preview')),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  key: const Key('md-error'),
                  style: const TextStyle(color: UiColors.dangerInk),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('md-save'),
          onPressed: _save,
          child: const Text('Save markdown'),
        ),
      ],
    );
  }
}
