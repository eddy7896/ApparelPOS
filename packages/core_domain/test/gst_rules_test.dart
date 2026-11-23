// GST (P3-4). Every rule here is UNVERIFIED until the CA confirms it (E-GST-1);
// these tests pin what the code does so a change cannot slip in unseen.
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  gstOwnRateTests();
  GstSettings on({
    GstMode mode = GstMode.inclusive,
    GstRounding rounding = GstRounding.perItem,
    int rateBp = 500,
  }) => GstSettings(
    enabled: true,
    mode: mode,
    rounding: rounding,
    rateBp: rateBp,
  );

  group('defaults', () {
    test('GST is off, 5%, inclusive, per item', () {
      const s = GstSettings();
      expect(s.enabled, isFalse);
      expect(s.rateBp, 500);
      expect(s.mode, GstMode.inclusive);
      expect(s.rounding, GstRounding.perItem);
      expect(defaultGstRateBp, 500);
    });
    test('the first fields switched on are the tax basics', () {
      const s = GstSettings();
      expect(s.prints(GstInvoiceField.shopGstin), isTrue);
      expect(s.prints(GstInvoiceField.taxableValue), isTrue);
      expect(s.prints(GstInvoiceField.cgstSgst), isTrue);
      expect(s.prints(GstInvoiceField.amountInWords), isFalse);
      expect(s.prints(GstInvoiceField.signatureLine), isFalse);
    });
    test('each field has its own stored key and words', () {
      final keys = GstInvoiceField.values.map((f) => f.key).toSet();
      expect(keys.length, GstInvoiceField.values.length);
      for (final f in GstInvoiceField.values) {
        expect(f.label, isNotEmpty);
      }
    });
    test('modes and rounding read back from the stored text', () {
      expect(GstMode.fromDb('exclusive'), GstMode.exclusive);
      expect(GstMode.fromDb('inclusive'), GstMode.inclusive);
      expect(GstMode.fromDb('x'), isNull);
      expect(GstMode.fromDb(null), isNull);
      expect(GstRounding.fromDb('bill'), GstRounding.perBill);
      expect(GstRounding.fromDb('item'), GstRounding.perItem);
      expect(GstRounding.fromDb('x'), isNull);
    });
    test('copyWith changes only what it is given', () {
      final s = const GstSettings().copyWith(enabled: true, rateBp: 1200);
      expect(s.enabled, isTrue);
      expect(s.rateBp, 1200);
      expect(s.mode, GstMode.inclusive);
      expect(const GstSettings().copyWith().enabled, isFalse);
    });
  });

  group('GST off', () {
    test('no tax is worked out and nothing is added', () {
      final t = billTax([Money(49900), Money(129900)], const GstSettings());
      expect(t.totalTax, Money.zero);
      expect(t.addedOnTop, Money.zero);
      expect(t.total, Money(179800));
      expect(t.lines.first.rateBp, 0);
      expect(t.lines.first.taxable, Money.zero);
    });
    test('a rate of zero with GST on is the same as off', () {
      final t = billTax([Money(49900)], on(rateBp: 0));
      expect(t.totalTax, Money.zero);
      expect(t.total, Money(49900));
    });
  });

  group('tax included in the price', () {
    test('1,050.00 at 5%: 1,000.00 and 50.00 tax, split 25.00 and 25.00', () {
      final l = billTax([Money(105000)], on()).lines.single;
      expect(l.taxable, Money(100000));
      expect(l.tax, Money(5000));
      expect(l.cgst, Money(2500));
      expect(l.sgst, Money(2500));
      expect(l.addedOnTop, Money.zero);
      expect(l.paid, Money(105000));
      expect(l.rateBp, 500);
    });
    test('499.00 at 5% rounds half up to whole paise', () {
      final l = billTax([Money(49900)], on()).lines.single;
      expect(l.taxable, Money(47524)); // 475.238...
      expect(l.tax, Money(2376));
      expect(l.taxable + l.tax, Money(49900));
      expect(l.cgst + l.sgst, l.tax);
    });
    test('an odd tax paise goes to CGST, so the two add up exactly', () {
      final l = billTax([Money(49800)], on()).lines.single;
      expect(l.tax, Money(2371));
      expect(l.cgst, Money(1186));
      expect(l.sgst, Money(1185));
    });
    test('the total does not change: the price already had the tax', () {
      final t = billTax([Money(49900), Money(129900)], on());
      expect(t.total, Money(179800));
      expect(t.addedOnTop, Money.zero);
      expect(t.totalTaxable + t.totalTax, Money(179800));
    });
  });

  group('tax added on top', () {
    test('499.00 at 5% adds 24.95', () {
      final l = billTax([
        Money(49900),
      ], on(mode: GstMode.exclusive)).lines.single;
      expect(l.taxable, Money(49900));
      expect(l.tax, Money(2495));
      expect(l.addedOnTop, Money(2495));
      expect(l.paid, Money(52395));
    });
    test('half a paisa rounds up', () {
      final l = billTax([Money(10)], on(mode: GstMode.exclusive)).lines.single;
      expect(l.tax, Money(1)); // 0.5
    });
    test('the bill total is the prices plus the tax', () {
      final t = billTax([
        Money(49900),
        Money(129900),
      ], on(mode: GstMode.exclusive));
      expect(t.totalTax, Money(2495 + 6495));
      expect(t.addedOnTop, t.totalTax);
      expect(t.total, Money(179800 + 2495 + 6495));
    });
    test('another rate works the same way', () {
      final l = billTax([
        Money(100000),
      ], on(mode: GstMode.exclusive, rateBp: 1200)).lines.single;
      expect(l.tax, Money(12000));
    });
  });

  group('rounding per item or per bill', () {
    final three = [Money(10), Money(10), Money(10)];
    test('per item: each garment rounds on its own', () {
      final t = billTax(three, on(mode: GstMode.exclusive));
      expect(t.lines.map((l) => l.tax.paise), [1, 1, 1]);
      expect(t.totalTax, Money(3));
    });
    test('per bill: one tax on the total, shared out in whole paise', () {
      final t = billTax(
        three,
        on(mode: GstMode.exclusive, rounding: GstRounding.perBill),
      );
      expect(t.totalTax, Money(2)); // 30 paise at 5% = 1.5
      expect(t.lines.map((l) => l.tax.paise), [1, 1, 0]);
    });
    test('per bill the shares always add up to the one tax', () {
      final prices = [Money(49900), Money(129900), Money(33333), Money(1)];
      for (final mode in GstMode.values) {
        final t = billTax(
          prices,
          on(mode: mode, rounding: GstRounding.perBill),
        );
        final base = prices.fold<int>(0, (a, p) => a + p.paise);
        final expected = mode == GstMode.exclusive
            ? Money(base).percentBp(500)
            : Money(base - ((base * 10000 * 2 + 10500) ~/ (10500 * 2)));
        expect(t.totalTax, expected, reason: '$mode');
      }
    });
    test('per bill inclusive: taxable plus tax is still each price', () {
      final prices = [Money(49900), Money(129900)];
      final t = billTax(prices, on(rounding: GstRounding.perBill));
      for (var i = 0; i < prices.length; i++) {
        expect(t.lines[i].taxable + t.lines[i].tax, prices[i]);
      }
      expect(t.total, Money(179800));
    });
    test('a free garment carries no tax either way', () {
      for (final r in GstRounding.values) {
        final t = billTax([
          Money.zero,
          Money(49900),
        ], on(rounding: r, mode: GstMode.exclusive));
        expect(t.lines.first.tax, Money.zero);
      }
    });
    test('a bill of only free garments has no tax', () {
      final t = billTax([
        Money.zero,
        Money.zero,
      ], on(rounding: GstRounding.perBill));
      expect(t.totalTax, Money.zero);
    });
    test('an empty bill has nothing', () {
      expect(billTax(const [], on()).total, Money.zero);
    });
    test('a negative price is refused', () {
      expect(() => billTax([Money(-1)], on()), throwsArgumentError);
    });
  });

  group('amountInWords', () {
    test('zero and small amounts', () {
      expect(amountInWords(Money.zero), 'Rupees Zero Only');
      expect(amountInWords(Money(1)), 'Rupees Zero and One Paise Only');
      expect(amountInWords(Money(1900)), 'Rupees Nineteen Only');
      expect(amountInWords(Money(2000)), 'Rupees Twenty Only');
      expect(amountInWords(Money(2100)), 'Rupees Twenty-One Only');
      expect(amountInWords(Money(10000)), 'Rupees One Hundred Only');
      expect(amountInWords(Money(10100)), 'Rupees One Hundred One Only');
    });
    test('rupees and paise', () {
      expect(
        amountInWords(Money(149850)),
        'Rupees One Thousand Four Hundred Ninety-Eight and Fifty Paise Only',
      );
      expect(
        amountInWords(Money(49905)),
        'Rupees Four Hundred Ninety-Nine and Five Paise Only',
      );
    });
    test('thousand, lakh and crore the Indian way', () {
      expect(amountInWords(Money(100000)), 'Rupees One Thousand Only');
      expect(amountInWords(Money(10000000)), 'Rupees One Lakh Only');
      expect(amountInWords(Money(1000000000)), 'Rupees One Crore Only');
      expect(
        amountInWords(Money(1234567890)),
        'Rupees One Crore Twenty-Three Lakh Forty-Five Thousand Six Hundred Seventy-Eight and Ninety Paise Only',
      );
      expect(
        amountInWords(Money(9999999999)),
        startsWith('Rupees Nine Crore Ninety-Nine Lakh'),
      );
      expect(amountInWords(Money(1000100)), 'Rupees Ten Thousand One Only');
    });
    test('a negative amount is refused', () {
      expect(() => amountInWords(Money(-1)), throwsArgumentError);
    });
  });

  group('GSTIN and setup', () {
    test('a GSTIN-shaped text', () {
      expect(isGstinShaped('27ABCDE1234F1Z5'), isTrue);
      expect(isGstinShaped(' 27abcde1234f1z5 '), isTrue);
      expect(isGstinShaped('27ABCDE1234F1Y5'), isFalse); // 14th must be Z
      expect(isGstinShaped('27ABCDE1234F1Z'), isFalse);
      expect(isGstinShaped('ABCDE1234F1Z5'), isFalse);
      expect(isGstinShaped('27ABCDE12345F1Z5'), isFalse);
      expect(isGstinShaped(''), isFalse);
    });

    GstSettings good() => on().copyWith(
      gstin: '27ABCDE1234F1Z5',
      address: '12 Market Road, Pune',
    );

    test('good settings have no problem', () {
      expect(gstSettingsProblem(good()), isNull);
    });
    test('a rate outside 0 to 50% is refused', () {
      expect(
        gstSettingsProblem(good().copyWith(rateBp: 0)),
        GstSettingsProblem.rateOutOfRange,
      );
      expect(
        gstSettingsProblem(good().copyWith(rateBp: 5001)),
        GstSettingsProblem.rateOutOfRange,
      );
      expect(gstSettingsProblem(good().copyWith(rateBp: 5000)), isNull);
      expect(gstSettingsProblem(good().copyWith(rateBp: 1)), isNull);
    });
    test('the GSTIN and the address are required', () {
      expect(
        gstSettingsProblem(good().copyWith(gstin: '')),
        GstSettingsProblem.gstinMissing,
      );
      expect(
        gstSettingsProblem(good().copyWith(gstin: '   ')),
        GstSettingsProblem.gstinMissing,
      );
      expect(
        gstSettingsProblem(good().copyWith(gstin: 'nope')),
        GstSettingsProblem.gstinInvalid,
      );
      expect(
        gstSettingsProblem(good().copyWith(address: '  ')),
        GstSettingsProblem.addressMissing,
      );
      expect(
        gstSettingsProblem(good().copyWith(address: 'x' * 201)),
        GstSettingsProblem.addressTooLong,
      );
      expect(gstSettingsProblem(good().copyWith(address: 'x' * 200)), isNull);
    });
    test('every problem has words', () {
      for (final p in GstSettingsProblem.values) {
        expect(gstSettingsProblemText(p), isNotEmpty);
      }
    });
  });
}

