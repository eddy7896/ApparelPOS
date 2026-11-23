import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

// India is UTC+5:30, so 04:30 UTC is 10:00 in the shop.
DateTime shop(int h, int m) =>
    DateTime.utc(2026, 11, 22, h, m).subtract(shopUtcOffset);

void main() {
  test('morning until noon India time', () {
    expect(greetingFor(shop(5, 0)), 'Good morning');
    expect(greetingFor(shop(11, 59)), 'Good morning');
  });
  test('afternoon from noon until 5 pm', () {
    expect(greetingFor(shop(12, 0)), 'Good afternoon');
    expect(greetingFor(shop(16, 59)), 'Good afternoon');
  });
  test('evening from 5 pm', () {
    expect(greetingFor(shop(17, 0)), 'Good evening');
    expect(greetingFor(shop(23, 30)), 'Good evening');
  });
  test('the small hours are still the night before: evening, not morning', () {
    expect(greetingFor(shop(2, 0)), 'Good evening');
  });
  test('uses India time, not UTC', () {
    // 06:30 UTC is 12:00 in India: afternoon, although UTC says morning.
    expect(greetingFor(DateTime.utc(2026, 11, 22, 6, 30)), 'Good afternoon');
  });
}
