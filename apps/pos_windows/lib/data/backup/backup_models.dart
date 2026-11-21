// What the backup screens need to know, with no dart:io so the browser preview
// compiles. The service that does the work is in backup_service.dart (desktop
// only); screens talk to it through [BackupController].
import 'package:core_domain/core_domain.dart';

/// No backup place has been chosen yet.
final class NoBackupPlaces implements Exception {
  @override
  String toString() => 'NoBackupPlaces: choose where backups go first';
}

/// What happened in one place.
final class PlaceResult {
  const PlaceResult({
    required this.slot,
    required this.ok,
    this.fileName,
    this.error,
    this.pruned = 0,
  });
  final int slot;
  final bool ok;
  final String? fileName;

  /// A short reason when [ok] is false.
  final String? error;

  /// How many old backups were deleted from this place.
  final int pruned;
}

/// What happened in one backup run.
final class BackupResult {
  const BackupResult({required this.at, required this.places});
  final DateTime at;
  final List<PlaceResult> places;

  /// Every place got its copy.
  bool get complete => places.isNotEmpty && places.every((p) => p.ok);

  /// At least one place got its copy.
  bool get anySaved => places.any((p) => p.ok);
}

/// What the manager sees about backups.
final class BackupStatus {
  const BackupStatus({
    required this.places,
    required this.lastAttemptAt,
    required this.lastSavedAt,
    required this.lastCompleteAt,
    required this.failures,
  });

  /// Chosen places by slot (1 and 2); null where none is chosen.
  final Map<int, String?> places;
  final DateTime? lastAttemptAt;
  final DateTime? lastSavedAt;

  /// Last time every place got a copy.
  final DateTime? lastCompleteAt;

  /// Slot number to reason, for the places that failed last time.
  final Map<int, String> failures;
}

/// How a restore ended.
enum RestoreOutcome {
  done,

  /// No key on this computer and none typed in.
  keyRequired,

  /// The recovery key typed in is not a valid recovery key (a typing mistake).
  badRecoveryKey,

  /// The key does not open that backup.
  wrongKey,

  /// The file is not a healthy backup.
  damaged,

  /// The backup was made by a newer version of the app.
  tooNew,

  /// This computer already holds a different key.
  keyMismatch,

  /// First-launch restore refused because shop data already exists here.
  notEmpty,

  /// Something else went wrong.
  failed,
}

/// The result of a restore. [needsRestart] is true when the database was
/// closed, so the app must be started again whatever the outcome.
final class RestoreReport {
  const RestoreReport(this.outcome, {this.needsRestart = false});
  final RestoreOutcome outcome;
  final bool needsRestart;
}

/// What the backup screens call. Implemented natively over the real files; the
/// browser preview has none (null).
abstract class BackupController {
  Future<BackupStatus> status({required Role? role});
  Future<void> setPlace({required Role? role, required int slot, String? path});
  Future<BackupResult> backupNow({required Role? role});

  /// The automatic backup at start-up (never throws).
  Future<BackupResult?> backupIfDue();

  /// The automatic backup after a shift close (never throws).
  Future<BackupResult?> backupAfterShiftClose({required int openShiftsLeft});

  /// Restores the backup file at [backupPath] over the current data. The caller
  /// must already have checked who may do this. [recoveryKeyText] is needed on
  /// a computer that does not hold the key. With [firstRun] true it is allowed
  /// only while no user exists (a brand new computer).
  Future<RestoreReport> restore({
    required String backupPath,
    String? recoveryKeyText,
    bool firstRun = false,
  });

  /// How many kept-aside copies of the data from before a restore exist.
  Future<int> beforeRestoreCopyCount();

  /// Deletes the kept-aside copies: the owner has seen the restored data is
  /// right. Needs `backupAndRestore`.
  Future<void> discardBeforeRestoreCopies({required Role? role});

  /// Closes the app (after a restore, so the data is opened fresh).
  Future<void> quit();
}
