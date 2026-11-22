// P2-1 database tests: constraints, WAL, versioning and the audit + outbox
// rule (ADR-0006). E-SERIAL-1 (a barcode is unique) and E-AUDIT-1 (audit and
// outbox rows are written in the same transaction as the change).
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';

const t = 1700000000; // any UTC time, in seconds

AppDatabase memoryDb() => AppDatabase(NativeDatabase.memory());

Future<void> sql(
  AppDatabase db,
  String statement, [
  List<Object?> args = const [],
]) => db.customStatement(statement, args);

Future<void> seedStyle(AppDatabase db) async {
  await sql(
    db,
    "INSERT INTO products (id, name, created_at, updated_at) VALUES ('p1', 'Kurta', $t, $t)",
  );
  await sql(
    db,
    "INSERT INTO variants (id, product_id, size, color, mrp_paise, created_at, updated_at) VALUES ('v1', 'p1', 'M', 'Blue', 49900, $t, $t)",
  );
  await sql(
    db,
    "INSERT INTO batches (id, supplier, lot, purchased_at, created_at, updated_at) VALUES ('b1', 'Sample Supplier', 123, $t, $t, $t)",
  );
}

Future<void> insertArticle(
  AppDatabase db,
  String id,
  String barcode, {
  String status = 'IN_STOCK',
  int mrp = 49900,
}) => sql(
  db,
  "INSERT INTO articles (id, barcode_value, variant_id, batch_id, mrp_paise, status, created_at, updated_at) VALUES ('$id', '$barcode', 'v1', 'b1', $mrp, '$status', $t, $t)",
);

