// GST (P3-4, owner 2026-11-23): off by default, switched on by the owner only.
// ALL OF THESE RULES ARE UNVERIFIED until the shop's CA confirms them (SSOT
// rule 14, E-GST-1): the rate (5% to start, editable), whether prices include
// tax or tax is added, whether tax is rounded per garment or per bill, the
// CGST and SGST split, the GSTIN pattern and which fields an invoice needs.
// Nothing is hard-coded as law: the owner chooses at setup. Integer paise and
// basis points only (E-MONEY-1); fractions of a paisa round half up (ADR-0007).
import 'money.dart';

/// Whether the price on the tag already includes tax, or tax is added to it.
enum GstMode {
  inclusive('inclusive'),
  exclusive('exclusive');

  const GstMode(this.dbValue);
  final String dbValue;

  static GstMode? fromDb(String? v) {
    for (final m in values) {
      if (m.dbValue == v) {
        return m;
      }
    }
    return null;
  }
}

/// Whether tax is worked out on each garment or once on the whole bill.
enum GstRounding {
  perItem('item'),
  perBill('bill');

  const GstRounding(this.dbValue);
  final String dbValue;

  static GstRounding? fromDb(String? v) {
    for (final m in values) {
      if (m.dbValue == v) {
        return m;
      }
    }
    return null;
  }
}

/// The 5% the owner stated (unverified; the owner or the CA confirms).
const int defaultGstRateBp = 500;

/// The largest rate accepted (a typo guard, not a legal limit).
const int maxGstRateBp = 5000;

/// Fields the owner may switch on or off for the printed GST invoice. The list
/// is open (the owner asks the CA); this is the first set that can be printed
/// from what the app knows.
enum GstInvoiceField {
  shopAddress('shop_address', 'Shop address'),
  shopGstin('shop_gstin', 'Shop GSTIN'),
  customerName('customer_name', 'Customer name'),
  customerPhone('customer_phone', 'Customer phone'),
  unitPrice('unit_price', 'MRP of each garment'),
  discount('discount', 'Markdown and discount'),
  taxableValue('taxable_value', 'Taxable value'),
  gstRate('gst_rate', 'GST rate'),
  taxPerItem('tax_per_item', 'Tax on each garment'),
  cgstSgst('cgst_sgst', 'CGST and SGST split'),
  totalTax('total_tax', 'Total tax'),
  amountInWords('amount_in_words', 'Total in words'),
  paymentMode('payment_mode', 'How it was paid'),
  servedBy('served_by', 'Operator ID'),
  termsLine('terms_line', 'Terms line'),
  signatureLine('signature_line', 'Signature line');

  const GstInvoiceField(this.key, this.label);

  /// The text stored in the shop settings (`gst_field_<key>`).
  final String key;

  /// The words on the setup screen.
  final String label;
}

/// What is switched on when GST is first enabled: the usual tax columns and the
/// basics; the rest the owner turns on if the CA asks.
const Set<GstInvoiceField> defaultGstInvoiceFields = {
  GstInvoiceField.shopAddress,
  GstInvoiceField.shopGstin,
  GstInvoiceField.customerName,
  GstInvoiceField.customerPhone,
  GstInvoiceField.discount,
  GstInvoiceField.taxableValue,
  GstInvoiceField.gstRate,
  GstInvoiceField.taxPerItem,
  GstInvoiceField.cgstSgst,
  GstInvoiceField.totalTax,
  GstInvoiceField.paymentMode,
  GstInvoiceField.servedBy,
};

/// The shop's GST settings.
final class GstSettings {
  const GstSettings({
    this.enabled = false,
    this.mode = GstMode.inclusive,
    this.rateBp = defaultGstRateBp,
    this.rounding = GstRounding.perItem,
    this.gstin = '',
    this.address = '',
    this.fields = defaultGstInvoiceFields,
  });

  /// GST is off until the owner switches it on.
  final bool enabled;
  final GstMode mode;
  final int rateBp;
  final GstRounding rounding;
  final String gstin;
  final String address;
  final Set<GstInvoiceField> fields;

  GstSettings copyWith({
    bool? enabled,
    GstMode? mode,
    int? rateBp,
    GstRounding? rounding,
    String? gstin,
    String? address,
    Set<GstInvoiceField>? fields,
  }) => GstSettings(
    enabled: enabled ?? this.enabled,
    mode: mode ?? this.mode,
    rateBp: rateBp ?? this.rateBp,
    rounding: rounding ?? this.rounding,
    gstin: gstin ?? this.gstin,
    address: address ?? this.address,
    fields: fields ?? this.fields,
  );

