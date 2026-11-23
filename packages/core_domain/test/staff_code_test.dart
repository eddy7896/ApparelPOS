import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('formatStaffCode', () {
    test('OP and at least three digits', () {
      expect(formatStaffCode(1), 'OP001');
      expect(formatStaffCode(12), 'OP012');
      expect(formatStaffCode(999), 'OP999');
    });
    test('grows past 999 instead of repeating', () {
      expect(formatStaffCode(1000), 'OP1000');
    });
    test('zero and negative numbers are refused', () {
      expect(() => formatStaffCode(0), throwsArgumentError);
      expect(() => formatStaffCode(-3), throwsArgumentError);
    });
    test('the code never contains a name', () {
      expect(formatStaffCode(7), isNot(matches(RegExp(r'[a-z]'))));
    });
  });

  group('parseStaffCode', () {
    test('reads a code back', () {
      expect(parseStaffCode('OP001'), 1);
      expect(parseStaffCode('OP1000'), 1000);
    });
    test('anything else is null', () {
      for (final bad in [
        '',
        'op001',
        'OP',
        'OP00',
        'OP-1',
        'Asha',
        'OP0001x',
        'OP000',
      ]) {
        expect(parseStaffCode(bad), isNull, reason: bad);
      }
    });
  });

  group('nextStaffNumber', () {
    test('starts at 1', () {
      expect(nextStaffNumber(const []), 1);
    });
    test('is one more than the highest used, never reusing a gap', () {
      expect(nextStaffNumber([1, 2, 3]), 4);
      expect(nextStaffNumber([1, 5]), 6);
      expect(nextStaffNumber([7]), 8);
    });
  });

  group('billServedByLine', () {
    test('says Served by and the code, never a name', () {
      expect(billServedByLine('OP007'), 'Served by: OP007');
    });
  });
}
