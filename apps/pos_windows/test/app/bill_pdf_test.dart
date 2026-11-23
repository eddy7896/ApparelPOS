// The text on the bill, worked out exactly, and a PDF that builds. P2-4c.
import 'dart:convert';
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/app/bill_pdf.dart';
import 'package:pos_windows/app/label_printer.dart';
import 'package:pos_windows/data/sales_repository.dart';

SavedBill bill({
  List<SavedBillLine>? lines,
  required Settlement settlement,
  DateTime? at,
  Money owed = Money.zero,
}) => SavedBill(
  billId: 'b1',
  billNumber: BillNumber(yearLabel: '2026-27', counterNo: 1, serial: 7),
  billedAt: at ?? DateTime.utc(2026, 11, 20, 10, 0),
  lines:
      lines ??
      [
        SavedBillLine(
          barcode: '000000000011',
          productName: 'Cotton Kurta',
          size: 'M',
          color: 'Blue',
          priced: priceLine(
            mrp: Money(49900),
            cashierDiscount: PriceCut.percentBp(1000),
          ),
        ),
        SavedBillLine(
          barcode: '000000000028',
          productName: 'Denim Jeans',
          size: 'L',
          color: 'Black',
          priced: priceLine(mrp: Money(149900)),
        ),
      ],
  settlement: settlement,
  owed: owed,
);

