// Shown once to the owner or manager: the recovery key. They write it down and
// type its last group back, then carry on. See RecoveryKeyRepository.
import 'package:flutter/material.dart';

import '../../data/recovery_key_repository.dart';
import '../services.dart';
import '../session_controller.dart';

/// Wraps Manager Mode: until the recovery key has been acknowledged, only the
/// recovery key screen shows. Does nothing when there is no key store (the
/// browser preview) or no repository.
class RecoveryKeyGate extends StatefulWidget {
  const RecoveryKeyGate({
    super.key,
    required this.session,
    required this.services,
    required this.child,
  });

  final SessionController session;
  final AppServices services;
  final Widget child;

  @override
  State<RecoveryKeyGate> createState() => _RecoveryKeyGateState();
}

class _RecoveryKeyGateState extends State<RecoveryKeyGate> {
  bool? _needs;
  String? _text;

  RecoveryKeyRepository? get _repo => widget.services.recovery;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) {
      setState(() => _needs = false);
      return;
    }
    final needs = await repo.needsAcknowledgement();
    final text = needs
        ? await repo.recoveryKeyText(role: widget.session.user!.role)
        : null;
    if (mounted) {
      setState(() {
        _needs = needs && text != null;
        _text = text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final needs = _needs;
    if (needs == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!needs) {
      return widget.child;
    }
    return _RecoveryKeyScreen(
      text: _text!,
      onDone: () async {
        await _repo!.acknowledge(
          role: widget.session.user!.role,
          userId: widget.session.user!.userId,
        );
        if (mounted) {
          setState(() {
            _needs = false;
            _text = null;
          });
        }
      },
    );
  }
}

class _RecoveryKeyScreen extends StatefulWidget {
  const _RecoveryKeyScreen({required this.text, required this.onDone});

  final String text;
  final Future<void> Function() onDone;

  @override
  State<_RecoveryKeyScreen> createState() => _RecoveryKeyScreenState();
}

class _RecoveryKeyScreenState extends State<_RecoveryKeyScreen> {
  final _check = TextEditingController();
  bool _busy = false;

  String get _last => widget.text.split('-').last;

  @override
  void dispose() {
    _check.dispose();
    super.dispose();
  }

  bool get _ok => _check.text.trim().toUpperCase() == _last;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Write down your recovery key',
            key: const Key('recovery-title'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Your shop data is locked with a key kept on this computer. If this '
            'computer is lost or Windows is reinstalled, only this recovery key '
            'can open a backup. Write it on paper and keep it somewhere safe, '
            'away from the computer. Nobody else should see it. It is shown only now.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: SelectableText(
              widget.text,
              key: const Key('recovery-key-text'),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('recovery-check-field'),
            controller: _check,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'To confirm, type the last 4 characters (after the last dash)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('recovery-continue'),
            onPressed: _ok && !_busy
                ? () async {
                    setState(() => _busy = true);
                    await widget.onDone();
                  }
                : null,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('I have written it down'),
            ),
          ),
        ],
      ),
    ),
  );
}
