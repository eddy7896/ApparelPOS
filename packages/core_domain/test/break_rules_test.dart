import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

DateTime t(int h, int m, [int s = 0]) => DateTime.utc(2026, 11, 22, h, m, s);

void main() {
  group('totalBreakTime', () {
    test('no breaks is zero', () {
      expect(totalBreakTime(const [], t(18, 0)), Duration.zero);
    });

    test('adds up finished breaks', () {
      final spans = [
        BreakSpan(start: t(12, 0), end: t(12, 12)),
        BreakSpan(start: t(15, 0), end: t(15, 5, 30)),
      ];
      expect(
        totalBreakTime(spans, t(18, 0)),
        const Duration(minutes: 17, seconds: 30),
      );
    });

    test('a break still going counts up to now', () {
      final spans = [
        BreakSpan(start: t(12, 0), end: t(12, 10)),
        BreakSpan(start: t(15, 0)),
      ];
      expect(totalBreakTime(spans, t(15, 20)), const Duration(minutes: 30));
    });

    test('a clock that went backwards never gives a negative break', () {
      final spans = [BreakSpan(start: t(15, 0), end: t(14, 50))];
      expect(totalBreakTime(spans, t(18, 0)), Duration.zero);
      expect(
        totalBreakTime([BreakSpan(start: t(15, 0))], t(14, 0)),
        Duration.zero,
      );
    });
  });

  group('breakMinutesText', () {
    test('whole minutes, rounded down; under a minute is "0 min"', () {
      expect(breakMinutesText(const Duration(seconds: 59)), '0 min');
      expect(
        breakMinutesText(const Duration(minutes: 12, seconds: 59)),
        '12 min',
      );
    });

    test('an hour or more shows hours and minutes', () {
      expect(breakMinutesText(const Duration(minutes: 60)), '1 h 0 min');
      expect(breakMinutesText(const Duration(minutes: 135)), '2 h 15 min');
    });
  });

  group('breakClockText', () {
    test('minutes and seconds under an hour', () {
      expect(breakClockText(const Duration(minutes: 6, seconds: 12)), '06:12');
      expect(breakClockText(Duration.zero), '00:00');
      expect(breakClockText(const Duration(seconds: 59)), '00:59');
    });

    test('hours from one hour on', () {
      expect(
        breakClockText(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
      expect(breakClockText(const Duration(minutes: 60)), '1:00:00');
    });

    test('a negative duration (a clock that went back) shows zero', () {
      expect(breakClockText(const Duration(seconds: -5)), '00:00');
    });
  });
}
