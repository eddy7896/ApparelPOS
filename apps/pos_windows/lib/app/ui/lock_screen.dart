import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/auth_service.dart';
import '../../data/brand.dart';
import '../session_controller.dart';
import 'brand_mark.dart';
import 'notice.dart';

/// Pick your name, then type your PIN (cashier) or password (manager, owner).
class LockScreen extends StatefulWidget {
  LockScreen({super.key, required this.session, Brand? brand})
    : brand = brand ?? Brand.placeholder;

  final SessionController session;

  /// The shop's name, logo and color for the header.
  final Brand brand;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  SignInChoice? _selected;
  final _secret = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _secret.dispose();
    super.dispose();
  }

  void _choose(SignInChoice? choice) {
    setState(() {
      _selected = choice;
      _secret.clear();
      _error = null;
    });
  }

  void _digit(String d) {
    if (_secret.text.length < maxPinLength) {
      _secret.text = _secret.text + d;
    }
  }

  void _backspace() {
    final t = _secret.text;
    if (t.isNotEmpty) {
      _secret.text = t.substring(0, t.length - 1);
    }
  }

  Future<void> _submit() async {
    final choice = _selected;
    if (choice == null || _busy || _secret.text.isEmpty) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final what = choice.role.usesPin ? 'PIN' : 'password';
    final result = await widget.session.signIn(choice.userId, _secret.text);
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _secret.clear();
      _error = switch (result) {
        SignedIn() => null,
        WrongSecret(:final triesLeft) =>
          'Wrong $what. $triesLeft ${triesLeft == 1 ? 'try' : 'tries'} left.',
        AccountLocked(:final until) => _lockedText(until),
        UnknownUser() => 'This account is not available.',
      };
    });
  }

  String _lockedText(DateTime until) {
    final seconds = until.difference(widget.session.now).inSeconds;
    final minutes = ((seconds + 59) ~/ 60).clamp(1, 1000);
    return 'Locked. Try again in $minutes ${minutes == 1 ? 'minute' : 'minutes'}.';
  }

  @override
  Widget build(BuildContext context) {
    final choice = _selected;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: BrandMark(
                    brand: widget.brand,
                    size: 56,
                    nameStyle: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  choice == null ? 'Choose your name' : 'Hello, ${choice.name}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (choice == null) _names() else _entry(choice),
                const EncryptionNotice(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _names() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final c in widget.session.choices)
          SizedBox(
            width: 220,
            child: Card(
              child: InkWell(
                key: Key('user-${c.userId}'),
                onTap: () => _choose(c),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        c.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(_roleLabel(c.role)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _roleLabel(Role role) => switch (role) {
    Role.cashier => 'Cashier',
    Role.manager => 'Manager',
    Role.owner => 'Owner',
  };

  Widget _entry(SignInChoice choice) {
    final pin = choice.role.usesPin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('secret-field'),
          controller: _secret,
          obscureText: true,
          autofocus: true,
          keyboardType: pin
              ? TextInputType.number
              : TextInputType.visiblePassword,
          inputFormatters: pin
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(maxPinLength),
                ]
              : null,
          decoration: InputDecoration(labelText: pin ? 'PIN' : 'Password'),
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            key: const Key('signin-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        if (pin) _keypad(),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('signin-submit'),
          onPressed: _busy ? null : _submit,
          child: const Text('Sign in'),
        ),
        TextButton(
          key: const Key('back'),
          onPressed: _busy ? null : () => _choose(null),
          child: const Text('Choose another name'),
        ),
      ],
    );
  }

  Widget _keypad() {
    Widget key(String label, VoidCallback onTap, {Key? k}) => SizedBox(
      width: 84,
      height: 56,
      child: OutlinedButton(
        key: k,
        onPressed: _busy ? null : onTap,
        child: Text(label),
      ),
    );
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                for (final d in row) key(d, () => _digit(d), k: Key('key-$d')),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              const SizedBox(width: 84),
              key('0', () => _digit('0'), k: const Key('key-0')),
              key('⌫', _backspace, k: const Key('key-backspace')),
            ],
          ),
        ),
      ],
    );
  }
}
