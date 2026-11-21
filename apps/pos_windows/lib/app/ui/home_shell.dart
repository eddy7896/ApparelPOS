import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../services.dart';
import '../session_controller.dart';
import 'register_screen.dart';
import 'stock_entry_screen.dart';

/// What opens after sign-in: the register for a cashier; Billing and Stock
/// entry buttons for a manager or owner. Reports are a later task.
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
      body: sales
          ? RegisterPanel(session: session, services: services)
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    key: const Key('billing-button'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RegisterScreen(
                          session: session,
                          services: services,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.point_of_sale),
                    label: const Text('Billing'),
                  ),
                  const SizedBox(height: 12),
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
