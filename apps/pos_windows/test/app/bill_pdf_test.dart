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
