// E-ENC-1: the database file is unreadable without the key. These run on the
// real SQLCipher build the app uses (selected in pubspec.yaml), on real files.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/encryption/encrypted_connection.dart';
import 'package:pos_windows/data/encryption/key_store.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

const secretStyle = 'ZEBRA-SECRET-STYLE-NAME';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('enc_test_');
    file = File('${dir.path}/apparel_pos.db');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<AppDatabase> open(KeyStore keys) async =>
      AppDatabase(await openEncryptedDatabase(file, keys, inBackground: false));

  Future<void> addStyle(AppDatabase db) => db
      .into(db.products)
      .insert(
        ProductsCompanion.insert(
          id: 'p1',
          name: secretStyle,
          createdAt: DateTime.utc(2026, 11, 21),
          updatedAt: DateTime.utc(2026, 11, 21),
        ),
      );

  bool containsText(Uint8List bytes, String text) =>
      String.fromCharCodes(bytes).contains(text);

  test('this build really is SQLCipher (the pubspec hook is in effect)', () {
    final db = raw.sqlite3.openInMemory();
    addTearDown(db.close);
    final v = db.select('PRAGMA cipher_version');
    expect(v, isNotEmpty);
    expect(v.first.values.first.toString(), isNotEmpty);
  });

  group('a new database', () {
    test('is not a plain SQLite file and shows none of its contents', () async {
      final keys = MemoryKeyStore();
      final db = await open(keys);
      await addStyle(db);
      await db.close();
      final bytes = file.readAsBytesSync();
      expect(isPlainDatabase(file), isFalse);
      expect(String.fromCharCodes(bytes.take(15)), isNot('SQLite format 3'));
      expect(containsText(bytes, secretStyle), isFalse);
      expect(containsText(bytes, 'CREATE TABLE'), isFalse);
      expect(containsText(bytes, 'products'), isFalse);
    });

    test(
      'the write-ahead journal is encrypted too while the database is open',
      () async {
        final keys = MemoryKeyStore();
        final db = await open(keys);
        await addStyle(db);
        final wal = File('${file.path}-wal');
        if (wal.existsSync()) {
          expect(containsText(wal.readAsBytesSync(), secretStyle), isFalse);
        }
        await db.close();
      },
    );

    test('cannot be read without the key', () async {
      final db = await open(MemoryKeyStore());
      await addStyle(db);
      await db.close();
      final plain = raw.sqlite3.open(file.path);
      addTearDown(plain.close);
      expect(
        () => plain.select('SELECT name FROM sqlite_master'),
        throwsA(isA<raw.SqliteException>()),
      );
    });

    test('cannot be read with a wrong key', () async {
      final db = await open(MemoryKeyStore());
      await addStyle(db);
      await db.close();
      final wrong = MemoryKeyStore(newDatabaseKey(Random(1)));
      await expectLater(open(wrong), throwsA(isA<WrongDatabaseKey>()));
    });

    test(
      'is read with the right key, after closing and opening again',
      () async {
        final keys = MemoryKeyStore();
        final db = await open(keys);
        await addStyle(db);
        await db.close();
        final again = await open(keys);
        addTearDown(again.close);
        final rows = await again.select(again.products).get();
        expect(rows.single.name, secretStyle);
      },
    );

    test(
      'makes a 32-byte key on first launch and reuses it on the next',
      () async {
        final keys = MemoryKeyStore();
        expect(await keys.read(), isNull);
        final db = await open(keys);
        await db.close();
        final first = await keys.read();
        expect(first!.length, 32);
        final db2 = await open(keys);
        await db2.close();
        expect(await keys.read(), first);
      },
    );

    test('the key is not in the file, the settings or the audit log', () async {
      final keys = MemoryKeyStore();
      final db = await open(keys);
      await addStyle(db);
      final hex = RecoveryKey.hex((await keys.read())!);
      final settings = await db
          .customSelect('SELECT name, value FROM app_settings')
          .get();
      for (final r in settings) {
        expect(r.read<String>('value'), isNot(contains(hex)));
      }
      await db.close();
      expect(containsText(file.readAsBytesSync(), hex), isFalse);
      expect(containsText(file.readAsBytesSync(), hex.toUpperCase()), isFalse);
    });
  });

  group('the key goes missing', () {
    test('an existing database is not replaced by a new one; the file is untouched', () async {
      final db = await open(MemoryKeyStore());
      await addStyle(db);
      await db.close();
      final before = file.readAsBytesSync();
      final empty = MemoryKeyStore();
      await expectLater(open(empty), throwsA(isA<KeyMissing>()));
      expect(file.readAsBytesSync(), before);
      expect(await empty.read(), isNull); // no new key was made either
    });

    test('the recovery key restores it on another computer', () async {
      final original = MemoryKeyStore();
      final db = await open(original);
      await addStyle(db);
      await db.close();
      final written = RecoveryKey.format((await original.read())!);
      // a new computer: an empty key store, the copied file, the typed-in key
      final restored = MemoryKeyStore(
        RecoveryKey.parse(written.toLowerCase().replaceAll('-', ' ')),
      );
      final again = await open(restored);
      addTearDown(again.close);
      expect(
        (await again.select(again.products).get()).single.name,
        secretStyle,
      );
    });
  });

  group('a plain-text database from an earlier development build', () {
    Future<void> makePlain() async {
      final db = AppDatabase(NativeDatabase(file));
      await addStyle(db);
      await db.close();
    }

    test(
      'is converted: not plain any more, nothing readable, data kept',
      () async {
        await makePlain();
        expect(isPlainDatabase(file), isTrue);
        final keys = MemoryKeyStore();
        final db = await open(keys);
        addTearDown(db.close);
        expect(isPlainDatabase(file), isFalse);
        expect(containsText(file.readAsBytesSync(), secretStyle), isFalse);
        expect((await db.select(db.products).get()).single.name, secretStyle);
        final v = await db.customSelect('PRAGMA user_version').getSingle();
        expect(v.read<int>('user_version'), db.schemaVersion);
      },
    );

    test('leaves no plain-text copy or journal behind', () async {
      await makePlain();
      final db = await open(MemoryKeyStore());
      await db.close();
      final leftovers = dir
          .listSync()
          .map((e) => e.path.split(Platform.pathSeparator).last)
          .toList();
      expect(leftovers.where((n) => n.contains('encrypting')), isEmpty);
      for (final f in dir.listSync().whereType<File>()) {
        expect(
          containsText(f.readAsBytesSync(), secretStyle),
          isFalse,
          reason: f.path,
        );
      }
    });

    test(
      'is converted with a key already in the store, if there is one',
      () async {
        await makePlain();
        final key = newDatabaseKey(Random(7));
        final keys = MemoryKeyStore(key);
        final db = await open(keys);
        addTearDown(db.close);
        expect(await keys.read(), key);
        expect((await db.select(db.products).get()).single.name, secretStyle);
      },
    );
  });

  group('the guards', () {
    test('a build without SQLCipher is refused', () {
      expect(() => requireCipher(null), throwsA(isA<EncryptionUnavailable>()));
      expect(() => requireCipher(''), throwsA(isA<EncryptionUnavailable>()));
      expect(() => requireCipher('  '), throwsA(isA<EncryptionUnavailable>()));
      expect(() => requireCipher('4.20.0 community'), returnsNormally);
    });

    test('new keys are 32 random bytes and differ', () {
      final a = newDatabaseKey();
      final b = newDatabaseKey();
      expect(a.length, 32);
      expect(a, isNot(b));
      expect(newDatabaseKey(Random(5)), newDatabaseKey(Random(5)));
    });

    test('a plain database is detected only by its header', () {
      expect(isPlainDatabase(file), isFalse); // no file
      file.writeAsBytesSync(Uint8List(100));
      expect(isPlainDatabase(file), isFalse);
      file.writeAsStringSync('SQLite format 3\u0000${'x' * 100}');
      expect(isPlainDatabase(file), isTrue);
    });
  });
}
