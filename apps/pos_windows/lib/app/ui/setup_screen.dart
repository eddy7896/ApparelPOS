import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../services.dart';
import '../session_controller.dart';
import 'restore_screen.dart';
import 'notice.dart';

/// First launch: create the owner account (ADR-0002 D1, install wizard).
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.session, this.services});

  final SessionController session;

  /// Needed only for the Restore link (null in tests of the form alone).
  final AppServices? services;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.session.createFirstOwner(
      name: _name.text,
      password: _password.text,
      confirm: _confirm.text,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _error = switch (result) {
        SetupResult.done => null,
        SetupResult.weakPassword =>
          'The password must be at least 10 characters.',
        SetupResult.mismatch => 'The two passwords do not match.',
        SetupResult.blankName => 'Enter your name.',
        SetupResult.notAllowed => 'Setup is already done on this counter.',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Set up your shop',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create the owner account. Cashiers are added later by the owner.',
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('setup-name'),
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Your name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('setup-password'),
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password (at least 10 characters)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('setup-confirm'),
                  controller: _confirm,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Type the password again',
                  ),
                  onSubmitted: (_) => _busy ? null : _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('setup-submit'),
                  onPressed: _busy ? null : _submit,
                  child: const Text('Create owner account'),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  OutlinedButton(
                    key: const Key('practice-users'),
                    onPressed: _busy
                        ? null
                        : () => widget.session.createPracticeUsers(),
                    child: const Text(
                      'Add practice users and demo stock (development only)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Practice owner password: $practiceOwnerPassword\nPractice cashier PIN: $practiceCashierPin',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (widget.services?.backup != null) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    key: const Key('setup-restore'),
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => RestoreScreen(
                                services: widget.services!,
                                firstRun: true,
                              ),
                            ),
                          ),
                    child: const Text(
                      'This is a new computer: restore from a backup',
                    ),
                  ),
                ],
                const EncryptionNotice(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
