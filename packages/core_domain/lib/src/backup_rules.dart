// Daily backups (ADR-0015, owner 2026-11-21): a backup is made when the last
// open shift of the day is closed, and again when the app starts if none was
// made today (India day); the last 60 are kept in each place. A backup file is
// named by its India date and time, so names sort in time order and the
// owner can read them. Files that are not our backups are never touched.

import 'report_rules.dart';
import 'shop_time.dart';

/// The default number of backups kept in each place (owner, 2026-11-21).
const int defaultBackupsToKeep = 60;

abstract final class BackupName {
  static const String _prefix = 'apparel-pos-';
  static const String _suffix = '.backup';
  static final RegExp _pattern = RegExp(
    r'^apparel-pos-(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})\.backup$',
  );

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// `apparel-pos-YYYYMMDD-HHMMSS.backup`, in India time.
  static String format(DateTime utc) {
    final l = utc.toUtc().add(shopUtcOffset);
    return '$_prefix${l.year.toString().padLeft(4, '0')}${_two(l.month)}${_two(l.day)}'
        '-${_two(l.hour)}${_two(l.minute)}${_two(l.second)}$_suffix';
  }

  /// The UTC instant in [name], or null if it is not a backup name.
  static DateTime? parse(String name) {
    final m = _pattern.firstMatch(name);
    if (m == null) {
      return null;
    }
    final v = [for (var i = 1; i <= 6; i++) int.parse(m.group(i)!)];
    if (v[1] < 1 ||
        v[1] > 12 ||
        v[2] < 1 ||
        v[2] > 31 ||
        v[3] > 23 ||
        v[4] > 59 ||
        v[5] > 59) {
      return null;
    }
    final local = DateTime.utc(v[0], v[1], v[2], v[3], v[4], v[5]);
    if (local.month != v[1] || local.day != v[2]) {
      return null; // a date that does not exist, such as 31 February
    }
    return local.subtract(shopUtcOffset);
  }
}

/// The backup files in [names] to delete so that only the newest [keep] stay.
/// Names that are not backups are ignored (never deleted). [keep] must be at
/// least 1, so the newest backup is never deleted. Does not change [names].
List<String> backupsToDelete(
  List<String> names, {
  int keep = defaultBackupsToKeep,
}) {
  if (keep < 1) {
    throw ArgumentError.value(keep, 'keep', 'must be at least 1');
  }
  final ours = [
    for (final n in names)
      if (BackupName.parse(n) != null) n,
  ]..sort((a, b) => BackupName.parse(a)!.compareTo(BackupName.parse(b)!));
  return ours.length <= keep ? const [] : ours.sublist(0, ours.length - keep);
}

/// True when no backup was made on the India day of [nowUtc]. [lastBackupUtc]
/// is null when there never was one. A last backup dated after now (a wrong
/// clock) does not stop today's backup.
bool isBackupDue(DateTime? lastBackupUtc, DateTime nowUtc) {
  if (lastBackupUtc == null) {
    return true;
  }
  final today = ShopDay.fromUtc(nowUtc);
  return !(ShopDay.fromUtc(lastBackupUtc) == today &&
      !lastBackupUtc.isAfter(nowUtc));
}

/// A backup follows a shift close only when no shift is left open.
bool backupAfterClose({required int openShiftsLeft}) {
  if (openShiftsLeft < 0) {
    throw ArgumentError.value(
      openShiftsLeft,
      'openShiftsLeft',
      'must not be negative',
    );
  }
  return openShiftsLeft == 0;
}
