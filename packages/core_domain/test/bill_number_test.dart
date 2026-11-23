import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('financialYearLabel (India time, April to March)', () {
    test('April 1 local starts the new year', () {
      // 2026-04-01 00:00 IST = 2026-03-31 18:30 UTC
      expect(financialYearLabel(DateTime.utc(2026, 3, 31, 18, 30)), '2026-27');
    });
    test('last minute of March local is still the old year', () {
      // 2026-03-31 23:59 IST = 2026-03-31 18:29 UTC
      expect(financialYearLabel(DateTime.utc(2026, 3, 31, 18, 29)), '2025-26');
    });
    test('January belongs to the year that began the April before', () {
      expect(financialYearLabel(DateTime.utc(2027, 1, 15, 6)), '2026-27');
    });
    test('century rollover prints two digits', () {
      expect(financialYearLabel(DateTime.utc(2099, 6, 1)), '2099-00');
    });
  });

  group('BillNumber', () {
    test('formats year, counter and a six-digit serial', () {
      expect(
        BillNumber(yearLabel: '2026-27', counterNo: 1, serial: 123).format(),
        '2026-27/C1/000123',
      );
    });
    test('parses what it formats', () {
      final b = BillNumber.parse('2026-27/C12/999999')!;
      expect(b.yearLabel, '2026-27');
      expect(b.counterNo, 12);
      expect(b.serial, 999999);
      expect(b.format(), '2026-27/C12/999999');
    });
    test('rejects malformed text', () {
      for (final bad in [
        '',
        '2026-27/C1/123',
        '2026-28/C1/000123', // years not consecutive
        '2026-27/C0/000123',
        '2026-27/C1/000000',
        '2026-27/1/000123',
        ' 2026-27/C1/000123',
        '2026-27/C1/0001234',
      ]) {
        expect(BillNumber.parse(bad), isNull, reason: bad);
      }
    });
    test('constructor refuses out-of-range parts', () {
      expect(
        () => BillNumber(yearLabel: '2026-27', counterNo: 0, serial: 1),
        throwsArgumentError,
      );
      expect(
        () => BillNumber(yearLabel: '2026-27', counterNo: 1, serial: 0),
        throwsArgumentError,
      );
      expect(
        () => BillNumber(yearLabel: '2026-27', counterNo: 1, serial: 1000000),
        throwsArgumentError,
      );
      expect(
        () => BillNumber(yearLabel: '2026', counterNo: 1, serial: 1),
        throwsArgumentError,
      );
    });
    test('next serial rolls only within the same counter and year', () {
      final b = BillNumber(yearLabel: '2026-27', counterNo: 2, serial: 9);
      expect(b.next().format(), '2026-27/C2/000010');
    });
    test('next past 999999 throws', () {
      final b = BillNumber(yearLabel: '2026-27', counterNo: 2, serial: 999999);
      expect(b.next, throwsStateError);
    });
  });
}
