// The four states a garment can be in. The database stores the text value.
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  test('each state has a distinct database value', () {
    final values = ArticleStatus.values.map((s) => s.dbValue).toList();
    expect(values, ['IN_STOCK', 'SOLD', 'RETURNED', 'DAMAGED']);
    expect(values.toSet().length, values.length);
  });

  test('fromDb is the inverse of dbValue', () {
    for (final s in ArticleStatus.values) {
      expect(ArticleStatus.fromDb(s.dbValue), s);
    }
  });

  test('an unknown value is refused', () {
    expect(() => ArticleStatus.fromDb('LOST'), throwsArgumentError);
    expect(() => ArticleStatus.fromDb('in_stock'), throwsArgumentError);
  });
}
