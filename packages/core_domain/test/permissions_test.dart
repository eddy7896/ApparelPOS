// E-AUTHZ-2: the permission matrix denies by default. Owner decisions 2026-11-18:
// cashier sells, takes returns, closes own shift, looks up stock and prices,
// discounts up to 10%; manager is the same as owner.
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  const cashierAllowed = {
    Permission.sell,
    Permission.printBill,
    Permission.takeReturn,
    Permission.closeShift,
    Permission.viewStockAndPrices,
    Permission.giveDiscount,
  };

  group('deny by default', () {
    test('no role (not signed in) can do anything', () {
      for (final p in Permission.values) {
        expect(can(null, p), isFalse, reason: '$p');
      }
    });

    test('cashier can do exactly the allowed set and nothing else', () {
      for (final p in Permission.values) {
        expect(can(Role.cashier, p), cashierAllowed.contains(p), reason: '$p');
      }
    });

    test('cashier is denied every sensitive permission', () {
      for (final p in [
        Permission.viewCost,
        Permission.viewMargins,
        Permission.viewDaybook,
        Permission.viewReports,
        Permission.enterStock,
        Permission.printLabels,
        Permission.setMarkdown,
        Permission.manageSettings,
        Permission.configureGst,
        Permission.manageUsers,
        Permission.overrideDiscountLimit,
        Permission.approveLateReturn,
        Permission.backupAndRestore,
        Permission.allowPayLater,
        Permission.writeOffDebt,
      ]) {
        expect(can(Role.cashier, p), isFalse, reason: '$p');
      }
    });

    test('the owner has every permission', () {
      for (final p in Permission.values) {
        expect(can(Role.owner, p), isTrue, reason: '$p');
      }
    });

    test(
      'a manager has every permission except writing off a debt and GST',
      () {
        const ownerOnly = {Permission.writeOffDebt, Permission.configureGst};
        for (final p in Permission.values) {
          expect(can(Role.manager, p), !ownerOnly.contains(p), reason: '$p');
        }
      },
    );

    test('a cashier cannot leave a bill unpaid or write off a debt', () {
      expect(can(Role.cashier, Permission.allowPayLater), isFalse);
      expect(can(Role.cashier, Permission.writeOffDebt), isFalse);
      expect(can(Role.manager, Permission.allowPayLater), isTrue);
      expect(can(Role.owner, Permission.allowPayLater), isTrue);
    });

    test('require throws PermissionDenied for a denied action', () {
      expect(
        () => require(Role.cashier, Permission.viewCost),
        throwsA(isA<PermissionDenied>()),
      );
      expect(
        () => require(null, Permission.sell),
        throwsA(isA<PermissionDenied>()),
      );
      expect(() => require(Role.cashier, Permission.sell), returnsNormally);
    });
  });

  group('cashier discount limit', () {
    const price = Money(100000); // 1000.00

    test('default limit is 10%', () {
      expect(defaultCashierDiscountLimitBp, 1000);
    });

    test('percent at or under the limit is allowed for a cashier', () {
      expect(
        discountDecision(Role.cashier, PriceCut.percentBp(1000), price),
        DiscountDecision.allowed,
      );
      expect(
        discountDecision(Role.cashier, PriceCut.percentBp(1), price),
        DiscountDecision.allowed,
      );
    });

    test('percent over the limit needs the manager', () {
      expect(
        discountDecision(Role.cashier, PriceCut.percentBp(1001), price),
        DiscountDecision.needsManagerOverride,
      );
    });

    test('amount is judged by its share of the price', () {
      expect(
        discountDecision(Role.cashier, PriceCut.amount(Money(10000)), price),
        DiscountDecision.allowed,
      ); // exactly 10%
      expect(
        discountDecision(Role.cashier, PriceCut.amount(Money(10001)), price),
        DiscountDecision.needsManagerOverride,
      );
    });

    test('a different limit can be passed in (owner setting)', () {
      expect(
        discountDecision(
          Role.cashier,
          PriceCut.percentBp(600),
          price,
          limitBp: 500,
        ),
        DiscountDecision.needsManagerOverride,
      );
      expect(
        discountDecision(
          Role.cashier,
          PriceCut.percentBp(500),
          price,
          limitBp: 500,
        ),
        DiscountDecision.allowed,
      );
      expect(
        discountDecision(
          Role.cashier,
          PriceCut.percentBp(1),
          price,
          limitBp: 0,
        ),
        DiscountDecision.needsManagerOverride,
      );
    });

    test('manager and owner never need an override', () {
      for (final role in [Role.manager, Role.owner]) {
        expect(
          discountDecision(role, PriceCut.percentBp(9000), price),
          DiscountDecision.allowed,
        );
      }
    });

    test('a zero discount is always allowed', () {
      expect(
        discountDecision(Role.cashier, PriceCut.percentBp(0), price),
        DiscountDecision.allowed,
      );
    });

    test('no role means denied', () {
      expect(
        discountDecision(null, PriceCut.percentBp(1), price),
        DiscountDecision.denied,
      );
    });

    test('a discount over 100 percent of the price needs the manager', () {
      expect(
        discountDecision(Role.cashier, PriceCut.amount(Money(100001)), price),
        DiscountDecision.needsManagerOverride,
      );
    });

    test('limit must be 0 to 10000', () {
      expect(
        () => discountDecision(
          Role.cashier,
          PriceCut.percentBp(1),
          price,
          limitBp: 10001,
        ),
        throwsArgumentError,
      );
      expect(
        () => discountDecision(
          Role.cashier,
          PriceCut.percentBp(1),
          price,
          limitBp: -1,
        ),
        throwsArgumentError,
      );
    });
  });
}
