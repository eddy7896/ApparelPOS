// Backups in Manager Mode: where they go (a USB drive and a second folder, both
// chosen with the system folder dialog), when the last complete one was made,
// which place failed and why, Back up now, and the way into Restore. Only
// manager and owner reach it (the data layer refuses anyone else too).
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/backup/backup_models.dart';
import '../bill_pdf.dart' show billDateText;
import '../services.dart';
import '../session_controller.dart';
import 'restore_screen.dart';

const Map<int, String> placeNames = {1: 'USB drive', 2: 'Second folder'};

class BackupScreen extends StatefulWidget {
  const BackupScreen({
    super.key,
    required this.session,
    required this.services,
  });

  final SessionController session;
  final AppServices services;

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  BackupStatus? _status;
  int _asideCopies = 0;
  String? _message;
  bool _busy = false;

  BackupController? get _backup => widget.services.backup;
  Role? get _role => widget.session.user?.role;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final b = _backup;
    if (b == null) {
      return;
    }
    try {
      final s = await b.status(role: _role);
      final aside = await b.beforeRestoreCopyCount();
      if (mounted) {
        setState(() {
          _status = s;
          _asideCopies = aside;
        });
      }
    } on PermissionDenied {
      if (mounted) {
        setState(
          () => _message = 'Only the manager or the owner can see backups.',
        );
      }
    }
  }

  Future<void> _choose(int slot) async {
    widget.session.noteActivity();
    final path = await widget.services.pickers.folder();
    if (path == null || !mounted) {
      return;
    }
    await _backup!.setPlace(role: _role, slot: slot, path: path);
    await _load();
  }

  Future<void> _clear(int slot) async {
    await _backup!.setPlace(role: _role, slot: slot, path: null);
    await _load();
  }

  Future<void> _backupNow() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await _backup!.backupNow(role: _role);
      final ok = r.places.where((p) => p.ok).length;
      final bad = [
        for (final p in r.places)
          if (!p.ok) '${placeNames[p.slot]}: ${p.error}',
      ];
      _message =
          'Backed up to $ok of ${r.places.length} places.${bad.isEmpty ? '' : ' ${bad.join(' ')}'}';
    } on NoBackupPlaces {
      _message = 'Choose where backups go first.';
    } on Object catch (e) {
      _message = 'The backup failed: $e';
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
    await _load();
  }

  Future<void> _discardAside() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete the copy from before the restore?'),
        content: const Text(
          'Only do this when you have checked that the restored data is right. '
          'The data from before the restore cannot be brought back afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            key: const Key('confirm-discard'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete it'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _backup!.discardBeforeRestoreCopies(role: _role);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        'Backups · ${widget.services.currentBrand.displayName}',
        key: const Key('backups-title'),
      ),
    ),
    body: _body(context),
  );

  Widget _body(BuildContext context) {
    if (_backup == null) {
      return const Center(
        child: Text(
          'Backups are not available in the browser preview.',
          key: Key('no-backup'),
        ),
      );
    }
    final s = _status;
    if (s == null) {
      return Center(
        child: _message == null
            ? const CircularProgressIndicator()
            : Text(_message!, key: const Key('backup-error')),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final slot in [1, 2]) _place(context, slot, s),
        const SizedBox(height: 8),
        Text(
          s.lastCompleteAt == null
              ? 'No complete backup yet.'
              : 'Last complete backup: ${billDateText(s.lastCompleteAt!)}',
          key: const Key('last-complete'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (s.lastSavedAt != null && s.lastSavedAt != s.lastCompleteAt)
          Text(
            'Last backup to at least one place: ${billDateText(s.lastSavedAt!)}',
            key: const Key('last-saved'),
          ),
        for (final e in s.failures.entries)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${placeNames[e.key]} failed last time: ${e.value}',
              key: Key('failure-${e.key}'),
              style: TextStyle(color: scheme.error),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            FilledButton.icon(
              key: const Key('backup-now'),
              onPressed: _busy || s.places.values.every((p) => p == null)
                  ? null
                  : _backupNow,
              icon: const Icon(Icons.backup),
              label: const Text('Back up now'),
            ),
          ],
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_message!, key: const Key('backup-result')),
          ),
        const Divider(height: 40),
        Text('Restore', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text(
          'Put a backup back, for example on a new computer. This replaces the data on this computer.',
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('open-restore'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => RestoreScreen(
                session: widget.session,
                services: widget.services,
              ),
            ),
          ),
          icon: const Icon(Icons.settings_backup_restore),
          label: const Text('Restore from a backup'),
        ),
        if (_asideCopies > 0) ...[
          const SizedBox(height: 16),
          Card(
            color: scheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'The data from before the last restore is kept aside ($_asideCopies copy). '
                      'Delete it once you have checked the restored data.',
                      key: const Key('aside-note'),
                    ),
                  ),
                  TextButton(
                    key: const Key('discard-aside'),
                    onPressed: _discardAside,
                    child: const Text('Delete it'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _place(BuildContext context, int slot, BackupStatus s) {
    final path = s.places[slot];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    placeNames[slot]!,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(path ?? 'Not chosen', key: Key('place-$slot')),
                ],
              ),
            ),
            OutlinedButton(
              key: Key('choose-place-$slot'),
              onPressed: () => _choose(slot),
              child: Text(path == null ? 'Choose folder' : 'Change'),
            ),
            if (path != null) ...[
              const SizedBox(width: 8),
              TextButton(
                key: Key('clear-place-$slot'),
                onPressed: () => _clear(slot),
                child: const Text('Clear'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
