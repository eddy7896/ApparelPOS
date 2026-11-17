// Money is a whole number of paise. There is no floating-point type here
// (E-MONEY-1, ADR-0007).

/// An amount of money in integer paise (100 paise = 1 rupee). May be negative
/// (a return, a refund, a discount line).
final class Money implements Comparable<Money> {
  const Money(this.paise);

  /// Whole rupees plus optional paise, e.g. `Money.rupees(499, 50)` is 499.50.
  /// [paise] must be 0 to 99.
  factory Money.rupees(int rupees, [int paise = 0]) {
    if (paise < 0 || paise > 99) {
      throw ArgumentError.value(paise, 'paise', 'must be between 0 and 99');
    }
    return Money(rupees * 100 + paise);
  }

  static const Money zero = Money(0);

  final int paise;

  Money operator +(Money other) => Money(paise + other.paise);
  Money operator -(Money other) => Money(paise - other.paise);
  Money operator -() => Money(-paise);

  bool operator <(Money other) => paise < other.paise;
  bool operator <=(Money other) => paise <= other.paise;
  bool operator >(Money other) => paise > other.paise;
  bool operator >=(Money other) => paise >= other.paise;

  /// This amount times a whole quantity.
  Money times(int quantity) => Money(paise * quantity);

  /// [basisPoints] percent of this amount (100 basis points = 1%, so 5% is
  /// 500). Fractions of a paisa round half up, away from zero: 12.5 becomes 13
  /// and -12.5 becomes -13, so a return reverses a sale exactly.
  Money percentBp(int basisPoints) {
    if (basisPoints < 0) {
      throw ArgumentError.value(basisPoints, 'basisPoints', 'must not be negative');
    }
    final scaled = paise.abs() * basisPoints;
    final rounded = (scaled + 5000) ~/ 10000;
    return Money(paise < 0 ? -rounded : rounded);
  }

  @override
  int compareTo(Money other) => paise.compareTo(other.paise);

  @override
  bool operator ==(Object other) => other is Money && other.paise == paise;

  @override
  int get hashCode => paise.hashCode;

  @override
  String toString() => 'Money($paise paise)';
}
