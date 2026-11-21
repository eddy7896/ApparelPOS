// Restoring a backup. In Manager Mode it needs the owner's password again and
// the word RESTORE typed in (owner, 2026-11-21); on the first launch of a new
// computer (no user exists yet) neither is possible, so it asks only for the
// file, the recovery key and the word. The data that was here is kept aside, and
// the app closes afterwards so it opens the restored data fresh.
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/backup/backup_models.dart';
import '../services.dart';
import '../session_controller.dart';
import 'approval_dialog.dart';

String restoreMessage(RestoreOutcome o) => switch (o) {
  RestoreOutcome.done => 'The backup has been restored.',
  RestoreOutcome.keyRequired => 'This computer does not hold the key. Type in the recovery key you wrote down.',
  RestoreOutcome.badRecoveryKey => 'The recovery key is not right. Check each group of four characters, including the last one.',
  RestoreOutcome.wrongKey =>
    'That key does not open this backup. Nothing was changed.',
  RestoreOutcome.damaged =>
    'This file is not a healthy backup. Nothing was changed.',
  RestoreOutcome.tooNew => 'This backup was made by a newer version of the app. Update the app first. Nothing was changed.',
  RestoreOutcome.keyMismatch => 'This computer already holds a different key than the backup. Nothing was changed. Ask for help before going on.',
  RestoreOutcome.notEmpty =>
    'This computer already has shop data, so it cannot be restored from here.',
  RestoreOutcome.failed => 'The restore did not work.',
};

class RestoreScreen extends StatefulWidget {
  const RestoreScreen({
    super.key,
    required this.services,
    this.session,
    this.firstRun = false,
  });

  final AppServices services;

  /// Who is signed in (null on the first launch, before any user exists).
  final SessionController? session;
  final bool firstRun;

  @override
  State<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends State<RestoreScreen> {
  final _key = TextEditingController();
  final _confirm = TextEditingController();
  String? _file;
  String? _message;
  bool _busy = false;
  RestoreReport? _report;

  BackupController get _backup => widget.services.backup!;

  @override
  void dispose() {
    _key.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _ready => _file != null && _confirm.text == 'RESTORE' && !_busy;

  Future<void> _choose() async {
    widget.session?.noteActivity();
    final path = await widget.services.pickers.backupFile();
    if (path != null && mounted) {
      setState(() {
        _file = path;
        _message = null;
      });
    }
  }

  Future<void> _restore() async {
    if (!widget.firstRun) {
      final who = await askApprover(
        context,
        widget.services.auth,
        permission: Permission.backupAndRestore,
        message: 'Restoring replaces all the data on this computer. The owner or a manager must type their password.',
        onNobody: (m) => setState(() => _message = m),
      );
      if (who == null || !mounted) {
        return;
      }
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await _backup.restore(
        backupPath: _file!,
        recoveryKeyText: _key.text,
        firstRun: widget.firstRun,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _report = r;
        _message = restoreMessage(r.outcome);
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Restore from a backup')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: _report?.needsRestart == true
              ? _done(context)
              : _form(context),
        ),
      ),
    ),
  );

  List<Widget> _done(BuildContext context) {
    final ok = _report!.outcome == RestoreOutcome.done;
    return [
      Text(
        ok ? 'Restore finished' : 'The restore stopped',
        key: const Key('restore-done-title'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text(_message ?? '', key: const Key('restore-done-text')),
      const SizedBox(height: 8),
      const Text('The app will close now. Open it again to carry on.'),
      const SizedBox(height: 16),
      FilledButton(
        key: const Key('restore-close'),
        onPressed: _backup.quit,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Text('Close the app'),
        ),
      ),
    ];
  }

  List<Widget> _form(BuildContext context) => [
    Text(
      widget.firstRun
          ? 'Restore your shop from a backup'
          : 'Restore from a backup',
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    const SizedBox(height: 8),
    Text(
      widget.firstRun
          ? 'Use this on a new computer. Choose the backup file, then type the recovery key you wrote down.'
          : 'This replaces all the data on this computer with the backup. The data that is here now is kept aside '
                'until you delete it, but the app closes and opens the restored data.',
    ),
    const SizedBox(height: 16),
    Row(
      children: [
        OutlinedButton(
          key: const Key('choose-backup-file'),
          onPressed: _busy ? null : _choose,
          child: const Text('Choose backup file'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _file ?? 'No file chosen',
            key: const Key('backup-file-name'),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
    const SizedBox(height: 12),
    TextField(
      key: const Key('restore-recovery-key'),
      controller: _key,
      decoration: InputDecoration(
        labelText: widget.firstRun
            ? 'Recovery key'
            : 'Recovery key (only if this computer does not hold the key)',
        border: const OutlineInputBorder(),
      ),
    ),
    const SizedBox(height: 12),
    TextField(
      key: const Key('restore-confirm'),
      controller: _confirm,
      decoration: const InputDecoration(
        labelText: 'Type RESTORE to confirm',
        border: OutlineInputBorder(),
      ),
      onChanged: (_) => setState(() {}),
    ),
    if (_message != null)
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          _message!,
          key: const Key('restore-message'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    const SizedBox(height: 16),
    FilledButton(
      key: const Key('restore-go'),
      onPressed: _ready ? _restore : null,
      child: const Padding(padding: EdgeInsets.all(12), child: Text('Restore')),
    ),
  ];
}
