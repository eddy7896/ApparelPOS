// GST reports for the CA (P3-4 second step): invoice register, returns register,
// tax by rate and by day, CSV text. UNVERIFIED until the CA confirms the
// columns; these tests pin what the code does.
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/gst_repository.dart';
import 'package:pos_windows/data/gst_report_repository.dart';
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
  late GstReportRepository reports;
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
    reports = GstReportRepository(db);
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

  Future<SavedBill> sell(List<String> barcodes, int pay, {String? customer}) =>
      sales.saveBill(
        role: Role.cashier,
        cashierId: 'cashier-1',
        lines: [for (final b in barcodes) BillLineInput(b)],
        payments: [Payment(PaymentMode.cash, Money(pay))],
        customerName: customer,
      );

  Future<GstReport> report(
    ShopDay from,
    ShopDay to, {
    Role? role = Role.owner,
  }) => reports.report(role: role, from: from, to: to);

  final d23 = ShopDay(2026, 11, 23);
  final d24 = ShopDay(2026, 11, 24);
  final d25 = ShopDay(2026, 11, 25);

  group('with GST off', () {
    test('nothing is in the registers; the bills are counted', () async {
      await sell([kurta[0]], 49900);
      final r = await report(d23, d23);
      expect(r.invoices, isEmpty);
      expect(r.returns, isEmpty);
      expect(r.byRate, isEmpty);
      expect(r.byDay, isEmpty);
      expect(r.billsWithoutGst, 1);
      expect(r.tax, Money.zero);
    });
  });

  group('the registers', () {
    test('an invoice with its taxable value, CGST, SGST and total', () async {
      await save(good());
      await sell([kurta[0], jeans[0]], 179800, customer: 'Ravi Kumar');
      final r = await report(d23, d23);
      final i = r.invoices.single;
      expect(i.billNo, '2026-27/C1/000001');
      expect(i.day.compareTo(d23), 0);
      expect(i.customer, 'Ravi Kumar');
      expect(i.rateBp, 500);
      expect(i.taxable, Money(47524 + 123714)); // 499.00 and 1,299.00 at 5%
      expect(i.tax, Money(2376 + 6186));
      expect(i.cgst + i.sgst, i.tax);
      expect(i.total, Money(179800));
      expect(r.taxable, i.taxable);
      expect(r.tax, i.tax);
      expect(r.billsWithoutGst, 0);
    });

    test('an odd paisa of tax goes to CGST, the same as on the bill', () async {
      await save(good());
      await sales.saveBill(
        role: Role.cashier,
        cashierId: 'cashier-1',
        lines: [BillLineInput(kurta[0], discount: PriceCut.percentBp(1000))],
        payments: [Payment(PaymentMode.cash, Money(44910))],
      );
      final i = (await report(d23, d23)).invoices.single;
      expect(i.tax, Money(2139));
      expect(i.cgst, Money(1070));
      expect(i.sgst, Money(1069));
    });

    test('tax on top: the invoice total includes the tax', () async {
      await save(good(mode: GstMode.exclusive));
      await sell([kurta[0]], 52395);
      final i = (await report(d23, d23)).invoices.single;
      expect(i.taxable, Money(49900));
      expect(i.tax, Money(2495));
      expect(i.total, Money(52395));
    });

    test('a bill made with GST off is counted, not listed', () async {
      await sell([kurta[0]], 49900);
      await save(good());
      await sell([kurta[1]], 49900);
      final r = await report(d23, d23);
      expect(r.invoices.length, 1);
      expect(r.invoices.single.billNo, endsWith('000002'));
      expect(r.billsWithoutGst, 1);
    });

    test('a customer name is empty when none was given', () async {
      await save(good());
      await sell([kurta[0]], 49900);
      expect((await report(d23, d23)).invoices.single.customer, '');
    });

    test(
      'the range includes both end days and stops at India midnight',
      () async {
        await save(good());
        now = DateTime.utc(2026, 11, 22, 18, 29); // 23:59 on the 22nd
        await sell([kurta[0]], 49900);
        now = DateTime.utc(2026, 11, 22, 18, 30); // 00:00 on the 23rd
        await sell([kurta[1]], 49900);
        now = DateTime.utc(2026, 11, 23, 18, 29); // 23:59 on the 23rd
        await sell([kurta[2]], 49900);
        now = DateTime.utc(2026, 11, 23, 18, 30); // 00:00 on the 24th
        await sell([kurta[3]], 49900);
        final r = await report(d23, d23);
        expect(r.invoices.map((i) => i.billNo.substring(i.billNo.length - 1)), [
          '2',
          '3',
        ]);
        expect((await report(d23, d24)).invoices.length, 3);
        expect((await report(ShopDay(2026, 11, 22), d24)).invoices.length, 4);
      },
    );
  });

  group('returns', () {
    test(
      'a return of a taxed garment is listed with its tax and refund',
      () async {
        await save(good());
        await sell([kurta[0], kurta[1]], 99800);
        now = DateTime.utc(2026, 11, 24, 6, 30);
        await returns.saveReturn(
          role: Role.cashier,
          cashierId: 'cashier-1',
          items: [ReturnItemInput(kurta[0], ReturnOutcome.restock)],
          refundMode: RefundMode.cash,
        );
        final r = await report(d23, d24);
        final x = r.returns.single;
        expect(x.billNos, '2026-27/C1/000001');
        expect(x.day.compareTo(d24), 0);
        expect(x.tax, Money(2376));
        expect(x.taxable, Money(47524));
        expect(x.refund, Money(49900));
        expect(r.returnedTax, Money(2376));
        expect(r.netTax, Money(2376));
        // the return is not on the earlier day
        expect((await report(d23, d23)).returns, isEmpty);
      },
    );

    test('a return of a garment sold with GST off is not listed', () async {
      await sell([kurta[0]], 49900);
      await save(good());
      await returns.saveReturn(
        role: Role.cashier,
        cashierId: 'cashier-1',
        items: [ReturnItemInput(kurta[0], ReturnOutcome.restock)],
        refundMode: RefundMode.cash,
      );
      expect((await report(d23, d23)).returns, isEmpty);
    });

    test(
      'garments from two bills in one return list both bill numbers',
      () async {
        await save(good());
        await sell([kurta[0]], 49900);
        await sell([kurta[1]], 49900);
        await returns.saveReturn(
          role: Role.cashier,
          cashierId: 'cashier-1',
          items: [
            ReturnItemInput(kurta[0], ReturnOutcome.restock),
            ReturnItemInput(kurta[1], ReturnOutcome.restock),
          ],
          refundMode: RefundMode.cash,
        );
        final x = (await report(d23, d23)).returns.single;
        expect(x.billNos, '2026-27/C1/000001, 2026-27/C1/000002');
        expect(x.tax, Money(2376 * 2));
      },
    );
  });

  group('tax by rate and by day', () {
    test('each rate on its own line, sales less returns', () async {
      await save(good());
      await sell([kurta[0]], 49900);
      await save(good(rateBp: 1200));
      await sell([kurta[1]], 49900);
      await returns.saveReturn(
        role: Role.cashier,
        cashierId: 'cashier-1',
        items: [ReturnItemInput(kurta[1], ReturnOutcome.restock)],
        refundMode: RefundMode.cash,
      );
      final r = await report(d23, d23);
      expect(r.byRate.map((x) => x.rateBp), [500, 1200]);
      expect(r.byRate[0].tax, Money(2376));
      expect(r.byRate[0].returnedTax, Money.zero);
      expect(r.byRate[0].netTax, Money(2376));
      final twelve = r.byRate[1];
      expect(twelve.taxable + twelve.tax, Money(49900));
      expect(twelve.returnedTax, twelve.tax);
      expect(twelve.netTax, Money.zero);
      expect(twelve.netTaxable, Money.zero);
    });

    test(
      'a day-by-day summary with only the days that had something',
      () async {
        await save(good());
        await sell([kurta[0], kurta[1]], 99800);
        now = DateTime.utc(2026, 11, 25, 6, 30);
        await sell([kurta[2]], 49900);
        await returns.saveReturn(
          role: Role.cashier,
          cashierId: 'cashier-1',
          items: [ReturnItemInput(kurta[0], ReturnOutcome.restock)],
          refundMode: RefundMode.cash,
        );
        final r = await report(d23, d25);
        expect(r.byDay.map((d) => shopDayText(d.day)), [
          '23/11/2026',
          '25/11/2026',
        ]);
        expect(r.byDay[0].invoices, 1);
        expect(r.byDay[0].tax, Money(2376 * 2));
        expect(r.byDay[0].returnedTax, Money.zero);
        expect(r.byDay[1].invoices, 1);
        expect(r.byDay[1].tax, Money(2376));
        expect(r.byDay[1].returnedTax, Money(2376));
        expect(r.byDay[1].netTax, Money.zero);
        expect(r.netTax, Money(2376 * 2));
      },
    );
  });

  group('CSV for the CA', () {
    test(
      'the invoice register: a header, then a line for each invoice',
      () async {
        await save(good());
        await sell([kurta[0]], 49900, customer: 'Ravi, Kumar');
        final lines = (await report(d23, d23)).invoicesCsv().split('\r\n');
        expect(
          lines[0],
          'Invoice no,Date,Customer,Customer GSTIN,GST rate,Taxable value,CGST,SGST,Total tax,Invoice total',
        );
        expect(
          lines[1],
          '2026-27/C1/000001,23/11/2026,"Ravi, Kumar",,5%,475.24,11.88,11.88,23.76,499.00',
        );
        expect(lines.length, 2);
      },
    );

    test('the returns register', () async {
      await save(good());
      await sell([kurta[0]], 49900);
      await returns.saveReturn(
        role: Role.cashier,
        cashierId: 'cashier-1',
        items: [ReturnItemInput(kurta[0], ReturnOutcome.restock)],
        refundMode: RefundMode.cash,
      );
      final lines = (await report(d23, d23)).returnsCsv().split('\r\n');
      expect(
        lines[0],
        'Date,Original invoice no,Taxable value returned,CGST returned,SGST returned,Total tax returned,Refund',
      );
      expect(
        lines[1],
        '23/11/2026,2026-27/C1/000001,475.24,11.88,11.88,23.76,499.00',
      );
    });

    test('the summary has the rate block and the day block', () async {
      await save(good());
      await sell([kurta[0]], 49900);
      final lines = (await report(d23, d23)).summaryCsv().split('\r\n');
      expect(
        lines[0],
        'GST rate,Taxable value,Tax,Taxable value returned,Tax returned,Net taxable value,Net tax',
      );
      expect(lines[1], '5%,475.24,23.76,0.00,0.00,475.24,23.76');
      expect(lines[2], '');
      expect(lines[3], 'Date,Invoices,Taxable value,Tax,Tax returned,Net tax');
      expect(lines[4], '23/11/2026,1,475.24,23.76,0.00,23.76');
    });

    test('an empty range still has the header lines', () async {
      final r = await report(d23, d23);
      expect(r.invoicesCsv().split('\r\n').length, 1);
      expect(r.returnsCsv().split('\r\n').length, 1);
    });

    test('a customer name that could run as a formula is defused', () async {
      await save(good());
      await sell([kurta[0]], 49900, customer: '=HYPERLINK("x")');
      expect(
        (await report(d23, d23)).invoicesCsv(),
        contains("\"'=HYPERLINK(\"\"x\"\")\""),
      );
    });
  });

  group('sales by HSN code', () {
    Future<void> hsnOf(String style, String hsn, {int? rate}) async {
      final id =
          (await db
                  .customSelect(
                    'SELECT id FROM products WHERE name = ?',
                    variables: [Variable<String>(style)],
                  )
                  .getSingle())
              .read<String>('id');
      await gst.setStyleGst(
        role: Role.owner,
        actorId: 'o',
        styleId: id,
        hsn: hsn,
        changeRate: rate != null,
        rateBp: rate,
      );
    }

    test('garments, taxable value and tax for each code and rate', () async {
      await hsnOf('Cotton Kurta', '6109');
      await save(good());
      await sell([kurta[0], kurta[1], jeans[0]], 49900 * 2 + 129900);
      final r = await report(d23, d23);
      expect(r.byHsn.map((h) => (h.hsn, h.rateBp, h.quantity)), [
        ('', 500, 1),
        ('6109', 500, 2),
      ]);
      final k = r.byHsn[1];
      expect(k.taxable, Money(47524 * 2));
      expect(k.tax, Money(2376 * 2));
    });

    test('the same code at two rates is two lines', () async {
      await hsnOf('Cotton Kurta', '6109');
      await save(good());
      await sell([kurta[0]], 49900);
      await hsnOf('Cotton Kurta', '6109', rate: 1200);
      await sell([kurta[1]], 49900);
      final r = await report(d23, d23);
      expect(r.byHsn.map((h) => (h.hsn, h.rateBp)), [
        ('6109', 500),
        ('6109', 1200),
      ]);
    });

    test('returns come off the code they were sold under', () async {
      await hsnOf('Cotton Kurta', '6109');
      await save(good());
      await sell([kurta[0], kurta[1]], 99800);
      await returns.saveReturn(
        role: Role.cashier,
        cashierId: 'cashier-1',
        items: [ReturnItemInput(kurta[0], ReturnOutcome.restock)],
        refundMode: RefundMode.cash,
      );
      final h = (await report(d23, d23)).byHsn.single;
      expect((h.quantity, h.returnedQuantity, h.netQuantity), (2, 1, 1));
      expect(h.netTax, Money(2376));
      expect(h.netTaxable, Money(47524));
    });

    test('a code set after the sale does not move the sale', () async {
      await save(good());
      await sell([kurta[0]], 49900);
      await hsnOf('Cotton Kurta', '6109');
      expect((await report(d23, d23)).byHsn.single.hsn, '');
    });

    test('the CSV says No HSN for a style without a code', () async {
      await save(good());
      await sell([kurta[0]], 49900);
      final lines = (await report(d23, d23)).hsnCsv().split('\r\n');
      expect(lines[0], startsWith('HSN code,GST rate,Garments sold'));
      expect(lines[1], 'No HSN,5%,1,475.24,23.76,0,0.00,0.00,475.24,23.76');
    });

    test('no tax, no lines', () async {
      await sell([kurta[0]], 49900);
      expect((await report(d23, d23)).byHsn, isEmpty);
    });
  });

  group('sales to business customers', () {
    Future<void> sellToBusiness(String gstin, {String name = 'Shah Traders'}) =>
        sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [BillLineInput(kurta[0])],
          payments: [Payment(PaymentMode.cash, Money(49900))],
          customerName: name,
          customerGstin: gstin,
        );

    test('only invoices with a customer GSTIN, with the GSTIN', () async {
      await save(good());
      await sell([kurta[1]], 49900);
      await sellToBusiness('29abcde1234f1z5');
      final r = await report(d23, d23);
      expect(r.invoices.length, 2);
      expect(r.businessInvoices.length, 1);
      final b = r.businessInvoices.single;
      expect(b.customerGstin, '29ABCDE1234F1Z5');
      expect(b.customer, 'Shah Traders');
    });

    test('its CSV and the invoice register carry the GSTIN', () async {
      await save(good());
      await sellToBusiness('29ABCDE1234F1Z5');
      final r = await report(d23, d23);
      final lines = r.businessCsv().split('\r\n');
      expect(
        lines[0],
        'Customer GSTIN,Customer,Invoice no,Date,Taxable value,CGST,SGST,Invoice total',
      );
      expect(
        lines[1],
        '29ABCDE1234F1Z5,Shah Traders,2026-27/C1/000001,23/11/2026,475.24,11.88,11.88,499.00',
      );
      expect(r.invoicesCsv(), contains('29ABCDE1234F1Z5'));
    });

    test('none at all gives just the header', () async {
      await save(good());
      await sell([kurta[0]], 49900);
      final r = await report(d23, d23);
      expect(r.businessInvoices, isEmpty);
      expect(r.businessCsv().split('\r\n').length, 1);
    });
  });

  group('purchases and input tax', () {
    Future<void> buy({
      String supplier = 'Sharma Textiles',
      String gstin = '27ABCDE1234F1Z5',
      String invoice = 'INV/17',
      int tax = 150000,
      int cost = 100000,
      String style = 'Linen Shirt',
      Role role = Role.owner,
    }) => stock.receivePurchase(
      role: role,
      draft: PurchaseDraft(
        supplier: supplier,
        style: style,
        supplierGstin: gstin,
        invoiceNo: invoice,
        inputTax: Money(tax),
        lines: [
          PurchaseLine(
            size: 'M',
            color: 'White',
            quantity: 3,
            cost: Money(cost),
            mrp: Money(cost * 2),
          ),
        ],
      ),
    );

    test(
      'lists each purchase with its supplier, invoice, goods value and tax',
      () async {
        await buy();
        final r = await report(d23, d23);
        final p = r.purchases.last;
        expect(p.supplier, 'Sharma Textiles');
        expect(p.supplierGstin, '27ABCDE1234F1Z5');
        expect(p.invoiceNo, 'INV/17');
        expect(p.inputTax, Money(150000));
        expect(p.goodsValue, Money(300000)); // 3 x 1,000.00
        expect(p.day.compareTo(d23), 0);
      },
    );

    test('totals the input tax and what is left after it', () async {
      await save(good());
      await sell([kurta[0]], 49900);
      final before = (await report(d23, d23)).inputTax;
      await buy(tax: 1000);
      await buy(tax: 2500, style: 'Silk Saree');
      final r = await report(d23, d23);
      expect(r.inputTax, before + Money(3500));
      expect(r.netTaxAfterInput, Money(2376) - r.inputTax);
    });

    test('a purchase outside the range is left out', () async {
      await buy();
      expect((await report(d24, d25)).purchases, isEmpty);
    });

    test('the CSV has the header and a line each', () async {
      await buy();
      final lines = (await report(d23, d23)).purchasesCsv().split('\r\n');
      expect(
        lines[0],
        'Date,Supplier,Supplier GSTIN,Supplier invoice no,Goods value,Input tax',
      );
      expect(
        lines.last,
        '23/11/2026,Sharma Textiles,27ABCDE1234F1Z5,INV/17,3000.00,1500.00',
      );
    });

    test('a purchase with no GST details still appears, with no tax', () async {
      await buy(gstin: '', invoice: '', tax: 0);
      final p = (await report(d23, d23)).purchases.last;
      expect((p.supplierGstin, p.invoiceNo, p.inputTax), ('', '', Money.zero));
    });
  });

  group('who may read it', () {
    test('manager and owner; a cashier and nobody are refused', () async {
      await report(d23, d23, role: Role.manager);
      await report(d23, d23, role: Role.owner);
      for (final role in [Role.cashier, null]) {
        await expectLater(
          report(d23, d23, role: role),
          throwsA(isA<PermissionDenied>()),
        );
      }
    });

    test('the last day before the first is refused', () async {
      await expectLater(report(d24, d23), throwsArgumentError);
    });

    test('the goods value of a purchase (cost) is read only after the cost permission check', () {
      final text = File('lib/data/gst_report_repository.dart')
          .readAsStringSync();
      expect(text, contains('can(role, Permission.viewCost)'));
      expect(RegExp('batch_lines').allMatches(text).length, 1);
    });
  });
}
