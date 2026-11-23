// Managing staff (owner, 2026-11-22): the owner manages everyone; a manager
// manages cashiers only; nobody can turn off themselves, the last active owner,
// or someone whose shift is still open. Turning someone off keeps all their
// history (E-AUDIT-1). No database here, only the rules.

import 'permissions.dart';

const int maxPersonNameLength = 40;

/// A person's name for the sign-in screen: trimmed, spaces squeezed, 1 to 40
/// characters, no control characters. Null when it is not acceptable.
String? cleanPersonName(String raw) {
  for (final unit in raw.runes) {
    if (unit < 0x20 || (unit >= 0x7F && unit <= 0x9F)) {
      return null;
    }
  }
  final clean = raw.trim().replaceAll(RegExp(r' {2,}'), ' ');
  if (clean.isEmpty || clean.runes.length > maxPersonNameLength) {
    return null;
  }
  return clean;
}

/// True when [actor] may add, rename, reset or turn off a [target] role.
bool canManageStaff(Role? actor, Role target) => switch (actor) {
  Role.owner => true,
  Role.manager => target == Role.cashier,
  _ => false,
};

enum TurnOffBlock { notAllowed, yourself, lastOwner, openShift }

/// Why [target] cannot be turned off right now, or null when they can.
TurnOffBlock? turnOffBlock({
  required Role? actor,
  required Role target,
  required bool isSelf,
  required bool isLastActiveOwner,
  required bool hasOpenShift,
}) {
  if (!canManageStaff(actor, target)) {
    return TurnOffBlock.notAllowed;
  }
  if (isSelf) {
    return TurnOffBlock.yourself;
  }
  if (target == Role.owner && isLastActiveOwner) {
    return TurnOffBlock.lastOwner;
  }
  if (hasOpenShift) {
    return TurnOffBlock.openShift;
  }
  return null;
}

String turnOffText(TurnOffBlock b) => switch (b) {
  TurnOffBlock.notAllowed => 'You may not change this person.',
  TurnOffBlock.yourself => 'You cannot turn yourself off.',
  TurnOffBlock.lastOwner => 'There must always be one owner who can sign in.',
  TurnOffBlock.openShift =>
    'Their shift is still open. They must close it first.',
};
