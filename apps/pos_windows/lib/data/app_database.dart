// The counter's local database (Drift on SQLite), release 1 stock tables.
// Rules (ADR-0006, ADR-0007): ids are UUID text made on the device, times are
// UTC, money is integer paise, every write also writes an audit row and an
// outbox row in the same transaction. The file is encrypted (SQLCipher) by the
// connection that opens it, not here (data/encryption/, P3-1).
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
@TableIndex(name: 'users_staff_number', unique: true, columns: {#staffNumber})
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name =>
      text().customConstraint('NOT NULL UNIQUE COLLATE NOCASE')();
  TextColumn get role => text().customConstraint(
    "NOT NULL CHECK (role IN ('CASHIER', 'MANAGER', 'OWNER'))",
  )();
  TextColumn get credentialHash => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// The number behind the operator ID printed on bills (OP001, OP002...).
  /// Given in order when the person is added, never reused.
  IntColumn get staffNumber => integer().nullable()();
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

/// A group (no parent) or a category inside a group, set up by the owner or a
/// manager in Settings (two levels at most). Styles are put in categories; the
/// quick lookup and the analytics group by them.
@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Null for a group.
  TextColumn get parentId => text().nullable().references(Categories, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A style, such as "Cotton Kurta".
@DataClassName('ProductRow')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get createdBy => text().nullable()();

  /// The category this style is in (none until the shop sets it).
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A markdown set ahead of time on a whole style (owner, 2026-11-23): a
/// percentage or a fixed amount off the MRP of its unsold garments, until
/// `endsBefore` (the India midnight that ends the last day). One per style.
/// Bills keep their own copy of what was taken off, so changing or removing a
/// markdown never changes a past bill. Needs the `setMarkdown` permission.
@DataClassName('StyleMarkdownRow')
class StyleMarkdowns extends Table {
  TextColumn get productId => text().references(Products, #id)();

  /// A percentage in basis points (2000 is 20%); null when it is an amount.
  IntColumn get percentBp => integer().nullable()();

  /// A fixed amount in paise; null when it is a percentage.
  IntColumn get amountPaise => integer().nullable()();
  DateTimeColumn get endsBefore => dateTime()();
  TextColumn get setBy => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {productId};

  @override
  List<String> get customConstraints => [
    'CHECK ((percent_bp IS NULL) <> (amount_paise IS NULL))',
    'CHECK (percent_bp IS NULL OR (percent_bp > 0 AND percent_bp < 10000))',
    'CHECK (amount_paise IS NULL OR amount_paise > 0)',
  ];
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

/// One finished bill. Never edited or deleted; a mistake is reversed by a
/// return (E-AUDIT-1). Customer details are optional and typed on the bill.
@DataClassName('BillRow')
class Bills extends Table {
  TextColumn get id => text()();
  TextColumn get billNo => text().customConstraint('NOT NULL UNIQUE')();
  TextColumn get counterId => text().references(Counters, #id)();
  TextColumn get cashierId => text().references(Users, #id)();
  TextColumn get shiftId => text().nullable().references(Shifts, #id)();
  TextColumn get customerName => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  IntColumn get totalPaise =>
      integer().check(totalPaise.isBiggerOrEqualValue(0))();
  IntColumn get changePaise =>
      integer().check(changePaise.isBiggerOrEqualValue(0))();
  DateTimeColumn get billedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One garment on a bill, with the price it was sold at. Name, size and color
/// are copied so the bill reads the same forever. No cost here.
@DataClassName('BillLineRow')
class BillLines extends Table {
  TextColumn get id => text()();
  TextColumn get billId => text().references(Bills, #id)();
  TextColumn get articleId => text().references(Articles, #id)();
  TextColumn get barcodeValue => text()();
  TextColumn get productName => text()();
  TextColumn get size => text()();
  TextColumn get color => text()();
  IntColumn get mrpPaise => integer().check(mrpPaise.isBiggerOrEqualValue(0))();
  IntColumn get markdownPaise =>
      integer().check(markdownPaise.isBiggerOrEqualValue(0))();
  IntColumn get discountPaise =>
      integer().check(discountPaise.isBiggerOrEqualValue(0))();
  IntColumn get finalPaise =>
      integer().check(finalPaise.isBiggerOrEqualValue(0))();

  // GST (P3-4; unverified until the CA confirms): the tax on this garment as it
  // was on the day of the bill. All zero while GST is off, and for every bill
  // made before version 12. `finalPaise + extraTaxPaise` is what was paid.
  /// The rate used, in basis points (500 is 5%); 0 when GST was off.
  IntColumn get gstBp => integer().withDefault(const Constant(0))();

  /// The value the tax was charged on.
  IntColumn get taxablePaise => integer().withDefault(const Constant(0))();

  /// The tax (CGST plus SGST).
  IntColumn get taxPaise => integer().withDefault(const Constant(0))();

  /// Tax added on top of the price (exclusive billing); 0 when the price
  /// included it.
  IntColumn get extraTaxPaise => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// What each payment mode paid toward a bill (cash is net of change).
@DataClassName('BillPaymentRow')
class BillPayments extends Table {
  TextColumn get id => text()();
  TextColumn get billId => text().references(Bills, #id)();
  TextColumn get mode => text().customConstraint(
    "NOT NULL CHECK (mode IN ('cash', 'upi', 'card', 'credit_note'))",
  )();
  IntColumn get amountPaise =>
      integer().check(amountPaise.isBiggerOrEqualValue(1))();

  @override
  Set<Column> get primaryKey => {id};
}

/// The last bill serial used by a counter in a financial year.
@DataClassName('BillSequenceRow')
class BillSequences extends Table {
  TextColumn get counterId => text().references(Counters, #id)();
  TextColumn get yearLabel => text()();
  IntColumn get lastSerial =>
      integer().check(lastSerial.isBetweenValues(0, 999999))();

  @override
  Set<Column> get primaryKey => {counterId, yearLabel};
}

/// A credit note: a barcode with an expiry (SSOT 16). Never edited; what is
/// left on it is its amount minus its uses.
@DataClassName('CreditNoteRow')
class CreditNotes extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().customConstraint('NOT NULL UNIQUE')();
  TextColumn get counterId => text().references(Counters, #id)();
  IntColumn get serial => integer().check(serial.isBetweenValues(1, 99999))();
  IntColumn get amountPaise =>
      integer().check(amountPaise.isBiggerOrEqualValue(1))();
  DateTimeColumn get issuedAt => dateTime()();
  TextColumn get issuedBy => text().references(Users, #id)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {counterId, serial},
  ];
}

/// Money taken off a credit note by a bill.
@DataClassName('CreditNoteUseRow')
class CreditNoteUses extends Table {
  TextColumn get id => text()();
  TextColumn get creditNoteId => text().references(CreditNotes, #id)();
  TextColumn get billId => text().references(Bills, #id)();
  IntColumn get amountPaise =>
      integer().check(amountPaise.isBiggerOrEqualValue(1))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One return: who took it, who approved it if it was late, how it was paid out.
@DataClassName('ReturnRow')
class Returns extends Table {
  TextColumn get id => text()();
  TextColumn get cashierId => text().references(Users, #id)();
  TextColumn get shiftId => text().nullable().references(Shifts, #id)();
  TextColumn get approvedBy => text().nullable().references(Users, #id)();
  TextColumn get refundMode => text().customConstraint(
    "NOT NULL CHECK (refund_mode IN ('cash', 'upi', 'card', 'credit_note'))",
  )();
  TextColumn get creditNoteId =>
      text().nullable().references(CreditNotes, #id)();
  IntColumn get totalPaise =>
      integer().check(totalPaise.isBiggerOrEqualValue(0))();
  DateTimeColumn get returnedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One garment in a return. A bill line can be returned once (unique), and the
/// refund is the line's net price exactly (E-RETURN-1).
@DataClassName('ReturnLineRow')
class ReturnLines extends Table {
  TextColumn get id => text()();
  TextColumn get returnId => text().references(Returns, #id)();
  TextColumn get billLineId =>
      text().customConstraint('NOT NULL UNIQUE REFERENCES bill_lines (id)')();
  TextColumn get articleId => text().references(Articles, #id)();
  IntColumn get refundPaise =>
      integer().check(refundPaise.isBiggerOrEqualValue(0))();
  TextColumn get outcome => text().customConstraint(
    "NOT NULL CHECK (outcome IN ('RESTOCK', 'DAMAGED'))",
  )();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A shift: one cashier's working period at a counter, opened with the cash in
/// the drawer counted by notes and coins. Never edited; closing writes a
/// separate row in `shift_closes`.
@DataClassName('ShiftRow')
class Shifts extends Table {
  TextColumn get id => text()();
  TextColumn get cashierId => text().references(Users, #id)();
  TextColumn get counterId => text().references(Counters, #id)();
  DateTimeColumn get openedAt => dateTime()();
  IntColumn get openingPaise =>
      integer().check(openingPaise.isBiggerOrEqualValue(0))();

  /// The opening count as JSON: denomination name to how many.
  TextColumn get openingCount => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The blind close of a shift (one per shift). The expected amount and the
/// variance are stored here for the owner; the cashier is never shown them
/// (E-SHIFT-1).
@DataClassName('ShiftCloseRow')
class ShiftCloses extends Table {
  TextColumn get id => text()();
  TextColumn get shiftId =>
      text().customConstraint('NOT NULL UNIQUE REFERENCES shifts (id)')();
  DateTimeColumn get closedAt => dateTime()();
  IntColumn get countedPaise =>
      integer().check(countedPaise.isBiggerOrEqualValue(0))();
  IntColumn get expectedPaise => integer()();
  IntColumn get variancePaise => integer()();

  /// The closing count as JSON: denomination name to how many.
  TextColumn get countDetail => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A break inside a shift (the Pause button, UX-3): the shift stays open, the
/// counter is locked. Never edited; the end of a break is a separate row in
/// `shift_break_ends`, so a break with no end row is still going.
@DataClassName('ShiftBreakRow')
class ShiftBreaks extends Table {
  TextColumn get id => text()();
  TextColumn get shiftId => text().references(Shifts, #id)();
  DateTimeColumn get startedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The end of a break (one per break).
@DataClassName('ShiftBreakEndRow')
class ShiftBreakEnds extends Table {
  TextColumn get id => text()();
  TextColumn get breakId =>
      text().customConstraint('NOT NULL UNIQUE REFERENCES shift_breaks (id)')();
  DateTimeColumn get endedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The money ledger. One row per payment mode of each bill (positive) and per
/// refund (negative), written in the same transaction as the sale or return.
/// Never edited; a mistake is reversed by a new row.
@DataClassName('DaybookRow')
class Daybook extends Table {
  TextColumn get id => text()();
  DateTimeColumn get at => dateTime()();
  TextColumn get shiftId => text().references(Shifts, #id)();
  TextColumn get kind => text().customConstraint(
    "NOT NULL CHECK (kind IN ('SALE_CASH', 'SALE_UPI', 'SALE_CARD', 'SALE_CREDIT_NOTE', "
    "'REFUND_CASH', 'REFUND_UPI', 'REFUND_CARD', 'REFUND_CREDIT_NOTE', "
    "'DUES_CASH', 'DUES_UPI', 'DUES_CARD'))",
  )();
  IntColumn get amountPaise => integer().check(amountPaise.equals(0).not())();
  TextColumn get refType => text().customConstraint(
    "NOT NULL CHECK (ref_type IN ('bill', 'return', 'dues'))",
  )();
  TextColumn get refId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A customer who has taken clothes on pay later (udhaar), found again by the
/// last 10 digits of the phone number (owner, 2026-11-23). Never edited.
@DataClassName('CustomerRow')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// The phone key (`customerPhoneKey`): the digits, last 10 when there are
  /// more. Unique.
  TextColumn get phone => text().unique()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Money a customer handed over against what they owe: cash, UPI and card, and
/// the change given back. One row per visit; its daybook rows (DUES_*) carry the
/// money into the drawer and the reports. Never edited.
@DataClassName('DuesReceiptRow')
class DuesReceipts extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text().references(Customers, #id)();
  DateTimeColumn get at => dateTime()();
  TextColumn get shiftId => text().references(Shifts, #id)();
  TextColumn get receivedBy => text()();
  IntColumn get cashPaise =>
      integer().check(cashPaise.isBiggerOrEqualValue(0))();
  IntColumn get upiPaise => integer().check(upiPaise.isBiggerOrEqualValue(0))();
  IntColumn get cardPaise =>
      integer().check(cardPaise.isBiggerOrEqualValue(0))();
  IntColumn get changePaise =>
      integer().check(changePaise.isBiggerOrEqualValue(0))();

  /// What was taken off the debt: cash + UPI + card - change.
  IntColumn get appliedPaise =>
      integer().check(appliedPaise.isBiggerThanValue(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (applied_paise = cash_paise + upi_paise + card_paise - change_paise)',
  ];
}

/// What each customer owes, bill by bill: an OWED row when a bill is left
/// unpaid, then rows that take it down (a PAYMENT, a RETURN_OFFSET when a
/// garment comes back, a WRITE_OFF by the owner). What is owed on a bill is the
/// sum of its rows. Never edited; a mistake is a new row (E-AUDIT-1).
@DataClassName('DuesLedgerRow')
class DuesLedger extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text().references(Customers, #id)();
  TextColumn get billId => text().references(Bills, #id)();
  TextColumn get kind => text().customConstraint(
    "NOT NULL CHECK (kind IN ('OWED', 'PAYMENT', 'RETURN_OFFSET', 'WRITE_OFF'))",
  )();

  /// Positive when it adds to what is owed (OWED), negative when it takes off.
  IntColumn get amountPaise => integer().check(amountPaise.equals(0).not())();
  TextColumn get receiptId => text().nullable().references(DuesReceipts, #id)();
  TextColumn get returnId => text().nullable().references(Returns, #id)();
  DateTimeColumn get at => dateTime()();
  TextColumn get actorId => text()();

  /// For OWED: the manager or owner who allowed it.
  TextColumn get approvedBy => text().nullable()();

  /// For WRITE_OFF: why (required).
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK ((kind = 'OWED' AND amount_paise > 0) OR (kind <> 'OWED' AND amount_paise < 0))",
    "CHECK (kind <> 'PAYMENT' OR receipt_id IS NOT NULL)",
    "CHECK (kind <> 'RETURN_OFFSET' OR return_id IS NOT NULL)",
    "CHECK (kind <> 'WRITE_OFF' OR (note IS NOT NULL AND length(trim(note)) > 0))",
  ];
}

@DriftDatabase(
  tables: [
    AppSettings,
    SizeOptions,
    ColorOptions,
    Users,
    Counters,
    Categories,
    StyleMarkdowns,
    Customers,
    DuesReceipts,
    DuesLedger,
    Products,
    Variants,
    Batches,
    BatchLines,
    Articles,
    AuditLog,
    Outbox,
    Bills,
    BillLines,
    BillPayments,
    BillSequences,
    CreditNotes,
    CreditNoteUses,
    Returns,
    ReturnLines,
    Shifts,
    ShiftCloses,
    ShiftBreaks,
    ShiftBreakEnds,
    Daybook,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // Each version adds a step here and a migration test.
    onUpgrade: (m, from, to) async {
      if (from < 2 && to >= 2) {
        await m.createTable(users); // version 2: sign-in users (P2-2)
      }
      if (from < 3 && to >= 3) {
        // version 3: shop settings and the size and color lists (P2-3)
        await m.createTable(appSettings);
        await m.createTable(sizeOptions);
        await m.createTable(colorOptions);
      }
      if (from < 4 && to >= 4) {
        // version 4: bills, their lines, payments and the bill serials (P2-4b)
        await m.createTable(bills);
        await m.createTable(billLines);
        await m.createTable(billPayments);
        await m.createTable(billSequences);
      }
      if (from < 5 && to >= 5) {
        // version 5: returns and credit notes (P2-5b); bill payments may now
        // be paid by credit note, which changes a CHECK, so the table is rebuilt.
        await m.createTable(creditNotes);
        await m.createTable(creditNoteUses);
        await m.createTable(returns);
        await m.createTable(returnLines);
        await m.alterTable(TableMigration(billPayments));
      }
      if (from < 6 && to >= 6) {
        // version 6: shifts, blind closes and the daybook (P2-6b); bills and
        // returns record the shift they were made in.
        await m.createTable(shifts);
        await m.createTable(shiftCloses);
        await m.createTable(daybook);
        // Older steps create bills and returns with today's definition, which
        // already has the column; add it only where it is missing.
        Future<bool> has(String table) async => (await customSelect(
          'PRAGMA table_info($table)',
        ).get()).any((r) => r.read<String>('name') == 'shift_id');
        if (!await has('bills')) {
          await m.addColumn(bills, bills.shiftId);
        }
        if (!await has('returns')) {
          await m.addColumn(returns, returns.shiftId);
        }
      }
      if (from < 9 && to >= 9) {
        // version 9: stock categories (owner, 2026-11-23)
        final tables = {
          for (final r in await customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table'",
          ).get())
            r.read<String>('name'),
        };
        if (!tables.contains('categories')) {
          await m.createTable(categories);
        }
        final hasCol = (await customSelect(
          'PRAGMA table_info(products)',
        ).get()).any((r) => r.read<String>('name') == 'category_id');
        if (!hasCol) {
          await m.addColumn(products, products.categoryId);
        }
      }
      if (from < 12 && to >= 12) {
        // version 12: GST fields on every bill line (P3-4; GST stays off). The
        // columns default to 0, so older bills read as "no GST".
        final have = (await customSelect(
          'PRAGMA table_info(bill_lines)',
        ).get()).map((r) => r.read<String>('name')).toSet();
        if (!have.contains('gst_bp')) {
          await m.addColumn(billLines, billLines.gstBp);
        }
        if (!have.contains('taxable_paise')) {
          await m.addColumn(billLines, billLines.taxablePaise);
        }
        if (!have.contains('tax_paise')) {
          await m.addColumn(billLines, billLines.taxPaise);
        }
        if (!have.contains('extra_tax_paise')) {
          await m.addColumn(billLines, billLines.extraTaxPaise);
        }
      }
      if (from < 11 && to >= 11) {
        // version 11: pay later (owner, 2026-11-23): customers, what they
        // owe bill by bill, what they paid, and the daybook takes the new
        // kinds (a CHECK changes, so its table is rebuilt; rows are kept).
        final tables = {
          for (final r in await customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table'",
          ).get())
            r.read<String>('name'),
        };
        if (!tables.contains('customers')) {
          await m.createTable(customers);
        }
        if (!tables.contains('dues_receipts')) {
          await m.createTable(duesReceipts);
        }
        if (!tables.contains('dues_ledger')) {
          await m.createTable(duesLedger);
        }
        if (from >= 6) {
          await m.alterTable(TableMigration(daybook));
        }
      }
      if (from < 10 && to >= 10) {
        // version 10: markdowns set ahead of time on a style (owner, 2026-11-23)
        final tables = {
          for (final r in await customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table'",
          ).get())
            r.read<String>('name'),
        };
        if (!tables.contains('style_markdowns')) {
          await m.createTable(styleMarkdowns);
        }
      }
      if (from < 8 && to >= 8) {
        // version 8: every person gets an operator ID (UX, owner 2026-11-23);
        // people added before get theirs in the order they were added.
        Future<bool> hasCol() async => (await customSelect(
          'PRAGMA table_info(users)',
        ).get()).any((r) => r.read<String>('name') == 'staff_number');
        if (!await hasCol()) {
          await m.addColumn(users, users.staffNumber);
        }
        final waiting = await customSelect(
          'SELECT id FROM users WHERE staff_number IS NULL ORDER BY created_at, rowid',
        ).get();
        var next =
            ((await customSelect(
              'SELECT COALESCE(MAX(staff_number), 0) AS m FROM users',
            ).getSingle()).read<int>('m')) +
            1;
        for (final r in waiting) {
          await customStatement(
            'UPDATE users SET staff_number = ? WHERE id = ?',
            [next++, r.read<String>('id')],
          );
        }
        final has = await customSelect(
          "SELECT 1 FROM sqlite_master WHERE type = 'index' AND name = 'users_staff_number'",
        ).get();
        if (has.isEmpty) {
          await m.createIndex(usersStaffNumber);
        }
      }
      if (from < 7 && to >= 7) {
        // version 7: breaks inside a shift (UX-3)
        await m.createTable(shiftBreaks);
        await m.createTable(shiftBreakEnds);
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
      // Sales are never edited or deleted, only reversed (E-AUDIT-1). The
      // database itself refuses, whatever code asks. (Only for tables that exist
      // yet, so a test can stop a migration at an older version.)
      final existing = {
        for (final r in await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        ).get())
          r.read<String>('name'),
      };
      for (final table in [
        'bills',
        'bill_lines',
        'bill_payments',
        'credit_notes',
        'credit_note_uses',
        'returns',
        'return_lines',
        'shifts',
        'shift_closes',
        'shift_breaks',
        'shift_break_ends',
        'daybook',
        'customers',
        'dues_receipts',
        'dues_ledger',
      ]) {
        if (!existing.contains(table)) {
          continue;
        }
        for (final verb in ['UPDATE', 'DELETE']) {
          await customStatement(
            'CREATE TRIGGER IF NOT EXISTS ${table}_no_${verb.toLowerCase()} '
            'BEFORE $verb ON $table BEGIN '
            "SELECT RAISE(ABORT, '$table rows are never ${verb.toLowerCase()}d'); END",
          );
        }
      }
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
