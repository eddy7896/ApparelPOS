import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  test('each role has a distinct database value and round-trips', () {
    expect(Role.values.map((r) => r.dbValue), ['CASHIER', 'MANAGER', 'OWNER']);
    for (final r in Role.values) {
      expect(Role.fromDb(r.dbValue), r);
    }
  });

  test('an unknown role value is refused', () {
    expect(() => Role.fromDb('ADMIN'), throwsArgumentError);
    expect(() => Role.fromDb('cashier'), throwsArgumentError);
  });

  test('cashiers sign in with a PIN, manager and owner with a password', () {
    expect(Role.cashier.usesPin, isTrue);
    expect(Role.manager.usesPin, isFalse);
    expect(Role.owner.usesPin, isFalse);
  });
}
