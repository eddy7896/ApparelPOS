import 'package:core_domain/core_domain.dart';
import 'package:pos_windows/data/backup/backup_models.dart';

/// A stand-in for the backup service in screen tests: it records what the
/// screens ask for and returns what the test sets up.
class FakeBackupController implements BackupController {
  Map<int, String?> places = {1: null, 2: null};
  DateTime? lastComplete;
  DateTime? lastSaved;
  Map<int, String> failures = {};
  int asideCopies = 0;
  BackupResult? nextResult;
  RestoreReport nextRestore = const RestoreReport(
    RestoreOutcome.done,
    needsRestart: true,
  );

  final calls = <String>[];
  String? restoredPath;
  String? restoredKeyText;
  bool? restoredFirstRun;
  int quits = 0;
  int? afterCloseOpenLeft;
  int backupIfDueCalls = 0;

  void _need(Role? role) {
    if (role != Role.manager && role != Role.owner) {
      throw PermissionDenied(role, Permission.backupAndRestore);
    }
  }

  @override
  Future<BackupStatus> status({required Role? role}) async {
    _need(role);
    return BackupStatus(
      places: Map.of(places),
      lastAttemptAt: lastComplete,
      lastSavedAt: lastSaved ?? lastComplete,
      lastCompleteAt: lastComplete,
      failures: Map.of(failures),
    );
  }

  @override
  Future<void> setPlace({
    required Role? role,
    required int slot,
    String? path,
  }) async {
    _need(role);
    calls.add('setPlace $slot $path');
    places[slot] = path;
  }

  @override
  Future<BackupResult> backupNow({required Role? role}) async {
    _need(role);
    calls.add('backupNow');
    if (places.values.every((p) => p == null)) {
      throw NoBackupPlaces();
    }
    final r =
        nextResult ??
        BackupResult(
          at: DateTime.utc(2026, 11, 21, 10),
          places: [
            for (final e in places.entries)
              if (e.value != null)
                PlaceResult(slot: e.key, ok: true, fileName: 'x'),
          ],
        );
    lastComplete = r.complete ? r.at : lastComplete;
    return r;
  }

  @override
  Future<BackupResult?> backupIfDue() async {
    backupIfDueCalls++;
    return null;
  }

  @override
  Future<BackupResult?> backupAfterShiftClose({
    required int openShiftsLeft,
  }) async {
    afterCloseOpenLeft = openShiftsLeft;
    calls.add('afterClose $openShiftsLeft');
    return null;
  }

  @override
  Future<RestoreReport> restore({
    required String backupPath,
    String? recoveryKeyText,
    bool firstRun = false,
  }) async {
    restoredPath = backupPath;
    restoredKeyText = recoveryKeyText;
    restoredFirstRun = firstRun;
    calls.add('restore');
    return nextRestore;
  }

  @override
  Future<int> beforeRestoreCopyCount() async => asideCopies;

  @override
  Future<void> discardBeforeRestoreCopies({required Role? role}) async {
    _need(role);
    calls.add('discard');
    asideCopies = 0;
  }

  @override
  Future<void> quit() async => quits++;
}