void main() {
  final fonts = LabelFonts(
    regular: File('assets/fonts/NotoSans-Regular.ttf').readAsBytesSync(),
    bold: File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync(),
  );

  group('describeBill', () {
    final settlement = settle(Money(194810), [
      Payment(PaymentMode.upi, Money(94810)),
      Payment(PaymentMode.cash, Money(110000)),
    ]);
    final sheet = describeBill(
      bill: bill(settlement: settlement),
      shopName: 'Sample Apparel',
      operatorCode: 'OP001',
      customerName: ' Ravi ',
      customerPhone: '9876543210',
    );
    test('header lines', () {
      expect(sheet.shopName, 'Sample Apparel');
      expect(sheet.billNo, '2026-27/C1/000007');
      expect(sheet.dateText, '20-11-2026 15:30'); // India time
      expect(sheet.operatorCode, 'OP001');
      expect(sheet.customer, 'Ravi, 9876543210');
    });
    test(
      'the header says who served by operator ID, and no name is printed',
      () {
        final lines = billHeaderLines(sheet);
        expect(lines, contains('Served by: OP001'));
        expect(lines.any((l) => l.contains('Asha')), isFalse);
        expect(lines.any((l) => l.toLowerCase().contains('cashier')), isFalse);
        expect(lines, contains('Bill no: 2026-27/C1/000007'));
        expect(lines, contains('Customer: Ravi, 9876543210'));
      },
    );
    test('rows show MRP, what came off, and the price', () {
      expect(sheet.rows[0].description, 'Cotton Kurta M Blue');
      expect(sheet.rows[0].mrp, '₹499.00');
      expect(sheet.rows[0].off, '-₹49.90');
      expect(sheet.rows[0].price, '₹449.10');
      expect(sheet.rows[1].off, '');
      expect(sheet.rows[1].price, '₹1,499.00');
    });
    test('total, payments and change', () {
      expect(sheet.totalText, '₹1,948.10');
      expect(sheet.payments, ['Cash ₹1,000.00', 'UPI ₹948.10']);
      expect(sheet.changeText, '₹100.00');
    });
    test('no customer, no change, no shop name', () {
      final s = describeBill(
        bill: bill(
          settlement: settle(Money(194810), [
            Payment(PaymentMode.card, Money(194810)),
          ]),
        ),
        shopName: null,
        operatorCode: 'OP001',
      );
      expect(s.customer, isNull);
      expect(s.changeText, isNull);
      expect(s.shopName, isNull);
    });
    test('a credit note payment is named', () {
      final s = describeBill(
        bill: bill(
          settlement: settle(Money(194810), [
            Payment(PaymentMode.creditNote, Money(100000)),
            Payment(PaymentMode.cash, Money(94810)),
          ]),
        ),
        shopName: null,
        operatorCode: 'OP001',
      );
      expect(s.payments, ['Cash ₹948.10', 'Credit note ₹1,000.00']);
    });
    test('the date rolls over at India midnight', () {
      expect(
        billDateText(DateTime.utc(2026, 12, 31, 18, 30)),
        '01-01-2027 00:00',
      );
    });
  });

  group('a bill left to be paid later', () {
    // 1,948.10 bill: 500.00 paid now, 1,448.10 left
    final part = settle(Money(194810), [
      Payment(PaymentMode.cash, Money(50000)),
    ]);
    test('says what is still to be paid, and a paid bill says nothing', () {
      final later = describeBill(
        bill: bill(settlement: part, owed: part.due),
        shopName: 'Sample Apparel',
        operatorCode: 'OP001',
        customerName: 'Ravi',
        customerPhone: '9876543210',
      );
      expect(later.balanceDueText, '₹1,448.10');
      expect(later.payments, ['Cash ₹500.00']);
      expect(later.totalText, '₹1,948.10');
      final paid = describeBill(
        bill: bill(
          settlement: settle(Money(194810), [
            Payment(PaymentMode.cash, Money(194810)),
          ]),
        ),
        shopName: 'Sample Apparel',
        operatorCode: 'OP001',
      );
      expect(paid.balanceDueText, isNull);
    });
    test('nothing paid now still prints', () async {
      final none = settle(Money(194810), const []);
      final sheet = describeBill(
        bill: bill(settlement: none, owed: none.due),
        shopName: 'Sample Apparel',
        operatorCode: 'OP001',
        customerName: 'Ravi',
        customerPhone: '9876543210',
      );
      expect(sheet.payments, isEmpty);
      expect(sheet.balanceDueText, '₹1,948.10');
      final bytes = await buildBillPdf(sheet, fonts);
      expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
    });
  });

  group('a GST invoice (P3-4, unverified until the CA confirms)', () {
    final priced = [
      priceLine(
        mrp: Money(49900),
        cashierDiscount: PriceCut.percentBp(1000),
      ), // 449.10
      priceLine(mrp: Money(149900)),
    ];

    SavedBill gstBill(GstSettings g, List<Payment> pay) {
      final t = billTax([for (final p in priced) p.finalPrice], g);
      final st = settle(t.total, pay);
      return SavedBill(
        billId: 'b1',
        billNumber: BillNumber(yearLabel: '2026-27', counterNo: 1, serial: 7),
        billedAt: DateTime.utc(2026, 11, 20, 10),
        lines: [
          for (var i = 0; i < priced.length; i++)
            SavedBillLine(
              barcode: '00000000001$i',
              productName: i == 0 ? 'Cotton Kurta' : 'Denim Jeans',
              size: 'M',
              color: 'Blue',
              priced: priced[i],
              tax: t.lines[i],
            ),
        ],
        settlement: st,
        gst: g,
      );
    }

    final base = GstSettings(
      enabled: true,
      gstin: '27ABCDE1234F1Z5',
      address: '12 Market Road, Pune',
      fields: GstInvoiceField.values.toSet(),
    );

    test('with everything switched on: title, address, GSTIN, tax columns and totals', () {
      final b = gstBill(base, [Payment(PaymentMode.cash, Money(194900))]);
      final sheet = describeBill(
        bill: b,
        shopName: 'Sample Apparel',
        operatorCode: 'OP001',
        customerName: 'Ravi',
        customerPhone: '9876543210',
      );
      expect(sheet.title, 'TAX INVOICE');
      expect(sheet.topLines, [
        '12 Market Road, Pune',
        'GSTIN: 27ABCDE1234F1Z5',
      ]);
      expect(billHeaderLines(sheet).take(2), sheet.topLines);
      expect(
        sheet.showTaxable &&
            sheet.showRate &&
            sheet.showTax &&
            sheet.showMrp &&
            sheet.showOff,
        isTrue,
      );
      // 449.10 + 1,499.00 = 1,948.10 including 5% tax
      expect(sheet.totalText, '₹1,948.10');
      final r0 = sheet.rows.first;
      expect(r0.price, '₹449.10');
      expect(r0.rate, '5%');
      expect(r0.taxable, '₹427.71'); // 449.10 / 1.05 = 427.714...
      expect(r0.tax, '₹21.39');
      expect(sheet.taxLines, [
        'Taxable value ₹1,855.33',
        startsWith('CGST '),
        startsWith('SGST '),
        'Total tax ₹92.77',
      ]);
      expect(
        sheet.wordsLine,
        'Rupees One Thousand Nine Hundred Forty-Eight and Ten Paise Only',
      );
      expect(sheet.termsLine, contains('7 days'));
      expect(sheet.signatureLine, isTrue);
      expect(sheet.customer, 'Ravi, 9876543210');
    });

    test('a field switched off is not printed', () {
      final g = base.copyWith(
        fields: {
          GstInvoiceField.shopGstin,
          GstInvoiceField.totalTax,
          GstInvoiceField.discount,
        },
      );
      final sheet = describeBill(
        bill: gstBill(g, [Payment(PaymentMode.cash, Money(194900))]),
        shopName: 'Sample Apparel',
        operatorCode: 'OP001',
        customerName: 'Ravi',
        customerPhone: '9876543210',
      );
      expect(sheet.topLines, ['GSTIN: 27ABCDE1234F1Z5']);
      expect(
        sheet.showTaxable || sheet.showRate || sheet.showTax || sheet.showMrp,
        isFalse,
      );
      expect(sheet.rows.first.taxable, '');
      expect(sheet.taxLines, ['Total tax ₹92.77']);
      expect(sheet.wordsLine, isNull);
      expect(sheet.termsLine, isNull);
      expect(sheet.signatureLine, isFalse);
      expect(sheet.customer, isNull);
      expect(sheet.payments, isEmpty);
      expect(sheet.showServedBy, isFalse);
      expect(
        billHeaderLines(sheet).any((l) => l.startsWith('Served by')),
        isFalse,
      );
    });

    test(
      'tax added on top: each garment shows what it came to with the tax',
      () {
        final g = base.copyWith(mode: GstMode.exclusive);
        final b = gstBill(g, [Payment(PaymentMode.cash, Money(204600))]);
        final sheet = describeBill(
          bill: b,
          shopName: 'S',
          operatorCode: 'OP001',
        );
        // 1,948.10 plus 5% = 2,045.51 (49.10 + ... per item)
        expect(b.total, b.tax.total);
        expect(sheet.totalText, formatRupees(b.total));
        expect(sheet.rows.first.price, formatRupees(b.tax.lines.first.paid));
        expect(
          b.tax.lines.fold<int>(0, (a, l) => a + l.paid.paise),
          b.total.paise,
        );
      },
    );

    test('a bill made with GST off keeps the plain look', () {
      final sheet = describeBill(
        bill: gstBill(const GstSettings(), [
          Payment(PaymentMode.cash, Money(194810)),
        ]),
        shopName: 'S',
        operatorCode: 'OP001',
        customerName: 'Ravi',
      );
      expect(sheet.title, isNull);
      expect(sheet.topLines, isEmpty);
      expect(sheet.taxLines, isEmpty);
      expect(sheet.wordsLine, isNull);
      expect(sheet.showOff && sheet.showMrp, isTrue);
      expect(sheet.showTaxable || sheet.showRate || sheet.showTax, isFalse);
      expect(sheet.showServedBy, isTrue);
      expect(sheet.customer, 'Ravi');
      expect(sheet.payments, ['Cash ₹1,948.10']);
    });

    test('the PDF builds, with and without the tax columns', () async {
      for (final g in [
        base,
        base.copyWith(fields: {GstInvoiceField.shopGstin}),
      ]) {
        final sheet = describeBill(
          bill: gstBill(g, [Payment(PaymentMode.cash, Money(194900))]),
          shopName: 'Sample Apparel',
          operatorCode: 'OP001',
        );
        final bytes = await buildBillPdf(sheet, fonts);
        expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
      }
    });
  });

  group('buildBillPdf', () {
    final settlement = settle(Money(194810), [
      Payment(PaymentMode.cash, Money(194810)),
    ]);
    test('makes a one-page PDF', () async {
      final sheet = describeBill(
        bill: bill(settlement: settlement),
        shopName: 'Sample Apparel',
        operatorCode: 'OP001',
      );
      final bytes = await buildBillPdf(sheet, fonts);
      expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
      expect(
        RegExp(r'/Type\s*/Page(?![a-z])')
            .allMatches(latin1.decode(bytes))
            .length,
        1,
      );
    });
    test('many garments flow onto more pages', () async {
      final many = [
        for (var i = 0; i < 80; i++)
          SavedBillLine(
            barcode: '000000000011',
            productName: 'Cotton Kurta',
            size: 'M',
            color: 'Blue',
            priced: priceLine(mrp: Money(49900)),
          ),
      ];
      final s = settle(Money(49900 * 80), [
        Payment(PaymentMode.cash, Money(49900 * 80)),
      ]);
      final sheet = describeBill(
        bill: bill(lines: many, settlement: s),
        shopName: 'Sample Apparel',
        operatorCode: 'OP001',
      );
      final bytes = await buildBillPdf(sheet, fonts);
      expect(
        RegExp(r'/Type\s*/Page(?![a-z])')
            .allMatches(latin1.decode(bytes))
            .length,
        greaterThan(1),
      );
    });
  });
}
