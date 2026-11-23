// Pay later (udhaar), owner 2026-11-23: a manager or the owner lets a bill be
// left unpaid (name and phone required), customers pay later against what they
// owe (oldest bill first), a return from an unpaid bill first takes down what
// is owed, and only the owner writes a debt off. E-AUDIT-1, E-AUTHZ-1.
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/dues_repository.dart';
import 'package:pos_windows/data/report_repository.dart';
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
  late DuesRepository dues;
  late DateTime now;
  late List<String> kurta; // 4 x 499.00
  late List<String> jeans; // 3 x 1299.00
  var n = 0;
  String newId() => 'id-${++n}';

  Future<List<String>> codes(String style) async => [
    for (final r
        in await db
            .customSelect(
              'SELECT a.barcode_value AS b FROM articles a '
              'JOIN variants v ON v.id = a.variant_id '
              'JOIN products p ON p.id = v.product_id '
              'WHERE p.name = ? ORDER BY a.barcode_value',
              variables: [Variable<String>(style)],
            )
            .get())
      r.read<String>('b'),
  ];

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    now = DateTime.utc(2026, 11, 23, 6, 30);
    stock = StockRepository(db, newId: newId, now: () => now);
    sales = SalesRepository(db, newId: newId, now: () => now);
    returns = ReturnsRepository(db, newId: newId, now: () => now);
    shifts = ShiftRepository(db, newId: newId, now: () => now);
    dues = DuesRepository(db, newId: newId, now: () => now);
    await stock.ensureCounter();
    for (final (style, qty, mrp) in [
      ('Cotton Kurta', 4, 49900),
      ('Denim Jeans', 3, 129900),
    ]) {
      await stock.receivePurchase(
        role: Role.owner,
        draft: PurchaseDraft(
          supplier: 'S',
          style: style,
          lines: [
            PurchaseLine(
              size: 'M',
              color: 'Blue',
              quantity: qty,
              cost: Money(20000),
              mrp: Money(mrp),
            ),
          ],
        ),
      );
    }
    kurta = await codes('Cotton Kurta');
    jeans = await codes('Denim Jeans');
    for (final (id, role) in [
      ('cashier-1', 'CASHIER'),
      ('manager-1', 'MANAGER'),
    ]) {
      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              id: id,
              name: id,
              role: role,
              credentialHash: 'x',
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    await shifts.openShift(
      role: Role.cashier,
      userId: 'cashier-1',
      counts: {Denomination.note500: 4},
    );
  });
  tearDown(() => db.close());

  PayLaterInput later({
    String name = 'Ravi Kumar',
    String phone = '98765 43210',
    Role? approverRole = Role.manager,
    String? approvedBy = 'manager-1',
  }) => PayLaterInput(
    customerName: name,
    customerPhone: phone,
    approverRole: approverRole,
    approvedBy: approvedBy,
  );

  /// A bill of [barcodes] with [paidNow] taken in cash and the rest owed.
  Future<SavedBill> sellOnCredit(
    List<String> barcodes, {
    int paidNow = 0,
    PayLaterInput? payLater,
    Role role = Role.cashier,
    String cashier = 'cashier-1',
  }) => sales.saveBill(
    role: role,
    cashierId: cashier,
    lines: [for (final b in barcodes) BillLineInput(b)],
    payments: [if (paidNow > 0) Payment(PaymentMode.cash, Money(paidNow))],
    payLater: payLater ?? later(),
  );

  Future<CustomerDues> ravi() async =>
      (await dues.findByPhone(role: Role.cashier, phone: '9876543210'))!;

  Future<int> count(String sql) async =>
      (await db.customSelect(sql).getSingle()).read<int>('c');

  group('a bill left unpaid', () {
    test('a cashier with a manager approving: part now, the rest owed', () async {
      final bill = await sellOnCredit([jeans[0]], paidNow: 50000);
      expect(bill.total, Money(129900));
      expect(bill.owed, Money(79900));
      expect(bill.settlement.byMode[PaymentMode.cash], Money(50000));
      final c = await ravi();
      expect(c.name, 'Ravi Kumar');
      expect(c.phone, '9876543210');
      expect(c.owed, Money(79900));
      expect(c.billCount, 1);
      final row = await db
          .customSelect(
            'SELECT kind, amount_paise, approved_by, actor_id FROM dues_ledger',
          )
          .getSingle();
      expect(row.read<String>('kind'), 'OWED');
      expect(row.read<int>('amount_paise'), 79900);
      expect(row.read<String>('approved_by'), 'manager-1');
      expect(row.read<String>('actor_id'), 'cashier-1');
    });

    test(
      'only what was paid goes in the daybook and the bill payments',
      () async {
        await sellOnCredit([jeans[0]], paidNow: 50000);
        final day = await db
            .customSelect('SELECT kind, amount_paise FROM daybook')
            .getSingle();
        expect(day.read<String>('kind'), 'SALE_CASH');
        expect(day.read<int>('amount_paise'), 50000);
        final pay = await db
            .customSelect('SELECT SUM(amount_paise) AS s FROM bill_payments')
            .getSingle();
        expect(pay.read<int>('s'), 50000);
        final bill = await db
            .customSelect(
              'SELECT total_paise, customer_name, customer_phone FROM bills',
            )
            .getSingle();
        expect(bill.read<int>('total_paise'), 129900);
        expect(bill.read<String>('customer_name'), 'Ravi Kumar');
        expect(bill.read<String>('customer_phone'), '98765 43210');
      },
    );

    test('nothing paid now at all is fine', () async {
      final bill = await sellOnCredit([kurta[0]]);
      expect(bill.owed, Money(49900));
      expect(await count('SELECT COUNT(*) AS c FROM daybook'), 0);
      expect(await count('SELECT COUNT(*) AS c FROM bill_payments'), 0);
      expect((await ravi()).owed, Money(49900));
    });

    test('UPI now and the rest later', () async {
      final bill = await sales.saveBill(
        role: Role.manager,
        cashierId: 'cashier-1',
        lines: [BillLineInput(jeans[0])],
        payments: [Payment(PaymentMode.upi, Money(100000))],
        payLater: later(approverRole: null, approvedBy: null),
      );
      expect(bill.owed, Money(29900));
    });

    test(
      'a manager saving it needs no second approver; their id is the approval',
      () async {
        await sales.saveBill(
          role: Role.manager,
          cashierId: 'cashier-1',
          lines: [BillLineInput(kurta[0])],
          payments: const [],
          payLater: later(approverRole: null, approvedBy: null),
        );
        final row = await db
            .customSelect('SELECT approved_by FROM dues_ledger')
            .getSingle();
        expect(row.read<String>('approved_by'), 'cashier-1');
      },
    );

    test('a cashier alone, or approved by a cashier, is refused and nothing is saved', () async {
      await expectLater(
        sellOnCredit([
          kurta[0],
        ], payLater: later(approverRole: null, approvedBy: null)),
        throwsA(isA<PermissionDenied>()),
      );
      await expectLater(
        sellOnCredit(
          [kurta[0]],
          payLater: later(approverRole: Role.cashier, approvedBy: 'cashier-1'),
        ),
        throwsA(isA<PermissionDenied>()),
      );
      expect(await count('SELECT COUNT(*) AS c FROM bills'), 0);
      expect(await count('SELECT COUNT(*) AS c FROM customers'), 0);
      final status = await db
          .customSelect(
            "SELECT status FROM articles WHERE barcode_value = '${kurta[0]}'",
          )
          .getSingle();
      expect(status.read<String>('status'), 'IN_STOCK');
    });

    test('the name and phone are both required', () async {
      for (final (name, phone) in [
        ('', '9876543210'),
        ('   ', '9876543210'),
        ('Ravi', ''),
        ('Ravi', '12345'),
        ('Ravi', 'call me'),
        ('x' * 81, '9876543210'),
      ]) {
        await expectLater(
          sellOnCredit([kurta[0]], payLater: later(name: name, phone: phone)),
          throwsA(isA<InvalidBill>()),
          reason: '$name / $phone',
        );
      }
      expect(await count('SELECT COUNT(*) AS c FROM bills'), 0);
    });

    test('a bill paid in full cannot be marked pay later', () async {
      await expectLater(
        sellOnCredit([kurta[0]], paidNow: 49900),
        throwsA(isA<InvalidBill>()),
      );
      expect(await count('SELECT COUNT(*) AS c FROM bills'), 0);
    });

    test('without pay later an unpaid bill is still refused', () async {
      await expectLater(
        sales.saveBill(
          role: Role.manager,
          cashierId: 'cashier-1',
          lines: [BillLineInput(kurta[0])],
          payments: [Payment(PaymentMode.cash, Money(10000))],
        ),
        throwsA(isA<BillNotPaid>()),
      );
    });

    test('the same phone typed another way is the same customer, with the first name', () async {
      await sellOnCredit([kurta[0]]);
      await sellOnCredit([
        kurta[1],
      ], payLater: later(name: 'R. Kumar', phone: '+91 98765-43210'));
      expect(await count('SELECT COUNT(*) AS c FROM customers'), 1);
      final c = await ravi();
      expect(c.name, 'Ravi Kumar');
      expect(c.owed, Money(99800));
      expect(c.billCount, 2);
    });

    test('another phone is another customer', () async {
      await sellOnCredit([kurta[0]]);
      await sellOnCredit([
        kurta[1],
      ], payLater: later(name: 'Meena', phone: '9123456789'));
      expect(await count('SELECT COUNT(*) AS c FROM customers'), 2);
    });

    test(
      'the audit trail says it was pay later but holds no name or phone',
      () async {
        await sellOnCredit([kurta[0]]);
        final a = await db
            .customSelect(
              "SELECT details FROM audit_log WHERE action = 'sale.bill'",
            )
            .getSingle();
        final text = a.read<String>('details');
        expect(text, contains('payLater'));
        expect(text, contains('manager-1'));
        expect(text.contains('Ravi'), isFalse);
        expect(text.contains('9876'), isFalse);
        final o = await db
            .customSelect(
              "SELECT payload FROM outbox WHERE operation = 'sale.bill'",
            )
            .getSingle();
        expect(o.read<String>('payload').contains('Ravi'), isFalse);
      },
    );
  });

  group('paying what is owed', () {
    Future<DuesPaymentResult> pay(
      int cash, {
      int upi = 0,
      int card = 0,
      Role role = Role.cashier,
      String user = 'cashier-1',
      String? customer,
    }) async => dues.receivePayment(
      role: role,
      userId: user,
      customerId: customer ?? (await ravi()).id,
      payments: [
        if (cash > 0) Payment(PaymentMode.cash, Money(cash)),
        if (upi > 0) Payment(PaymentMode.upi, Money(upi)),
        if (card > 0) Payment(PaymentMode.card, Money(card)),
      ],
    );

    test(
      'a part payment in cash takes it off and goes in the daybook',
      () async {
        await sellOnCredit([jeans[0]]);
        now = DateTime.utc(2026, 11, 24, 6, 30);
        final r = await pay(30000);
        expect(r.applied, Money(30000));
        expect(r.change, Money.zero);
        expect(r.remaining, Money(99900));
        expect((await ravi()).owed, Money(99900));
        final day = await db
            .customSelect(
              "SELECT kind, amount_paise, ref_type, ref_id FROM daybook WHERE kind LIKE 'DUES_%'",
            )
            .getSingle();
        expect(day.read<String>('kind'), 'DUES_CASH');
        expect(day.read<int>('amount_paise'), 30000);
        expect(day.read<String>('ref_type'), 'dues');
        expect(day.read<String>('ref_id'), r.receiptId);
      },
    );

    test('cash over what is owed gives change; only what was owed is kept', () async {
      await sellOnCredit([kurta[0]]);
      final r = await pay(100000);
      expect(r.applied, Money(49900));
      expect(r.change, Money(50100));
      expect(r.remaining, Money.zero);
      expect((await ravi()).owed, Money.zero);
      final day = await db
          .customSelect(
            "SELECT amount_paise FROM daybook WHERE kind = 'DUES_CASH'",
          )
          .getSingle();
      expect(day.read<int>('amount_paise'), 49900);
      final rec = await db
          .customSelect(
            'SELECT cash_paise, change_paise, applied_paise FROM dues_receipts',
          )
          .getSingle();
      expect(rec.read<int>('cash_paise'), 100000);
      expect(rec.read<int>('change_paise'), 50100);
      expect(rec.read<int>('applied_paise'), 49900);
    });

    test('cash, UPI and card together', () async {
      await sellOnCredit([jeans[0]]);
      final r = await pay(40000, upi: 50000, card: 20000);
      expect(r.applied, Money(110000));
      expect(r.remaining, Money(19900));
      final kinds = await db
          .customSelect(
            "SELECT kind FROM daybook WHERE kind LIKE 'DUES_%' ORDER BY kind",
          )
          .get();
      expect(kinds.map((k) => k.read<String>('kind')), [
        'DUES_CARD',
        'DUES_CASH',
        'DUES_UPI',
      ]);
    });

    test('the oldest bill is settled first', () async {
      await sellOnCredit([kurta[0]]); // 499, billed first
      now = DateTime.utc(2026, 11, 24, 6, 30);
      await sellOnCredit([jeans[0]]); // 1299
      now = DateTime.utc(2026, 11, 25, 6, 30);
      await pay(60000); // all of the kurta bill, 101.00 of the jeans bill
      final detail = await dues.detail(
        role: Role.cashier,
        customerId: (await ravi()).id,
      );
      expect(detail!.bills.length, 1);
      expect(detail.bills.single.outstanding, Money(129900 - 10100));
      final ledger = await db
          .customSelect(
            "SELECT amount_paise FROM dues_ledger WHERE kind = 'PAYMENT' ORDER BY rowid",
          )
          .get();
      expect(ledger.map((r) => r.read<int>('amount_paise')), [-49900, -10100]);
    });

    test(
      'UPI or card more than is owed is refused and nothing is saved',
      () async {
        await sellOnCredit([kurta[0]]);
        await expectLater(
          pay(0, upi: 50000),
          throwsA(isA<NonCashOverpayment>()),
        );
        expect(await count('SELECT COUNT(*) AS c FROM dues_receipts'), 0);
        expect(
          await count(
            "SELECT COUNT(*) AS c FROM daybook WHERE kind LIKE 'DUES_%'",
          ),
          0,
        );
        expect((await ravi()).owed, Money(49900));
      },
    );

    test('a credit note cannot pay it, nor can an empty payment', () async {
      await sellOnCredit([kurta[0]]);
      final id = (await ravi()).id;
      await expectLater(
        dues.receivePayment(
          role: Role.cashier,
          userId: 'cashier-1',
          customerId: id,
          payments: [Payment(PaymentMode.creditNote, Money(100))],
        ),
        throwsA(isA<InvalidDues>()),
      );
      await expectLater(
        dues.receivePayment(
          role: Role.cashier,
          userId: 'cashier-1',
          customerId: id,
          payments: const [],
        ),
        throwsA(isA<InvalidDues>()),
      );
    });

    test('a customer who owes nothing, or nobody, is refused', () async {
      await sellOnCredit([kurta[0]]);
      await pay(49900);
      await expectLater(pay(100), throwsA(isA<NothingOwed>()));
      await expectLater(
        pay(100, customer: 'nobody'),
        throwsA(isA<NothingOwed>()),
      );
    });

    test('an open shift is needed to take the money', () async {
      await sellOnCredit([kurta[0]]);
      await shifts.closeShift(
        role: Role.cashier,
        userId: 'cashier-1',
        counts: {Denomination.note500: 4},
      );
      await expectLater(pay(1000), throwsA(isA<NoOpenShift>()));
      expect(await count('SELECT COUNT(*) AS c FROM dues_receipts'), 0);
    });

    test('nobody signed in may not take a payment', () async {
      await sellOnCredit([kurta[0]]);
      await expectLater(
        dues.receivePayment(
          role: null,
          userId: 'x',
          customerId: (await ravi()).id,
          payments: [Payment(PaymentMode.cash, Money(100))],
        ),
        throwsA(isA<PermissionDenied>()),
      );
    });

    test('cash taken counts in the drawer at the blind close', () async {
      await sellOnCredit([kurta[0]]);
      await pay(30000);
      // 2000.00 opening + 300.00 dues
      final receipt = await shifts.closeShift(
        role: Role.cashier,
        userId: 'cashier-1',
        counts: {Denomination.note500: 4, Denomination.note100: 3},
      );
      expect(receipt, isNotNull);
      final r = await db
          .customSelect(
            'SELECT expected_paise, counted_paise FROM shift_closes',
          )
          .getSingle();
      expect(r.read<int>('expected_paise'), 230000);
      expect(r.read<int>('counted_paise'), 230000);
    });

    test('UPI or card dues do not count as cash in the drawer', () async {
      await sellOnCredit([kurta[0]]);
      await pay(0, upi: 30000);
      await shifts.closeShift(
        role: Role.cashier,
        userId: 'cashier-1',
        counts: {Denomination.note500: 4},
      );
      final r = await db
          .customSelect('SELECT expected_paise FROM shift_closes')
          .getSingle();
      expect(r.read<int>('expected_paise'), 200000);
    });

    test(
      'a payment written down is audited without customer details',
      () async {
        await sellOnCredit([kurta[0]]);
        await pay(100);
        final a = await db
            .customSelect(
              "SELECT actor, details FROM audit_log WHERE action = 'dues.receive'",
            )
            .getSingle();
        expect(a.read<String>('actor'), 'cashier-1');
        expect(a.read<String>('details').contains('Ravi'), isFalse);
      },
    );
  });

  group('looking at who owes', () {
    test(
      'customers are listed by what they owe, and cleared ones are left out',
      () async {
        await sellOnCredit([kurta[0]]);
        await sellOnCredit([
          jeans[0],
        ], payLater: later(name: 'Meena', phone: '9123456789'));
        await sellOnCredit([
          kurta[1],
        ], payLater: later(name: 'Old Pal', phone: '9000000001'));
        await dues.receivePayment(
          role: Role.cashier,
          userId: 'cashier-1',
          customerId: (await dues.findByPhone(
            role: Role.cashier,
            phone: '9000000001',
          ))!.id,
          payments: [Payment(PaymentMode.cash, Money(49900))],
        );
        final list = await dues.customers(role: Role.cashier);
        expect(list.map((c) => c.name), ['Meena', 'Ravi Kumar']);
        expect(list.first.owed, Money(129900));
        final all = await dues.customers(role: Role.cashier, onlyOwing: false);
        expect(all.map((c) => c.name), ['Meena', 'Ravi Kumar', 'Old Pal']);
        expect(await dues.totalOwed(role: Role.cashier), Money(129900 + 49900));
      },
    );

    test('a customer page lists their bills owing and the history', () async {
      await sellOnCredit([kurta[0]]);
      now = DateTime.utc(2026, 11, 24, 6, 30);
      final id = (await ravi()).id;
      await dues.receivePayment(
        role: Role.cashier,
        userId: 'cashier-1',
        customerId: id,
        payments: [Payment(PaymentMode.cash, Money(10000))],
      );
      final d = await dues.detail(role: Role.cashier, customerId: id);
      expect(d!.customer.owed, Money(39900));
      expect(d.bills.single.total, Money(49900));
      expect(d.bills.single.outstanding, Money(39900));
      expect(d.history.map((h) => h.kind), ['PAYMENT', 'OWED']);
      expect(d.history.first.amount, Money(-10000));
      expect(d.history.last.amount, Money(49900));
      expect(d.customer.oldestBillAt, DateTime.utc(2026, 11, 23, 6, 30));
    });

    test('an unknown phone or customer is null; nobody may look', () async {
      expect(
        await dues.findByPhone(role: Role.cashier, phone: '9000000009'),
        isNull,
      );
      expect(await dues.findByPhone(role: Role.cashier, phone: 'abc'), isNull);
      expect(
        await dues.detail(role: Role.cashier, customerId: 'nobody'),
        isNull,
      );
      await expectLater(
        dues.customers(role: null),
        throwsA(isA<PermissionDenied>()),
      );
      await expectLater(
        dues.totalOwed(role: null),
        throwsA(isA<PermissionDenied>()),
      );
    });
  });

  group('writing a debt off', () {
    Future<void> writeOff({
      Role? role = Role.owner,
      int amount = 49900,
      String note = 'moved away',
    }) async => dues.writeOff(
      role: role,
      actorId: 'owner-1',
      customerId: (await ravi()).id,
      amount: Money(amount),
      note: note,
    );

    test(
      'the owner can, with a reason, and the oldest bill closes first',
      () async {
        await sellOnCredit([kurta[0]]);
        now = DateTime.utc(2026, 11, 24, 6, 30);
        await sellOnCredit([kurta[1]]);
        await writeOff(amount: 60000);
        expect((await ravi()).owed, Money(99800 - 60000));
        final rows = await db
            .customSelect(
              "SELECT amount_paise, note FROM dues_ledger WHERE kind = 'WRITE_OFF' ORDER BY rowid",
            )
            .get();
        expect(rows.map((r) => r.read<int>('amount_paise')), [-49900, -10100]);
        expect(rows.first.read<String>('note'), 'moved away');
        expect(
          await count(
            "SELECT COUNT(*) AS c FROM daybook WHERE kind LIKE 'DUES_%'",
          ),
          0,
        );
        final a = await db
            .customSelect(
              "SELECT actor FROM audit_log WHERE action = 'dues.writeoff'",
            )
            .getSingle();
        expect(a.read<String>('actor'), 'owner-1');
      },
    );

    test('a manager, a cashier and nobody may not', () async {
      await sellOnCredit([kurta[0]]);
      for (final role in [Role.manager, Role.cashier, null]) {
        await expectLater(
          writeOff(role: role),
          throwsA(isA<PermissionDenied>()),
          reason: '$role',
        );
      }
      expect((await ravi()).owed, Money(49900));
    });

    test('a reason is required, and so is a sensible amount', () async {
      await sellOnCredit([kurta[0]]);
      await expectLater(writeOff(note: '  '), throwsA(isA<InvalidDues>()));
      await expectLater(writeOff(note: 'x' * 201), throwsA(isA<InvalidDues>()));
      await expectLater(writeOff(amount: 0), throwsA(isA<InvalidDues>()));
      await expectLater(writeOff(amount: 49901), throwsA(isA<InvalidDues>()));
      expect((await ravi()).owed, Money(49900));
    });

    test('nothing owed cannot be written off', () async {
      await sellOnCredit([kurta[0]]);
      await writeOff();
      await expectLater(writeOff(amount: 100), throwsA(isA<NothingOwed>()));
    });
  });

  group('a return from an unpaid bill', () {
    Future<SavedReturn> giveBack(
      List<String> barcodes, {
      RefundMode mode = RefundMode.cash,
    }) => returns.saveReturn(
      role: Role.cashier,
      cashierId: 'cashier-1',
      items: [
        for (final b in barcodes) ReturnItemInput(b, ReturnOutcome.restock),
      ],
      refundMode: mode,
    );

    test('lookup says how much is still owed on that bill', () async {
      await sellOnCredit([jeans[0]], paidNow: 30000);
      final c = await returns.lookup(role: Role.cashier, barcode: jeans[0]);
      expect(c!.owedOnBill, Money(99900));
      expect(c.netPrice, Money(129900));
    });

    test(
      'the refund first takes down what is owed; nothing is paid out',
      () async {
        await sellOnCredit([kurta[0], jeans[0]]); // owes 1798.00
        final r = await giveBack([jeans[0]]);
        expect(r.total, Money(129900));
        expect(r.offset, Money(129900));
        expect(r.payout, Money.zero);
        expect((await ravi()).owed, Money(49900));
        expect(
          await count(
            "SELECT COUNT(*) AS c FROM daybook WHERE kind LIKE 'REFUND_%'",
          ),
          0,
        );
        final l = await db
            .customSelect(
              "SELECT amount_paise, return_id FROM dues_ledger WHERE kind = 'RETURN_OFFSET'",
            )
            .getSingle();
        expect(l.read<int>('amount_paise'), -129900);
        expect(l.read<String>('return_id'), r.returnId);
        final back = await db
            .customSelect(
              "SELECT status FROM articles WHERE barcode_value = '${jeans[0]}'",
            )
            .getSingle();
        expect(back.read<String>('status'), 'IN_STOCK');
      },
    );

    test('a credit note is not made when nothing is left to pay out', () async {
      await sellOnCredit([jeans[0]]);
      final r = await giveBack([jeans[0]], mode: RefundMode.creditNote);
      expect(r.creditNote, isNull);
      expect(await count('SELECT COUNT(*) AS c FROM credit_notes'), 0);
    });

    test(
      'what is owed is less than the garment: the rest is paid out',
      () async {
        await sellOnCredit([jeans[0]], paidNow: 100000); // owes 299.00
        final r = await giveBack([jeans[0]]);
        expect(r.offset, Money(29900));
        expect(r.payout, Money(100000));
        expect((await ravi()).owed, Money.zero);
        final d = await db
            .customSelect(
              "SELECT amount_paise FROM daybook WHERE kind = 'REFUND_CASH'",
            )
            .getSingle();
        expect(d.read<int>('amount_paise'), -100000);
      },
    );

    test('a credit note is for the rest only', () async {
      await sellOnCredit([jeans[0]], paidNow: 100000);
      final r = await giveBack([jeans[0]], mode: RefundMode.creditNote);
      expect(r.creditNote!.amount, Money(100000));
      expect(r.payout, Money(100000));
      expect(r.offset, Money(29900));
    });

    test('two garments from one bill share what is owed', () async {
      await sellOnCredit([
        kurta[0],
        kurta[1],
        jeans[0],
      ], paidNow: 100000); // owes 1,298 + ... = 2,297 - 1,000
      final owedBefore = (await ravi()).owed;
      expect(owedBefore, Money(49900 * 2 + 129900 - 100000));
      final r = await giveBack([kurta[0], kurta[1]]);
      expect(r.total, Money(99800));
      expect(r.offset, Money(99800));
      expect((await ravi()).owed, Money(owedBefore.paise - 99800));
    });

    test('returns from two bills are offset bill by bill', () async {
      await sellOnCredit([kurta[0]]); // owes 499
      await sellOnCredit(
        [jeans[0]],
        paidNow: 129900 - 10000,
        payLater: later(),
      ); // owes 100
      final r = await giveBack([kurta[0], jeans[0]]);
      expect(r.total, Money(179800));
      expect(r.offset, Money(49900 + 10000));
      expect(r.payout, Money(179800 - 59900));
      expect((await ravi()).owed, Money.zero);
    });

    test('a garment from a bill paid in full is refunded as before', () async {
      await sales.saveBill(
        role: Role.cashier,
        cashierId: 'cashier-1',
        lines: [BillLineInput(kurta[0])],
        payments: [Payment(PaymentMode.cash, Money(49900))],
      );
      final r = await giveBack([kurta[0]]);
      expect(r.offset, Money.zero);
      expect(r.payout, Money(49900));
      expect(await count("SELECT COUNT(*) AS c FROM dues_ledger"), 0);
    });

    test('a paid-up pay-later bill is refunded in full', () async {
      await sellOnCredit([kurta[0]]);
      await dues.receivePayment(
        role: Role.cashier,
        userId: 'cashier-1',
        customerId: (await ravi()).id,
        payments: [Payment(PaymentMode.cash, Money(49900))],
      );
      final r = await giveBack([kurta[0]]);
      expect(r.offset, Money.zero);
      expect(r.payout, Money(49900));
    });
  });

  group('the daily report', () {
    final day = ShopDay(2026, 11, 23);
    late ReportRepository report;
    setUp(() => report = ReportRepository(db));

    test('shows what was left unpaid, what came in, and still agrees with the daybook', () async {
      await sellOnCredit([jeans[0]], paidNow: 50000); // owes 799.00
      now = DateTime.utc(2026, 11, 23, 7);
      await dues.receivePayment(
        role: Role.cashier,
        userId: 'cashier-1',
        customerId: (await ravi()).id,
        payments: [
          Payment(PaymentMode.cash, Money(30000)),
          Payment(PaymentMode.upi, Money(10000)),
        ],
      );
      final r = await report.dailyReport(role: Role.owner, day: day);
      expect(r.salesTotal, Money(129900));
      expect(r.moneyIn[PaymentMode.cash], Money(50000));
      expect(r.owedNew, Money(79900));
      expect(r.duesReceived[PaymentMode.cash], Money(30000));
      expect(r.duesReceived[PaymentMode.upi], Money(10000));
      expect(r.duesReceivedTotal, Money(40000));
      expect(r.totalOwedNow, Money(39900));
      expect(r.matchesDaybook, isTrue);
    });

    test('a return that took down what is owed still agrees', () async {
      await sellOnCredit([jeans[0]]);
      now = DateTime.utc(2026, 11, 23, 7);
      await returns.saveReturn(
        role: Role.cashier,
        cashierId: 'cashier-1',
        items: [ReturnItemInput(jeans[0], ReturnOutcome.restock)],
        refundMode: RefundMode.cash,
      );
      final r = await report.dailyReport(role: Role.owner, day: day);
      expect(r.refundsTotal, Money(129900));
      expect(r.returnOffsets, Money(129900));
      expect(r.refundsPaidTotal, Money.zero);
      expect(r.matchesDaybook, isTrue);
      expect(r.totalOwedNow, Money.zero);
    });

    test('a write-off shows, on the day it was made', () async {
      await sellOnCredit([kurta[0]]);
      now = DateTime.utc(2026, 11, 24, 7);
      await dues.writeOff(
        role: Role.owner,
        actorId: 'owner-1',
        customerId: (await ravi()).id,
        amount: Money(49900),
        note: 'gone',
      );
      expect(
        (await report.dailyReport(role: Role.owner, day: day)).writtenOff,
        Money.zero,
      );
      final next = await report.dailyReport(
        role: Role.owner,
        day: ShopDay(2026, 11, 24),
      );
      expect(next.writtenOff, Money(49900));
      expect(next.totalOwedNow, Money.zero);
      expect(next.matchesDaybook, isTrue);
    });

    test('a day with no pay later has zeros', () async {
      final r = await report.dailyReport(role: Role.owner, day: day);
      expect(r.owedNew, Money.zero);
      expect(r.duesReceived, isEmpty);
      expect(r.totalOwedNow, Money.zero);
    });

    test('an unexplained dues-sized daybook gap is still caught', () async {
      await sellOnCredit([kurta[0]]);
      await db
          .customStatement(
            "INSERT INTO daybook (id, at, shift_id, kind, amount_paise, ref_type, ref_id) "
            "SELECT 'x1', at, shift_id, 'SALE_CASH', 100, 'bill', 'zzz' FROM daybook LIMIT 1",
          )
          .catchError((_) {});
      // nothing paid now: add a stray sale row against the day
      final shift = (await db.customSelect('SELECT id FROM shifts').getSingle())
          .read<String>('id');
      await db.customStatement(
        "INSERT INTO daybook (id, at, shift_id, kind, amount_paise, ref_type, ref_id) "
        "VALUES ('x2', ${now.millisecondsSinceEpoch ~/ 1000}, '$shift', 'SALE_CASH', 100, 'bill', 'zzz')",
      );
      final r = await report.dailyReport(role: Role.owner, day: day);
      expect(r.matchesDaybook, isFalse);
    });
  });

  group('never edited, never reads cost', () {
    test(
      'the ledger, receipts and customers cannot be changed or removed',
      () async {
        await sellOnCredit([kurta[0]]);
        await dues.receivePayment(
          role: Role.cashier,
          userId: 'cashier-1',
          customerId: (await ravi()).id,
          payments: [Payment(PaymentMode.cash, Money(100))],
        );
        for (final sql in [
          "UPDATE dues_ledger SET amount_paise = 1",
          "DELETE FROM dues_ledger",
          "UPDATE dues_receipts SET cash_paise = 1",
          "DELETE FROM dues_receipts",
          "DELETE FROM customers",
          "UPDATE customers SET name = 'x'",
        ]) {
          await expectLater(
            db.customStatement(sql),
            throwsA(anything),
            reason: sql,
          );
        }
      },
    );

    test('the database refuses a ledger row with the wrong sign or no reason', () async {
      await sellOnCredit([kurta[0]]);
      final r = await db
          .customSelect('SELECT customer_id, bill_id FROM dues_ledger')
          .getSingle();
      final c = r.read<String>('customer_id');
      final b = r.read<String>('bill_id');
      Future<void> insert(
        String kind,
        int amount, {
        String extra = '',
      }) => db.customStatement(
        'INSERT INTO dues_ledger (id, customer_id, bill_id, kind, amount_paise, at, actor_id$extra) '
        "VALUES ('t${++n}', '$c', '$b', '$kind', $amount, 1700000000, 'u'${extra.isEmpty ? '' : ", 'x'"})",
      );
      await expectLater(insert('OWED', -5), throwsA(anything));
      await expectLater(insert('OWED', 0), throwsA(anything));
      await expectLater(insert('WRITE_OFF', 5), throwsA(anything));
      await expectLater(
        insert('PAYMENT', -5),
        throwsA(anything),
      ); // needs a receipt
      await expectLater(
        insert('RETURN_OFFSET', -5),
        throwsA(anything),
      ); // needs a return
      await expectLater(
        insert('WRITE_OFF', -5),
        throwsA(anything),
      ); // needs a reason
      await expectLater(insert('SOMETHING', -5), throwsA(anything));
    });

    test('the pay later code never reads cost', () {
      for (final f in ['lib/data/dues_repository.dart']) {
        final text = File(f).readAsStringSync();
        expect(text.contains('batch_lines'), isFalse);
        expect(text.contains('unit_cost'), isFalse);
      }
    });
  });
}
