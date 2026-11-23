import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('who may manage whom (owner, 2026-11-22)', () {
    test('the owner manages everyone', () {
      for (final r in Role.values) {
        expect(canManageStaff(Role.owner, r), isTrue, reason: '$r');
      }
    });
    test('a manager manages cashiers only', () {
      expect(canManageStaff(Role.manager, Role.cashier), isTrue);
      expect(canManageStaff(Role.manager, Role.manager), isFalse);
      expect(canManageStaff(Role.manager, Role.owner), isFalse);
    });
    test('a cashier manages nobody', () {
      for (final r in Role.values) {
        expect(canManageStaff(Role.cashier, r), isFalse, reason: '$r');
      }
    });
    test('nobody at all manages nobody', () {
      expect(canManageStaff(null, Role.cashier), isFalse);
    });
  });

  group('cleanPersonName', () {
    test('trims and squeezes spaces', () {
      expect(cleanPersonName('  Asha   Rao '), 'Asha Rao');
    });
    test('blank is refused', () {
      expect(cleanPersonName('   '), isNull);
      expect(cleanPersonName(''), isNull);
    });
    test('40 characters is the limit', () {
      expect(cleanPersonName('a' * 40), 'a' * 40);
      expect(cleanPersonName('a' * 41), isNull);
    });
    test('control characters are refused', () {
      expect(cleanPersonName('Asha\nRao'), isNull);
      expect(cleanPersonName('Asha\u0007'), isNull);
    });
    test('letters of any language are fine', () {
      expect(cleanPersonName('आशा'), 'आशा');
    });
  });

  group('turnOffBlock (who cannot be turned off, and why)', () {
    TurnOffBlock? block({
      Role actor = Role.owner,
      Role target = Role.cashier,
      bool self = false,
      bool lastOwner = false,
      bool openShift = false,
    }) => turnOffBlock(
      actor: actor,
      target: target,
      isSelf: self,
      isLastActiveOwner: lastOwner,
      hasOpenShift: openShift,
    );

    test('an allowed, ordinary cashier can be turned off', () {
      expect(block(), isNull);
      expect(block(actor: Role.manager), isNull);
    });
    test('not allowed when the actor may not manage that role', () {
      expect(
        block(actor: Role.manager, target: Role.manager),
        TurnOffBlock.notAllowed,
      );
      expect(block(actor: Role.cashier), TurnOffBlock.notAllowed);
    });
    test('never yourself', () {
      expect(block(target: Role.owner, self: true), TurnOffBlock.yourself);
    });
    test('never the last active owner', () {
      expect(
        block(target: Role.owner, lastOwner: true),
        TurnOffBlock.lastOwner,
      );
    });
    test('not while their shift is open', () {
      expect(block(openShift: true), TurnOffBlock.openShift);
    });
    test('another owner can be turned off when there are two', () {
      expect(block(target: Role.owner), isNull);
    });
    test('the first problem wins: permission before the rest', () {
      expect(
        block(
          actor: Role.manager,
          target: Role.owner,
          self: true,
          openShift: true,
        ),
        TurnOffBlock.notAllowed,
      );
    });
  });

  group('turnOffText', () {
    test('each block has a plain sentence', () {
      for (final b in TurnOffBlock.values) {
        expect(turnOffText(b), isNotEmpty);
      }
      expect(turnOffText(TurnOffBlock.openShift), contains('shift'));
    });
  });
}
