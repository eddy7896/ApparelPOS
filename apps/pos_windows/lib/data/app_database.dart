// The counter's local database (Drift on SQLite), release 1 stock tables.
// Rules (ADR-0006, ADR-0007): ids are UUID text made on the device, times are
// UTC, money is integer paise, every write also writes an audit row and an
// outbox row in the same transaction. Encryption (SQLCipher) is P3-1 and is NOT
// done here: this database is not encrypted yet (E-ENC-1 pending).
// ignore_for_file: recursive_getters
// (Drift's documented way to write a check on a column refers to the column itself.)
import 'dart:convert';

import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// This counter's reserved range of lot numbers and where it is now
/// (ADR-0006 point 8; core_domain `LotRange` / `LotCursor`).
@DataClassName('CounterRow')
class Counters extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get lotFirst => integer().check(lotFirst.isBetweenValues(0, 999))();
  IntColumn get lotLast => integer().check(lotLast.isBetweenValues(0, 999))();
  IntColumn get currentLot => integer()();
  IntColumn get nextSerial =>
      integer().check(nextSerial.isBetweenValues(0, 10000))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (lot_last >= lot_first)',
    'CHECK (current_lot >= lot_first AND current_lot <= lot_last)',
  ];
}

/// A person who can sign in at the counter. The PIN (cashier) or password
/// (manager, owner) is stored only as an Argon2id hash. Wrong-try state is kept
/// here so a lock survives restarting the app (E-AUTH-2).
@DataClassName('UserRow')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name =>
      text().customConstraint('NOT NULL UNIQUE COLLATE NOCASE')();
  TextColumn get role => text().customConstraint(
    "NOT NULL CHECK (role IN ('CASHIER', 'MANAGER', 'OWNER'))",
  )();
  TextColumn get credentialHash => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get failures => integer().withDefault(const Constant(0))();
  IntColumn get lockCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lockedUntil => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Shop settings as name and value pairs (for example `shop_name`).
@DataClassName('SettingRow')
class AppSettings extends Table {
  TextColumn get name => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {name};
}

