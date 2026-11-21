// E-BACKUP-1: a backup restores to a clean machine. Real encrypted files, two
// real backup places, a clean directory and an empty key store holding only the
// recovery key. Also: one place failing, keeping the last 60, the cashier never
// seeing backup problems. P3-2b.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/backup/backup_service.dart';
import 'package:pos_windows/data/backup/native_backup_controller.dart';
import 'package:pos_windows/data/shift_repository.dart';
import 'package:pos_windows/data/encryption/encrypted_connection.dart';
import 'package:pos_windows/data/encryption/key_store.dart';
import 'package:pos_windows/data/stock_repository.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

const secretStyle = 'ZEBRA-SECRET-STYLE-NAME';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory root;
  late Directory machineA;
  late File dbA;
  late Directory usb;
  late Directory folder;
  late MemoryKeyStore keysA;
  late AppDatabase db;
  late BackupService backups;
  late DateTime now;
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() async {
    root = Directory.systemTemp.createTempSync('backup_test_');
    machineA = Directory('${root.path}/machineA')..createSync();
    usb = Directory('${root.path}/usb')..createSync();
    folder = Directory('${root.path}/folder')..createSync();
    dbA = File('${machineA.path}/apparel_pos.db');
    keysA = MemoryKeyStore();
    now = DateTime.utc(2026, 11, 21, 10);
    n = 0;
    db = AppDatabase(
      await openEncryptedDatabase(dbA, keysA, inBackground: false),
    );
    final stock = StockRepository(db, newId: newId, now: () => now);
    await stock.ensureCounter();
    await stock.receivePurchase(
      role: Role.owner,
      draft: PurchaseDraft(
        supplier: 'S',
        style: secretStyle,
        lines: [
          PurchaseLine(
            size: 'M',
            color: 'Blue',
            quantity: 3,
            cost: Money(20000),
            mrp: Money(49900),
          ),
        ],
      ),
    );
    backups = BackupService(db, dbA, keysA, newId: newId, now: () => now);
    await backups.setPlace(role: Role.owner, slot: 1, path: usb.path);
    await backups.setPlace(role: Role.owner, slot: 2, path: folder.path);
  });
  tearDown(() async {
    await db.close();
    try {
      root.deleteSync(recursive: true);
    } on FileSystemException {
      // a temp folder left behind is harmless; a failed cleanup must not fail a test
    }
  });

  /// Every row of every table, as text, for comparing two databases.
  String dump(File file, Uint8List key) {
    final d = raw.sqlite3.open(file.path, mode: raw.OpenMode.readOnly);
    try {
      applyKey(d, key);
      final tables = d
          .select(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
          )
          .map((r) => r['name'] as String);
      final out = StringBuffer();
      for (final t in tables) {
        out.writeln('## $t');
        for (final r in d.select('SELECT * FROM "$t" ORDER BY rowid')) {
          out.writeln(
            jsonEncode(
              r.values
                  .map((v) => v is Uint8List ? base64Encode(v) : v)
                  .toList(),
            ),
          );
        }
      }
      return out.toString();
    } finally {
      d.close();
    }
  }

  Future<void> checkpoint() =>
      db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');

  List<String> filesIn(Directory d) =>
      [for (final f in d.listSync().whereType<File>()) f.uri.pathSegments.last]
        ..sort();

  group('backing up', () {
    test(
      'writes a named, encrypted copy to both places and records it',
      () async {
        final r = await backups.backupNow(role: Role.owner);
        expect(r.complete, isTrue);
        final expected = BackupName.format(now);
        for (final d in [usb, folder]) {
          expect(filesIn(d), [expected]);
          final f = File('${d.path}/$expected');
          expect(isPlainDatabase(f), isFalse);
          expect(
            String.fromCharCodes(f.readAsBytesSync()).contains(secretStyle),
            isFalse,
          );
        }
        final s = await backups.status(role: Role.owner);
        expect(s.lastCompleteAt, now);
        expect(s.failures, isEmpty);
        expect(await backups.isDue(), isFalse);
      },
    );

    test('leaves no temporary snapshot or half-written file behind', () async {
      await backups.backupNow(role: Role.owner);
      expect(filesIn(machineA).where((n) => n.contains('snapshot')), isEmpty);
      for (final d in [usb, folder]) {
        expect(filesIn(d).where((n) => n.endsWith('.partial')), isEmpty);
      }
    });

    test('is audited and queued with counts only: no paths, no key', () async {
      await backups.backupNow(role: Role.owner);
      final audit = await db
          .customSelect(
            "SELECT details FROM audit_log WHERE action = 'backup.run'",
          )
          .getSingle();
      final out = await db
          .customSelect(
            "SELECT payload FROM outbox WHERE operation = 'backup.run'",
          )
          .getSingle();
      final hex = RecoveryKey.hex((await keysA.read())!);
      for (final t in [
        audit.read<String>('details'),
        out.read<String>('payload'),
      ]) {
        expect(t, contains('placesOk'));
        expect(t, isNot(contains(usb.path)));
        expect(t, isNot(contains(folder.path)));
        expect(t, isNot(contains(hex)));
      }
    });

    test('with no place chosen it says so', () async {
      await backups.setPlace(role: Role.owner, slot: 1, path: null);
      await backups.setPlace(role: Role.owner, slot: 2, path: '  ');
      await expectLater(
        backups.backupNow(role: Role.owner),
        throwsA(isA<NoBackupPlaces>()),
      );
    });

    test('two requests at once make one backup', () async {
      final both = await Future.wait([
        backups.backupNow(role: Role.owner),
        backups.backupNow(role: Role.owner),
      ]);
      expect(identical(both[0], both[1]), isTrue);
      expect(filesIn(usb).length, 1);
    });

    test(
      'the snapshot is a moment in time: later changes are not in it',
      () async {
        await backups.backupNow(role: Role.owner);
        await db.customStatement(
          "INSERT INTO app_settings (name, value) VALUES ('later', 'x')",
        );
        await checkpoint();
        final key = (await keysA.read())!;
        final backupFile = File('${usb.path}/${BackupName.format(now)}');
        expect(dump(backupFile, key), isNot(contains('"later"')));
        expect(dump(dbA, key), contains('"later"'));
      },
    );

    test(
      'a database key that is missing fails the backup and records it',
      () async {
        final noKey = BackupService(
          db,
          dbA,
          MemoryKeyStore(),
          newId: newId,
          now: () => now,
        );
        await expectLater(
          noKey.backupNow(role: Role.owner),
          throwsA(isA<BackupFailed>()),
        );
        expect(filesIn(usb), isEmpty);
        final s = await noKey.status(role: Role.owner);
        expect(s.failures.keys, [1, 2]);
        expect(await noKey.isDue(), isTrue);
      },
    );
  });

  group('E-BACKUP-1: restoring to a clean machine with the recovery key', () {
    test('the restored database has exactly the same data', () async {
      await checkpoint();
      final key = (await keysA.read())!;
      final before = dump(dbA, key);
      final recoveryText = RecoveryKey.format(key); // what the owner wrote down
      await backups.backupNow(role: Role.owner);

      // a clean machine: new directory, empty key store, only the paper and the backup
      final machineB = Directory('${root.path}/machineB')..createSync();
      final dbB = File('${machineB.path}/apparel_pos.db');
      final keysB = MemoryKeyStore();
      final backup = File('${usb.path}/${BackupName.format(now)}');
      final result = await restoreBackup(
        backup: backup,
        target: dbB,
        keys: keysB,
        recoveryKey: RecoveryKey.parse(recoveryText),
        appSchemaVersion: db.schemaVersion,
      );
      expect(result.beforeRestoreCopy, isNull);
      expect(await keysB.read(), key);
      expect(dump(dbB, key), before);

      // and the app can open it the normal way and read it
      final opened = AppDatabase(
        await openEncryptedDatabase(dbB, keysB, inBackground: false),
      );
      addTearDown(opened.close);
      expect(
        (await opened.select(opened.products).get()).single.name,
        secretStyle,
      );
      expect((await opened.select(opened.articles).get()).length, 3);
    });

    test('the second place restores the same data as the first', () async {
      await backups.backupNow(role: Role.owner);
      final key = (await keysA.read())!;
      final dbB = File('${root.path}/b.db');
      await restoreBackup(
        backup: File('${folder.path}/${BackupName.format(now)}'),
        target: dbB,
        keys: MemoryKeyStore(),
        recoveryKey: key,
        appSchemaVersion: db.schemaVersion,
      );
      expect(
        dump(dbB, key),
        dump(File('${usb.path}/${BackupName.format(now)}'), key),
      );
      expect(dump(dbB, key), contains(secretStyle));
    });

    test(
      'without any key it asks for the recovery key, and changes nothing',
      () async {
        await backups.backupNow(role: Role.owner);
        final dbB = File('${root.path}/b.db');
        await expectLater(
          restoreBackup(
            backup: File('${usb.path}/${BackupName.format(now)}'),
            target: dbB,
            keys: MemoryKeyStore(),
            appSchemaVersion: 6,
          ),
          throwsA(isA<RestoreKeyRequired>()),
        );
        expect(dbB.existsSync(), isFalse);
      },
    );

    test('a wrong recovery key is refused and nothing is created', () async {
      await backups.backupNow(role: Role.owner);
      final dbB = File('${root.path}/b.db');
      final keysB = MemoryKeyStore();
      await expectLater(
        restoreBackup(
          backup: File('${usb.path}/${BackupName.format(now)}'),
          target: dbB,
          keys: keysB,
          recoveryKey: newDatabaseKey(Random(9)),
          appSchemaVersion: db.schemaVersion,
        ),
        throwsA(isA<WrongDatabaseKey>()),
      );
      expect(dbB.existsSync(), isFalse);
      expect(await keysB.read(), isNull);
    });

    test('a damaged backup is refused', () async {
      final bad = File('${root.path}/apparel-pos-20261121-120000.backup')
        ..writeAsBytesSync(Uint8List.fromList(List.filled(5000, 7)));
      await expectLater(
        restoreBackup(
          backup: bad,
          target: File('${root.path}/b.db'),
          keys: MemoryKeyStore(),
          recoveryKey: newDatabaseKey(Random(1)),
          appSchemaVersion: 6,
        ),
        throwsA(anyOf(isA<WrongDatabaseKey>(), isA<BackupFailed>())),
      );
    });

    test('a backup from a newer app version is refused', () async {
      await backups.backupNow(role: Role.owner);
      final dbB = File('${root.path}/b.db');
      await expectLater(
        restoreBackup(
          backup: File('${usb.path}/${BackupName.format(now)}'),
          target: dbB,
          keys: MemoryKeyStore(),
          recoveryKey: (await keysA.read())!,
          appSchemaVersion: db.schemaVersion - 1,
        ),
        throwsA(isA<BackupTooNew>()),
      );
      expect(dbB.existsSync(), isFalse);
    });
  });

  group('restoring over the current database', () {
    Future<(File, Uint8List)> backupThenChange() async {
      await backups.backupNow(role: Role.owner);
      await db.customStatement(
        "INSERT INTO app_settings (name, value) VALUES ('after-backup', 'today')",
      );
      await checkpoint();
      await db.close();
      return (
        File('${usb.path}/${BackupName.format(now)}'),
        (await keysA.read())!,
      );
    }

    test('keeps the current database aside, restores the backup, and discards the copy only when told', () async {
      final (backup, key) = await backupThenChange();
      final result = await restoreBackup(
        backup: backup,
        target: dbA,
        keys: keysA,
        appSchemaVersion: 6,
        now: DateTime.utc(2026, 11, 21, 12),
      );
      final aside = result.beforeRestoreCopy!;
      expect(aside.existsSync(), isTrue);
      expect(
        dump(aside, key),
        contains('after-backup'),
      ); // today's work is not lost
      expect(
        dump(dbA, key),
        isNot(contains('after-backup')),
      ); // the backup's moment
      expect(beforeRestoreCopies(dbA).length, 1);
      discardBeforeRestoreCopies(dbA);
      expect(aside.existsSync(), isFalse);
      expect(beforeRestoreCopies(dbA), isEmpty);
      db = AppDatabase(
        await openEncryptedDatabase(dbA, keysA, inBackground: false),
      ); // for tearDown
    });

    test('a failed restore puts the current database back untouched', () async {
      final (backup, key) = await backupThenChange();
      final before = dump(dbA, key);
      // a backup that opens with the key at first, then breaks when copied: corrupt a copy of it
      final broken = File('${root.path}/apparel-pos-20261121-130000.backup');
      broken.writeAsBytesSync(Uint8List.fromList(List.filled(8192, 3)));
      await expectLater(
        restoreBackup(
          backup: broken,
          target: dbA,
          keys: keysA,
          appSchemaVersion: 6,
        ),
        throwsA(isA<Object>()),
      );
      expect(dump(dbA, key), before);
      expect(beforeRestoreCopies(dbA), isEmpty);
      expect(filesIn(machineA).where((n) => n.endsWith('.restoring')), isEmpty);
      db = AppDatabase(
        await openEncryptedDatabase(dbA, keysA, inBackground: false),
      );
      expect(backup.existsSync(), isTrue);
    });

    test(
      'a restore that fails half way puts the current database back',
      () async {
        final (backup, key) = await backupThenChange();
        final before = dump(dbA, key);
        await expectLater(
          restoreBackup(
            backup: backup,
            target: dbA,
            keys: keysA,
            appSchemaVersion: 6,
            afterMovedAside: () async => throw StateError('disk full'),
          ),
          throwsA(isA<StateError>()),
        );
        expect(dump(dbA, key), before);
        expect(dump(dbA, key), contains('after-backup'));
        expect(beforeRestoreCopies(dbA), isEmpty);
        expect(
          filesIn(machineA).where(
            (n) => n.contains('before-restore') || n.endsWith('.restoring'),
          ),
          isEmpty,
        );
        db = AppDatabase(
          await openEncryptedDatabase(dbA, keysA, inBackground: false),
        );
      },
    );

    test('a different key on this computer is refused so the old copy stays readable', () async {
      final (backup, _) = await backupThenChange();
      // pretend this computer's store now holds another key, and the owner typed the backup's key
      final other = MemoryKeyStore(newDatabaseKey(Random(4)));
      final typed = (await keysA.read())!;
      await expectLater(
        restoreBackup(
          backup: backup,
          target: dbA,
          keys: other,
          recoveryKey: typed,
          appSchemaVersion: 6,
        ),
        throwsA(isA<RestoreKeyMismatch>()),
      );
      expect(beforeRestoreCopies(dbA), isEmpty);
      db = AppDatabase(
        await openEncryptedDatabase(dbA, keysA, inBackground: false),
      );
    });
  });

  group('one place is not available', () {
    test('the other still gets its copy, the day is partly done, and it is retried', () async {
      folder.deleteSync(
        recursive: true,
      ); // the second place is gone (a drive not plugged in)
      final r = await backups.backupNow(role: Role.owner);
      expect(r.complete, isFalse);
      expect(r.anySaved, isTrue);
      expect(
        r.places.firstWhere((p) => p.slot == 2).error,
        contains('plugged in'),
      );
      expect(filesIn(usb), [BackupName.format(now)]);
      final s = await backups.status(role: Role.owner);
      expect(s.lastSavedAt, now);
      expect(s.lastCompleteAt, isNull);
      expect(s.failures.keys, [2]);
      expect(await backups.isDue(), isTrue);

      // plugged back in; the automatic backup at start-up tries again
      folder.createSync();
      now = now.add(const Duration(hours: 1));
      final again = await backups.backupIfDue();
      expect(again!.complete, isTrue);
      expect(filesIn(folder), [BackupName.format(now)]);
      final s2 = await backups.status(role: Role.owner);
      expect(s2.failures, isEmpty);
      expect(await backups.isDue(), isFalse);
    });

    test(
      'damage deep inside a copy (not just the first page) is caught too',
      () async {
        final bad = BackupService(
          db,
          dbA,
          keysA,
          newId: newId,
          now: () => now,
          copier: (from, to) async {
            await from.copy(to.path);
            final bytes = to.readAsBytesSync();
            expect(bytes.length, greaterThan(9000)); // more than two pages
            for (var i = 8200; i < 8400; i++) {
              bytes[i] = bytes[i] ^ 0xFF;
            }
            to.writeAsBytesSync(bytes);
          },
        );
        final r = await bad.backupNow(role: Role.owner);
        expect(r.anySaved, isFalse);
        expect(filesIn(usb), isEmpty);
      },
    );

    test('a copy that comes out damaged is not kept', () async {
      final bad = BackupService(
        db,
        dbA,
        keysA,
        newId: newId,
        now: () => now,
        copier: (from, to) async {
          await from.copy(to.path);
          final bytes = to.readAsBytesSync();
          for (var i = 100; i < 300; i++) {
            bytes[i] = bytes[i] ^ 0xFF;
          }
          to.writeAsBytesSync(bytes);
        },
      );
      final r = await bad.backupNow(role: Role.owner);
      expect(r.anySaved, isFalse);
      expect(filesIn(usb), isEmpty);
      expect(filesIn(folder), isEmpty);
      expect((await bad.status(role: Role.owner)).failures.keys, [1, 2]);
    });
  });

  group('keeping the last 60', () {
    test(
      'deletes the oldest beyond the limit, never files that are not backups',
      () async {
        for (var d = 0; d < 62; d++) {
          final t = DateTime.utc(2026, 1, 1).add(Duration(days: d));
          File('${usb.path}/${BackupName.format(t)}')
              .writeAsStringSync('old $d');
        }
        File('${usb.path}/notes.txt').writeAsStringSync('keep me');
        File('${usb.path}/apparel-pos-old.backup')
            .writeAsStringSync('keep me too');
        final r = await backups.backupNow(role: Role.owner);
        final names = filesIn(usb);
        expect(names.where((n) => BackupName.parse(n) != null).length, 60);
        expect(names, contains(BackupName.format(now)));
        expect(names, contains('notes.txt'));
        expect(names, contains('apparel-pos-old.backup'));
        expect(
          names,
          isNot(contains(BackupName.format(DateTime.utc(2026, 1, 1)))),
        );
        expect(r.places.firstWhere((p) => p.slot == 1).pruned, 3);
        expect(
          filesIn(folder).length,
          1,
        ); // the other place is pruned on its own
      },
    );

    test('the limit can be set lower', () async {
      final few = BackupService(
        db,
        dbA,
        keysA,
        newId: newId,
        now: () => now,
        keep: 2,
      );
      for (final hours in [3, 2, 1]) {
        now = DateTime.utc(2026, 11, 21, 10).subtract(Duration(hours: hours));
        await few.backupNow(role: Role.owner);
      }
      now = DateTime.utc(2026, 11, 21, 10);
      await few.backupNow(role: Role.owner);
      expect(filesIn(usb).length, 2);
      expect(filesIn(usb).last, BackupName.format(now));
    });
  });

  group('the automatic backups', () {
    test(
      'at start-up: only when due and only when a place is chosen',
      () async {
        expect(await backups.backupIfDue(), isNotNull); // never backed up
        expect(await backups.backupIfDue(), isNull); // already done today
        now = DateTime.utc(2026, 11, 21, 18, 30); // India midnight: a new day
        expect(await backups.backupIfDue(), isNotNull);
        await backups.setPlace(role: Role.owner, slot: 1, path: null);
        await backups.setPlace(role: Role.owner, slot: 2, path: null);
        now = DateTime.utc(2026, 11, 23);
        expect(await backups.backupIfDue(), isNull);
      },
    );

    test('after a shift close: only when no shift is left open, even if one was made today', () async {
      await backups.backupNow(role: Role.owner);
      now = now.add(const Duration(hours: 2));
      expect(await backups.backupAfterShiftClose(openShiftsLeft: 1), isNull);
      final r = await backups.backupAfterShiftClose(openShiftsLeft: 0);
      expect(r!.complete, isTrue);
      expect(filesIn(usb).length, 2);
    });

    test(
      'never throws: a failure is recorded for the manager and billing goes on',
      () async {
        final noKey = BackupService(
          db,
          dbA,
          MemoryKeyStore(),
          newId: newId,
          now: () => now,
        );
        expect(await noKey.backupIfDue(), isNull);
        expect(await noKey.backupAfterShiftClose(openShiftsLeft: 0), isNull);
        expect((await noKey.status(role: Role.owner)).failures, isNotEmpty);
      },
    );
  });

  group('who may see and change backups', () {
    test('a cashier and nobody are refused', () async {
      for (final role in [Role.cashier, null]) {
        await expectLater(
          backups.backupNow(role: role),
          throwsA(isA<PermissionDenied>()),
        );
        await expectLater(
          backups.status(role: role),
          throwsA(isA<PermissionDenied>()),
        );
        await expectLater(
          backups.setPlace(role: role, slot: 1, path: 'x'),
          throwsA(isA<PermissionDenied>()),
        );
      }
      expect(filesIn(usb), isEmpty);
    });
    test('a manager may', () async {
      await backups.backupNow(role: Role.manager);
      expect((await backups.status(role: Role.manager)).lastCompleteAt, now);
    });
    test('only slots 1 and 2 exist', () async {
      await expectLater(
        backups.setPlace(role: Role.owner, slot: 3, path: 'x'),
        throwsArgumentError,
      );
    });
    test('the places are remembered', () async {
      final s = await backups.status(role: Role.owner);
      expect(s.places, {1: usb.path, 2: folder.path});
    });
  });

  test(
    'the listing of a place is newest first and ignores other files',
    () async {
      for (final h in [1, 3, 2]) {
        File('${usb.path}/${BackupName.format(DateTime.utc(2026, 11, 21, h))}')
            .writeAsStringSync('x');
      }
      File('${usb.path}/readme.txt').writeAsStringSync('x');
      final list = listBackups(usb);
      expect([for (final (_, t) in list) t.hour], [3, 2, 1]);
      expect(listBackups(Directory('${root.path}/nope')), isEmpty);
    },
  );

  group('the first launch on a new computer', () {
    test('a brand new empty database and its key are replaced by the backup and its key', () async {
      await backups.backupNow(role: Role.owner);
      final keyA = (await keysA.read())!;
      final machineB = Directory('${root.path}/machineB')..createSync();
      final dbB = File('${machineB.path}/apparel_pos.db');
      final keysB = MemoryKeyStore();
      // what happens on the first launch: the app has already made a new database and key
      final fresh = AppDatabase(
        await openEncryptedDatabase(dbB, keysB, inBackground: false),
      );
      await fresh
          .customSelect('SELECT 1')
          .get(); // the app writes its own tables on first launch
      await fresh.close();
      final newKey = (await keysB.read())!;
      expect(newKey, isNot(keyA));
      final backup = File('${usb.path}/${BackupName.format(now)}');
      // without the first-launch switch it is refused
      await expectLater(
        restoreBackup(
          backup: backup,
          target: dbB,
          keys: keysB,
          recoveryKey: keyA,
          appSchemaVersion: db.schemaVersion,
        ),
        throwsA(isA<RestoreKeyMismatch>()),
      );
      await restoreBackup(
        backup: backup,
        target: dbB,
        keys: keysB,
        recoveryKey: keyA,
        appSchemaVersion: db.schemaVersion,
        replaceKey: true,
      );
      expect(await keysB.read(), keyA);
      final opened = AppDatabase(
        await openEncryptedDatabase(dbB, keysB, inBackground: false),
      );
      addTearDown(opened.close);
      expect(
        (await opened.select(opened.products).get()).single.name,
        secretStyle,
      );
    });
  });

  group('the controller the screens use', () {
    late File dbB;
    late AppDatabase dbBOpen;
    late MemoryKeyStore keysB;
    late NativeBackupController controller;
    late File backupFile;
    late int quits;
    late Uint8List keyA;

    Future<void> setUpMachineB({bool withKey = true}) async {
      final machineB = Directory('${root.path}/machineB')..createSync();
      dbB = File('${machineB.path}/apparel_pos.db');
      keysB = MemoryKeyStore();
      dbBOpen = AppDatabase(
        await openEncryptedDatabase(dbB, keysB, inBackground: false),
      );
      addTearDown(
        dbBOpen.close,
      ); // Windows cannot delete a file that is still open
      await dbBOpen.customSelect('SELECT 1').get(); // make sure it is created
      quits = 0;
      controller = NativeBackupController(
        dbBOpen,
        dbB,
        keysB,
        BackupService(dbBOpen, dbB, keysB, newId: newId, now: () => now),
        quitApp: () async => quits++,
      );
    }

    setUp(() async {
      await backups.backupNow(role: Role.owner);
      keyA = (await keysA.read())!;
      backupFile = File('${usb.path}/${BackupName.format(now)}');
    });

    test('first run: restores with the recovery key text, closes the database, asks for a restart', () async {
      await setUpMachineB();
      final r = await controller.restore(
        backupPath: backupFile.path,
        recoveryKeyText: RecoveryKey.format(keyA).toLowerCase(),
        firstRun: true,
      );
      expect(r.outcome, RestoreOutcome.done);
      expect(r.needsRestart, isTrue);
      expect(await keysB.read(), keyA);
      expect(
        beforeRestoreCopies(dbB),
        isEmpty,
      ); // the empty database that was here is gone
      final opened = AppDatabase(
        await openEncryptedDatabase(dbB, keysB, inBackground: false),
      );
      addTearDown(opened.close);
      expect(
        (await opened.select(opened.products).get()).single.name,
        secretStyle,
      );
      await controller.quit();
      expect(quits, 1);
    });

    test('first run is refused when a user already exists', () async {
      await setUpMachineB();
      await dbBOpen
          .into(dbBOpen.users)
          .insert(
            UsersCompanion.insert(
              id: 'u',
              name: 'Asha',
              role: 'OWNER',
              credentialHash: 'x',
              createdAt: now,
              updatedAt: now,
            ),
          );
      final r = await controller.restore(
        backupPath: backupFile.path,
        recoveryKeyText: RecoveryKey.format(keyA),
        firstRun: true,
      );
      expect(r.outcome, RestoreOutcome.notEmpty);
      expect(r.needsRestart, isFalse);
      expect(
        await dbBOpen.customSelect('SELECT 1 AS x').getSingle(),
        isNotNull,
      ); // still open
    });

    test('mistakes are reported without closing the database', () async {
      await setUpMachineB();
      Future<RestoreReport> go({String? key, String? path}) =>
          controller.restore(
            backupPath: path ?? backupFile.path,
            recoveryKeyText: key,
            firstRun: true,
          );
      expect(
        (await go(key: 'nonsense')).outcome,
        RestoreOutcome.badRecoveryKey,
      );
      expect(
        (await go(key: RecoveryKey.format(newDatabaseKey(Random(2))))).outcome,
        RestoreOutcome.wrongKey,
      );
      final garbage = File('${root.path}/apparel-pos-20261121-120000.backup')
        ..writeAsBytesSync(Uint8List(5000));
      expect(
        (await go(key: RecoveryKey.format(keyA), path: garbage.path)).outcome,
        anyOf(RestoreOutcome.damaged, RestoreOutcome.wrongKey),
      );
      for (final report in [
        await go(key: 'x'),
        await go(key: RecoveryKey.format(newDatabaseKey(Random(2)))),
      ]) {
        expect(report.needsRestart, isFalse);
      }
      await dbBOpen.customSelect('SELECT 1').get(); // still usable
    });

    test('with no key on this computer and none typed it asks for the recovery key', () async {
      await setUpMachineB();
      await dbBOpen.close();
      final empty = NativeBackupController(
        dbBOpen,
        dbB,
        MemoryKeyStore(),
        BackupService(
          dbBOpen,
          dbB,
          MemoryKeyStore(),
          newId: newId,
          now: () => now,
        ),
        quitApp: () async {},
      );
      expect(
        (await empty.restore(backupPath: backupFile.path)).outcome,
        RestoreOutcome.keyRequired,
      );
    });

    test('kept-aside copies are counted and only a manager or owner may delete them', () async {
      // a manager restoring over this very database (as Manager Mode does)
      await db.customStatement(
        "INSERT INTO app_settings (name, value) VALUES ('after-backup', 'today')",
      );
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
      final live = NativeBackupController(
        db,
        dbA,
        keysA,
        backups,
        quitApp: () async => quits++,
      );
      quits = 0;
      final r = await live.restore(backupPath: backupFile.path);
      expect(r.outcome, RestoreOutcome.done);
      expect(await live.beforeRestoreCopyCount(), 1);
      await expectLater(
        live.discardBeforeRestoreCopies(role: Role.cashier),
        throwsA(isA<PermissionDenied>()),
      );
      expect(await live.beforeRestoreCopyCount(), 1);
      await live.discardBeforeRestoreCopies(role: Role.manager);
      expect(await live.beforeRestoreCopyCount(), 0);
      db = AppDatabase(
        await openEncryptedDatabase(dbA, keysA, inBackground: false),
      ); // for tearDown
    });
  });

  test('openShiftCount counts shifts with no close', () async {
    for (final id in ['c1', 'c2']) {
      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              id: id,
              name: id,
              role: 'CASHIER',
              credentialHash: 'x',
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    final shifts = ShiftRepository(db, newId: newId, now: () => now);
    expect(await shifts.openShiftCount(), 0);
    await shifts.openShift(role: Role.cashier, userId: 'c1', counts: const {});
    await shifts.openShift(role: Role.cashier, userId: 'c2', counts: const {});
    expect(await shifts.openShiftCount(), 2);
    await shifts.closeShift(role: Role.cashier, userId: 'c1', counts: const {});
    expect(await shifts.openShiftCount(), 1);
    await shifts.closeShift(role: Role.cashier, userId: 'c2', counts: const {});
    expect(await shifts.openShiftCount(), 0);
  });
}
