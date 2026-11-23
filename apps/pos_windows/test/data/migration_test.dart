// Each schema version has a migration test (ADR-0006 point 5). Each one starts
// at an older version and must reach the latest schema exactly (drift creates a
// table with its newest definition, so stopping at an older target would not
// match older schemas once a later version changes a table). Version 1 is the
// stock tables; version 2 adds the sign-in users table (P2-2); version 3 adds
// shop settings and the size and color lists (P2-3); version 4 adds bills (P2-4b);
// version 5 adds returns and credit notes (P2-5b); version 6 adds shifts, blind
// closes and the daybook (P2-6b); version 7 adds breaks inside a shift (UX-3); version 8 gives every person an operator ID; version 9 adds stock categories; version 10 adds markdowns set ahead of time on a style; version 11 adds pay later (customers, what they owe, the daybook takes dues); version 12 adds GST fields to bill lines.
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

  test('version 1 upgrades to the latest version (12) with the exact expected schema', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 12);
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
      await verifier.migrateAndValidate(db, 12);
      final rows = await db.customSelect('SELECT name FROM products').get();
      expect(rows.single.read<String>('name'), 'Kurta');
      expect(
        (await db.customSelect('SELECT COUNT(*) AS c FROM users').getSingle())
            .read<int>('c'),
        0,
      );
    },
  );

  test('version 2 upgrades to the latest version (12) with the exact expected schema', () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 12);
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
      await verifier.migrateAndValidate(db, 12);
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

  test('version 3 upgrades to the latest version (12) with the exact expected schema', () async {
    final connection = await verifier.startAt(3);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 12);
  });

  test('stock made in version 3 survives; bills start empty and are '
      'protected from edits in version 4', () async {
    final schema = await verifier.schemaAt(3);
    schema.rawDatabase.execute(
      "INSERT INTO products (id, name, created_at, updated_at) VALUES ('p1', 'Kurta', 1700000000, 1700000000)",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 12);
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
    expect(triggers.length, 30); // 2 for each of 15 never-edited tables
  });

  test('version 4 upgrades to the latest version (12) with the exact expected schema', () async {
    final connection = await verifier.startAt(4);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 12);
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
    await verifier.migrateAndValidate(db, 12);
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

  test('version 5 upgrades to the latest version (12) with the exact expected schema', () async {
    final connection = await verifier.startAt(5);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 12);
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
    await verifier.migrateAndValidate(db, 12);
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

  test('version 6 upgrades to the latest version (12) with the exact expected schema', () async {
    final connection = await verifier.startAt(6);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 12);
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
    await verifier.migrateAndValidate(db, 12);
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

  test('version 7 upgrades to the latest version (12) with the exact expected schema', () async {
    final connection = await verifier.startAt(7);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 12);
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
    await verifier.migrateAndValidate(db, 12);
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

  test('version 8 upgrades to the latest version (12) with the exact expected schema', () async {
    final connection = await verifier.startAt(8);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 12);
  });

  test('styles made before version 9 keep working with no category', () async {
    final schema = await verifier.schemaAt(8);
    final raw = schema.rawDatabase;
    raw.execute(
      "INSERT INTO products (id, name, created_at, updated_at) VALUES ('p1', 'Cotton Kurta', 1700000000, 1700000000)",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 12);
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

  test('version 9 upgrades to the latest version (12) with the exact expected schema', () async {
    final connection = await verifier.startAt(9);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 12);
  });

  test('a style gets no markdown from the upgrade, and a markdown can then be kept', () async {
    final schema = await verifier.schemaAt(9);
    final raw = schema.rawDatabase;
    raw.execute(
      "INSERT INTO products (id, name, created_at, updated_at) VALUES ('p1', 'Cotton Kurta', 1700000000, 1700000000)",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 12);
    expect(
      (await db
              .customSelect('SELECT COUNT(*) AS c FROM style_markdowns')
              .getSingle())
          .read<int>('c'),
      0,
    );
    await db.customStatement(
      "INSERT INTO style_markdowns (product_id, percent_bp, ends_before, set_by, created_at, updated_at) VALUES ('p1', 2000, 1800000000, 'u1', 1700000000, 1700000000)",
    );
    final r = await db
        .customSelect('SELECT percent_bp FROM style_markdowns')
        .getSingle();
    expect(r.read<int>('percent_bp'), 2000);
  });

  test('the database refuses a markdown that is both a percent and an amount, or neither, or out of range', () async {
    final schema = await verifier.schemaAt(9);
    schema.rawDatabase.execute(
      "INSERT INTO products (id, name, created_at, updated_at) VALUES ('p1', 'Cotton Kurta', 1700000000, 1700000000)",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 12);
    Future<void> insert(String cols, String vals) => db.customStatement(
      'INSERT INTO style_markdowns (product_id, $cols, ends_before, set_by, created_at, updated_at) '
      "VALUES ('p1', $vals, 1800000000, 'u1', 1700000000, 1700000000)",
    );
    await expectLater(
      insert('percent_bp, amount_paise', '2000, 5000'),
      throwsA(anything),
    );
    await expectLater(insert('percent_bp', 'NULL'), throwsA(anything));
    await expectLater(insert('percent_bp', '0'), throwsA(anything));
    await expectLater(insert('percent_bp', '10000'), throwsA(anything));
    await expectLater(insert('amount_paise', '0'), throwsA(anything));
    await insert('amount_paise', '5000'); // a good one still goes in
  });

  test('version 10 upgrades to the latest version (12) with the exact expected schema', () async {
    final connection = await verifier.startAt(10);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 12);
  });

  test('daybook rows made before version 11 are kept, still cannot be changed, and the new kinds are accepted', () async {
    final schema = await verifier.schemaAt(10);
    final raw = schema.rawDatabase;
    raw.execute(
      "INSERT INTO users (id, name, role, credential_hash, created_at, updated_at) VALUES ('u1', 'Asha', 'CASHIER', 'x', 1700000000, 1700000000)",
    );
    raw.execute(
      "INSERT INTO counters (id, name, lot_first, lot_last, current_lot, next_serial, created_at, updated_at) VALUES ('c1', 'Counter 1', 0, 499, 0, 0, 1700000000, 1700000000)",
    );
    raw.execute(
      "INSERT INTO shifts (id, cashier_id, counter_id, opened_at, opening_paise, opening_count) VALUES ('s1', 'u1', 'c1', 1700000000, 200000, '{}')",
    );
    raw.execute(
      "INSERT INTO daybook (id, at, shift_id, kind, amount_paise, ref_type, ref_id) VALUES ('d1', 1700000100, 's1', 'SALE_CASH', 49900, 'bill', 'b1')",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 12);
    final r = await db
        .customSelect('SELECT kind, amount_paise FROM daybook')
        .getSingle();
    expect(r.read<String>('kind'), 'SALE_CASH');
    expect(r.read<int>('amount_paise'), 49900);
    await expectLater(
      db.customStatement("UPDATE daybook SET amount_paise = 1 WHERE id = 'd1'"),
      throwsA(anything),
    );
    await expectLater(
      db.customStatement("DELETE FROM daybook WHERE id = 'd1'"),
      throwsA(anything),
    );
    await db.customStatement(
      "INSERT INTO daybook (id, at, shift_id, kind, amount_paise, ref_type, ref_id) VALUES ('d2', 1700000200, 's1', 'DUES_CASH', 10000, 'dues', 'r1')",
    );
    await expectLater(
      db.customStatement(
        "INSERT INTO daybook (id, at, shift_id, kind, amount_paise, ref_type, ref_id) VALUES ('d3', 1700000300, 's1', 'DUES_CHEQUE', 10000, 'dues', 'r1')",
      ),
      throwsA(anything),
    );
  });

  test('version 11 upgrades to the latest version (12) with the exact expected schema', () async {
    final connection = await verifier.startAt(11);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 12);
  });

  test(
    'bill lines made before version 12 read as no GST, and cannot be changed',
    () async {
      final schema = await verifier.schemaAt(11);
      final raw = schema.rawDatabase;
      raw.execute(
        "INSERT INTO users (id, name, role, credential_hash, created_at, updated_at) VALUES ('u1', 'Asha', 'CASHIER', 'x', 1700000000, 1700000000)",
      );
      raw.execute(
        "INSERT INTO counters (id, name, lot_first, lot_last, current_lot, next_serial, created_at, updated_at) VALUES ('c1', 'Counter 1', 0, 499, 0, 0, 1700000000, 1700000000)",
      );
      raw.execute(
        "INSERT INTO products (id, name, created_at, updated_at) VALUES ('p1', 'Kurta', 1700000000, 1700000000)",
      );
      raw.execute(
        "INSERT INTO variants (id, product_id, size, color, mrp_paise, created_at, updated_at) VALUES ('v1', 'p1', 'M', 'Blue', 49900, 1700000000, 1700000000)",
      );
      raw.execute(
        "INSERT INTO batches (id, supplier, lot, purchased_at, created_at, updated_at) VALUES ('ba1', 'S', 0, 1700000000, 1700000000, 1700000000)",
      );
      raw.execute(
        "INSERT INTO articles (id, variant_id, batch_id, barcode_value, status, mrp_paise, created_at, updated_at) VALUES ('a1', 'v1', 'ba1', '000000000011', 'SOLD', 49900, 1700000000, 1700000000)",
      );
      raw.execute(
        "INSERT INTO bills (id, bill_no, counter_id, cashier_id, total_paise, change_paise, billed_at, created_at) VALUES ('b1', '2026-27/C1/000001', 'c1', 'u1', 49900, 0, 1700000000, 1700000000)",
      );
      raw.execute(
        "INSERT INTO bill_lines (id, bill_id, article_id, barcode_value, product_name, size, color, mrp_paise, markdown_paise, discount_paise, final_paise) VALUES ('l1', 'b1', 'a1', '000000000011', 'Kurta', 'M', 'Blue', 49900, 0, 0, 49900)",
      );
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 12);
      final r = await db
          .customSelect(
            'SELECT final_paise, gst_bp, taxable_paise, tax_paise, extra_tax_paise FROM bill_lines',
          )
          .getSingle();
      expect(r.read<int>('final_paise'), 49900);
      for (final c in [
        'gst_bp',
        'taxable_paise',
        'tax_paise',
        'extra_tax_paise',
      ]) {
        expect(r.read<int>(c), 0, reason: c);
      }
      await expectLater(
        db.customStatement(
          "UPDATE bill_lines SET tax_paise = 5 WHERE id = 'l1'",
        ),
        throwsA(anything),
      );
    },
  );
}
