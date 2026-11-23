// Each schema version has a migration test (ADR-0006 point 5). Each one starts
// at an older version and must reach the latest schema exactly (drift creates a
// table with its newest definition, so stopping at an older target would not
// match older schemas once a later version changes a table). Version 1 is the
// stock tables; version 2 adds the sign-in users table (P2-2); version 3 adds
// shop settings and the size and color lists (P2-3); version 4 adds bills (P2-4b);
// version 5 adds returns and credit notes (P2-5b); version 6 adds shifts, blind
// closes and the daybook (P2-6b); version 7 adds breaks inside a shift (UX-3); version 8 gives every person an operator ID; version 9 adds stock categories.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';

import '../generated_migrations/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('version 1 upgrades to the latest version (9) with the exact expected schema', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 9);
  });

  test(
    'stock rows made in version 1 survive the upgrade to the latest version',
    () async {
      final schema = await verifier.schemaAt(1);
      schema.rawDatabase.execute(
        "INSERT INTO products (id, name, created_at, updated_at) VALUES ('p1', 'Kurta', 1700000000, 1700000000)",
      );
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 9);
      final rows = await db.customSelect('SELECT name FROM products').get();
      expect(rows.single.read<String>('name'), 'Kurta');
      expect(
        (await db.customSelect('SELECT COUNT(*) AS c FROM users').getSingle())
            .read<int>('c'),
        0,
      );
    },
  );

  test('version 2 upgrades to the latest version (9) with the exact expected schema', () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 9);
  });

  test(
    'users made in version 2 survive the upgrade to the latest version',
    () async {
      final schema = await verifier.schemaAt(2);
      schema.rawDatabase.execute(
        "INSERT INTO users (id, name, role, credential_hash, active, failures, lock_count, created_at, updated_at) VALUES ('u1', 'Asha', 'CASHIER', 'h', 1, 0, 0, 1700000000, 1700000000)",
      );
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 9);
      final rows = await db.customSelect('SELECT name FROM users').get();
      expect(rows.single.read<String>('name'), 'Asha');
      expect(
        (await db
                .customSelect('SELECT COUNT(*) AS c FROM size_options')
                .getSingle())
            .read<int>('c'),
        0,
      );
    },
  );

  test('version 3 upgrades to the latest version (9) with the exact expected schema', () async {
    final connection = await verifier.startAt(3);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 9);
  });

  test('stock made in version 3 survives; bills start empty and are '
      'protected from edits in version 4', () async {
    final schema = await verifier.schemaAt(3);
    schema.rawDatabase.execute(
      "INSERT INTO products (id, name, created_at, updated_at) VALUES ('p1', 'Kurta', 1700000000, 1700000000)",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 9);
    expect(
      (await db.customSelect('SELECT name FROM products').getSingle())
          .read<String>('name'),
      'Kurta',
    );
    for (final t in [
      'bills',
      'bill_lines',
      'bill_payments',
      'bill_sequences',
    ]) {
      expect(
        (await db.customSelect('SELECT COUNT(*) AS c FROM $t').getSingle())
            .read<int>('c'),
        0,
      );
    }
    final triggers = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'trigger'")
        .get();
    expect(triggers.length, 24); // 2 for each of 12 never-edited tables
  });

  test('version 4 upgrades to the latest version (9) with the exact expected schema', () async {
    final connection = await verifier.startAt(4);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 9);
  });

  test('bills and payments made in version 4 survive, and a credit note '
      'payment is now allowed in version 5', () async {
    final schema = await verifier.schemaAt(4);
    final raw = schema.rawDatabase;
    raw.execute(
      "INSERT INTO counters (id, name, lot_first, lot_last, current_lot, next_serial, created_at, updated_at) VALUES ('c1', 'Counter 1', 0, 499, 0, 0, 1700000000, 1700000000)",
    );
    raw.execute(
      "INSERT INTO users (id, name, role, credential_hash, active, failures, lock_count, created_at, updated_at) VALUES ('u1', 'Asha', 'CASHIER', 'h', 1, 0, 0, 1700000000, 1700000000)",
    );
    raw.execute(
      "INSERT INTO bills (id, bill_no, counter_id, cashier_id, total_paise, change_paise, billed_at, created_at) VALUES ('b1', '2026-27/C1/000001', 'c1', 'u1', 49900, 0, 1700000000, 1700000000)",
    );
    raw.execute(
      "INSERT INTO bill_payments (id, bill_id, mode, amount_paise) VALUES ('p1', 'b1', 'cash', 49900)",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 9);
    final rows = await db
        .customSelect('SELECT mode, amount_paise FROM bill_payments')
        .get();
    expect(rows.single.read<String>('mode'), 'cash');
    expect(rows.single.read<int>('amount_paise'), 49900);
    await db.customStatement(
      "INSERT INTO bill_payments (id, bill_id, mode, amount_paise) VALUES ('p2', 'b1', 'credit_note', 100)",
    );
    await expectLater(
      db.customStatement(
        "INSERT INTO bill_payments (id, bill_id, mode, amount_paise) VALUES ('p3', 'b1', 'cheque', 100)",
      ),
      throwsA(anything),
    );
    // the no-edit rule still holds on the rebuilt table
    await expectLater(
      db.customStatement('DELETE FROM bill_payments'),
      throwsA(anything),
    );
  });

  test('version 5 upgrades to the latest version (9) with the exact expected schema', () async {
    final connection = await verifier.startAt(5);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 9);
  });

  test('bills made in version 5 survive version 6 with no shift, and new '
      'sales then need one', () async {
    final schema = await verifier.schemaAt(5);
    final raw = schema.rawDatabase;
    raw.execute(
      "INSERT INTO counters (id, name, lot_first, lot_last, current_lot, next_serial, created_at, updated_at) VALUES ('c1', 'Counter 1', 0, 499, 0, 0, 1700000000, 1700000000)",
    );
    raw.execute(
      "INSERT INTO users (id, name, role, credential_hash, active, failures, lock_count, created_at, updated_at) VALUES ('u1', 'Asha', 'CASHIER', 'h', 1, 0, 0, 1700000000, 1700000000)",
    );
    raw.execute(
      "INSERT INTO bills (id, bill_no, counter_id, cashier_id, total_paise, change_paise, billed_at, created_at) VALUES ('b1', '2026-27/C1/000001', 'c1', 'u1', 49900, 0, 1700000000, 1700000000)",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 9);
    final b = await db
        .customSelect('SELECT bill_no, shift_id FROM bills')
        .getSingle();
    expect(b.read<String>('bill_no'), '2026-27/C1/000001');
    expect(b.read<String?>('shift_id'), isNull);
    for (final t in ['shifts', 'shift_closes', 'daybook']) {
      expect(
        (await db.customSelect('SELECT COUNT(*) AS c FROM $t').getSingle())
            .read<int>('c'),
        0,
      );
    }
  });

  test('version 6 upgrades to the latest version (9) with the exact expected schema', () async {
    final connection = await verifier.startAt(6);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 9);
  });

  test('a shift open in version 6 survives version 7 with no breaks', () async {
    final schema = await verifier.schemaAt(6);
    final raw = schema.rawDatabase;
    raw.execute(
      "INSERT INTO counters (id, name, lot_first, lot_last, current_lot, next_serial, created_at, updated_at) VALUES ('c1', 'Counter 1', 0, 499, 0, 0, 1700000000, 1700000000)",
    );
    raw.execute(
      "INSERT INTO users (id, name, role, credential_hash, active, failures, lock_count, created_at, updated_at) VALUES ('u1', 'Asha', 'CASHIER', 'h', 1, 0, 0, 1700000000, 1700000000)",
    );
    raw.execute(
      "INSERT INTO shifts (id, cashier_id, counter_id, opened_at, opening_paise, opening_count) VALUES ('s1', 'u1', 'c1', 1700000000, 50000, '{}')",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 9);
    final s = await db
        .customSelect('SELECT id, opening_paise FROM shifts')
        .getSingle();
    expect(s.read<String>('id'), 's1');
    expect(s.read<int>('opening_paise'), 50000);
    for (final t in ['shift_breaks', 'shift_break_ends']) {
      expect(
        (await db.customSelect('SELECT COUNT(*) AS c FROM $t').getSingle())
            .read<int>('c'),
        0,
      );
    }
  });

  test('version 7 upgrades to the latest version (9) with the exact expected schema', () async {
    final connection = await verifier.startAt(7);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 9);
  });

  test('people made before version 8 get operator numbers in the order they were added', () async {
    final schema = await verifier.schemaAt(7);
    final raw = schema.rawDatabase;
    raw.execute(
      "INSERT INTO users (id, name, role, credential_hash, active, failures, lock_count, created_at, updated_at) VALUES ('u-late', 'Zed', 'CASHIER', 'h', 1, 0, 0, 1700000300, 1700000300)",
    );
    raw.execute(
      "INSERT INTO users (id, name, role, credential_hash, active, failures, lock_count, created_at, updated_at) VALUES ('u-first', 'Meera', 'OWNER', 'h', 1, 0, 0, 1700000100, 1700000100)",
    );
    raw.execute(
      "INSERT INTO users (id, name, role, credential_hash, active, failures, lock_count, created_at, updated_at) VALUES ('u-off', 'Old', 'CASHIER', 'h', 0, 0, 0, 1700000200, 1700000200)",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 9);
    final rows = await db
        .customSelect(
          'SELECT id, staff_number FROM users ORDER BY staff_number',
        )
        .get();
    expect(
      [for (final r in rows) r.read<String>('id')],
      ['u-first', 'u-off', 'u-late'],
    );
    expect([for (final r in rows) r.read<int>('staff_number')], [1, 2, 3]);
  });

  test('two people can never share an operator number', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement(
      "INSERT INTO users (id, name, role, credential_hash, active, failures, lock_count, staff_number, created_at, updated_at) VALUES ('a', 'A', 'CASHIER', 'h', 1, 0, 0, 1, 1700000000, 1700000000)",
    );
    await expectLater(
      db.customStatement(
        "INSERT INTO users (id, name, role, credential_hash, active, failures, lock_count, staff_number, created_at, updated_at) VALUES ('b', 'B', 'CASHIER', 'h', 1, 0, 0, 1, 1700000000, 1700000000)",
      ),
      throwsA(anything),
    );
  });

  test('version 8 upgrades to the latest version (9) with the exact expected schema', () async {
    final connection = await verifier.startAt(8);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 9);
  });

  test('styles made before version 9 keep working with no category', () async {
    final schema = await verifier.schemaAt(8);
    final raw = schema.rawDatabase;
    raw.execute(
      "INSERT INTO products (id, name, created_at, updated_at) VALUES ('p1', 'Cotton Kurta', 1700000000, 1700000000)",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 9);
    final r = await db
        .customSelect('SELECT name, category_id FROM products')
        .getSingle();
    expect(r.read<String>('name'), 'Cotton Kurta');
    expect(r.read<String?>('category_id'), isNull);
    expect(
      (await db
              .customSelect('SELECT COUNT(*) AS c FROM categories')
              .getSingle())
          .read<int>('c'),
      0,
    );
  });
}
