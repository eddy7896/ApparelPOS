// The blind close (P2-6c). The cashier counts the drawer by notes and coins and
// confirms; nothing on this screen, or after it, shows the expected amount or
// the variance (E-SHIFT-1, SSOT 17). The variance goes to the owner's list.
// After the close the counter is locked, so the next person signs in and opens
// their own shift.
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/shift_repository.dart';
import '../services.dart';
import '../session_controller.dart';
import 'cash_count_form.dart';

class CloseShiftScreen extends StatefulWidget {
  const CloseShiftScreen({
    super.key,
    required this.session,
    required this.services,
  });

  final SessionController session;
  final AppServices services;

  @override
  State<CloseShiftScreen> createState() => _CloseShiftScreenState();
}

class _CloseShiftScreenState extends State<CloseShiftScreen> {
  bool _busy = false;
  bool _closed = false;
  String? _message;

  Future<void> _close(Map<Denomination, int> counts) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Close your shift?'),
        content: const Text(
          'You will not be able to sell or take returns until you open a new shift.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-close'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Close shift'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
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
      if (mounted) {
        setState(() => _closed = true);
      }
    } on NoOpenShift {
      if (mounted) {
        setState(() => _message = 'There is no open shift to close.');
      }
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Close shift')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: _closed ? _done(context) : _form(context),
        ),
      ),
    ),
  );

  List<Widget> _form(BuildContext context) => [
    Text(
      'Count the drawer',
      key: const Key('close-shift-title'),
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    const SizedBox(height: 8),
    const Text(
      'Count all the cash in the drawer by notes and coins. Count it all, '
      'including the money you opened with.',
    ),
    const SizedBox(height: 16),
    CashCountForm(buttonLabel: 'Close shift', busy: _busy, onSubmit: _close),
    if (_message != null)
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          _message!,
          key: const Key('message-banner'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
  ];

  List<Widget> _done(BuildContext context) => [
    Text(
      'Shift closed',
      key: const Key('shift-closed-title'),
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    const SizedBox(height: 8),
    const Text('Your count has been recorded. Thank you.'),
    const SizedBox(height: 16),
    FilledButton(
      key: const Key('lock-after-close'),
      onPressed: widget.session.lock,
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Lock the counter'),
      ),
    ),
  ];
}