void gstOwnRateTests() {
  GstSettings on({
    GstMode mode = GstMode.inclusive,
    GstRounding rounding = GstRounding.perItem,
  }) => GstSettings(enabled: true, mode: mode, rounding: rounding);

  group('a style with its own rate', () {
    test('uses its own rate; others use the shop rate', () {
      final t = billTax(
        [Money(112000), Money(105000)],
        on(),
        ownRatesBp: [1200, null],
      );
      expect(t.lines[0].rateBp, 1200);
      expect(t.lines[0].tax, Money(12000)); // 1,120.00 / 1.12 = 1,000.00
      expect(t.lines[1].rateBp, 500);
      expect(t.lines[1].tax, Money(5000));
    });

    test('a null list is the shop rate for all', () {
      final t = billTax([Money(105000)], on());
      expect(t.lines.single.rateBp, 500);
    });

    test('an own rate of zero means that style carries no tax', () {
      final t = billTax(
        [Money(49900), Money(105000)],
        on(),
        ownRatesBp: [0, null],
      );
      expect(t.lines[0].tax, Money.zero);
      expect(t.lines[0].rateBp, 0);
      expect(t.lines[0].taxable, Money.zero);
      expect(t.lines[1].tax, Money(5000));
    });

    test('per bill: the tax is shared inside each rate, and adds up', () {
      final prices = [Money(10), Money(10), Money(10), Money(10), Money(10)];
      final t = billTax(
        prices,
        on(mode: GstMode.exclusive, rounding: GstRounding.perBill),
        ownRatesBp: [500, 500, 500, 1200, 1200],
      );
      // 30 paise at 5% = 1.5 -> 2; 20 paise at 12% = 2.4 -> 2
      expect(t.lines.sublist(0, 3).fold<int>(0, (a, l) => a + l.tax.paise), 2);
      expect(t.lines.sublist(3).fold<int>(0, (a, l) => a + l.tax.paise), 2);
      expect(t.lines.map((l) => l.rateBp), [500, 500, 500, 1200, 1200]);
    });

    test('lines keep their order whatever their rates', () {
      final t = billTax(
        [Money(100), Money(200), Money(300)],
        on(mode: GstMode.exclusive),
        ownRatesBp: [1200, 500, 1200],
      );
      expect(t.lines.map((l) => l.price.paise), [100, 200, 300]);
      expect(t.lines.map((l) => l.rateBp), [1200, 500, 1200]);
    });

    test('a list of the wrong length is refused', () {
      expect(
        () => billTax([Money(1)], on(), ownRatesBp: [500, 500]),
        throwsArgumentError,
      );
    });

    test('GST off ignores own rates', () {
      final t = billTax(
        [Money(105000)],
        const GstSettings(),
        ownRatesBp: [1200],
      );
      expect(t.totalTax, Money.zero);
    });
  });

  group('HSN and customer GSTIN', () {
    test('cleanHsn takes 4 to 8 digits', () {
      expect(cleanHsn('6109'), '6109');
      expect(cleanHsn(' 61091000 '), '61091000');
      for (final bad in ['', '610', '123456789', '61a9', null]) {
        expect(cleanHsn(bad), isNull, reason: '$bad');
      }
    });
    test('cleanGstin makes capitals or refuses', () {
      expect(cleanGstin(' 27abcde1234f1z5 '), '27ABCDE1234F1Z5');
      expect(cleanGstin('nope'), isNull);
      expect(cleanGstin(null), isNull);
    });
    test('the HSN and customer GSTIN fields are on to begin with', () {
      const s = GstSettings();
      expect(s.prints(GstInvoiceField.hsnCode), isTrue);
      expect(s.prints(GstInvoiceField.customerGstin), isTrue);
    });
  });
}