/// The sizes offered in the purchase grid, in the order shown.
@DataClassName('SizeOptionRow')
class SizeOptions extends Table {
  TextColumn get id => text()();
  TextColumn get name =>
      text().customConstraint('NOT NULL UNIQUE COLLATE NOCASE')();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The colors offered in the purchase grid, in the order shown.
@DataClassName('ColorOptionRow')
class ColorOptions extends Table {
  TextColumn get id => text()();
  TextColumn get name =>
      text().customConstraint('NOT NULL UNIQUE COLLATE NOCASE')();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A style, such as "Cotton Kurta".
@DataClassName('ProductRow')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A style in one size and color, with its current MRP.
@DataClassName('VariantRow')
class Variants extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get size => text()();
  TextColumn get color => text()();
  IntColumn get mrpPaise => integer().check(mrpPaise.isBiggerOrEqualValue(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {productId, size, color},
  ];
}

/// One purchase (GRN): supplier, date and the lot its barcodes come from.
@DataClassName('BatchRow')
class Batches extends Table {
  TextColumn get id => text()();
  TextColumn get supplier => text()();
  IntColumn get lot => integer().check(lot.isBetweenValues(0, 999))();
  DateTimeColumn get purchasedAt => dateTime()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// What was bought and at what cost. COST COLUMNS LIVE ONLY HERE: cashier code
/// must never select this table (E-AUTHZ-1, enforced when the cashier data
/// layer is built).
@DataClassName('BatchLineRow')
class BatchLines extends Table {
  TextColumn get id => text()();
  TextColumn get batchId => text().references(Batches, #id)();
  TextColumn get variantId => text().references(Variants, #id)();
  IntColumn get quantity => integer().check(quantity.isBiggerOrEqualValue(1))();
  IntColumn get unitCostPaise =>
      integer().check(unitCostPaise.isBiggerOrEqualValue(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {batchId, variantId},
  ];
}

/// One physical garment. It keeps its own MRP (the one printed on its tag).
@DataClassName('ArticleRow')
class Articles extends Table {
  TextColumn get id => text()();
  TextColumn get barcodeValue => text().customConstraint(
    "NOT NULL UNIQUE CHECK (length(barcode_value) = 12 AND barcode_value NOT GLOB '*[^0-9]*')",
  )();
  TextColumn get variantId => text().references(Variants, #id)();
  TextColumn get batchId => text().references(Batches, #id)();
  IntColumn get mrpPaise => integer().check(mrpPaise.isBiggerOrEqualValue(0))();
  TextColumn get status => text().customConstraint(
    "NOT NULL CHECK (status IN ('IN_STOCK', 'SOLD', 'RETURNED', 'DAMAGED'))",
  )();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Who did what and when. Rows are only ever added.
@DataClassName('AuditRow')
class AuditLog extends Table {
  TextColumn get id => text()();
  DateTimeColumn get at => dateTime()();
  TextColumn get actor => text().nullable()();
  TextColumn get action => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get details => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Changes waiting to be sent to the cloud (release 2). Written with the change.
@DataClassName('OutboxRow')
class Outbox extends Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  DateTimeColumn get sentAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    AppSettings,
    SizeOptions,
    ColorOptions,
    Users,
    Counters,
    Products,
    Variants,
    Batches,
    BatchLines,
    Articles,
    AuditLog,
    Outbox,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // Each version adds a step here and a migration test.
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(users); // version 2: sign-in users (P2-2)
      }
      if (from < 3) {
        // version 3: shop settings and the size and color lists (P2-3)
        await m.createTable(appSettings);
        await m.createTable(sizeOptions);
        await m.createTable(colorOptions);
      }
    },
    beforeOpen: (details) async {
      final before = details.versionBefore;
      if (before != null && before > schemaVersion) {
        throw StateError(
          'The database is version $before but this app only knows $schemaVersion. Update the app.',
        );
      }
      // Write-ahead logging, and foreign keys (SQLite leaves them off by default).
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// Runs a change and, in the same transaction, writes one audit row and one
/// outbox row. If anything fails, nothing is saved (ADR-0006 point 4, E-AUDIT-1).
class AuditedWriter {
  AuditedWriter(this._db, {DateTime Function()? now, String Function()? newId})
    : _now = now ?? (() => DateTime.now().toUtc()),
      _newId = newId ?? _unsupportedId;

  final AppDatabase _db;
  final DateTime Function() _now;
  final String Function() _newId;

  static String _unsupportedId() =>
      throw StateError('pass newId (a UUID maker) to AuditedWriter');

  Future<T> run<T>({
    required String action,
    required String entityType,
    required String entityId,
    required Future<T> Function() body,
    String? actor,
    Map<String, Object?> details = const {},
  }) {
    return _db.transaction(() async {
      final result = await body();
      final at = _now();
      final json = jsonEncode(details);
      await _db
          .into(_db.auditLog)
          .insert(
            AuditLogCompanion.insert(
              id: _newId(),
              at: at,
              actor: Value(actor),
              action: action,
              entityType: entityType,
              entityId: entityId,
              details: json,
            ),
          );
      await _db
          .into(_db.outbox)
          .insert(
            OutboxCompanion.insert(
              id: _newId(),
              createdAt: at,
              entityType: entityType,
              entityId: entityId,
              operation: action,
              payload: json,
            ),
          );
      return result;
    });
  }

  /// Like [run] but for events that stay on this device (sign-ins, lockouts):
  /// one audit row, no outbox row, so they are never queued for the cloud.
  Future<T> runLocal<T>({
    required String action,
    required String entityType,
    required String entityId,
    required Future<T> Function() body,
    String? actor,
    Map<String, Object?> details = const {},
  }) {
    return _db.transaction(() async {
      final result = await body();
      await _db
          .into(_db.auditLog)
          .insert(
            AuditLogCompanion.insert(
              id: _newId(),
              at: _now(),
              actor: Value(actor),
              action: action,
              entityType: entityType,
              entityId: entityId,
              details: jsonEncode(details),
            ),
          );
      return result;
    });
  }
}
