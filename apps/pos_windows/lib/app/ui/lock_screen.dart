import 'dart:async';
import 'dart:math' as math;

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/auth_service.dart';
import '../../data/brand.dart';
import '../session_controller.dart';
import 'brand_mark.dart';
import 'notice.dart';
import 'ui_tokens.dart';

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

  /// On a break, only the cashier who paused sees the resume screen; this
  /// shows the ordinary list instead (the owner needs to get in too).
  bool _everyone = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // The break clock counts up every second while the break screen shows.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _onBreakScreen) {
        setState(() {});
      }
    });
  }

  bool get _onBreakScreen => widget.session.pausedUserId != null && !_everyone;

  /// Who is typing: the cashier on a break, or whoever was chosen.
  SignInChoice? get _current {
    if (_onBreakScreen) {
      for (final c in widget.session.choices) {
        if (c.userId == widget.session.pausedUserId) {
          return c;
        }
      }
    }
    return _selected;
  }

  final _secret = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _tick?.cancel();
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
    final choice = _current;
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
    if (_onBreakScreen && _current != null) {
      return _breakScreen(context, _current!);
    }
    final choice = _selected;
    final wide = MediaQuery.sizeOf(context).width >= 860;
    final names = _names();
    final entry = _entryCard(choice);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandMark(
                  brand: widget.brand,
                  size: 44,
                  nameStyle: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.session.pausedName != null
                      ? 'The counter is on a break.'
                      : 'This counter is locked. Who is signing in?',
                  style: const TextStyle(fontSize: 16, color: UiColors.inkSoft),
                ),
                if (widget.session.pausedName != null)
                  Container(
                    key: const Key('on-break-banner'),
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: UiColors.amberSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.session.pausedName} is on a break. '
                      'The shift stays open and the drawer cash stays put. '
                      'Sign in to carry on.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: UiColors.amberInk),
                    ),
                  ),
                const SizedBox(height: 24),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: names),
                      const SizedBox(width: 32),
                      Expanded(child: entry),
                    ],
                  )
                else ...[
                  names,
                  const SizedBox(height: 20),
                  entry,
                ],
                const EncryptionNotice(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The break screen (mock-up board 4): amber, a running clock, and the PIN
  /// of the cashier who paused to carry on.
  Widget _breakScreen(BuildContext context, SignInChoice who) {
    final since = widget.session.pausedSince;
    final elapsed = since == null
        ? Duration.zero
        : widget.session.now.difference(since);
    final local = since?.toUtc().add(shopUtcOffset);
    String two(int n) => n.toString().padLeft(2, '0');
    final wide = MediaQuery.sizeOf(context).width >= 860;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: const Key('on-break-chip'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: UiColors.amberChip,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pause, size: 20, color: UiColors.amberInk),
              SizedBox(width: 10),
              Text(
                'On a break',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: UiColors.amberInk,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Take your time, ${who.name}',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        if (local != null)
          Text(
            'Break started at ${two(local.hour)}:${two(local.minute)}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        const SizedBox(height: 14),
        Text(
          breakClockText(elapsed),
          key: const Key('break-clock'),
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '${widget.session.pausedName} is on a break. The counter is locked, '
          'the shift stays open and nobody can bill on it. The drawer cash '
          'stays put. Sign in to carry on.',
          key: const Key('on-break-banner'),
          style: const TextStyle(fontSize: 16, color: UiColors.inkSoft),
        ),
      ],
    );
    final card = Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: UiColors.amberBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Type your ${who.role.usesPin ? 'PIN' : 'password'} to come back',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _entry(who, buttonLabel: 'Resume my shift'),
            const SizedBox(height: 16),
            Text(
              "Only ${who.name}'s ${who.role.usesPin ? 'PIN' : 'password'} resumes this shift. If you will not be back, ask the owner or close the shift from the register before you leave.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: UiColors.inkMuted),
            ),
            TextButton(
              key: const Key('someone-else'),
              onPressed: () => setState(() {
                _everyone = true;
                _secret.clear();
                _error = null;
              }),
              child: const Text('Someone else? Sign in as another person'),
            ),
          ],
        ),
      ),
    );
    return Scaffold(
      backgroundColor: UiColors.amberPage,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandMark(
                  brand: widget.brand,
                  size: 44,
                  nameStyle: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 24),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: info),
                      const SizedBox(width: 40),
                      SizedBox(width: 420, child: card),
                    ],
                  )
                else ...[
                  info,
                  const SizedBox(height: 20),
                  card,
                ],
                const EncryptionNotice(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The people, two to a row, the chosen one outlined in the main color.
  Widget _names() {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final c in widget.session.choices)
              SizedBox(
                width: w,
                child: Material(
                  color: _selected?.userId == c.userId
                      ? scheme.primaryContainer
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    key: Key('user-${c.userId}'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _choose(c),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 96),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          width: 2,
                          color: _selected?.userId == c.userId
                              ? scheme.primary
                              : UiColors.line,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            c.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: UiColors.ink,
                            ),
                          ),
                          Text(
                            _roleLabel(c.role),
                            style: const TextStyle(
                              fontSize: 14,
                              color: UiColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _roleLabel(Role role) => switch (role) {
    Role.cashier => 'Cashier',
    Role.manager => 'Manager',
    Role.owner => 'Owner',
  };

  Widget _entryCard(SignInChoice? choice) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              choice == null
                  ? 'Choose your name'
                  : 'Hello ${choice.name}, type your ${choice.role.usesPin ? 'PIN' : 'password'}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            if (choice != null) ...[const SizedBox(height: 16), _entry(choice)],
            const SizedBox(height: 16),
            const Text(
              'Five wrong tries lock this name for 5 minutes. The counter '
              'locks itself after 5 minutes of no use.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: UiColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entry(SignInChoice choice, {String buttonLabel = 'Sign in'}) {
    final pin = choice.role.usesPin;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A cashier sees dots; the real field stays (tiny) so a keyboard works.
        SizedBox(
          height: pin ? 1 : null,
          width: pin ? 1 : null,
          child: TextField(
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
            style: pin
                ? const TextStyle(fontSize: 1, color: Colors.transparent)
                : const TextStyle(fontSize: 22, letterSpacing: 4),
            decoration: pin
                ? const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                  )
                : const InputDecoration(labelText: 'Password'),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
        ),
        if (pin) ...[
          ListenableBuilder(
            listenable: _secret,
            builder: (context, _) {
              final n = _secret.text.length;
              final dots = math.max(minPinLength, n);
              return Row(
                key: const Key('pin-dots'),
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 12,
                children: [
                  for (var i = 0; i < dots; i++)
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < n ? scheme.primary : Colors.white,
                        border: Border.all(color: scheme.primary, width: 2),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          const Text(
            'At least 6 digits',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: UiColors.inkMuted),
          ),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'At least 10 characters. The first time, you will be shown a '
              'recovery key to write down.',
              style: TextStyle(fontSize: 14, color: UiColors.inkMuted),
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            key: const Key('signin-error'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        if (pin) _keypad(),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('signin-submit'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(60),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: _busy ? null : _submit,
          child: Text(buttonLabel),
        ),
      ],
    );
  }

  Widget _keypad() {
    Widget key(String label, VoidCallback onTap, {Key? k, double size = 26}) =>
        SizedBox(
          height: 64,
          child: OutlinedButton(
            key: k,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: TextStyle(fontSize: size, fontWeight: FontWeight.w600),
            ),
            onPressed: _busy ? null : onTap,
            child: Text(label),
          ),
        );
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
          key(d, () => _digit(d), k: Key('key-$d')),
        key(
          'Clear',
          () => _secret.clear(),
          k: const Key('key-clear'),
          size: 18,
        ),
        key('0', () => _digit('0'), k: const Key('key-0')),
        key('⌫', _backspace, k: const Key('key-backspace')),
      ],
    );
  }
}
