// A line at the top of Manager Mode about backups, so a missing USB drive or a
// day without a backup is noticed by the manager and never by a cashier. Taps
// open the Backups screen. Shows nothing in the browser preview.
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/backup/backup_models.dart';
import '../bill_pdf.dart' show billDateText;
import '../services.dart';
import '../session_controller.dart';
import 'backup_screen.dart';

class BackupBanner extends StatefulWidget {
  const BackupBanner({
    super.key,
    required this.session,
    required this.services,
  });

  final SessionController session;
  final AppServices services;

  @override
  State<BackupBanner> createState() => _BackupBannerState();
}

class _BackupBannerState extends State<BackupBanner> {
  BackupStatus? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final b = widget.services.backup;
    if (b == null) {
      return;
    }
    try {
      final s = await b.status(role: widget.session.user?.role);
      if (mounted) {
        setState(() => _status = s);
      }
    } on PermissionDenied {
      // a cashier never sees this banner
    }
  }

  /// The warning to show, or null when all is well.
  String? _warning(BackupStatus s) {
    if (s.places.values.every((p) => p == null)) {
      return 'Backups are not set up yet. Choose where they go.';
    }
    if (s.failures.isNotEmpty) {
      return 'A backup place failed: ${s.failures.entries.map((e) => placeNames[e.key]).join(', ')}. Check the drive.';
    }
    if (isBackupDue(s.lastCompleteAt, widget.session.now)) {
      return 'No complete backup yet today.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    if (s == null) {
      return const SizedBox.shrink();
    }
    final warning = _warning(s);
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: const Key('backup-banner'),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BackupScreen(
              session: widget.session,
              services: widget.services,
            ),
          ),
        );
        await _load();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        color: warning == null
            ? scheme.surfaceContainerHighest
            : scheme.errorContainer,
        child: Text(
          warning ?? 'Last complete backup: ${billDateText(s.lastCompleteAt!)}',
          key: Key(warning == null ? 'backup-ok' : 'backup-warning'),
          style: TextStyle(
            color: warning == null ? null : scheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}
