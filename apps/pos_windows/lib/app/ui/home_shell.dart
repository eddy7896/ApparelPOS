import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../services.dart';
import '../session_controller.dart';
import 'stock_entry_screen.dart';

/// What opens after sign-in. Billing, stock and reports are later tasks; this
/// only shows which mode the user is in and lets them lock.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.session, required this.services});

  final SessionController session;
  final AppServices services;

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
        child: sales
            ? const Text('Billing is not built yet (task P2-4).')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    key: const Key('stock-entry-button'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => StockEntryScreen(
                          session: session,
                          services: services,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.inventory_2),
                    label: const Text('Stock entry'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Reports and settings are not built yet.'),
                ],
              ),
      ),
    );
  }
}
