// Sales and returns need an open shift. This shows the children once the
// signed-in person has one; until then it asks them to count the drawer cash
// and open it (owner, 2026-11-21).
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/shift_repository.dart';
import '../services.dart';
import '../session_controller.dart';
import 'cash_count_form.dart';
import 'ui_tokens.dart';

class ShiftGate extends StatefulWidget {
  const ShiftGate({
    super.key,
    required this.session,
    required this.services,
    required this.child,
    this.onChanged,
  });

  final SessionController session;
  final AppServices services;
  final Widget child;

  /// Called after the shift is loaded, opened or closed (the top bar reads it).
  final VoidCallback? onChanged;

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
    // Signing back in after Pause ends the break (UX-3).
    await widget.services.shifts.resumeShift(
      role: widget.session.user!.role,
      userId: id,
    );
    final s = await widget.services.shifts.currentShift(id);
    final stale = s != null && await widget.services.shifts.hasStaleShift(id);
    if (mounted) {
      setState(() {
        _shift = s;
        _stale = stale;
        _loaded = true;
      });
      widget.onChanged?.call();
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
        widget.onChanged?.call();
      }
    } on ShiftAlreadyOpen {
      await _load();
    } on DrawerOnBreak {
      if (mounted) {
        setState(
          () => _message =
              'The drawer is on a break. Ask the cashier who paused to '
              'sign in and carry on or close their shift first.',
        );
      }
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
    // A popup over a dimmed counter (UX-3): the register is not drawn until
    // the drawer is counted.
    return Stack(
      children: [
        const ModalBarrier(color: UiColors.scrim, dismissible: false),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Material(
              key: const Key('shift-popup'),
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              elevation: 12,
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    stale
                        ? 'Close your earlier shift'
                        : '${greetingFor(widget.session.now)}, ${widget.session.user!.name}',
                    key: Key(stale ? 'stale-shift-title' : 'open-shift-title'),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stale
                        ? 'Your last shift was opened on an earlier day and was never closed. '
                              'Count all the cash in the drawer by notes and coins to close it. '
                              'Then you can open a new shift.'
                        : 'Your shift is opening. Count the cash in the drawer so the day starts right. Tap + for each note or coin.',
                    style: const TextStyle(
                      fontSize: 16,
                      color: UiColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CashCountForm(
                    key: Key(stale ? 'stale-count' : 'open-count'),
                    buttonLabel: stale
                        ? 'Close earlier shift'
                        : 'Open my shift',
                    busy: _busy,
                    onSubmit: stale ? _closeStale : _open,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'An empty drawer is fine: leave everything at 0. You '
                      'cannot bill until the shift is open.',
                      style: TextStyle(fontSize: 13, color: UiColors.inkMuted),
                    ),
                  ),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _message!,
                        key: const Key('message-banner'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
