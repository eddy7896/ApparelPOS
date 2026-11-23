// Stock lookup: "do you have this in M, blue?" Type part of a style name or
// scan a tag; each style shows its sizes and colors with how many are in stock
// and the MRP. For cashiers and managers alike: no cost is ever read here.
import 'dart:async';

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/stock_lookup_repository.dart';
import '../services.dart';
import '../session_controller.dart';
import 'ui_tokens.dart';

class StockLookupScreen extends StatefulWidget {
  const StockLookupScreen({
    super.key,
    required this.session,
    required this.services,
  });

  final SessionController session;
  final AppServices services;

  @override
  State<StockLookupScreen> createState() => _StockLookupScreenState();
}

class _StockLookupScreenState extends State<StockLookupScreen> {
  final _query = TextEditingController();
  List<StyleStock>? _results;
  StockFilter _filter = StockFilter.all;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final repo = widget.services.stockLookup;
    if (repo == null) {
      return;
    }
    try {
      final r = await repo.search(
        role: widget.session.user?.role,
        query: _query.text,
      );
      if (mounted) {
        setState(() {
          _results = r;
          _error = null;
        });
      }
    } on PermissionDenied {
      if (mounted) {
        setState(() => _error = 'You may not look at stock.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      appBar: AppBar(title: const Text('Stock lookup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('lookup-field'),
              controller: _query,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Style name, or scan a tag',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => _search(),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(
                _error!,
                key: const Key('lookup-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (results == null)
              const Center(child: CircularProgressIndicator())
            else if (results.isEmpty)
              const Text(
                'No style like that in the shop.',
                key: Key('lookup-empty'),
              )
            else ...[
              _summary(context, results),
              const SizedBox(height: 12),
              Expanded(child: _list(context, results)),
            ],
          ],
        ),
      ),
    );
  }

  int _countWhere(List<StyleStock> all, StockFilter f) => [
    for (final s in all)
      for (final v in s.variants)
        if (f.keeps(v.inStock)) v,
  ].length;

  /// How many sizes and colors are out or running low, and the filter chips.
  Widget _summary(BuildContext context, List<StyleStock> all) {
    final out = _countWhere(all, StockFilter.outOfStock);
    final low = _countWhere(all, StockFilter.low);
    final every = _countWhere(all, StockFilter.all);
    final inStock = _countWhere(all, StockFilter.inStock);
    Widget chip(String key, String label, StockFilter f, int n) => ChoiceChip(
      key: Key(key),
      label: Text('$label ($n)'),
      selected: _filter == f,
      onSelected: (_) => setState(() => _filter = f),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (out > 0 || low > 0)
          Container(
            key: const Key('lookup-summary'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: out > 0 ? UiColors.dangerSoft : UiColors.amberSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  out > 0 ? Icons.block : Icons.warning_amber_rounded,
                  color: out > 0 ? UiColors.dangerInk : UiColors.amberInk,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    [
                      if (out > 0)
                        '$out ${out == 1 ? 'size and color is' : 'sizes and colors are'} out of stock',
                      if (low > 0) '$low running low',
                    ].join(', '),
                    key: const Key('lookup-summary-text'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: out > 0 ? UiColors.dangerInk : UiColors.amberInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip('filter-all', 'All', StockFilter.all, every),
            chip('filter-in', 'In stock', StockFilter.inStock, inStock),
            chip('filter-low', 'Running low', StockFilter.low, low),
            chip('filter-out', 'Out of stock', StockFilter.outOfStock, out),
          ],
        ),
      ],
    );
  }

  Widget _list(BuildContext context, List<StyleStock> all) {
    final cards = <Widget>[];
    for (final s in all) {
      final shown = [
        for (final v in s.variants)
          if (_filter.keeps(v.inStock)) v,
      ];
      if (shown.isNotEmpty) {
        cards.add(_styleCard(context, s, shown));
      }
    }
    if (cards.isEmpty) {
      return const Align(
        alignment: Alignment.topLeft,
        child: Text('Nothing matches this filter.', key: Key('filter-empty')),
      );
    }
    return ListView(key: const Key('lookup-results'), children: cards);
  }

  Widget _styleCard(
    BuildContext context,
    StyleStock s,
    List<VariantStock> shown,
  ) {
    final t = Theme.of(context).textTheme;
    final level = stockLevel(s.inStock);
    final (Color bg, Color fg, IconData icon, String text) = switch (level) {
      StockLevel.out => (
        UiColors.dangerSoft,
        UiColors.dangerInk,
        Icons.block,
        'Out of stock',
      ),
      StockLevel.low => (
        UiColors.amberSoft,
        UiColors.amberInk,
        Icons.warning_amber_rounded,
        'Only ${s.inStock} left',
      ),
      StockLevel.ok => (
        UiColors.successSoft,
        UiColors.successInk,
        Icons.check_circle,
        '${s.inStock} in stock',
      ),
    };
    return Card(
      key: Key('style-${s.name}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.name,
                    style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: fg),
                      const SizedBox(width: 6),
                      Text(
                        text,
                        key: Key('style-total-${s.name}'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [for (final v in shown) _variant(context, s, v)],
            ),
          ],
        ),
      ),
    );
  }

  /// One size and color. Out is red with a block icon, the words "Out of
  /// stock" and a struck-through name; low is amber with a warning icon and
  /// "Only N left"; the rest are calm. The words and icon carry the meaning,
  /// so color is never the only cue.
  Widget _variant(BuildContext context, StyleStock s, VariantStock v) {
    final scheme = Theme.of(context).colorScheme;
    final level = stockLevel(v.inStock);
    final (
      Color bg,
      Color border,
      Color fg,
      IconData icon,
      String text,
    ) = switch (level) {
      StockLevel.out => (
        UiColors.dangerSoft,
        UiColors.dangerLine,
        UiColors.dangerInk,
        Icons.block,
        'Out of stock',
      ),
      StockLevel.low => (
        UiColors.amberSoft,
        UiColors.amberLine,
        UiColors.amberInk,
        Icons.warning_amber_rounded,
        'Only ${v.inStock} left',
      ),
      StockLevel.ok => (
        scheme.primaryContainer,
        Colors.transparent,
        scheme.onPrimaryContainer,
        Icons.check_circle_outline,
        '${v.inStock} in stock',
      ),
    };
    final out = level == StockLevel.out;
    return Container(
      key: Key('variant-${s.name}-${v.size}-${v.color}'),
      constraints: const BoxConstraints(minWidth: 160, minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${v.size} · ${v.color}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: out ? fg : null,
              decoration: out ? TextDecoration.lineThrough : null,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                text,
                key: Key('count-${s.name}-${v.size}-${v.color}'),
                style: TextStyle(fontWeight: FontWeight.w700, color: fg),
              ),
            ],
          ),
          Text(
            formatRupees(v.mrp),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: out ? UiColors.inkMuted : null),
          ),
        ],
      ),
    );
  }
}