  bool prints(GstInvoiceField f) => fields.contains(f);
}

/// Why the settings cannot be switched on.
enum GstSettingsProblem {
  gstinMissing,
  gstinInvalid,
  addressMissing,
  addressTooLong,
  rateOutOfRange,
}

const int maxGstAddressLength = 200;

/// A GSTIN in the usual shape: two digits (state), ten characters (PAN), one
/// entity digit or letter, Z, and a check character. The check character's own
/// sum is NOT verified here (unverified; the CA confirms).
bool isGstinShaped(String text) =>
    RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$')
        .hasMatch(text.trim().toUpperCase());

/// The first reason [s] cannot be switched on, or null. Only checked when
/// switching on; switched off, anything may be kept.
GstSettingsProblem? gstSettingsProblem(GstSettings s) {
  if (s.rateBp < 1 || s.rateBp > maxGstRateBp) {
    return GstSettingsProblem.rateOutOfRange;
  }
  if (s.gstin.trim().isEmpty) {
    return GstSettingsProblem.gstinMissing;
  }
  if (!isGstinShaped(s.gstin)) {
    return GstSettingsProblem.gstinInvalid;
  }
  final a = s.address.trim();
  if (a.isEmpty) {
    return GstSettingsProblem.addressMissing;
  }
  if (a.length > maxGstAddressLength) {
    return GstSettingsProblem.addressTooLong;
  }
  return null;
}

/// The words for a problem, for the screen.
String gstSettingsProblemText(GstSettingsProblem p) => switch (p) {
  GstSettingsProblem.gstinMissing => 'Type the shop GSTIN.',
  GstSettingsProblem.gstinInvalid =>
    'That does not look like a GSTIN (15 letters and digits, like '
        '27ABCDE1234F1Z5). Check it with your CA.',
  GstSettingsProblem.addressMissing => 'Type the shop address.',
  GstSettingsProblem.addressTooLong =>
    'The address is longer than $maxGstAddressLength characters.',
  GstSettingsProblem.rateOutOfRange =>
    'The rate must be above 0% and at most ${maxGstRateBp ~/ 100}%.',
};

/// The tax on one garment.
final class LineTax {
  const LineTax({
    required this.price,
    required this.taxable,
    required this.tax,
    required this.addedOnTop,
    required this.cgst,
    required this.sgst,
    required this.rateBp,
  });

  /// The price after markdown and discount, before tax is added.
  final Money price;

  /// The value the tax is charged on.
  final Money taxable;

  /// The tax (CGST plus SGST).
  final Money tax;

  /// Tax added on top of the price (exclusive billing); zero when the price
  /// already includes it, or when GST is off.
  final Money addedOnTop;
  final Money cgst;
  final Money sgst;
  final int rateBp;

  /// What the customer pays for this garment.
  Money get paid => price + addedOnTop;
}

/// The tax on a whole bill.
final class BillTax {
  const BillTax(this.lines);
  final List<LineTax> lines;

  Money get totalTax => lines.fold<Money>(Money.zero, (sum, l) => sum + l.tax);
  Money get totalTaxable =>
      lines.fold<Money>(Money.zero, (sum, l) => sum + l.taxable);
  Money get totalCgst =>
      lines.fold<Money>(Money.zero, (sum, l) => sum + l.cgst);
  Money get totalSgst =>
      lines.fold<Money>(Money.zero, (sum, l) => sum + l.sgst);

  /// Tax added on top of the garment prices.
  Money get addedOnTop =>
      lines.fold<Money>(Money.zero, (sum, l) => sum + l.addedOnTop);

  /// What the customer pays in all.
  Money get total => lines.fold<Money>(Money.zero, (sum, l) => sum + l.paid);
}

int _divHalfUp(int numerator, int denominator) =>
    (numerator * 2 + denominator) ~/ (denominator * 2);