Future<void> expectRejected(Future<void> action) async {
  await expectLater(action, throwsA(anything));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  group('schema', () {
    test('has the expected tables and schema version 9', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
          )
          .get();
      expect(rows.map((r) => r.read<String>('name')), [
        'app_settings',
        'articles',
        'audit_log',
        'batch_lines',
        'batches',
        'bill_lines',
        'bill_payments',
        'bill_sequences',
        'bills',
        'categories',
        'color_options',
        'counters',
        'credit_note_uses',
        'credit_notes',
        'daybook',
        'outbox',
        'products',
        'return_lines',
        'returns',
        'shift_break_ends',
        'shift_breaks',
        'shift_closes',
        'shifts',
        'size_options',
        'users',
        'variants',
      ]);
      expect(db.schemaVersion, 9);
      final v = await db.customSelect('PRAGMA user_version').getSingle();
      expect(v.read<int>('user_version'), 9);
    });

    test('foreign keys are enforced', () async {
      await expectRejected(
        sql(
          db,
          "INSERT INTO variants (id, product_id, size, color, mrp_paise, created_at, updated_at) VALUES ('v', 'missing', 'M', 'Blue', 100, $t, $t)",
        ),
      );
    });

    test(
      'money columns are integers named in paise (no floating-point columns)',
      () async {
        final rows = await db
            .customSelect(
              "SELECT m.name AS tbl, p.name AS col, p.type AS type FROM sqlite_master m, pragma_table_info(m.name) p WHERE m.type = 'table'",
            )
            .get();
        for (final r in rows) {
          expect(
            r.read<String>('type').toUpperCase(),
            isNot(anyOf('REAL', 'FLOAT', 'DOUBLE')),
            reason: '${r.read<String>('tbl')}.${r.read<String>('col')}',
          );
        }
      },
    );
  });

  group('articles (E-SERIAL-1)', () {
    setUp(() => seedStyle(db));

    test('a barcode is unique across the shop', () async {
      await insertArticle(db, 'a1', '261101230013');
      await expectRejected(insertArticle(db, 'a2', '261101230013'));
    });

    test('a barcode must be 12 digits', () async {
      await expectRejected(insertArticle(db, 'a1', '26110123001'));
      await expectRejected(insertArticle(db, 'a1', '26110123001x'));
    });

    test('status must be one of the four states', () async {
      var i = 0;
      for (final ok in ['IN_STOCK', 'SOLD', 'RETURNED', 'DAMAGED']) {
        i++;
        await insertArticle(db, 'ok-$ok', '26110123000$i', status: ok);
      }
      await expectRejected(
        insertArticle(db, 'bad', '261101230099', status: 'LOST'),
      );
    });

    test('each article keeps its own MRP and it cannot be negative', () async {
      await insertArticle(db, 'a1', '261101230013', mrp: 49900);
      await insertArticle(db, 'a2', '261101230020', mrp: 54900);
      final rows = await db
          .customSelect('SELECT mrp_paise FROM articles ORDER BY id')
          .get();
      expect(rows.map((r) => r.read<int>('mrp_paise')), [49900, 54900]);
      await expectRejected(insertArticle(db, 'a3', '261101230037', mrp: -1));
    });

    test('an article needs a real variant and batch', () async {
      await expectRejected(
        sql(
          db,
          "INSERT INTO articles (id, barcode_value, variant_id, batch_id, mrp_paise, status, created_at, updated_at) VALUES ('x', '261101230013', 'nope', 'b1', 1, 'IN_STOCK', $t, $t)",
        ),
      );
    });
  });

  group('other constraints', () {
    setUp(() => seedStyle(db));

    test('one variant per style, size and color', () async {
      await expectRejected(
        sql(
          db,
          "INSERT INTO variants (id, product_id, size, color, mrp_paise, created_at, updated_at) VALUES ('v2', 'p1', 'M', 'Blue', 100, $t, $t)",
        ),
      );
      await sql(
        db,
        "INSERT INTO variants (id, product_id, size, color, mrp_paise, created_at, updated_at) VALUES ('v3', 'p1', 'L', 'Blue', 100, $t, $t)",
      );
    });

    test('variant MRP cannot be negative', () async {
      await expectRejected(
        sql(
          db,
          "INSERT INTO variants (id, product_id, size, color, mrp_paise, created_at, updated_at) VALUES ('v4', 'p1', 'S', 'Red', -5, $t, $t)",
        ),
      );
    });

    test('batch line: quantity at least 1, cost not negative, one line per variant', () async {
      await sql(
        db,
        "INSERT INTO batch_lines (id, batch_id, variant_id, quantity, unit_cost_paise) VALUES ('l1', 'b1', 'v1', 10, 20000)",
      );
      await expectRejected(
        sql(
          db,
          "INSERT INTO batch_lines (id, batch_id, variant_id, quantity, unit_cost_paise) VALUES ('l2', 'b1', 'v1', 5, 20000)",
        ),
      );
      await sql(
        db,
        "INSERT INTO variants (id, product_id, size, color, mrp_paise, created_at, updated_at) VALUES ('v5', 'p1', 'XL', 'Blue', 100, $t, $t)",
      );
      await expectRejected(
        sql(
          db,
          "INSERT INTO batch_lines (id, batch_id, variant_id, quantity, unit_cost_paise) VALUES ('l3', 'b1', 'v5', 0, 20000)",
        ),
      );
      await expectRejected(
        sql(
          db,
          "INSERT INTO batch_lines (id, batch_id, variant_id, quantity, unit_cost_paise) VALUES ('l4', 'b1', 'v5', 1, -1)",
        ),
      );
    });

    test('counter lot range must be valid and the current lot inside it', () async {
      await sql(
        db,
        "INSERT INTO counters (id, name, lot_first, lot_last, current_lot, next_serial, created_at, updated_at) VALUES ('c1', 'Counter 1', 0, 499, 0, 0, $t, $t)",
      );
      await expectRejected(
        sql(
          db,
          "INSERT INTO counters (id, name, lot_first, lot_last, current_lot, next_serial, created_at, updated_at) VALUES ('c2', 'C', 500, 400, 500, 0, $t, $t)",
        ),
      );
      await expectRejected(
        sql(
          db,
          "INSERT INTO counters (id, name, lot_first, lot_last, current_lot, next_serial, created_at, updated_at) VALUES ('c3', 'C', 0, 1000, 0, 0, $t, $t)",
        ),
      );
      await expectRejected(
        sql(
          db,
          "INSERT INTO counters (id, name, lot_first, lot_last, current_lot, next_serial, created_at, updated_at) VALUES ('c4', 'C', 500, 999, 400, 0, $t, $t)",
        ),
      );
      await expectRejected(
        sql(
          db,
          "INSERT INTO counters (id, name, lot_first, lot_last, current_lot, next_serial, created_at, updated_at) VALUES ('c5', 'C', 500, 999, 500, 10001, $t, $t)",
        ),
      );
    });
  });

  group('audit and outbox in the same transaction (E-AUDIT-1)', () {
    int n = 0;
    late AuditedWriter writer;
    setUp(() {
      n = 0;
      writer = AuditedWriter(
        db,
        now: () => DateTime.utc(2026, 11, 20, 10),
        newId: () => 'id-${++n}',
      );
    });

    Future<int> count(String table) async =>
        (await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle())
            .read<int>('c');

    test('the change, one audit row and one outbox row are saved together', () async {
      final result = await writer.run<String>(
        action: 'product.create',
        entityType: 'product',
        entityId: 'p1',
        actor: 'user-1',
        details: {'name': 'Kurta'},
        body: () async {
          await sql(
            db,
            "INSERT INTO products (id, name, created_at, updated_at) VALUES ('p1', 'Kurta', $t, $t)",
          );
          return 'done';
        },
      );
      expect(result, 'done');
      expect(await count('products'), 1);
      final audit = await db
          .customSelect('SELECT * FROM audit_log')
          .getSingle();
      expect(audit.read<String>('action'), 'product.create');
      expect(audit.read<String>('entity_type'), 'product');
      expect(audit.read<String>('entity_id'), 'p1');
      expect(audit.read<String>('actor'), 'user-1');
      expect(audit.read<String>('details'), contains('Kurta'));
      final out = await db.customSelect('SELECT * FROM outbox').getSingle();
      expect(out.read<String>('entity_type'), 'product');
      expect(out.read<String>('entity_id'), 'p1');
      expect(out.read<String>('operation'), 'product.create');
      expect(out.readNullable<int>('sent_at'), isNull);
    });

    test('if the change fails nothing is saved', () async {
      await expectLater(
        writer.run<void>(
          action: 'product.create',
          entityType: 'product',
          entityId: 'p1',
          body: () async {
            await sql(
              db,
              "INSERT INTO products (id, name, created_at, updated_at) VALUES ('p1', 'Kurta', $t, $t)",
            );
            throw StateError('boom');
          },
        ),
        throwsStateError,
      );
      expect(await count('products'), 0);
      expect(await count('audit_log'), 0);
      expect(await count('outbox'), 0);
    });

    test('if the audit row cannot be written the change is undone', () async {
      // Every id is "same", so the second write's audit row clashes with the first.
      final clash = AuditedWriter(
        db,
        now: () => DateTime.utc(2026, 11, 20),
        newId: () => 'same',
      );
      await clash.run<void>(
        action: 'product.create',
        entityType: 'product',
        entityId: 'p1',
        body: () async => sql(
          db,
          "INSERT INTO products (id, name, created_at, updated_at) VALUES ('p1', 'Kurta', $t, $t)",
        ),
      );
      await expectLater(
        clash.run<void>(
          action: 'product.create',
          entityType: 'product',
          entityId: 'p2',
          body: () async => sql(
            db,
            "INSERT INTO products (id, name, created_at, updated_at) VALUES ('p2', 'Shirt', $t, $t)",
          ),
        ),
        throwsA(anything),
      );
      expect(await count('products'), 1);
      expect(await count('audit_log'), 1);
      expect(await count('outbox'), 1);
    });
  });

  group('opening a database file', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('pos_db_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('uses write-ahead logging (WAL)', () async {
      final file = File('${dir.path}/pos.db');
      final fileDb = AppDatabase(NativeDatabase(file));
      addTearDown(fileDb.close);
      final mode = await fileDb.customSelect('PRAGMA journal_mode').getSingle();
      expect(mode.read<String>('journal_mode').toLowerCase(), 'wal');
    });

    test(
      'a database made by a newer app version is refused, not changed',
      () async {
        final file = File('${dir.path}/newer.db');
        final first = AppDatabase(NativeDatabase(file));
        await first.customSelect('SELECT 1').get();
        await first.customStatement('PRAGMA user_version = 99');
        await first.close();

        final second = AppDatabase(NativeDatabase(file));
        addTearDown(second.close);
        await expectLater(
          second.customSelect('SELECT 1').get(),
          throwsA(anything),
        );
      },
    );
  });
}
