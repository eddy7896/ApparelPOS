// P2-4b: looking up a garment as a cashier and saving a bill in one
// transaction. E-SALE-1, E-AUTHZ-1, E-OFFLINE-1, E-AUDIT-1.
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/sales_repository.dart';
import 'package:pos_windows/data/shift_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

Money r(int rupees) => Money.rupees(rupees);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late StockRepository stock;
  late SalesRepository sales;
  late DateTime now;
  late List<String>
  barcodes; // 3 garments: M Blue x2 (MRP 499), L Blue x1 (MRP 999)
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 11, 20, 10);
    n = 0;
    stock = StockRepository(db, newId: newId, now: () => now);
    sales = SalesRepository(db, newId: newId, now: () => now);
    await stock.ensureCounter();
    await db
        .into(db.users)
        .insert(
          UsersCompanion.insert(
            id: 'cashier-1',
            name: 'Asha',
            role: 'CASHIER',
            credentialHash: 'x',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await ShiftRepository(
      db,
      newId: newId,
      now: () => now,
    ).openShift(role: Role.cashier, userId: 'cashier-1', counts: const {});
    final result = await stock.receivePurchase(
      role: Role.owner,
      draft: PurchaseDraft(
        supplier: 'Sample Supplier',
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
          variables: [Variable<String>(result.batchId)],
        )
        .get();
    barcodes = [for (final r in rows) r.read<String>('barcode_value')];
    now = DateTime.utc(2026, 11, 20, 11);
  });
  tearDown(() => db.close());

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle())
          .read<int>('c');

  Future<String> statusOf(String barcode) async =>
      (await db
              .customSelect(
                'SELECT status FROM articles WHERE barcode_value = ?',
                variables: [Variable<String>(barcode)],
              )
              .getSingle())
          .read<String>('status');

  Future<SavedBill> sellOne(String barcode, {Money? pay}) => sales.saveBill(
    role: Role.cashier,
    cashierId: 'cashier-1',
    lines: [BillLineInput(barcode)],
    payments: [Payment(PaymentMode.cash, pay ?? Money(49900))],
  );

  group('lookup (cashier safe)', () {
    test('shows name, size, color, MRP and status', () async {
      final item = await sales.lookup(role: Role.cashier, barcode: barcodes[0]);
      expect(item, isNotNull);
      expect(item!.productName, 'Cotton Kurta');
      expect(item.mrp, Money(49900));
      expect(item.status, ArticleStatus.inStock);
      expect(item.soldOnBill, isNull);
    });
    test('unknown barcode is null', () async {
      expect(
        await sales.lookup(role: Role.cashier, barcode: '000000000000'),
        isNull,
      );
    });
    test('no role may not look up', () async {
      expect(
        () => sales.lookup(role: null, barcode: barcodes[0]),
        throwsA(isA<PermissionDenied>()),
      );
    });
    test('a sold garment says which bill sold it', () async {
      final bill = await sellOne(barcodes[0]);
      final item = await sales.lookup(role: Role.cashier, barcode: barcodes[0]);
      expect(item!.status, ArticleStatus.sold);
      expect(item.soldOnBill, bill.billNumber.format());
    });
    test('the sales code never touches the cost table (E-AUTHZ-1)', () {
      final source = File('lib/data/sales_repository.dart').readAsStringSync();
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
          reason: 'sales_repository.dart must not mention $banned',
        );
      }
    });
  });

  group('saving a bill', () {
    test(
      'marks garments sold and saves bill, lines, payment and serial',
      () async {
        final bill = await sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [BillLineInput(barcodes[0]), BillLineInput(barcodes[2])],
          payments: [Payment(PaymentMode.cash, r(1500))],
          customerName: ' Ravi ',
          customerPhone: '98765 43210',
        );
        expect(bill.billNumber.format(), '2026-27/C1/000001');
        expect(bill.total, Money(149800));
        expect(bill.settlement.change, Money(1000 * 0 + 200));
        expect(await statusOf(barcodes[0]), 'SOLD');
        expect(await statusOf(barcodes[2]), 'SOLD');
        expect(await statusOf(barcodes[1]), 'IN_STOCK');
        expect(await count('bills'), 1);
        expect(await count('bill_lines'), 2);
        final b = await db.customSelect('SELECT * FROM bills').getSingle();
        expect(b.read<String>('customer_name'), 'Ravi');
        expect(b.read<int>('total_paise'), 149800);
        expect(b.read<int>('change_paise'), 200);
        expect(b.read<String>('cashier_id'), 'cashier-1');
      },
    );

    test('line keeps its own price breakdown and a copy of the name', () async {
      await sales.saveBill(
        role: Role.cashier,
        cashierId: 'cashier-1',
        lines: [BillLineInput(barcodes[0], discount: PriceCut.percentBp(1000))],
        payments: [Payment(PaymentMode.upi, Money(44910))],
      );
      final l = await db.customSelect('SELECT * FROM bill_lines').getSingle();
      expect(l.read<int>('mrp_paise'), 49900);
      expect(l.read<int>('discount_paise'), 4990);
      expect(l.read<int>('markdown_paise'), 0);
      expect(l.read<int>('final_paise'), 44910);
      expect(l.read<String>('product_name'), 'Cotton Kurta');
      expect(l.read<String>('size'), 'M');
    });

    test('bill serials run 1, 2, 3 on the counter', () async {
      final a = await sellOne(barcodes[0]);
      final b = await sellOne(barcodes[1]);
      expect(a.billNumber.serial, 1);
      expect(b.billNumber.serial, 2);
    });

    test('the serial restarts in a new financial year', () async {
      await sellOne(barcodes[0]);
      now = DateTime.utc(2027, 3, 31, 18, 30); // 1 April 2027, India time
      final b = await sellOne(barcodes[1]);
      expect(b.billNumber.format(), '2027-28/C1/000001');
    });

    test('the counter number comes from the setting', () async {
      await db
          .into(db.appSettings)
          .insert(AppSettingsCompanion.insert(name: 'counter_no', value: '2'));
      final b = await sellOne(barcodes[0]);
      expect(b.billNumber.format(), '2026-27/C2/000001');
    });

    test(
      'audit and outbox rows are written, with no phone and no cost',
      () async {
        await sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [BillLineInput(barcodes[0])],
          payments: [Payment(PaymentMode.cash, Money(49900))],
          customerName: 'Ravi',
          customerPhone: '9876543210',
        );
        final audit = await db
            .customSelect("SELECT * FROM audit_log WHERE action = 'sale.bill'")
            .getSingle();
        expect(audit.read<String>('actor'), 'cashier-1');
        final outbox = await db
            .customSelect("SELECT * FROM outbox WHERE operation = 'sale.bill'")
            .getSingle();
        for (final text in [
          audit.read<String>('details'),
          outbox.read<String>('payload'),
        ]) {
          expect(text, isNot(contains('9876543210')));
          expect(text, isNot(contains('Ravi')));
          expect(text, isNot(contains('20000')));
        }
      },
    );

    test('works with no network at all (E-OFFLINE-1)', () async {
      // Nothing in the save path needs a network: the whole flow above runs on
      // an in-memory database with no network code injected.
      final bill = await sellOne(barcodes[0]);
      expect(bill.settlement.isPaid, isTrue);
    });
  });

  group('a garment cannot be sold twice (E-SALE-1)', () {
    test(
      'a second bill with the same barcode is refused, naming the bill',
      () async {
        final first = await sellOne(barcodes[0]);
        await expectLater(
          sellOne(barcodes[0]),
          throwsA(
            isA<ArticleNotSellable>()
                .having(
                  (e) => e.reason,
                  'reason',
                  NotSellableReason.alreadySold,
                )
                .having((e) => e.soldOnBill, 'bill', first.billNumber.format()),
          ),
        );
        expect(await count('bills'), 1);
      },
    );

    test('unknown barcode is refused', () async {
      await expectLater(
        sellOne('000000000000'),
        throwsA(
          isA<ArticleNotSellable>().having(
            (e) => e.reason,
            'reason',
            NotSellableReason.notFound,
          ),
        ),
      );
    });

    test('a damaged garment is refused', () async {
      await db.customStatement(
        "UPDATE articles SET status = 'DAMAGED' WHERE barcode_value = '${barcodes[0]}'",
      );
      await expectLater(
        sellOne(barcodes[0]),
        throwsA(
          isA<ArticleNotSellable>().having(
            (e) => e.reason,
            'reason',
            NotSellableReason.notInStock,
          ),
        ),
      );
    });

    test('one bad line saves nothing, not even the good lines', () async {
      await sellOne(barcodes[0]);
      await expectLater(
        sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [BillLineInput(barcodes[1]), BillLineInput(barcodes[0])],
          payments: [Payment(PaymentMode.cash, r(5000))],
        ),
        throwsA(isA<ArticleNotSellable>()),
      );
      expect(await statusOf(barcodes[1]), 'IN_STOCK');
      expect(await count('bills'), 1);
      // and the serial was not used up
      final next = await sellOne(barcodes[1]);
      expect(next.billNumber.serial, 2);
    });

    test('the same barcode twice on one bill is refused', () async {
      await expectLater(
        sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [BillLineInput(barcodes[0]), BillLineInput(barcodes[0])],
          payments: [Payment(PaymentMode.cash, r(5000))],
        ),
        throwsA(isA<InvalidBill>()),
      );
    });
  });

  group('payment', () {
    test('a short payment saves nothing', () async {
      await expectLater(
        sellOne(barcodes[0], pay: Money(10000)),
        throwsA(isA<BillNotPaid>().having((e) => e.due, 'due', Money(39900))),
      );
      expect(await statusOf(barcodes[0]), 'IN_STOCK');
      expect(await count('bills'), 0);
    });

    test('split cash and UPI records each mode, cash net of change', () async {
      await sales.saveBill(
        role: Role.cashier,
        cashierId: 'cashier-1',
        lines: [BillLineInput(barcodes[0])],
        payments: [
          Payment(PaymentMode.upi, Money(30000)),
          Payment(PaymentMode.cash, Money(20000)),
        ],
      );
      final rows = await db
          .customSelect(
            'SELECT mode, amount_paise FROM bill_payments ORDER BY mode',
          )
          .get();
      expect(
        {
          for (final p in rows)
            p.read<String>('mode'): p.read<int>('amount_paise'),
        },
        {'cash': 19900, 'upi': 30000},
      );
      final b = await db
          .customSelect('SELECT change_paise FROM bills')
          .getSingle();
      expect(b.read<int>('change_paise'), 100);
    });

    test('UPI over the total is refused', () async {
      await expectLater(
        sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [BillLineInput(barcodes[0])],
          payments: [Payment(PaymentMode.upi, Money(60000))],
        ),
        throwsA(isA<NonCashOverpayment>()),
      );
      expect(await statusOf(barcodes[0]), 'IN_STOCK');
    });
  });

  group('discounts and markdown', () {
    test('a cashier discount over 10% needs the manager', () async {
      await expectLater(
        sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [
            BillLineInput(barcodes[0], discount: PriceCut.percentBp(1001)),
          ],
          payments: [Payment(PaymentMode.cash, r(500))],
        ),
        throwsA(isA<DiscountNeedsManager>()),
      );
      expect(await statusOf(barcodes[0]), 'IN_STOCK');
    });

    test('exactly 10% is allowed for a cashier', () async {
      await sales.saveBill(
        role: Role.cashier,
        cashierId: 'cashier-1',
        lines: [BillLineInput(barcodes[0], discount: PriceCut.percentBp(1000))],
        payments: [Payment(PaymentMode.cash, Money(44910))],
      );
      expect(await statusOf(barcodes[0]), 'SOLD');
    });

    test(
      'a manager who approved lets a cashier give a bigger discount',
      () async {
        await sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [
            BillLineInput(barcodes[0], discount: PriceCut.percentBp(2000)),
          ],
          payments: [Payment(PaymentMode.cash, Money(39920))],
          discountApproverRole: Role.manager,
          discountApprovedBy: 'manager-1',
        );
        expect(await statusOf(barcodes[0]), 'SOLD');
        final audit = await db
            .customSelect(
              "SELECT details FROM audit_log WHERE action = 'sale.bill'",
            )
            .getSingle();
        expect(audit.read<String>('details'), contains('manager-1'));
        final b = await db
            .customSelect('SELECT cashier_id FROM bills')
            .getSingle();
        expect(b.read<String>('cashier_id'), 'cashier-1');
      },
    );

    test('an approver who is only a cashier changes nothing', () async {
      await expectLater(
        sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [
            BillLineInput(barcodes[0], discount: PriceCut.percentBp(2000)),
          ],
          payments: [Payment(PaymentMode.cash, Money(39920))],
          discountApproverRole: Role.cashier,
          discountApprovedBy: 'cashier-2',
        ),
        throwsA(isA<DiscountNeedsManager>()),
      );
    });

    test('an approver role without an approver id is a mistake', () async {
      await expectLater(
        sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [BillLineInput(barcodes[0])],
          payments: [Payment(PaymentMode.cash, Money(49900))],
          discountApproverRole: Role.manager,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('a manager may give a bigger discount', () async {
      await sales.saveBill(
        role: Role.manager,
        cashierId: 'cashier-1',
        lines: [BillLineInput(barcodes[0], discount: PriceCut.percentBp(5000))],
        payments: [Payment(PaymentMode.cash, Money(24950))],
      );
      expect(await statusOf(barcodes[0]), 'SOLD');
    });

    test('a cashier may not set a markdown', () async {
      await expectLater(
        sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [
            BillLineInput(barcodes[0], markdown: PriceCut.percentBp(2000)),
          ],
          payments: [Payment(PaymentMode.cash, r(500))],
        ),
        throwsA(isA<PermissionDenied>()),
      );
    });

    test('an owner markdown is priced and kept on the line', () async {
      await sales.saveBill(
        role: Role.owner,
        cashierId: 'cashier-1',
        lines: [BillLineInput(barcodes[0], markdown: PriceCut.percentBp(2000))],
        payments: [Payment(PaymentMode.cash, Money(39920))],
      );
      final l = await db.customSelect('SELECT * FROM bill_lines').getSingle();
      expect(l.read<int>('markdown_paise'), 9980);
      expect(l.read<int>('final_paise'), 39920);
    });

    test('a discount on a marked-down garment is refused', () async {
      await expectLater(
        sales.saveBill(
          role: Role.owner,
          cashierId: 'cashier-1',
          lines: [
            BillLineInput(
              barcodes[0],
              markdown: PriceCut.percentBp(2000),
              discount: PriceCut.percentBp(500),
            ),
          ],
          payments: [Payment(PaymentMode.cash, r(500))],
        ),
        throwsA(isA<DiscountNotAllowed>()),
      );
      expect(await statusOf(barcodes[0]), 'IN_STOCK');
    });
  });

  group('who may sell, and what is a valid bill', () {
    test('no role may not sell', () async {
      await expectLater(
        sales.saveBill(
          role: null,
          cashierId: 'cashier-1',
          lines: [BillLineInput(barcodes[0])],
          payments: [Payment(PaymentMode.cash, r(500))],
        ),
        throwsA(isA<PermissionDenied>()),
      );
    });
    test('an empty bill is refused', () async {
      await expectLater(
        sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: const [],
          payments: const [],
        ),
        throwsA(isA<InvalidBill>()),
      );
    });
    test('a bad phone number is refused and nothing is saved', () async {
      await expectLater(
        sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [BillLineInput(barcodes[0])],
          payments: [Payment(PaymentMode.cash, r(500))],
          customerPhone: '12ab',
        ),
        throwsA(isA<InvalidBill>()),
      );
      expect(await statusOf(barcodes[0]), 'IN_STOCK');
    });
  });

  group('sales are never edited or deleted (E-AUDIT-1)', () {
    test(
      'the database refuses to change or remove a bill, line or payment',
      () async {
        await sellOne(barcodes[0]);
        for (final sql in [
          "UPDATE bills SET total_paise = 1",
          "DELETE FROM bills",
          "UPDATE bill_lines SET final_paise = 1",
          "DELETE FROM bill_lines",
          "UPDATE bill_payments SET amount_paise = 1",
          "DELETE FROM bill_payments",
        ]) {
          await expectLater(
            db.customStatement(sql),
            throwsA(anything),
            reason: sql,
          );
        }
        expect(await count('bills'), 1);
      },
    );
  });
}
