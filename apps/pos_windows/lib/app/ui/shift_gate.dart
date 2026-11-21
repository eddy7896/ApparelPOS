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
  bool _stale = false;
  bool _loaded = false;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.session.user!.userId;
    final s = await widget.services.shifts.currentShift(id);
    final stale = s != null && await widget.services.shifts.hasStaleShift(id);
    if (mounted) {
      setState(() {
        _shift = s;
        _stale = stale;
        _loaded = true;
      });
    }
  }

  /// An open shift from an earlier day must be closed, blind, before selling.
  Future<void> _closeStale(Map<Denomination, int> counts) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.services.shifts.closeShift(
        role: widget.session.user!.role,
        userId: widget.session.user!.userId,
        counts: counts,
      );
      widget.services.backupAfterShiftClose();
      await _load();
    } on NoOpenShift {
      await _load();
    } on PermissionDenied {
      if (mounted) {
        setState(() => _message = 'You may not close a shift.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
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
    if (_shift != null && !_stale) {
      return widget.child;
    }
    final stale = _shift != null && _stale;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              stale ? 'Close your earlier shift' : 'Open your shift',
              key: Key(stale ? 'stale-shift-title' : 'open-shift-title'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              stale
                  ? 'Your last shift was opened on an earlier day and was never closed. '
                        'Count all the cash in the drawer by notes and coins to close it. '
                        'Then you can open a new shift.'
                  : 'Count the cash in the drawer by notes and coins, then open the shift.',
            ),
            const SizedBox(height: 16),
            CashCountForm(
              key: Key(stale ? 'stale-count' : 'open-count'),
              buttonLabel: stale ? 'Close earlier shift' : 'Open shift',
              busy: _busy,
              onSubmit: stale ? _closeStale : _open,
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
