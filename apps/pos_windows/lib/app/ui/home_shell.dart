import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../services.dart';
import '../session_controller.dart';
import 'recovery_key_screen.dart';
import 'register_screen.dart';
import 'daily_report_screen.dart';
import 'shift_closes_screen.dart';
import 'shift_gate.dart';
import 'returns_screen.dart';
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
          ? ShiftGate(
              session: session,
              services: services,
              child: RegisterPanel(session: session, services: services),
            )
          : RecoveryKeyGate(
              session: session,
              services: services,
              child: Center(
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
                      key: const Key('returns-button'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ReturnsScreen(
                            session: session,
                            services: services,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.assignment_return),
                      label: const Text('Returns'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('daily-report-button'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DailyReportScreen(
                            session: session,
                            services: services,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.bar_chart),
                      label: const Text('Daily report'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('shift-closes-button'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ShiftClosesScreen(
                            session: session,
                            services: services,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.fact_check),
                      label: const Text('Shift closes'),
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
                    const Text('Settings are not built yet.'),
                  ],
                ),
              ),
            ),
    );
  }
}
