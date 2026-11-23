import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('ShopDay (India calendar day)', () {
    test('a UTC time late in the evening is already the next India day', () {
      // 2026-11-20 18:30 UTC = 2026-11-21 00:00 India
      final d = ShopDay.fromUtc(DateTime.utc(2026, 11, 20, 18, 30));
      expect((d.year, d.month, d.day), (2026, 11, 21));
    });
    test('one minute earlier is still the same India day', () {
      final d = ShopDay.fromUtc(DateTime.utc(2026, 11, 20, 18, 29));
      expect((d.year, d.month, d.day), (2026, 11, 20));
    });
    test(
      'the day runs from India midnight to the next India midnight, in UTC',
      () {
        final d = ShopDay(2026, 11, 21);
        expect(d.startUtc, DateTime.utc(2026, 11, 20, 18, 30));
        expect(d.endUtc, DateTime.utc(2026, 11, 21, 18, 30));
      },
    );
    test('every instant belongs to exactly one day', () {
      final t = DateTime.utc(2026, 11, 20, 18, 30);
      final d = ShopDay.fromUtc(t);
      expect(d.contains(t), isTrue);
      expect(d.previous.contains(t), isFalse);
      expect(d.next.contains(t), isFalse);
      // the last instant of a day, and the first of the next
      expect(
        d.previous.contains(t.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(d.previous.contains(t), isFalse);
    });
    test('next and previous cross month and year ends', () {
      expect(ShopDay(2026, 12, 31).next, ShopDay(2027, 1, 1));
      expect(ShopDay(2027, 1, 1).previous, ShopDay(2026, 12, 31));
      expect(ShopDay(2026, 2, 28).next, ShopDay(2026, 3, 1));
      expect(ShopDay(2028, 2, 28).next, ShopDay(2028, 2, 29));
    });
    test('compare and equality', () {
      expect(ShopDay(2026, 11, 20) == ShopDay(2026, 11, 20), isTrue);
      expect(
        ShopDay(2026, 11, 20).compareTo(ShopDay(2026, 11, 21)),
        lessThan(0),
      );
      expect(ShopDay(2026, 11, 20).hashCode, ShopDay(2026, 11, 20).hashCode);
    });
    test('text is dd-mm-yyyy', () {
      expect(ShopDay(2026, 3, 5).format(), '05-03-2026');
    });
    test('an impossible date is refused', () {
      expect(() => ShopDay(2026, 13, 1), throwsArgumentError);
      expect(() => ShopDay(2026, 2, 30), throwsArgumentError);
      expect(() => ShopDay(2026, 0, 1), throwsArgumentError);
    });
  });

  group('netSales, costOfGoods, grossProfit', () {
    test('net sales are sales minus refunds', () {
      expect(
        netSales(sales: Money.rupees(5000), refunds: Money.rupees(499)),
        Money.rupees(4501),
      );
    });
    test(
      'cost of goods is cost of garments sold minus cost of restocked returns',
      () {
        expect(
          costOfGoods(
            sold: Money.rupees(2000),
            restockedReturns: Money.rupees(200),
          ),
          Money.rupees(1800),
        );
      },
    );
    test('profit is net sales minus cost of goods, and can be a loss', () {
      expect(
        grossProfit(
          netSales: Money.rupees(4501),
          costOfGoods: Money.rupees(1800),
        ),
        Money.rupees(2701),
      );
      expect(
        grossProfit(
          netSales: Money.rupees(100),
          costOfGoods: Money.rupees(300),
        ),
        Money.rupees(-200),
      );
    });
    test('amounts must not be negative', () {
      expect(
        () => netSales(sales: Money(-1), refunds: Money.zero),
        throwsArgumentError,
      );
      expect(
        () => netSales(sales: Money.zero, refunds: Money(-1)),
        throwsArgumentError,
      );
      expect(
        () => costOfGoods(sold: Money(-1), restockedReturns: Money.zero),
        throwsArgumentError,
      );
      expect(
        () => costOfGoods(sold: Money.zero, restockedReturns: Money(-1)),
        throwsArgumentError,
      );
    });
  });

  group('topStyles', () {
    StyleSales s(String n, int q, int v) =>
        StyleSales(name: n, quantity: q, value: Money(v));
    test('ranks by quantity, then value, then name', () {
      final top = topStyles([
        s('Denim Jeans', 3, 300000),
        s('Cotton Kurta', 5, 100000),
        s('Linen Shirt', 3, 450000),
        s('Anarkali', 3, 450000),
      ]);
      expect(
        [for (final x in top) x.name],
        ['Cotton Kurta', 'Anarkali', 'Linen Shirt', 'Denim Jeans'],
      );
    });
    test('keeps only the top 5 by default, or n', () {
      final rows = [for (var i = 1; i <= 8; i++) s('S$i', i, i * 100)];
      expect(topStyles(rows).length, 5);
      expect(topStyles(rows).first.name, 'S8');
      expect(topStyles(rows, n: 2).length, 2);
      expect(topStyles(rows, n: 20).length, 8);
    });
    test('does not change its input and handles nothing', () {
      final rows = [s('B', 1, 1), s('A', 2, 1)];
      topStyles(rows);
      expect(rows.first.name, 'B');
      expect(topStyles(const []), isEmpty);
    });
    test('n must be positive; quantity and value must not be negative', () {
      expect(() => topStyles(const [], n: 0), throwsArgumentError);
      expect(() => s('X', -1, 0), throwsArgumentError);
      expect(() => s('X', 1, -1), throwsArgumentError);
    });
  });

  group('who may read reports', () {
    test('reports and margins are for manager and owner, never a cashier', () {
      expect(can(Role.cashier, Permission.viewReports), isFalse);
      expect(can(Role.cashier, Permission.viewMargins), isFalse);
      expect(can(Role.manager, Permission.viewReports), isTrue);
      expect(can(Role.owner, Permission.viewMargins), isTrue);
    });
  });
}
