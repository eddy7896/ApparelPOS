// P2-6b: shifts, the blind close and the daybook. E-SHIFT-1, E-AUDIT-1,
// E-MONEY-1.
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/returns_repository.dart';
import 'package:pos_windows/data/sales_repository.dart';
import 'package:pos_windows/data/shift_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late StockRepository stock;
  late SalesRepository sales;
  late ReturnsRepository returns;
  late ShiftRepository shifts;
  late DateTime now;
  late List<String> barcodes; // 4 garments: 3 x 499.00, 1 x 999.00
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 11, 20, 4, 30); // 10:00 India
    n = 0;
    stock = StockRepository(db, newId: newId, now: () => now);
    sales = SalesRepository(db, newId: newId, now: () => now);
    returns = ReturnsRepository(db, newId: newId, now: () => now);
    shifts = ShiftRepository(db, newId: newId, now: () => now);
    await stock.ensureCounter();
    for (final id in ['cashier-1', 'cashier-2', 'manager-1']) {
      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              id: id,
              name: id,
              role: id.startsWith('manager') ? 'MANAGER' : 'CASHIER',
              credentialHash: 'x',
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    final r = await stock.receivePurchase(
      role: Role.owner,
      draft: PurchaseDraft(
        supplier: 'S',
        style: 'Cotton Kurta',
        lines: [
          PurchaseLine(
            size: 'M',
            color: 'Blue',
            quantity: 3,
            cost: Money(20000),
            mrp: Money(49900),
          ),
          PurchaseLine(
            size: 'L',
            color: 'Blue',
            quantity: 1,
            cost: Money(40000),
            mrp: Money(99900),
          ),
        ],
      ),
    );
    final rows = await db
        .customSelect(
          'SELECT barcode_value FROM articles WHERE batch_id = ? ORDER BY barcode_value',
          variables: [Variable<String>(r.batchId)],
        )
        .get();
    barcodes = [for (final x in rows) x.read<String>('barcode_value')];
  });
  tearDown(() => db.close());

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle())
          .read<int>('c');

  Future<ShiftInfo> open1({
    Map<Denomination, int>? counts,
    String user = 'cashier-1',
  }) => shifts.openShift(
    role: Role.cashier,
    userId: user,
    counts: counts ?? {Denomination.note500: 4}, // 2000.00
  );

  Future<SavedBill> sell(
    List<String> codes,
    List<Payment> payments, {
    String user = 'cashier-1',
  }) => sales.saveBill(
    role: Role.cashier,
    cashierId: user,
    lines: [for (final c in codes) BillLineInput(c)],
    payments: payments,
  );

  Future<List<ShiftCloseReport>> reports() =>
      shifts.closeReports(role: Role.owner);

  group('opening a shift', () {
    test('records the drawer cash counted by notes and coins', () async {
      final s = await open1(
        counts: {
          Denomination.note500: 2,
          Denomination.coin10: 3,
          Denomination.note10: 1,
        },
      );
      final row = await db.customSelect('SELECT * FROM shifts').getSingle();
      expect(row.read<int>('opening_paise'), 104000);
      expect(row.read<String>('cashier_id'), 'cashier-1');
      expect(row.read<String>('opening_count'), contains('note500'));
      expect(s.cashierId, 'cashier-1');
    });
    test('an empty drawer is a valid opening', () async {
      await open1(counts: const {});
      expect(
        (await db.customSelect('SELECT opening_paise FROM shifts').getSingle())
            .read<int>('opening_paise'),
        0,
      );
    });
    test('audit and outbox rows are written', () async {
      await open1();
      expect(
        (await db
                .customSelect(
                  "SELECT * FROM audit_log WHERE action = 'shift.open'",
                )
                .getSingle())
            .read<String>('actor'),
        'cashier-1',
      );
      expect(await count("outbox WHERE operation = 'shift.open'"), 1);
    });
    test(
      'a cashier cannot have two open shifts, but two cashiers each have one',
      () async {
        await open1();
        await expectLater(open1(), throwsA(isA<ShiftAlreadyOpen>()));
        await open1(user: 'cashier-2');
        expect(await count('shifts'), 2);
      },
    );
    test('no role may not open; a bad count is refused', () async {
      await expectLater(
        shifts.openShift(role: null, userId: 'cashier-1', counts: const {}),
        throwsA(isA<PermissionDenied>()),
      );
      await expectLater(
        shifts.openShift(
          role: Role.cashier,
          userId: 'cashier-1',
          counts: {Denomination.note500: -1},
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(await count('shifts'), 0);
    });
    test(
      'currentShift finds the open one and nothing for someone else',
      () async {
        final s = await open1();
        expect((await shifts.currentShift('cashier-1'))!.id, s.id);
        expect(await shifts.currentShift('cashier-2'), isNull);
      },
    );
  });

  group('a stale shift (opened on an earlier shop day)', () {
    test('is not stale the same India day, even late at night', () async {
      await open1();
      now = DateTime.utc(2026, 11, 20, 18, 29); // 23:59 India
      expect(await shifts.hasStaleShift('cashier-1'), isFalse);
    });
    test('is stale from India midnight', () async {
      await open1();
      now = DateTime.utc(2026, 11, 20, 18, 30); // 00:00 India, next day
      expect(await shifts.hasStaleShift('cashier-1'), isTrue);
    });
    test('no shift is not stale', () async {
      expect(await shifts.hasStaleShift('cashier-1'), isFalse);
    });
  });

  group('sales and returns need an open shift', () {
    test('a sale with no shift is refused and saves nothing', () async {
      await expectLater(
        sell([barcodes[0]], [Payment(PaymentMode.cash, Money(49900))]),
        throwsA(isA<NoOpenShift>()),
      );
      expect(await count('bills'), 0);
      expect(await count('daybook'), 0);
      expect(
        (await db
                .customSelect(
                  "SELECT status FROM articles WHERE barcode_value = '${barcodes[0]}'",
                )
                .getSingle())
            .read<String>('status'),
        'IN_STOCK',
      );
    });
    test("one cashier's shift does not cover another cashier", () async {
      await open1();
      await expectLater(
        sell(
          [barcodes[0]],
          [Payment(PaymentMode.cash, Money(49900))],
          user: 'cashier-2',
        ),
        throwsA(isA<NoOpenShift>()),
      );
    });
    test('a return with no shift is refused and saves nothing', () async {
      await open1();
      await sell([barcodes[0]], [Payment(PaymentMode.cash, Money(49900))]);
      await shifts.closeShift(
        role: Role.cashier,
        userId: 'cashier-1',
        counts: {Denomination.note500: 5},
      );
      await expectLater(
        returns.saveReturn(
          role: Role.cashier,
          cashierId: 'cashier-1',
          items: [ReturnItemInput(barcodes[0], ReturnOutcome.restock)],
          refundMode: RefundMode.cash,
        ),
        throwsA(isA<NoOpenShift>()),
      );
      expect(await count('returns'), 0);
    });
    test('after a close, selling needs a new shift', () async {
      await open1();
      await shifts.closeShift(
        role: Role.cashier,
        userId: 'cashier-1',
        counts: {Denomination.note500: 4},
      );
      await expectLater(
        sell([barcodes[0]], [Payment(PaymentMode.cash, Money(49900))]),
        throwsA(isA<NoOpenShift>()),
      );
      await open1();
      await sell([barcodes[0]], [Payment(PaymentMode.cash, Money(49900))]);
    });
  });

  group('the daybook', () {
    test(
      'a cash sale writes one row and stamps the bill with the shift',
      () async {
        final s = await open1();
        final bill = await sell(
          [barcodes[0]],
          [Payment(PaymentMode.cash, Money(50000))],
        );
        final rows = await db.customSelect('SELECT * FROM daybook').get();
        expect(rows.length, 1);
        expect(rows.single.read<String>('kind'), 'SALE_CASH');
        expect(rows.single.read<int>('amount_paise'), 49900); // net of change
        expect(rows.single.read<String>('shift_id'), s.id);
        expect(rows.single.read<String>('ref_type'), 'bill');
        expect(rows.single.read<String>('ref_id'), bill.billId);
        expect(
          (await db.customSelect('SELECT shift_id FROM bills').getSingle())
              .read<String>('shift_id'),
          s.id,
        );
      },
    );
    test('a split payment writes one row per mode', () async {
      await open1();
      await sell(
        [barcodes[0]],
        [
          Payment(PaymentMode.upi, Money(30000)),
          Payment(PaymentMode.cash, Money(19900)),
        ],
      );
      final kinds = {
        for (final r
            in await db
                .customSelect('SELECT kind, amount_paise FROM daybook')
                .get())
          r.read<String>('kind'): r.read<int>('amount_paise'),
      };
      expect(kinds, {'SALE_UPI': 30000, 'SALE_CASH': 19900});
    });
    test('a bill paid by credit note writes SALE_CREDIT_NOTE', () async {
      await open1();
      await sell([barcodes[0]], [Payment(PaymentMode.cash, Money(49900))]);
      final r = await returns.saveReturn(
        role: Role.cashier,
        cashierId: 'cashier-1',
        items: [ReturnItemInput(barcodes[0], ReturnOutcome.restock)],
        refundMode: RefundMode.creditNote,
      );
      await sales.saveBill(
        role: Role.cashier,
        cashierId: 'cashier-1',
        lines: [BillLineInput(barcodes[1])],
        payments: const [],
        creditNotes: [CreditNoteUseInput(r.creditNote!.code, Money(49900))],
      );
      final kinds = [
        for (final x
            in await db
                .customSelect('SELECT kind FROM daybook ORDER BY rowid')
                .get())
          x.read<String>('kind'),
      ];
      expect(kinds, ['SALE_CASH', 'REFUND_CREDIT_NOTE', 'SALE_CREDIT_NOTE']);
    });
    test('a refund writes a negative row for its mode', () async {
      await open1();
      await sell([barcodes[0]], [Payment(PaymentMode.cash, Money(49900))]);
      await returns.saveReturn(
        role: Role.cashier,
        cashierId: 'cashier-1',
        items: [ReturnItemInput(barcodes[0], ReturnOutcome.restock)],
        refundMode: RefundMode.upi,
      );
      final r = await db
          .customSelect(
            "SELECT amount_paise, ref_type FROM daybook WHERE kind = 'REFUND_UPI'",
          )
          .getSingle();
      expect(r.read<int>('amount_paise'), -49900);
      expect(r.read<String>('ref_type'), 'return');
      expect(
        (await db.customSelect('SELECT shift_id FROM returns').getSingle())
            .read<String?>('shift_id'),
        isNotNull,
      );
    });
    test(
      'a free garment (100% off) writes no zero row and still sells',
      () async {
        await open1();
        await sales.saveBill(
          role: Role.manager,
          cashierId: 'cashier-1',
          lines: [
            BillLineInput(barcodes[0], discount: PriceCut.percentBp(10000)),
          ],
          payments: const [],
        );
        expect(await count('daybook'), 0);
      },
    );
    test('the database refuses a zero row, edits and deletes', () async {
      final s = await open1();
      await sell([barcodes[0]], [Payment(PaymentMode.cash, Money(49900))]);
      await expectLater(
        db.customStatement(
          "INSERT INTO daybook (id, at, shift_id, kind, amount_paise, ref_type, ref_id) VALUES ('z', 1, '${s.id}', 'SALE_CASH', 0, 'bill', 'b')",
        ),
        throwsA(anything),
      );
      for (final sql in [
        'UPDATE daybook SET amount_paise = 1',
        'DELETE FROM daybook',
        'UPDATE shifts SET opening_paise = 1',
        'DELETE FROM shifts',
      ]) {
        await expectLater(
          db.customStatement(sql),
          throwsA(anything),
          reason: sql,
        );
      }
    });
  });

  group('the blind close (E-SHIFT-1)', () {
    test(
      'returns only a receipt, with no expected amount or variance',
      () async {
        final s = await open1();
        final receipt = await shifts.closeShift(
          role: Role.cashier,
          userId: 'cashier-1',
          counts: {Denomination.note500: 4},
        );
        expect(receipt, isA<ShiftCloseReceipt>());
        expect(receipt.shiftId, s.id);
        expect(receipt.toString(), isNot(contains('expected')));
      },
    );
    test('exact: opening 2000 + cash sale 499 - cash refund 499', () async {
      await open1();
      await sell([barcodes[0]], [Payment(PaymentMode.cash, Money(49900))]);
      await returns.saveReturn(
        role: Role.cashier,
        cashierId: 'cashier-1',
        items: [ReturnItemInput(barcodes[0], ReturnOutcome.restock)],
        refundMode: RefundMode.cash,
      );
      await shifts.closeShift(
        role: Role.cashier,
        userId: 'cashier-1',
        counts: {Denomination.note500: 4},
      );
      final r = (await reports()).single;
      expect(r.expected, Money.rupees(2000));
      expect(r.counted, Money.rupees(2000));
      expect(r.variance.kind, VarianceKind.exact);
    });
    test('short and over are signed from counted minus expected', () async {
      await open1();
      await sell(
        [barcodes[0]],
        [Payment(PaymentMode.cash, Money(49900))],
      ); // expected 2499.00
      await shifts.closeShift(
        role: Role.cashier,
        userId: 'cashier-1',
        counts: {
          Denomination.note500: 4,
          Denomination.note200: 2,
          Denomination.note50: 1,
          Denomination.coin10: 4,
          Denomination.coin5: 1,
          Denomination.coin2: 1,
          Denomination.coin1: 1,
        },
      ); // 2000+400+50+40+5+2+1 = 2498.00, short 1.00
      final r = (await reports()).single;
      expect(r.expected, Money.rupees(2499));
      expect(r.counted, Money.rupees(2498));
      expect(r.variance.difference, Money.rupees(-1));
      expect(r.variance.kind, VarianceKind.short);
    });
    test('over', () async {
      await open1();
      await shifts.closeShift(
        role: Role.cashier,
        userId: 'cashier-1',
        counts: {Denomination.note500: 4, Denomination.coin1: 1},
      );
      final r = (await reports()).single;
      expect(r.variance.kind, VarianceKind.over);
      expect(r.variance.difference, Money.rupees(1));
    });
    test(
      'UPI, card and credit note money is not counted as drawer cash',
      () async {
        await open1();
        await sell([barcodes[0]], [Payment(PaymentMode.upi, Money(49900))]);
        await sell([barcodes[1]], [Payment(PaymentMode.card, Money(49900))]);
        await shifts.closeShift(
          role: Role.cashier,
          userId: 'cashier-1',
          counts: {Denomination.note500: 4},
        );
        expect((await reports()).single.expected, Money.rupees(2000));
      },
    );
    test(
      "another cashier's sales are not in this shift's expected cash",
      () async {
        await open1();
        await open1(user: 'cashier-2', counts: const {});
        await sell(
          [barcodes[0]],
          [Payment(PaymentMode.cash, Money(49900))],
          user: 'cashier-2',
        );
        await shifts.closeShift(
          role: Role.cashier,
          userId: 'cashier-1',
          counts: {Denomination.note500: 4},
        );
        expect((await reports()).single.expected, Money.rupees(2000));
      },
    );
    test('change given is not counted as cash kept', () async {
      await open1(counts: const {});
      await sell(
        [barcodes[0]],
        [Payment(PaymentMode.cash, Money(50000))],
      ); // 1.00 change
      await shifts.closeShift(
        role: Role.cashier,
        userId: 'cashier-1',
        counts: {Denomination.note500: 1},
      );
      expect((await reports()).single.expected, Money.rupees(499));
    });
    test('closing twice, or with no shift, is refused', () async {
      await expectLater(
        shifts.closeShift(
          role: Role.cashier,
          userId: 'cashier-1',
          counts: const {},
        ),
        throwsA(isA<NoOpenShift>()),
      );
      await open1();
      await shifts.closeShift(
        role: Role.cashier,
        userId: 'cashier-1',
        counts: const {},
      );
      await expectLater(
        shifts.closeShift(
          role: Role.cashier,
          userId: 'cashier-1',
          counts: const {},
        ),
        throwsA(isA<NoOpenShift>()),
      );
      expect(await count('shift_closes'), 1);
    });
    test('no role may not close; a bad count saves nothing', () async {
      await open1();
      await expectLater(
        shifts.closeShift(role: null, userId: 'cashier-1', counts: const {}),
        throwsA(isA<PermissionDenied>()),
      );
      await expectLater(
        shifts.closeShift(
          role: Role.cashier,
          userId: 'cashier-1',
          counts: {Denomination.note500: -2},
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(await count('shift_closes'), 0);
      expect(await shifts.currentShift('cashier-1'), isNotNull);
    });
    test(
      'a cashier cannot read the variance; a manager and the owner can',
      () async {
        await open1();
        await shifts.closeShift(
          role: Role.cashier,
          userId: 'cashier-1',
          counts: {Denomination.note500: 4},
        );
        await expectLater(
          shifts.closeReports(role: Role.cashier),
          throwsA(isA<PermissionDenied>()),
        );
        await expectLater(
          shifts.closeReports(role: null),
          throwsA(isA<PermissionDenied>()),
        );
        expect((await shifts.closeReports(role: Role.manager)).length, 1);
        expect((await shifts.closeReports(role: Role.owner)).length, 1);
      },
    );
    test('the report names the cashier and times, newest first', () async {
      await open1();
      await shifts.closeShift(
        role: Role.cashier,
        userId: 'cashier-1',
        counts: const {},
      );
      now = DateTime.utc(2026, 11, 21, 4, 30);
      await open1(user: 'cashier-2');
      now = DateTime.utc(2026, 11, 21, 12);
      await shifts.closeShift(
        role: Role.cashier,
        userId: 'cashier-2',
        counts: {Denomination.note500: 4},
      );
      final list = await reports();
      expect([for (final r in list) r.cashierName], ['cashier-2', 'cashier-1']);
      expect(list.first.closedAt, DateTime.utc(2026, 11, 21, 12));
    });
    test('audit and outbox rows are written for the close', () async {
      await open1();
      await shifts.closeShift(
        role: Role.cashier,
        userId: 'cashier-1',
        counts: {Denomination.note500: 4},
      );
      expect(await count("audit_log WHERE action = 'shift.close'"), 1);
      expect(await count("outbox WHERE operation = 'shift.close'"), 1);
    });
    test('a close row cannot be edited or deleted', () async {
      await open1();
      await shifts.closeShift(
        role: Role.cashier,
        userId: 'cashier-1',
        counts: const {},
      );
      for (final sql in [
        'UPDATE shift_closes SET variance_paise = 0',
        'DELETE FROM shift_closes',
      ]) {
        await expectLater(
          db.customStatement(sql),
          throwsA(anything),
          reason: sql,
        );
      }
    });
    test('a shift can only be closed once even by direct SQL', () async {
      final s = await open1();
      await shifts.closeShift(
        role: Role.cashier,
        userId: 'cashier-1',
        counts: const {},
      );
      await expectLater(
        db.customStatement(
          "INSERT INTO shift_closes (id, shift_id, closed_at, counted_paise, expected_paise, variance_paise, count_detail) VALUES ('x', '${s.id}', 1, 0, 0, 0, '{}')",
        ),
        throwsA(anything),
      );
    });
  });

  group('the sales and shift code never read cost (E-AUTHZ-1)', () {
    test('shift_repository.dart does not mention the cost table', () {
      final source = File('lib/data/shift_repository.dart').readAsStringSync();
      for (final banned in [
        'batch_lines',
        'batchLines',
        'unit_cost',
        'unitCost',
      ]) {
        expect(
          RegExp(
            '^(?!\\s*//).*${RegExp.escape(banned)}',
            multiLine: true,
          ).hasMatch(source),
          isFalse,
          reason: banned,
        );
      }
    });
  });
}
