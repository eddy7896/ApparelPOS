// The owner's list of closed shifts: who, when, opening cash, expected cash,
// counted cash and the variance. This is the only place a variance shows
// (SSOT 17); a cashier cannot reach it and the data layer refuses them too.
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/shift_repository.dart';
import '../bill_pdf.dart' show billDateText;
import '../services.dart';
import '../session_controller.dart';

class ShiftClosesScreen extends StatefulWidget {
  const ShiftClosesScreen({
    super.key,
    required this.session,
    required this.services,
  });

  final SessionController session;
  final AppServices services;

  @override
  State<ShiftClosesScreen> createState() => _ShiftClosesScreenState();
}

class _ShiftClosesScreenState extends State<ShiftClosesScreen> {
  List<ShiftCloseReport>? _reports;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await widget.services.shifts.closeReports(
        role: widget.session.user!.role,
      );
      if (mounted) {
        setState(() => _reports = r);
      }
    } on PermissionDenied {
      if (mounted) {
        setState(() => _error = 'Only the manager or the owner can see this.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Shift closes')),
    body: _body(context),
  );

  Widget _body(BuildContext context) {
    if (_error != null) {
      return Center(child: Text(_error!, key: const Key('closes-error')));
    }
    final reports = _reports;
    if (reports == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (reports.isEmpty) {
      return const Center(
        child: Text('No shifts closed yet.', key: Key('closes-empty')),
      );
    }
    return ListView(
      key: const Key('closes-list'),
      padding: const EdgeInsets.all(16),
      children: [for (final r in reports) _card(context, r)],
    );
  }

  Widget _card(BuildContext context, ShiftCloseReport r) {
    final scheme = Theme.of(context).colorScheme;
    final diff = r.variance.difference;
    final abs = Money(diff.paise.abs());
    final (String label, Color color) = switch (r.variance.kind) {
      VarianceKind.exact => ('Exact', scheme.primary),
      VarianceKind.short => ('Short ${formatRupees(abs)}', scheme.error),
      VarianceKind.over => ('Over ${formatRupees(abs)}', scheme.tertiary),
    };
    return Card(
      key: Key('close-${r.shiftId}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.cashierName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  label,
                  key: Key('variance-${r.shiftId}'),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: color),
                ),
              ],
            ),
            Text(
              'Opened ${billDateText(r.openedAt)}   Closed ${billDateText(r.closedAt)}',
            ),
            const SizedBox(height: 4),
            Text(
              'Opening ${formatRupees(r.opening)}   '
              'Expected ${formatRupees(r.expected)}   '
              'Counted ${formatRupees(r.counted)}',
              key: Key('figures-${r.shiftId}'),
            ),
          ],
        ),
      ),
    );
  }
}
