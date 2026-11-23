// GST (P3-4, owner 2026-11-23). OFF by default (E-GST-1); only the owner may
// switch it on or change it; a bill keeps the tax it was made with. EVERY RULE
// is UNVERIFIED until the CA confirms it; these tests pin what the code does.
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/gst_repository.dart';
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
  late GstRepository gst;
  late ShiftRepository shifts;
  late List<String> kurta; // 4 x 499.00, cost 200.00
  late List<String> jeans; // 2 x 1299.00
  late DateTime now;
  var n = 0;
  String newId() => 'id-${++n}';

  GstSettings good({
    bool enabled = true,
    GstMode mode = GstMode.inclusive,
    GstRounding rounding = GstRounding.perItem,
    int rateBp = 500,
  }) => GstSettings(
    enabled: enabled,
    mode: mode,
    rounding: rounding,
    rateBp: rateBp,
    gstin: '27abcde1234f1z5',
    address: ' 12 Market Road, Pune ',
  );

  Future<void> save(GstSettings s, {Role? role = Role.owner}) =>
      gst.save(role: role, actorId: 'owner-1', settings: s);

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
    gst = GstRepository(db, newId: newId, now: () => now);
    shifts = ShiftRepository(db, newId: newId, now: () => now);
    await stock.ensureCounter();
    for (final (style, qty, mrp, cost) in [
      ('Cotton Kurta', 4, 49900, 20000),
      ('Denim Jeans', 2, 129900, 60000),
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
              cost: Money(cost),
              mrp: Money(mrp),
            ),
          ],
        ),
      );
    }
    kurta = await codes('Cotton Kurta');
    jeans = await codes('Denim Jeans');
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
    await shifts.openShift(
      role: Role.cashier,
      userId: 'cashier-1',
      counts: {Denomination.note500: 4},
    );
  });
  tearDown(() => db.close());

  Future<SavedBill> sell(List<String> barcodes, int pay) => sales.saveBill(
    role: Role.cashier,
    cashierId: 'cashier-1',
    lines: [for (final b in barcodes) BillLineInput(b)],
    payments: [Payment(PaymentMode.cash, Money(pay))],
  );

  Future<List<Map<String, int>>> lineRows() async => [
    for (final r
        in await db
            .customSelect(
              'SELECT final_paise, gst_bp, taxable_paise, tax_paise, extra_tax_paise '
              'FROM bill_lines ORDER BY rowid',
            )
            .get())
      {
        for (final c in [
          'final_paise',
          'gst_bp',
          'taxable_paise',
          'tax_paise',
          'extra_tax_paise',
        ])
          c: r.read<int>(c),
      },
  ];

  group('off by default (E-GST-1)', () {
    test('a new shop has GST off, 5%, inclusive, per item', () async {
      final s = await gst.settings(role: Role.cashier);
      expect(s.enabled, isFalse);
      expect(s.rateBp, 500);
      expect(s.mode, GstMode.inclusive);
      expect(s.rounding, GstRounding.perItem);
      expect(s.gstin, '');
    });

    test(
      'a bill made with GST off has no tax anywhere and the same total',
      () async {
        final bill = await sell([kurta[0], jeans[0]], 179800);
        expect(bill.total, Money(179800));
        expect(bill.tax.totalTax, Money.zero);
        expect(bill.gst.enabled, isFalse);
        for (final r in await lineRows()) {
          expect(r['gst_bp'], 0);
          expect(r['taxable_paise'], 0);
          expect(r['tax_paise'], 0);
          expect(r['extra_tax_paise'], 0);
        }
        final b = await db
            .customSelect('SELECT total_paise FROM bills')
            .getSingle();
        expect(b.read<int>('total_paise'), 179800);
      },
    );

    test('settings saved while off do not turn it on', () async {
      await save(good(enabled: false));
      expect((await gst.settings(role: Role.cashier)).enabled, isFalse);
      final bill = await sell([kurta[0]], 49900);
      expect(bill.tax.totalTax, Money.zero);
    });
  });

  group('who may change it', () {
    test('only the owner', () async {
      await save(good());
      for (final role in [Role.manager, Role.cashier, null]) {
        await expectLater(
          save(good(rateBp: 1200), role: role),
          throwsA(isA<PermissionDenied>()),
          reason: '$role',
        );
      }
      expect((await gst.settings(role: Role.owner)).rateBp, 500);
    });

    test(
      'everyone at the counter can read it; nobody signed in cannot',
      () async {
        await save(good());
        expect((await gst.settings(role: Role.cashier)).enabled, isTrue);
        expect((await gst.settings(role: Role.manager)).enabled, isTrue);
        await expectLater(
          gst.settings(role: null),
          throwsA(isA<PermissionDenied>()),
        );
      },
    );
  });

  group('saving the settings', () {
    test(
      'everything is kept, the GSTIN made capitals and the address trimmed',
      () async {
        await save(
          good(
            mode: GstMode.exclusive,
            rounding: GstRounding.perBill,
            rateBp: 1200,
          ).copyWith(
            fields: {GstInvoiceField.shopGstin, GstInvoiceField.amountInWords},
          ),
        );
        final s = await gst.settings(role: Role.owner);
        expect(s.enabled, isTrue);
        expect(s.mode, GstMode.exclusive);
        expect(s.rounding, GstRounding.perBill);
        expect(s.rateBp, 1200);
        expect(s.gstin, '27ABCDE1234F1Z5');
        expect(s.address, '12 Market Road, Pune');
        expect(s.fields, {
          GstInvoiceField.shopGstin,
          GstInvoiceField.amountInWords,
        });
      },
    );

    test(
      'a field switched off stays off, one never saved takes its default',
      () async {
        expect(
          (await gst.settings(role: Role.owner))
              .prints(GstInvoiceField.taxPerItem),
          isTrue,
        );
        await save(good().copyWith(fields: {GstInvoiceField.shopGstin}));
        expect(
          (await gst.settings(role: Role.owner))
              .prints(GstInvoiceField.taxPerItem),
          isFalse,
        );
      },
    );

    test('switching on needs a GSTIN, an address and a rate', () async {
      for (final (s, p) in [
        (good().copyWith(gstin: ''), GstSettingsProblem.gstinMissing),
        (good().copyWith(gstin: 'nope'), GstSettingsProblem.gstinInvalid),
        (good().copyWith(address: ''), GstSettingsProblem.addressMissing),
        (good().copyWith(rateBp: 0), GstSettingsProblem.rateOutOfRange),
      ]) {
        await expectLater(
          save(s),
          throwsA(
            isA<InvalidGstSettings>().having((e) => e.problem, 'problem', p),
          ),
        );
      }
      expect((await gst.settings(role: Role.owner)).enabled, isFalse);
    });

    test('switched off, nothing has to be filled in', () async {
      await save(const GstSettings());
      await save(good());
      await save(good(enabled: false).copyWith(gstin: '', address: ''));
      expect((await gst.settings(role: Role.owner)).enabled, isFalse);
    });

    test('the audit trail records who and what, never the GSTIN', () async {
      await save(good());
      final a = await db
          .customSelect(
            "SELECT actor, details FROM audit_log WHERE action = 'gst.settings'",
          )
          .getSingle();
      expect(a.read<String>('actor'), 'owner-1');
      expect(a.read<String>('details'), contains('"enabled":true'));
      expect(a.read<String>('details').contains('ABCDE'), isFalse);
    });

    test('a refused save writes nothing', () async {
      await expectLater(
        save(good().copyWith(gstin: '')),
        throwsA(isA<InvalidGstSettings>()),
      );
      expect(
        (await db
                .customSelect(
                  "SELECT COUNT(*) AS c FROM audit_log WHERE action = 'gst.settings'",
                )
                .getSingle())
            .read<int>('c'),
        0,
      );
    });
  });

  group('a bill with GST on', () {
    test(
      'tax included: the total is the same, the tax is kept per garment',
      () async {
        await save(good());
        final bill = await sell([kurta[0], jeans[0]], 179800);
        expect(bill.total, Money(179800));
        expect(bill.gst.enabled, isTrue);
        expect(
          bill.tax.totalTax,
          Money(2376 + 6186),
        ); // 499.00 and 1,299.00 at 5%
        final rows = await lineRows();
        expect(rows[0], {
          'final_paise': 49900,
          'gst_bp': 500,
          'taxable_paise': 47524,
          'tax_paise': 2376,
          'extra_tax_paise': 0,
        });
        expect(rows[1]['taxable_paise']! + rows[1]['tax_paise']!, 129900);
        final b = await db
            .customSelect('SELECT total_paise FROM bills')
            .getSingle();
        expect(b.read<int>('total_paise'), 179800);
      },
    );

    test('tax on top: the customer pays the prices and the tax', () async {
      await save(good(mode: GstMode.exclusive));
      final bill = await sell([kurta[0]], 52395);
      expect(bill.total, Money(52395));
      expect(bill.tax.addedOnTop, Money(2495));
      final r = (await lineRows()).single;
      expect(r['final_paise'], 49900);
      expect(r['tax_paise'], 2495);
      expect(r['extra_tax_paise'], 2495);
      final pay = await db
          .customSelect('SELECT SUM(amount_paise) AS s FROM bill_payments')
          .getSingle();
      expect(pay.read<int>('s'), 52395);
      final day = await db
          .customSelect(
            "SELECT amount_paise FROM daybook WHERE kind = 'SALE_CASH'",
          )
          .getSingle();
      expect(day.read<int>('amount_paise'), 52395);
    });

    test(
      'paying only the prices is not enough when tax is added on top',
      () async {
        await save(good(mode: GstMode.exclusive));
        await expectLater(sell([kurta[0]], 49900), throwsA(isA<BillNotPaid>()));
        final c = await db
            .customSelect('SELECT COUNT(*) AS c FROM bills')
            .getSingle();
        expect(c.read<int>('c'), 0);
      },
    );

    test('rounding per bill shares one tax over the garments', () async {
      await save(good(mode: GstMode.exclusive, rounding: GstRounding.perBill));
      final bill = await sell([
        kurta[0],
        kurta[1],
        jeans[0],
      ], 49900 * 2 + 129900 + 11485);
      // base 2,297.00 x 5% = 114.85 in all
      expect(bill.tax.totalTax, Money(11485));
      expect(bill.total, Money(49900 * 2 + 129900 + 11485));
    });

    test('a changed rate applies only to new bills', () async {
      await save(good());
      await sell([kurta[0]], 49900);
      await save(good(rateBp: 1200));
      await sell([kurta[1]], 49900);
      final rows = await lineRows();
      expect(rows[0]['gst_bp'], 500);
      expect(rows[0]['tax_paise'], 2376);
      expect(rows[1]['gst_bp'], 1200);
      expect(
        rows[1]['tax_paise'],
        49900 - (49900 * 10000 * 2 + 11200) ~/ (11200 * 2),
      );
    });

    test(
      'switching GST off later does not change a bill already made',
      () async {
        await save(good());
        await sell([kurta[0]], 49900);
        await save(good(enabled: false));
        final bill = await sell([kurta[1]], 49900);
        expect(bill.tax.totalTax, Money.zero);
        final rows = await lineRows();
        expect(rows[0]['tax_paise'], 2376);
        expect(rows[1]['tax_paise'], 0);
      },
    );

    test('the tax on a bill line cannot be edited afterwards', () async {
      await save(good());
      await sell([kurta[0]], 49900);
      await expectLater(
        db.customStatement('UPDATE bill_lines SET tax_paise = 0'),
        throwsA(anything),
      );
    });

    test(
      'a marked-down or discounted garment is taxed on what is charged',
      () async {
        await save(good());
        final bill = await sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [BillLineInput(kurta[0], discount: PriceCut.percentBp(1000))],
          payments: [Payment(PaymentMode.cash, Money(44910))],
        );
        expect(bill.total, Money(44910));
        final r = (await lineRows()).single;
        expect(r['final_paise'], 44910);
        expect(r['taxable_paise']! + r['tax_paise']!, 44910);
      },
    );
  });

  group('returns reverse the same tax', () {
    Future<SavedReturn> giveBack(String code) => returns.saveReturn(
      role: Role.cashier,
      cashierId: 'cashier-1',
      items: [ReturnItemInput(code, ReturnOutcome.restock)],
      refundMode: RefundMode.cash,
    );

    test('tax included: the refund is the price paid', () async {
      await save(good());
      await sell([kurta[0]], 49900);
      final r = await giveBack(kurta[0]);
      expect(r.total, Money(49900));
    });

    test('tax on top: the refund includes the tax that was added', () async {
      await save(good(mode: GstMode.exclusive));
      await sell([kurta[0]], 52395);
      final c = await returns.lookup(role: Role.cashier, barcode: kurta[0]);
      expect(c!.netPrice, Money(52395));
      final r = await giveBack(kurta[0]);
      expect(r.total, Money(52395));
      final day = await db
          .customSelect(
            "SELECT amount_paise FROM daybook WHERE kind = 'REFUND_CASH'",
          )
          .getSingle();
      expect(day.read<int>('amount_paise'), -52395);
    });

    test('a refund is the same after GST is switched off', () async {
      await save(good(mode: GstMode.exclusive));
      await sell([kurta[0]], 52395);
      await save(good(enabled: false));
      final r = await giveBack(kurta[0]);
      expect(r.total, Money(52395));
    });

    test('a bill from before GST refunds exactly as before', () async {
      await sell([kurta[0]], 49900);
      await save(good(mode: GstMode.exclusive));
      final r = await giveBack(kurta[0]);
      expect(r.total, Money(49900));
    });
  });

  group('the daily report', () {
    final day = ShopDay(2026, 11, 23);
    late ReportRepository report;
    setUp(() => report = ReportRepository(db));

    test('with GST off it shows no tax, and profit is as before', () async {
      await sell([kurta[0]], 49900);
      final r = await report.dailyReport(role: Role.owner, day: day);
      expect(r.gstOnSales, Money.zero);
      expect(r.gstOnReturns, Money.zero);
      expect(r.netGst, Money.zero);
      expect(r.profit, Money(29900));
    });

    test('tax included: the tax is shown and profit leaves it out', () async {
      await save(good());
      await sell([kurta[0]], 49900); // cost 200.00
      final r = await report.dailyReport(role: Role.owner, day: day);
      expect(r.salesTotal, Money(49900));
      expect(r.gstOnSales, Money(2376));
      expect(r.profit, Money(49900 - 2376 - 20000));
      expect(r.matchesDaybook, isTrue);
    });

    test(
      'tax on top: sales include the tax, profit still leaves it out',
      () async {
        await save(good(mode: GstMode.exclusive));
        await sell([kurta[0]], 52395);
        final r = await report.dailyReport(role: Role.owner, day: day);
        expect(r.salesTotal, Money(52395));
        expect(r.gstOnSales, Money(2495));
        expect(r.profit, Money(49900 - 20000));
        expect(r.matchesDaybook, isTrue);
      },
    );

    test('a return takes its tax back', () async {
      await save(good());
      await sell([kurta[0], kurta[1]], 99800);
      await returns.saveReturn(
        role: Role.cashier,
        cashierId: 'cashier-1',
        items: [ReturnItemInput(kurta[0], ReturnOutcome.restock)],
        refundMode: RefundMode.cash,
      );
      final r = await report.dailyReport(role: Role.owner, day: day);
      expect(r.gstOnSales, Money(2376 * 2));
      expect(r.gstOnReturns, Money(2376));
      expect(r.netGst, Money(2376));
      expect(r.netSales, Money(49900));
      expect(r.profit, Money(49900 - 2376 - 20000));
      expect(r.matchesDaybook, isTrue);
    });
  });

  group('HSN codes and own rates (P3-4, unverified until the CA confirms)', () {
    Future<String> styleId(String name) async =>
        (await db
                .customSelect(
                  'SELECT id FROM products WHERE name = ?',
                  variables: [Variable<String>(name)],
                )
                .getSingle())
            .read<String>('id');

    test('a style has no HSN and no own rate to begin with', () async {
      final all = await gst.styles(role: Role.manager);
      expect(all.map((s) => s.name), ['Cotton Kurta', 'Denim Jeans']);
      expect(all.every((s) => s.hsn.isEmpty && s.rateBp == null), isTrue);
    });

    test('a manager sets an HSN code; only the owner sets a rate', () async {
      final id = await styleId('Cotton Kurta');
      await gst.setStyleGst(
        role: Role.manager,
        actorId: 'm',
        styleId: id,
        hsn: '6109',
      );
      expect((await gst.styles(role: Role.owner)).first.hsn, '6109');
      await expectLater(
        gst.setStyleGst(
          role: Role.manager,
          actorId: 'm',
          styleId: id,
          hsn: '6109',
          changeRate: true,
          rateBp: 1200,
        ),
        throwsA(isA<PermissionDenied>()),
      );
      await gst.setStyleGst(
        role: Role.owner,
        actorId: 'o',
        styleId: id,
        hsn: '6109',
        changeRate: true,
        rateBp: 1200,
      );
      final s = (await gst.styles(role: Role.owner)).first;
      expect((s.hsn, s.rateBp), ('6109', 1200));
    });

    test('changing only the HSN leaves the rate; clearing sends it back to the shop rate', () async {
      final id = await styleId('Cotton Kurta');
      await gst.setStyleGst(
        role: Role.owner,
        actorId: 'o',
        styleId: id,
        hsn: '6109',
        changeRate: true,
        rateBp: 1200,
      );
      await gst.setStyleGst(
        role: Role.manager,
        actorId: 'm',
        styleId: id,
        hsn: '610910',
      );
      expect((await gst.styles(role: Role.owner)).first.rateBp, 1200);
      await gst.setStyleGst(
        role: Role.owner,
        actorId: 'o',
        styleId: id,
        hsn: '',
        changeRate: true,
        rateBp: null,
      );
      final s = (await gst.styles(role: Role.owner)).first;
      expect((s.hsn, s.rateBp), ('', null));
    });

    test(
      'bad codes, bad rates, unknown styles and cashiers are refused',
      () async {
        final id = await styleId('Cotton Kurta');
        for (final bad in ['61', '6109x', '123456789']) {
          await expectLater(
            gst.setStyleGst(
              role: Role.owner,
              actorId: 'o',
              styleId: id,
              hsn: bad,
            ),
            throwsA(isA<InvalidStyleGst>()),
            reason: bad,
          );
        }
        await expectLater(
          gst.setStyleGst(
            role: Role.owner,
            actorId: 'o',
            styleId: id,
            hsn: '',
            changeRate: true,
            rateBp: 5001,
          ),
          throwsA(isA<InvalidStyleGst>()),
        );
        await expectLater(
          gst.setStyleGst(
            role: Role.owner,
            actorId: 'o',
            styleId: 'nope',
            hsn: '6109',
          ),
          throwsA(isA<UnknownStyleGst>()),
        );
        await expectLater(
          gst.setStyleGst(
            role: Role.cashier,
            actorId: 'c',
            styleId: id,
            hsn: '6109',
          ),
          throwsA(isA<PermissionDenied>()),
        );
        await expectLater(
          gst.styles(role: Role.cashier),
          throwsA(isA<PermissionDenied>()),
        );
      },
    );

    test('stock entry sets them with the purchase', () async {
      await stock.receivePurchase(
        role: Role.owner,
        draft: PurchaseDraft(
          supplier: 'S',
          style: 'Linen Shirt',
          hsn: '6205',
          styleGstBp: 1200,
          supplierGstin: '27abcde1234f1z5',
          invoiceNo: ' INV/17 ',
          inputTax: Money(150000),
          lines: [
            PurchaseLine(
              size: 'M',
              color: 'White',
              quantity: 1,
              cost: Money(30000),
              mrp: Money(89900),
            ),
          ],
        ),
      );
      final p = await db
          .customSelect(
            "SELECT hsn, gst_bp FROM products WHERE name = 'Linen Shirt'",
          )
          .getSingle();
      expect((p.read<String?>('hsn'), p.read<int?>('gst_bp')), ('6205', 1200));
      final b = await db
          .customSelect(
            "SELECT supplier_gstin, invoice_no, input_tax_paise FROM batches WHERE supplier = 'S' ORDER BY rowid DESC LIMIT 1",
          )
          .getSingle();
      expect(b.read<String>('supplier_gstin'), '27ABCDE1234F1Z5');
      expect(b.read<String>('invoice_no'), 'INV/17');
      expect(b.read<int>('input_tax_paise'), 150000);
    });

    test('a manager cannot set a style rate at stock entry', () async {
      await expectLater(
        stock.receivePurchase(
          role: Role.manager,
          draft: PurchaseDraft(
            supplier: 'S',
            style: 'Cotton Kurta',
            styleGstBp: 1200,
            lines: [
              PurchaseLine(
                size: 'L',
                color: 'Blue',
                quantity: 1,
                cost: Money(1),
                mrp: Money(2),
              ),
            ],
          ),
        ),
        throwsA(isA<PermissionDenied>()),
      );
    });

    test('a purchase without GST details leaves the style as it was', () async {
      final id = await styleId('Cotton Kurta');
      await gst.setStyleGst(
        role: Role.owner,
        actorId: 'o',
        styleId: id,
        hsn: '6109',
        changeRate: true,
        rateBp: 1200,
      );
      await stock.receivePurchase(
        role: Role.owner,
        draft: PurchaseDraft(
          supplier: 'S',
          style: 'Cotton Kurta',
          lines: [
            PurchaseLine(
              size: 'L',
              color: 'Blue',
              quantity: 1,
              cost: Money(1),
              mrp: Money(2),
            ),
          ],
        ),
      );
      final s = (await gst.styles(role: Role.owner)).first;
      expect((s.hsn, s.rateBp), ('6109', 1200));
    });

    test('a bad HSN or supplier GSTIN stops the purchase', () async {
      await expectLater(
        stock.receivePurchase(
          role: Role.owner,
          draft: PurchaseDraft(
            supplier: 'S',
            style: 'X',
            hsn: '12',
            supplierGstin: 'nope',
            lines: [
              PurchaseLine(
                size: 'M',
                color: 'Blue',
                quantity: 1,
                cost: Money(1),
                mrp: Money(2),
              ),
            ],
          ),
        ),
        throwsA(isA<InvalidPurchase>()),
      );
    });

    test('a bill uses the style rate, keeps the HSN, and an unchanged style keeps the shop rate', () async {
      await gst.setStyleGst(
        role: Role.owner,
        actorId: 'o',
        styleId: await styleId('Cotton Kurta'),
        hsn: '6109',
        changeRate: true,
        rateBp: 1200,
      );
      await save(good());
      await sell([kurta[0], jeans[0]], 179800);
      final rows = await db
          .customSelect(
            'SELECT hsn, gst_bp, tax_paise FROM bill_lines ORDER BY rowid',
          )
          .get();
      expect(rows[0].read<String>('hsn'), '6109');
      expect(rows[0].read<int>('gst_bp'), 1200);
      expect(
        rows[0].read<int>('tax_paise'),
        49900 - (49900 * 10000 * 2 + 11200) ~/ (11200 * 2),
      );
      expect(rows[1].read<String>('hsn'), '');
      expect(rows[1].read<int>('gst_bp'), 500);
    });

    test(
      'changing the style code later does not change a bill already made',
      () async {
        final id = await styleId('Cotton Kurta');
        await gst.setStyleGst(
          role: Role.owner,
          actorId: 'o',
          styleId: id,
          hsn: '6109',
          changeRate: true,
          rateBp: 1200,
        );
        await save(good());
        await sell([kurta[0]], 49900);
        await gst.setStyleGst(
          role: Role.owner,
          actorId: 'o',
          styleId: id,
          hsn: '6110',
          changeRate: true,
          rateBp: 500,
        );
        final r = await db
            .customSelect('SELECT hsn, gst_bp FROM bill_lines')
            .getSingle();
        expect((r.read<String>('hsn'), r.read<int>('gst_bp')), ('6109', 1200));
      },
    );

    test('with GST off no HSN is kept on the bill', () async {
      await gst.setStyleGst(
        role: Role.owner,
        actorId: 'o',
        styleId: await styleId('Cotton Kurta'),
        hsn: '6109',
      );
      await sell([kurta[0]], 49900);
      expect(
        (await db.customSelect('SELECT hsn FROM bill_lines').getSingle())
            .read<String>('hsn'),
        '',
      );
    });

    test('a style with its own rate of zero carries no tax', () async {
      await gst.setStyleGst(
        role: Role.owner,
        actorId: 'o',
        styleId: await styleId('Cotton Kurta'),
        hsn: '',
        changeRate: true,
        rateBp: 0,
      );
      await save(good());
      final bill = await sell([kurta[0]], 49900);
      expect(bill.tax.totalTax, Money.zero);
    });
  });

  group('a business customer GSTIN on a bill', () {
    Future<SavedBill> sellTo(String? gstin, {int pay = 49900}) =>
        sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [BillLineInput(kurta[0])],
          payments: [Payment(PaymentMode.cash, Money(pay))],
          customerGstin: gstin,
        );

    test('is kept in capitals while GST is on', () async {
      await save(good());
      final bill = await sellTo(' 29abcde1234f1z5 ');
      expect(bill.customerGstin, '29ABCDE1234F1Z5');
      expect(
        (await db.customSelect('SELECT customer_gstin FROM bills').getSingle())
            .read<String>('customer_gstin'),
        '29ABCDE1234F1Z5',
      );
    });

    test('is not kept while GST is off', () async {
      final bill = await sellTo('29ABCDE1234F1Z5');
      expect(bill.customerGstin, isNull);
      expect(
        (await db.customSelect('SELECT customer_gstin FROM bills').getSingle())
            .read<String?>('customer_gstin'),
        isNull,
      );
    });

    test(
      'a GSTIN that is not the right shape stops the bill; blank is fine',
      () async {
        await save(good());
        await expectLater(sellTo('nope'), throwsA(isA<InvalidBill>()));
        expect(
          (await db.customSelect('SELECT COUNT(*) AS c FROM bills').getSingle())
              .read<int>('c'),
          0,
        );
        expect((await sellTo('  ')).customerGstin, isNull);
      },
    );
  });

  group('never reads cost', () {
    test('the GST code does not touch cost', () {
      final text = File('lib/data/gst_repository.dart').readAsStringSync();
      expect(text.contains('batch_lines'), isFalse);
      expect(text.contains('unit_cost'), isFalse);
    });
  });
}
