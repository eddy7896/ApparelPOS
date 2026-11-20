// The permission matrix: the only source of truth for who may do what
// (ADR-0003). Deny by default (E-AUTHZ-2). Owner decisions, 2026-11-18:
// cashier sells, takes returns, closes own shift, looks up stock and prices and
// discounts up to 10%; manager is the same as owner.

import 'money.dart';
import 'pricing.dart';

enum Role { cashier, manager, owner }

enum Permission {
  // Counter work.
  sell,
  printBill,
  takeReturn,
  closeShift,
  viewStockAndPrices,
  giveDiscount,
  // Back office.
  enterStock,
  printLabels,
  setMarkdown,
  overrideDiscountLimit,
  viewCost,
  viewMargins,
  viewDaybook,
  viewReports,
  manageSettings,
  configureGst,
  manageUsers,
  backupAndRestore,
}

const Set<Permission> _cashierPermissions = {
  Permission.sell,
  Permission.printBill,
  Permission.takeReturn,
  Permission.closeShift,
  Permission.viewStockAndPrices,
  Permission.giveDiscount,
};

/// Manager and owner have every permission today (same person; owner decision).
/// Written as a separate entry per role so they can diverge later.
final Map<Role, Set<Permission>> _matrix = {
  Role.cashier: _cashierPermissions,
  Role.manager: Set.unmodifiable(Permission.values),
  Role.owner: Set.unmodifiable(Permission.values),
};

/// Whether [role] may do [permission]. A null role (not signed in) may do
/// nothing, and so may any role missing from the matrix.
bool can(Role? role, Permission permission) {
  if (role == null) {
    return false;
  }
  return _matrix[role]?.contains(permission) ?? false;
}

/// Thrown by [require] when the role may not do the action.
final class PermissionDenied implements Exception {
  PermissionDenied(this.role, this.permission);
  final Role? role;
  final Permission permission;
  @override
  String toString() => 'PermissionDenied: $role may not $permission';
}

/// Throws [PermissionDenied] unless [role] may do [permission].
void require(Role? role, Permission permission) {
  if (!can(role, permission)) {
    throw PermissionDenied(role, permission);
  }
}

/// A cashier may discount up to this much (10%) without the manager's password.
const int defaultCashierDiscountLimitBp = 1000;

enum DiscountDecision { allowed, needsManagerOverride, denied }

/// Decides whether [role] may give [cut] on an item priced [price].
/// A cashier over [limitBp] (basis points of the price; the owner can change
/// it) needs the manager's password. Manager and owner are never limited.
DiscountDecision discountDecision(
  Role? role,
  PriceCut cut,
  Money price, {
  int limitBp = defaultCashierDiscountLimitBp,
}) {
  if (limitBp < 0 || limitBp > 10000) {
    throw ArgumentError.value(limitBp, 'limitBp', 'must be 0 to 10000');
  }
  if (!can(role, Permission.giveDiscount)) {
    return DiscountDecision.denied;
  }
  if (can(role, Permission.overrideDiscountLimit) || cut.isZero) {
    return DiscountDecision.allowed;
  }
  final bp = cut.basisPoints;
  final withinLimit = bp != null
      ? bp <= limitBp
      // Exact integer comparison of amount / price against limitBp / 10000.
      : cut.amountOff!.paise * 10000 <= price.paise * limitBp;
  return withinLimit
      ? DiscountDecision.allowed
      : DiscountDecision.needsManagerOverride;
}