/// The tax on [prices] (each after markdown and discount, none negative).
/// With GST off ([settings].enabled false) there is no tax and nothing is added.
BillTax billTax(List<Money> prices, GstSettings settings) {
  for (final p in prices) {
    if (p.paise < 0) {
      throw ArgumentError.value(p, 'prices', 'must not be negative');
    }
  }
  final bp = settings.rateBp;
  if (!settings.enabled || bp <= 0) {
    return BillTax([
      for (final p in prices)
        LineTax(
          price: p,
          taxable: Money.zero,
          tax: Money.zero,
          addedOnTop: Money.zero,
          cgst: Money.zero,
          sgst: Money.zero,
          rateBp: 0,
        ),
    ]);
  }
  final inclusive = settings.mode == GstMode.inclusive;
  int taxOf(int paise) => inclusive
      ? paise - _divHalfUp(paise * 10000, 10000 + bp)
      : _divHalfUp(paise * bp, 10000);

  final taxes = <int>[];
  if (settings.rounding == GstRounding.perItem) {
    for (final p in prices) {
      taxes.add(taxOf(p.paise));
    }
  } else {
    final base = prices.fold<int>(0, (a, p) => a + p.paise);
    final total = taxOf(base);
    // Share the one tax over the garments by price, in whole paise that add
    // up exactly (the largest fractions take the leftover paise).
    final shares = <int>[];
    final rema = <int>[];
    var given = 0;
    for (final p in prices) {
      final num = total * p.paise;
      final s = base == 0 ? 0 : num ~/ base;
      shares.add(s);
      rema.add(base == 0 ? 0 : num % base);
      given += s;
    }
    var left = total - given;
    final order = List<int>.generate(prices.length, (i) => i)
      ..sort((a, b) {
        final c = rema[b].compareTo(rema[a]);
        return c != 0 ? c : a.compareTo(b);
      });
    for (final i in order) {
      if (left <= 0) {
        break;
      }
      if (prices[i].paise > 0) {
        shares[i] += 1;
        left -= 1;
      }
    }
    taxes.addAll(shares);
  }
  return BillTax([
    for (var i = 0; i < prices.length; i++)
      () {
        final tax = Money(taxes[i]);
        final cgst = Money((tax.paise + 1) ~/ 2);
        return LineTax(
          price: prices[i],
          taxable: inclusive ? prices[i] - tax : prices[i],
          tax: tax,
          addedOnTop: inclusive ? Money.zero : tax,
          cgst: cgst,
          sgst: tax - cgst,
          rateBp: bp,
        );
      }(),
  ]);
}

const _ones = [
  'Zero',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
  'Eleven',
  'Twelve',
  'Thirteen',
  'Fourteen',
  'Fifteen',
  'Sixteen',
  'Seventeen',
  'Eighteen',
  'Nineteen',
];
const _tens = [
  '',
  '',
  'Twenty',
  'Thirty',
  'Forty',
  'Fifty',
  'Sixty',
  'Seventy',
  'Eighty',
  'Ninety',
];

String _below100(int n) {
  if (n < 20) {
    return _ones[n];
  }
  final t = _tens[n ~/ 10];
  return n % 10 == 0 ? t : '$t-${_ones[n % 10]}';
}

String _below1000(int n) {
  if (n < 100) {
    return _below100(n);
  }
  final h = '${_ones[n ~/ 100]} Hundred';
  return n % 100 == 0 ? h : '$h ${_below100(n % 100)}';
}

/// The amount in words in the Indian way (crore, lakh, thousand): `Rupees One
/// Thousand Four Hundred Ninety-Eight and Fifty Paise Only`. Not negative.
String amountInWords(Money amount) {
  if (amount.paise < 0) {
    throw ArgumentError.value(amount, 'amount', 'must not be negative');
  }
  final rupees = amount.paise ~/ 100;
  final paise = amount.paise % 100;
  final parts = <String>[];
  var rest = rupees;
  final crore = rest ~/ 10000000;
  rest %= 10000000;
  final lakh = rest ~/ 100000;
  rest %= 100000;
  final thousand = rest ~/ 1000;
  rest %= 1000;
  if (crore > 0) {
    parts.add('${_below1000(crore)} Crore');
  }
  if (lakh > 0) {
    parts.add('${_below100(lakh)} Lakh');
  }
  if (thousand > 0) {
    parts.add('${_below100(thousand)} Thousand');
  }
  if (rest > 0) {
    parts.add(_below1000(rest));
  }
  final rupeeWords = parts.isEmpty ? 'Zero' : parts.join(' ');
  final p = paise > 0 ? ' and ${_below100(paise)} Paise' : '';
  return 'Rupees $rupeeWords$p Only';
}
