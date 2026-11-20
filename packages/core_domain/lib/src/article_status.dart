// The states of one garment (article). Transitions (a sold barcode cannot be
// sold again, E-SALE-1) come with billing, P2-4.

enum ArticleStatus {
  inStock('IN_STOCK'),
  sold('SOLD'),
  returned('RETURNED'),
  damaged('DAMAGED');

  const ArticleStatus(this.dbValue);

  /// The text stored in the database.
  final String dbValue;

  static ArticleStatus fromDb(String value) {
    for (final status in values) {
      if (status.dbValue == value) {
        return status;
      }
    }
    throw ArgumentError.value(value, 'value', 'not an article status');
  }
}
