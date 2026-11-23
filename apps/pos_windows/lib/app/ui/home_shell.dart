import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../services.dart';
import '../session_controller.dart';
import 'close_shift_screen.dart';
import 'manager_home.dart';
import 'recovery_key_screen.dart';
import 'register_screen.dart';
import 'brand_mark.dart';
import 'shift_gate.dart';
import 'returns_screen.dart';
import 'stock_lookup_screen.dart';

/// What opens after sign-in: the register for a cashier; Billing and Stock
/// entry buttons for a manager or owner. Reports are a later task.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.session, required this.services});

  final SessionController session;
  final AppServices services;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  /// True while a bill is being made: Pause and Close shift wait for the end.
  final _billInProgress = ValueNotifier<bool>(false);
  SessionController get session => widget.session;
  AppServices get services => widget.services;

  @override
  void dispose() {
    _billInProgress.dispose();
    super.dispose();
  }

  /// The Pause button: record the break, then lock the counter.
  Future<void> _pause() async {
    final user = session.user!;
    await services.shifts.pauseShift(role: user.role, userId: user.userId);
    session.lockForBreak(user.name);
  }

  /// Sales Mode top bar: Pause, Close shift, Lock (owner, 2026-11-22).
  /// A button with a label on a wide window and only its icon on a narrow one
  /// (still 48 dp, with the label as its tooltip).
  Widget _barButton({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    String? hint,
  }) {
    final narrow = MediaQuery.sizeOf(context).width < 1100;
    return narrow
        ? IconButton.outlined(
            key: key,
            tooltip: hint ?? label,
            onPressed: onPressed,
            icon: Icon(icon),
          )
        : OutlinedButton.icon(
            key: key,
            onPressed: onPressed,
            icon: Icon(icon),
            label: hint == null
                ? Text(label)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label),
                      const SizedBox(width: 8),
                      Text(hint, style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
          );
  }

  List<Widget> _shiftButtons(BuildContext context) => [
    ValueListenableBuilder<bool>(
      valueListenable: _billInProgress,
      builder: (context, busy, _) => Tooltip(
        message: busy ? 'Finish or clear the bill first' : '',
        child: Row(
          children: [
            _barButton(
              key: const Key('pause-button'),
              onPressed: busy ? null : _pause,
              icon: Icons.pause_circle,
              label: 'Pause',
            ),
            const SizedBox(width: 8),
            _barButton(
              key: const Key('close-shift-button'),
              onPressed: busy
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CloseShiftScreen(
                          session: session,
                          services: services,
                        ),
                      ),
                    ),
              icon: Icons.lock_clock,
              label: 'Close shift',
            ),
          ],
        ),
      ),
    ),
    const SizedBox(width: 8),
  ];

  @override
  Widget build(BuildContext context) {
    final user = session.user!;
    final sales = user.role == Role.cashier;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            Flexible(child: BrandMark(brand: services.currentBrand)),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                sales ? 'Sales Mode' : 'Manager Mode',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (sales && services.stockLookup != null)
            _barButton(
              key: const Key('stock-lookup-button'),
              icon: Icons.search,
              label: 'Stock',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      StockLookupScreen(session: session, services: services),
                ),
              ),
            ),
          if (sales)
            TextButton.icon(
              key: const Key('returns-button'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ReturnsScreen(session: session, services: services),
                ),
              ),
              icon: const Icon(Icons.assignment_return),
              label: const Text('Returns'),
            ),
          Center(child: Text('Signed in: ${user.name}')),
          const SizedBox(width: 12),
          if (sales) ..._shiftButtons(context),
          _barButton(
            key: const Key('lock-button'),
            onPressed: session.lock,
            icon: Icons.lock,
            label: 'Lock',
            hint: 'Ctrl+L',
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: sales
          ? ShiftGate(
              session: session,
              services: services,
              child: RegisterPanel(
                session: session,
                services: services,
                billInProgress: _billInProgress,
                showCloseShift: false,
              ),
            )
          : RecoveryKeyGate(
              session: session,
              services: services,
              child: ManagerHome(session: session, services: services),
            ),
    );
  }
}
