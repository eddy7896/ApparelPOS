import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('BackupName', () {
    // 2026-11-21 15:30:45 India = 10:00:45 UTC
    final at = DateTime.utc(2026, 11, 21, 10, 0, 45);
    test('is the India date and time in the file name', () {
      expect(BackupName.format(at), 'apparel-pos-20261121-153045.backup');
    });
    test('parses what it formats, back to the same instant', () {
      expect(BackupName.parse(BackupName.format(at)), at);
    });
    test('a time just before India midnight keeps the earlier date', () {
      final t = DateTime.utc(2026, 11, 21, 18, 29, 59);
      expect(BackupName.format(t), 'apparel-pos-20261121-235959.backup');
      expect(BackupName.parse('apparel-pos-20261121-235959.backup'), t);
    });
    test('names sort in time order', () {
      final names = [
        BackupName.format(DateTime.utc(2026, 12, 1)),
        BackupName.format(DateTime.utc(2026, 11, 21)),
        BackupName.format(DateTime.utc(2027, 1, 1)),
      ]..sort();
      expect(
        [for (final n in names) BackupName.parse(n)!.year],
        [2026, 2026, 2027],
      );
      expect(BackupName.parse(names.first)!.month, 11);
    });
    test('anything else is not a backup name', () {
      for (final bad in [
        '',
        'apparel-pos-20261121-153045.bak',
        'apparel-pos-20261121-153045.backup.tmp',
        'apparel-pos-2026112-153045.backup',
        'apparel-pos-20261321-153045.backup',
        'apparel-pos-20260231-153045.backup',
        'apparel-pos-20260431-153045.backup',
        'apparel-pos-20261121-256045.backup',
        'photo.jpg',
        'xapparel-pos-20261121-153045.backup',
      ]) {
        expect(BackupName.parse(bad), isNull, reason: bad);
      }
    });
  });

  group('backupsToDelete', () {
    String n(int day) => BackupName.format(DateTime.utc(2026, 11, day));
    test('nothing is deleted while there are no more than the limit', () {
      expect(backupsToDelete([n(1), n(2), n(3)], keep: 3), isEmpty);
      expect(backupsToDelete([n(1)], keep: 60), isEmpty);
      expect(backupsToDelete(const [], keep: 60), isEmpty);
    });
    test('the oldest beyond the limit are deleted', () {
      final all = [n(5), n(1), n(4), n(2), n(3)]; // unsorted on purpose
      expect(backupsToDelete(all, keep: 3), [n(1), n(2)]);
    });
    test('default keeps 60', () {
      final all = [
        for (var d = 0; d < 65; d++)
          BackupName.format(DateTime.utc(2026, 1, 1).add(Duration(days: d))),
      ];
      final gone = backupsToDelete(all);
      expect(gone.length, 5);
      expect(BackupName.parse(gone.first)!.day, 1);
    });
    test('files that are not our backups are never listed for deletion', () {
      final all = ['notes.txt', n(1), n(2), 'apparel-pos-old.backup', n(3)];
      expect(backupsToDelete(all, keep: 1), [n(1), n(2)]);
    });
    test('the newest is never deleted, even with a limit of zero or less', () {
      expect(() => backupsToDelete([n(1)], keep: 0), throwsArgumentError);
      expect(() => backupsToDelete([n(1)], keep: -1), throwsArgumentError);
    });
    test('does not change its input', () {
      final all = [n(3), n(1)];
      backupsToDelete(all, keep: 1);
      expect(all, [n(3), n(1)]);
    });
  });

  group('isBackupDue', () {
    final lastNight = DateTime.utc(2026, 11, 20, 17); // 22:30 India on the 20th
    test('with no backup yet, one is due', () {
      expect(isBackupDue(null, DateTime.utc(2026, 11, 21, 4)), isTrue);
    });
    test('a backup already made on the same India day means none is due', () {
      expect(
        isBackupDue(
          DateTime.utc(2026, 11, 21, 4),
          DateTime.utc(2026, 11, 21, 10),
        ),
        isFalse,
      );
    });
    test('the next India day makes one due again, from India midnight', () {
      expect(
        isBackupDue(lastNight, DateTime.utc(2026, 11, 20, 18, 29)),
        isFalse,
      );
      expect(
        isBackupDue(lastNight, DateTime.utc(2026, 11, 20, 18, 30)),
        isTrue,
      );
    });
    test(
      'a backup dated later than now (a clock set back) does not block today',
      () {
        expect(
          isBackupDue(
            DateTime.utc(2026, 11, 21, 10),
            DateTime.utc(2026, 11, 21, 9),
          ),
          isTrue,
        );
        expect(
          isBackupDue(DateTime.utc(2027, 1, 1), DateTime.utc(2026, 11, 21)),
          isTrue,
        );
      },
    );
  });

  group('backupAfterClose', () {
    test('only when no shift is left open', () {
      expect(backupAfterClose(openShiftsLeft: 0), isTrue);
      expect(backupAfterClose(openShiftsLeft: 1), isFalse);
      expect(backupAfterClose(openShiftsLeft: 3), isFalse);
      expect(() => backupAfterClose(openShiftsLeft: -1), throwsArgumentError);
    });
  });

  group('who may back up and restore', () {
    test('manager and owner only', () {
      expect(can(Role.cashier, Permission.backupAndRestore), isFalse);
      expect(can(null, Permission.backupAndRestore), isFalse);
      expect(can(Role.manager, Permission.backupAndRestore), isTrue);
      expect(can(Role.owner, Permission.backupAndRestore), isTrue);
    });
  });
}
