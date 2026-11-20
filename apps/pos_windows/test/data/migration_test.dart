// Each schema version has a migration test (ADR-0006 point 5). Version 1 is the
// stock tables; version 2 adds the sign-in users table (P2-2); version 3 adds
// shop settings and the size and color lists (P2-3).
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';

import '../generated_migrations/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test(
    'version 1 upgrades to version 2 with the exact expected schema',
    () async {
      final connection = await verifier.startAt(1);
      final db = AppDatabase(connection);
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 2);
    },
  );

  test(
    'stock rows made in version 1 survive the upgrade to version 2',
    () async {
      final schema = await verifier.schemaAt(1);
      schema.rawDatabase.execute(
        "INSERT INTO products (id, name, created_at, updated_at) VALUES ('p1', 'Kurta', 1700000000, 1700000000)",
      );
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 2);
      final rows = await db.customSelect('SELECT name FROM products').get();
      expect(rows.single.read<String>('name'), 'Kurta');
      expect(
        (await db.customSelect('SELECT COUNT(*) AS c FROM users').getSingle())
            .read<int>('c'),
        0,
      );
    },
  );

  test(
    'version 2 upgrades to version 3 with the exact expected schema',
    () async {
      final connection = await verifier.startAt(2);
      final db = AppDatabase(connection);
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);
    },
  );

  test('users made in version 2 survive the upgrade to version 3', () async {
    final schema = await verifier.schemaAt(2);
    schema.rawDatabase.execute(
      "INSERT INTO users (id, name, role, credential_hash, active, failures, lock_count, created_at, updated_at) VALUES ('u1', 'Asha', 'CASHIER', 'h', 1, 0, 0, 1700000000, 1700000000)",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 3);
    final rows = await db.customSelect('SELECT name FROM users').get();
    expect(rows.single.read<String>('name'), 'Asha');
    expect(
      (await db
              .customSelect('SELECT COUNT(*) AS c FROM size_options')
              .getSingle())
          .read<int>('c'),
      0,
    );
  });
}
