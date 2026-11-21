// Sales and returns need an open shift. This shows the children once the
// signed-in person has one; until then it asks them to count the drawer cash
// and open it (owner, 2026-11-21).
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/shift_repository.dart';
import '../services.dart';
import '../session_controller.dart';
import 'cash_count_form.dart';

class ShiftGate extends StatefulWidget {
  const ShiftGate({
    super.key,
    required this.session,
    required this.services,
    required this.child,
  });

  final SessionController session;
  final AppServices services;
  final Widget child;

  @override
  State<ShiftGate> createState() => _ShiftGateState();
}

class _ShiftGateState extends State<ShiftGate> {
  ShiftInfo? _shift;
  bool _loaded = false;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await widget.services.shifts.currentShift(
      widget.session.user!.userId,
    );
    if (mounted) {
      setState(() {
        _shift = s;
        _loaded = true;
      });
    }
  }

  Future<void> _open(Map<Denomination, int> counts) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final s = await widget.services.shifts.openShift(
        role: widget.session.user!.role,
        userId: widget.session.user!.userId,
        counts: counts,
      );
      if (mounted) {
        setState(() => _shift = s);
      }
    } on ShiftAlreadyOpen {
      await _load();
    } on PermissionDenied {
      if (mounted) {
        setState(() => _message = 'You may not open a shift.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_shift != null) {
      return widget.child;
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Open your shift',
              key: const Key('open-shift-title'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Count the cash in the drawer by notes and coins, then open the shift.',
            ),
            const SizedBox(height: 16),
            CashCountForm(
              buttonLabel: 'Open shift',
              busy: _busy,
              onSubmit: _open,
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _message!,
                  key: const Key('message-banner'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
