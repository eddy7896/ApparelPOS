// Stock lookup: "do you have this in M, blue?" Type part of a style name or
// scan a tag; each style shows its sizes and colors with how many are in stock
// and the MRP. For cashiers and managers alike: no cost is ever read here.
import 'dart:async';

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/stock_lookup_repository.dart';
import '../services.dart';
import '../session_controller.dart';
import 'status_colors.dart';

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
            else
              Expanded(
                child: ListView(
                  key: const Key('lookup-results'),
                  children: [for (final s in results) _styleCard(context, s)],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _styleCard(BuildContext context, StyleStock s) {
    final t = Theme.of(context).textTheme;
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
                Text(
                  s.inStock == 0 ? 'Out of stock' : '${s.inStock} in stock',
                  key: Key('style-total-${s.name}'),
                  style: t.titleMedium?.copyWith(
                    color: s.inStock == 0
                        ? Theme.of(context).colorScheme.error
                        : successColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [for (final v in s.variants) _variant(context, s, v)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _variant(BuildContext context, StyleStock s, VariantStock v) {
    final scheme = Theme.of(context).colorScheme;
    final have = v.inStock > 0;
    return Container(
      key: Key('variant-${s.name}-${v.size}-${v.color}'),
      constraints: const BoxConstraints(minWidth: 150, minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: have ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${v.size} · ${v.color}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          Text(
            have ? '${v.inStock} in stock' : 'None left',
            key: Key('count-${s.name}-${v.size}-${v.color}'),
          ),
          Text(
            formatRupees(v.mrp),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
