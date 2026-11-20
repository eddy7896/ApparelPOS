import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../session_controller.dart';

/// What opens after sign-in. Billing, stock and reports are later tasks; this
/// only shows which mode the user is in and lets them lock.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final user = session.user!;
    final sales = user.role == Role.cashier;
    return Scaffold(
      appBar: AppBar(
        title: Text(sales ? 'Sales Mode' : 'Manager Mode'),
        actions: [
          Center(child: Text('Signed in: ${user.name}')),
          const SizedBox(width: 12),
          TextButton.icon(
            key: const Key('lock-button'),
            onPressed: session.lock,
            icon: const Icon(Icons.lock),
            label: const Text('Lock (Ctrl+L)'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: Text(
          sales
              ? 'Billing is not built yet (task P2-4).'
              : 'Stock, reports and settings are not built yet.',
        ),
      ),
    );
  }
}
