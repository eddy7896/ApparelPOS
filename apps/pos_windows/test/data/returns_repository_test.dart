// P2-5b: returns (window, approval, refund, restock or damaged) and credit
// notes (issue, use on a bill, balance, expiry). E-RETURN-1, E-SALE-1,
// E-AUDIT-1, E-AUTHZ-1.
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/returns_repository.dart';
import 'package:pos_windows/data/sales_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late StockRepository stock;
  late SalesRepository sales;
  late ReturnsRepository returns;
  late DateTime now;
  late List<String> barcodes; // two M Blue at 499.00, one L Blue at 999.00
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 11, 20, 10);
    n = 0;
    stock = StockRepository(db, newId: newId, now: () => now);
    sales = SalesRepository(db, newId: newId, now: () => now);
    returns = ReturnsRepository(db, newId: newId, now: () => now);
    await stock.ensureCounter();
    for (final id in ['cashier-1', 'manager-1']) {
      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              id: id,
              name: id,
              role: id.startsWith('cashier') ? 'CASHIER' : 'MANAGER',
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
            quantity: 2,
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
    now = DateTime.utc(2026, 11, 20, 11);
  });
  tearDown(() => db.close());

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle())
          .read<int>('c');

  Future<String> statusOf(String code) async =>
      (await db
              .customSelect(
                'SELECT status FROM articles WHERE barcode_value = ?',
                variables: [Variable<String>(code)],
              )
              .getSingle())
          .read<String>('status');

  Future<SavedBill> sell(
    List<String> codes, {
    PriceCut? discount,
    DateTime? at,
  }) async {
    if (at != null) {
      now = at;
    }
    final total = codes.fold<int>(
      0,
      (s, c) => s + (c == barcodes[2] ? 99900 : 49900),
    );
    return sales.saveBill(
      role: Role.manager,
      cashierId: 'cashier-1',
      lines: [for (final c in codes) BillLineInput(c, discount: discount)],
      payments: [Payment(PaymentMode.cash, Money(total))],
    );
  }

  Future<SavedReturn> giveBack(
    List<String> codes, {
    RefundMode mode = RefundMode.cash,
    Role role = Role.cashier,
    ReturnOutcome outcome = ReturnOutcome.restock,
    Role? approverRole,
    String? approvedBy,
  }) => returns.saveReturn(
    role: role,
    cashierId: 'cashier-1',
    items: [
      for (final c in codes)
        ReturnItemInput(
          c,
          outcome,
          note: outcome == ReturnOutcome.damaged ? 'torn seam' : null,
        ),
    ],
    refundMode: mode,
    approverRole: approverRole,
    approvedBy: approvedBy,
  );

  group('lookup', () {
    test(
      'a sold garment shows its bill and what was paid, inside the window',
      () async {
        final bill = await sell([
          barcodes[0],
        ], discount: PriceCut.percentBp(1000));
        final c = await returns.lookup(
          role: Role.cashier,
          barcode: barcodes[0],
        );
        expect(c!.billNo, bill.billNumber.format());
        expect(c.netPrice, Money(44910));
        expect(c.timing, ReturnTiming.withinWindow);
        expect(c.productName, 'Cotton Kurta');
      },
    );
    test('unknown barcode is null', () async {
      expect(
        await returns.lookup(role: Role.cashier, barcode: '000000000000'),
        isNull,
      );
    });
    test('a garment that was never sold cannot be returned', () async {
      await expectLater(
        returns.lookup(role: Role.cashier, barcode: barcodes[0]),
        throwsA(
          isA<GarmentNotReturnable>().having(
            (e) => e.reason,
            'reason',
            NotReturnableReason.notSold,
          ),
        ),
      );
    });
    test('no role may not look up', () async {
      await expectLater(
        returns.lookup(role: null, barcode: barcodes[0]),
        throwsA(isA<PermissionDenied>()),
      );
    });
    test('day 8 shows as needing approval', () async {
      await sell([barcodes[0]], at: DateTime.utc(2026, 11, 10, 6, 30));
      now = DateTime.utc(2026, 11, 17, 18, 30); // 18 Nov 00:00 India
      final c = await returns.lookup(role: Role.cashier, barcode: barcodes[0]);
      expect(c!.timing, ReturnTiming.needsApproval);
    });
    test('the returns code never touches the cost table (E-AUTHZ-1)', () {
      final source = File('lib/data/returns_repository.dart')
          .readAsStringSync();
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
          reason: 'returns_repository.dart must not mention $banned',
        );
      }
    });
  });

  group('saving a return', () {
    test(
      'refunds the exact net price, puts the garment back in stock',
      () async {
        await sell([barcodes[0]], discount: PriceCut.percentBp(1000));
        final r = await giveBack([barcodes[0]]);
        expect(r.total, Money(44910));
        expect(await statusOf(barcodes[0]), 'IN_STOCK');
        expect(await count('returns'), 1);
        final l = await db
            .customSelect('SELECT * FROM return_lines')
            .getSingle();
        expect(l.read<int>('refund_paise'), 44910);
        expect(l.read<String>('outcome'), 'RESTOCK');
      },
    );
    test('a damaged garment is taken out of sale and needs a note', () async {
      await sell([barcodes[0]]);
      await expectLater(
        returns.saveReturn(
          role: Role.cashier,
          cashierId: 'cashier-1',
          items: [ReturnItemInput(barcodes[0], ReturnOutcome.damaged)],
          refundMode: RefundMode.cash,
        ),
        throwsA(isA<InvalidReturn>()),
      );
      expect(await statusOf(barcodes[0]), 'SOLD');
      await giveBack([barcodes[0]], outcome: ReturnOutcome.damaged);
      expect(await statusOf(barcodes[0]), 'DAMAGED');
      await expectLater(
        sell([barcodes[0]]),
        throwsA(isA<ArticleNotSellable>()),
      );
    });
    test('a restocked garment can be sold again, and returned again', () async {
      await sell([barcodes[0]]);
      await giveBack([barcodes[0]]);
      final second = await sell([barcodes[0]]);
      expect(second.billNumber.serial, 2);
      final c = await returns.lookup(role: Role.cashier, barcode: barcodes[0]);
      expect(c!.billNo, second.billNumber.format());
      await giveBack([barcodes[0]]);
      expect(await count('returns'), 2);
    });
    test('a garment already returned cannot be returned twice', () async {
      await sell([barcodes[0]]);
      await giveBack([barcodes[0]]);
      await expectLater(
        giveBack([barcodes[0]]),
        throwsA(
          isA<GarmentNotReturnable>().having(
            (e) => e.reason,
            'reason',
            NotReturnableReason.alreadyReturned,
          ),
        ),
      );
      expect(await count('returns'), 1);
    });
    test('two garments in one return refund their sum', () async {
      await sell([barcodes[0], barcodes[2]]);
      final r = await giveBack([
        barcodes[0],
        barcodes[2],
      ], mode: RefundMode.upi);
      expect(r.total, Money(149800));
      expect(await count('return_lines'), 2);
    });
    test('one bad garment saves nothing, not even the good one', () async {
      await sell([barcodes[0]]);
      await expectLater(
        giveBack([barcodes[0], barcodes[1]]),
        throwsA(isA<GarmentNotReturnable>()),
      );
      expect(await statusOf(barcodes[0]), 'SOLD');
      expect(await count('returns'), 0);
    });
    test('the same garment twice in one return is refused', () async {
      await sell([barcodes[0]]);
      await expectLater(
        giveBack([barcodes[0], barcodes[0]]),
        throwsA(isA<InvalidReturn>()),
      );
    });
    test('an empty return is refused', () async {
      await expectLater(giveBack(const []), throwsA(isA<InvalidReturn>()));
    });
    test('no role may not take a return', () async {
      await sell([barcodes[0]]);
      await expectLater(
        returns.saveReturn(
          role: null,
          cashierId: 'cashier-1',
          items: [ReturnItemInput(barcodes[0], ReturnOutcome.restock)],
          refundMode: RefundMode.cash,
        ),
        throwsA(isA<PermissionDenied>()),
      );
    });
    test(
      'audit and outbox rows are written without note text or cost',
      () async {
        await sell([barcodes[0]]);
        await giveBack([barcodes[0]], outcome: ReturnOutcome.damaged);
        final audit = await db
            .customSelect(
              "SELECT * FROM audit_log WHERE action = 'sale.return'",
            )
            .getSingle();
        expect(audit.read<String>('actor'), 'cashier-1');
        final out = await db
            .customSelect(
              "SELECT * FROM outbox WHERE operation = 'sale.return'",
            )
            .getSingle();
        for (final t in [
          audit.read<String>('details'),
          out.read<String>('payload'),
        ]) {
          expect(t, isNot(contains('torn seam')));
          expect(t, isNot(contains('20000')));
        }
      },
    );
  });

  group('after the window', () {
    Future<void> sellLongAgo() =>
        sell([barcodes[0]], at: DateTime.utc(2026, 11, 1, 6));

    test('a cashier alone is refused', () async {
      await sellLongAgo();
      now = DateTime.utc(2026, 11, 20, 6);
      await expectLater(
        giveBack([barcodes[0]]),
        throwsA(isA<ReturnNeedsApproval>()),
      );
      expect(await statusOf(barcodes[0]), 'SOLD');
    });
    test('a manager approving lets the cashier take it, and is recorded', () async {
      await sellLongAgo();
      now = DateTime.utc(2026, 11, 20, 6);
      await giveBack(
        [barcodes[0]],
        approverRole: Role.manager,
        approvedBy: 'manager-1',
      );
      final r = await db
          .customSelect('SELECT approved_by FROM returns')
          .getSingle();
      expect(r.read<String>('approved_by'), 'manager-1');
      expect(
        (await db
                .customSelect(
                  "SELECT details FROM audit_log WHERE action = 'sale.return'",
                )
                .getSingle())
            .read<String>('details'),
        contains('manager-1'),
      );
    });
    test('an "approver" who is a cashier changes nothing', () async {
      await sellLongAgo();
      now = DateTime.utc(2026, 11, 20, 6);
      await expectLater(
        giveBack(
          [barcodes[0]],
          approverRole: Role.cashier,
          approvedBy: 'cashier-2',
        ),
        throwsA(isA<ReturnNeedsApproval>()),
      );
    });
    test('a manager taking it themselves needs no approver', () async {
      await sellLongAgo();
      now = DateTime.utc(2026, 11, 20, 6);
      await giveBack([barcodes[0]], role: Role.manager);
      final r = await db
          .customSelect('SELECT approved_by FROM returns')
          .getSingle();
      expect(r.read<String?>('approved_by'), isNull);
    });
    test('an approver role without an id is a mistake', () async {
      await sellLongAgo();
      await expectLater(
        giveBack([barcodes[0]], approverRole: Role.manager),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('credit notes', () {
    test('a credit note refund issues a note for the total', () async {
      await sell([barcodes[0], barcodes[2]]);
      final r = await giveBack([
        barcodes[0],
        barcodes[2],
      ], mode: RefundMode.creditNote);
      final note = r.creditNote!;
      expect(note.amount, Money(149800));
      expect(CreditNoteCode.tryParse(note.code), isNotNull);
      expect(note.lastDay, DateTime.utc(2027, 5, 19));
      final info = await sales.lookupCreditNote(
        role: Role.cashier,
        code: note.code,
      );
      expect(info!.balance, Money(149800));
      expect(info.usable, isTrue);
    });
    test('other refund modes issue no note', () async {
      await sell([barcodes[0]]);
      final r = await giveBack([barcodes[0]], mode: RefundMode.cash);
      expect(r.creditNote, isNull);
      expect(await count('credit_notes'), 0);
    });
    test('note serials run 1, 2, 3 and codes differ', () async {
      await sell([barcodes[0], barcodes[1]]);
      final a = await giveBack([barcodes[0]], mode: RefundMode.creditNote);
      final b = await giveBack([barcodes[1]], mode: RefundMode.creditNote);
      expect(CreditNoteCode.tryParse(a.creditNote!.code)!.serial, 1);
      expect(CreditNoteCode.tryParse(b.creditNote!.code)!.serial, 2);
    });
    test('an unknown code is null', () async {
      expect(
        await sales.lookupCreditNote(role: Role.cashier, code: '990001000019'),
        isNull,
      );
    });

    Future<String> note(int rupees) async {
      // A fresh return worth about [rupees]: sell and return the 499 garment, or the 999 one.
      final code = rupees == 999 ? barcodes[2] : barcodes[0];
      await sell([code]);
      return (await giveBack([
        code,
      ], mode: RefundMode.creditNote)).creditNote!.code;
    }

    test('a bill can use part of a note and the balance stays', () async {
      final code = await note(999);
      final bill = await sales.saveBill(
        role: Role.cashier,
        cashierId: 'cashier-1',
        lines: [BillLineInput(barcodes[0])],
        payments: const [],
        creditNotes: [CreditNoteUseInput(code, Money(49900))],
      );
      expect(bill.settlement.isPaid, isTrue);
      expect(bill.settlement.byMode[PaymentMode.creditNote], Money(49900));
      final info = await sales.lookupCreditNote(role: Role.cashier, code: code);
      expect(info!.balance, Money(50000));
      final p = await db
          .customSelect(
            "SELECT mode, amount_paise FROM bill_payments WHERE mode = 'credit_note'",
          )
          .getSingle();
      expect(p.read<int>('amount_paise'), 49900);
    });
    test('the same note can be used again until it is empty', () async {
      final code = await note(999); // 999.00
      for (final garment in [barcodes[0], barcodes[1]]) {
        await sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [BillLineInput(garment)],
          payments: const [],
          creditNotes: [CreditNoteUseInput(code, Money(49900))],
        );
      }
      final info = await sales.lookupCreditNote(role: Role.cashier, code: code);
      expect(info!.balance, Money(100)); // 999.00 - 499.00 - 499.00 = 1.00
      expect(await count('credit_note_uses'), 2);
    });
    test('using more than the balance is refused and saves nothing', () async {
      final code = await note(999);
      await expectLater(
        sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [BillLineInput(barcodes[0]), BillLineInput(barcodes[1])],
          payments: const [],
          creditNotes: [CreditNoteUseInput(code, Money(99901))],
        ),
        throwsA(isA<InvalidBill>()),
      );
      expect(await statusOf(barcodes[1]), 'IN_STOCK');
      expect(await count('credit_note_uses'), 0);
    });
    test('an expired note is refused', () async {
      final code = await note(999);
      now = DateTime.utc(2027, 5, 19, 18, 30);
      final info = await sales.lookupCreditNote(role: Role.cashier, code: code);
      expect(info!.valid, isFalse);
      expect(info.usable, isFalse);
      await expectLater(
        sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [BillLineInput(barcodes[0])],
          payments: const [],
          creditNotes: [CreditNoteUseInput(code, Money(49900))],
        ),
        throwsA(isA<InvalidBill>()),
      );
    });
    test('the last valid day still works', () async {
      final code = await note(999);
      now = DateTime.utc(2027, 5, 19, 18, 29);
      final bill = await sales.saveBill(
        role: Role.cashier,
        cashierId: 'cashier-1',
        lines: [BillLineInput(barcodes[0])],
        payments: const [],
        creditNotes: [CreditNoteUseInput(code, Money(49900))],
      );
      expect(bill.settlement.isPaid, isTrue);
    });
    test('an unknown note, a repeated note and a credit payment passed directly are refused', () async {
      await expectLater(
        sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [BillLineInput(barcodes[0])],
          payments: const [],
          creditNotes: [CreditNoteUseInput('990001000019', Money(49900))],
        ),
        throwsA(isA<InvalidBill>()),
      );
      final code = await note(999);
      await expectLater(
        sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [BillLineInput(barcodes[0])],
          payments: const [],
          creditNotes: [
            CreditNoteUseInput(code, Money(100)),
            CreditNoteUseInput(code, Money(100)),
          ],
        ),
        throwsA(isA<InvalidBill>()),
      );
      await expectLater(
        sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [BillLineInput(barcodes[0])],
          payments: [Payment(PaymentMode.creditNote, Money(49900))],
        ),
        throwsA(isA<InvalidBill>()),
      );
    });
    test(
      'a note larger than the bill is refused (no change from a note)',
      () async {
        final code = await note(999);
        await expectLater(
          sales.saveBill(
            role: Role.cashier,
            cashierId: 'cashier-1',
            lines: [BillLineInput(barcodes[0])],
            payments: const [],
            creditNotes: [CreditNoteUseInput(code, Money(99900))],
          ),
          throwsA(isA<NonCashOverpayment>()),
        );
      },
    );
    test('a note and cash together pay a bill', () async {
      final code = await note(999);
      final bill = await sales.saveBill(
        role: Role.cashier,
        cashierId: 'cashier-1',
        lines: [BillLineInput(barcodes[0]), BillLineInput(barcodes[1])],
        payments: [Payment(PaymentMode.cash, Money(100))],
        creditNotes: [CreditNoteUseInput(code, Money(99700))],
      );
      expect(bill.settlement.isPaid, isTrue);
      expect(bill.settlement.byMode[PaymentMode.cash], Money(100));
    });
  });

  group('returns and credit notes are never edited or deleted (E-AUDIT-1)', () {
    test('the database refuses', () async {
      await sell([barcodes[0]]);
      await giveBack([barcodes[0]], mode: RefundMode.creditNote);
      for (final sql in [
        'UPDATE returns SET total_paise = 1',
        'DELETE FROM returns',
        'UPDATE return_lines SET refund_paise = 1',
        'DELETE FROM return_lines',
        'UPDATE credit_notes SET amount_paise = 1',
        'DELETE FROM credit_notes',
      ]) {
        await expectLater(
          db.customStatement(sql),
          throwsA(anything),
          reason: sql,
        );
      }
      expect(await count('returns'), 1);
    });
    test('a bill line cannot be returned twice even by direct SQL', () async {
      await sell([barcodes[0]]);
      await giveBack([barcodes[0]]);
      await expectLater(
        db.customStatement(
          "INSERT INTO return_lines (id, return_id, bill_line_id, article_id, refund_paise, outcome) "
          "SELECT 'dup', return_id, bill_line_id, article_id, refund_paise, outcome FROM return_lines",
        ),
        throwsA(anything),
      );
    });
  });
}
