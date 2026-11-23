// Pricing: price = MRP, then markdown. A marked-down garment takes no cashier
// discount (owner, 2026-11-18). Integer paise only (E-MONEY-1).

import 'money.dart';

/// Thrown when an amount cut is larger than the price it comes off.
final class PriceCutTooLarge implements Exception {
  PriceCutTooLarge(this.cut, this.price);
  final Money cut;
  final Money price;
  @override
  String toString() => 'PriceCutTooLarge: $cut is more than $price';
}

/// Thrown when a cashier discount is given on a marked-down garment.
final class DiscountNotAllowed implements Exception {
  @override
  String toString() =>
      'DiscountNotAllowed: a marked-down garment takes no cashier discount';
}

/// A reduction in price: a percentage or a fixed amount. Used for a markdown
/// and for a cashier discount.
final class PriceCut {
  const PriceCut._(this._basisPoints, this._amount);

  /// A percentage in basis points (2000 is 20%), 0 to 10000.
  factory PriceCut.percentBp(int basisPoints) {
    if (basisPoints < 0 || basisPoints > 10000) {
      throw ArgumentError.value(
        basisPoints,
        'basisPoints',
        'must be 0 to 10000',
      );
    }
    return PriceCut._(basisPoints, null);
  }

  /// A fixed amount off; must not be negative.
  factory PriceCut.amount(Money off) {
    if (off.paise < 0) {
      throw ArgumentError.value(off, 'off', 'must not be negative');
    }
    return PriceCut._(null, off);
  }

  final int? _basisPoints;
  final Money? _amount;

  /// The percentage in basis points, or null if this is a fixed amount.
  int? get basisPoints => _basisPoints;

  /// The fixed amount, or null if this is a percentage.
  Money? get amountOff => _amount;

  /// True when this cut takes nothing off.
  bool get isZero =>
      (_basisPoints ?? 0) == 0 && (_amount ?? Money.zero) == Money.zero;

  /// How much this cut takes off [price]. A percentage rounds half up (the cut
  /// is rounded, then subtracted). An amount larger than [price] throws
  /// [PriceCutTooLarge].
  Money of(Money price) {
    final bp = _basisPoints;
    if (bp != null) {
      return price.percentBp(bp);
    }
    final amount = _amount!;
    if (amount > price) {
      throw PriceCutTooLarge(amount, price);
    }
    return amount;
  }
}

/// The result of pricing one garment.
final class PricedLine {
  const PricedLine({
    required this.mrp,
    required this.markdownAmount,
    required this.discountAmount,
  });

  final Money mrp;
  final Money markdownAmount;
  final Money discountAmount;

  Money get priceAfterMarkdown => mrp - markdownAmount;
  Money get finalPrice => priceAfterMarkdown - discountAmount;

  /// True when a markdown actually took something off.
  bool get markedDown => markdownAmount > Money.zero;
}

/// Prices one garment: [mrp], then [markdown], then [cashierDiscount].
/// Throws [DiscountNotAllowed] if both a real markdown and a cashier discount
/// are given. A markdown of zero counts as no markdown.
PricedLine priceLine({
  required Money mrp,
  PriceCut? markdown,
  PriceCut? cashierDiscount,
}) {
  if (mrp.paise < 0) {
    throw ArgumentError.value(mrp, 'mrp', 'must not be negative');
  }
  final markdownAmount = markdown?.of(mrp) ?? Money.zero;
  var discountAmount = Money.zero;
  if (cashierDiscount != null && !cashierDiscount.isZero) {
    if (markdownAmount > Money.zero) {
      throw DiscountNotAllowed();
    }
    discountAmount = cashierDiscount.of(mrp);
  }
  return PricedLine(
    mrp: mrp,
    markdownAmount: markdownAmount,
    discountAmount: discountAmount,
  );
}

/// Reads what a person typed as a price cut: `10%` or `12.5%` (a percentage,
/// at most two decimals, 0 to 100) or an amount in rupees such as `50` or
/// `₹49.50`. Returns null when the text is not one of these.
PriceCut? parsePriceCut(String text) {
  final t = text.trim();
  if (t.isEmpty) {
    return null;
  }
  if (t.endsWith('%')) {
    final body = t.substring(0, t.length - 1).trim();
    final m = RegExp(r'^([0-9]{1,3})(?:\.([0-9]{1,2}))?$').firstMatch(body);
    if (m == null) {
      return null;
    }
    final whole = int.parse(m.group(1)!);
    final fraction = int.parse((m.group(2) ?? '').padRight(2, '0'));
    final bp = whole * 100 + fraction;
    return bp > 10000 ? null : PriceCut.percentBp(bp);
  }
  final amount = parseRupees(t);
  return amount == null ? null : PriceCut.amount(amount);
}
