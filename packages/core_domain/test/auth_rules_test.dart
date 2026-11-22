// P2-2 sign-in rules (E-AUTH-1, E-AUTH-2). Owner decisions, 2026-11-20: cashier
// picks a name then types a PIN of exactly 6 digits (owner, 2026-11-22); manager and owner password has at
// least 10 characters; 5 wrong tries lock the account for 5 minutes, doubling
// each later lockout up to 1 hour; the screen locks after 5 idle minutes.
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

final t0 = DateTime.utc(2026, 11, 20, 10);

void main() {
  group('PIN rules (E-AUTH-1)', () {
    test('the length is exactly 6, no more and no less', () {
      expect(minPinLength, 6);
      expect(maxPinLength, 6);
    });
    test('exactly 6 digits is fine, leading zeros too', () {
      for (final pin in ['123456', '000000', '012345', '999999']) {
        expect(checkPin(pin), isNull, reason: pin);
      }
    });
    test('fewer than 6 digits is too short', () {
      for (final pin in ['', '1', '12345']) {
        expect(checkPin(pin), PinProblem.tooShort, reason: pin);
      }
    });
    test('anything that is not a digit is refused', () {
      for (final pin in [
        '12345a',
        '12 345 6',
        '１２３４５６',
        '12-3456',
        '123456\n',
      ]) {
        expect(checkPin(pin), PinProblem.notDigits, reason: pin);
      }
    });
    test('more than 6 digits is too long, even 7', () {
      for (final pin in ['1234567', '12345678', '1234567890123']) {
        expect(checkPin(pin), PinProblem.tooLong, reason: pin);
      }
    });
  });

  group('password rules', () {
    test('10 or more characters is fine, no other rules', () {
      expect(checkPassword('abcdefghij'), isNull);
      expect(checkPassword('a b c d e f g h'), isNull);
      expect(checkPassword('पासवर्ड123456'), isNull);
    });
    test('fewer than 10 characters is too short', () {
      expect(checkPassword(''), PasswordProblem.tooShort);
      expect(checkPassword('123456789'), PasswordProblem.tooShort);
    });
    test('only spaces is refused even when long', () {
      expect(checkPassword('          '), PasswordProblem.blank);
    });
    test('more than 128 characters is too long', () {
      expect(checkPassword('a' * 129), PasswordProblem.tooLong);
      expect(checkPassword('a' * 128), isNull);
    });
    test('length is counted in characters, not bytes', () {
      expect(checkPassword('é' * 10), isNull);
      expect(checkPassword('😀' * 10), isNull);
      expect(checkPassword('😀' * 9), PasswordProblem.tooShort);
    });
  });

  group('lockout (E-AUTH-2)', () {
    final policy = LockoutPolicy();
    var state = LoginState.fresh;

    setUp(() => state = LoginState.fresh);

    LoginState fail(int times, DateTime at) {
      var s = state;
      for (var i = 0; i < times; i++) {
        s = policy.onFailure(s, at);
      }
      return s;
    }

    test('defaults match the owner decision', () {
      expect(policy.maxFailures, 5);
      expect(policy.baseLock, const Duration(minutes: 5));
      expect(policy.maxLock, const Duration(hours: 1));
    });

    test('four wrong tries do not lock', () {
      state = fail(4, t0);
      expect(policy.isLocked(state, t0), isFalse);
      expect(state.failures, 4);
    });

    test('the fifth wrong try locks for 5 minutes', () {
      state = fail(5, t0);
      expect(policy.isLocked(state, t0), isTrue);
      expect(state.lockedUntil, t0.add(const Duration(minutes: 5)));
      expect(policy.remaining(state, t0), const Duration(minutes: 5));
      expect(
        policy.remaining(state, t0.add(const Duration(minutes: 2))),
        const Duration(minutes: 3),
      );
    });

    test('the lock ends exactly at the end time', () {
      state = fail(5, t0);
      expect(
        policy.isLocked(state, t0.add(const Duration(minutes: 5, seconds: -1))),
        isTrue,
      );
      expect(
        policy.isLocked(state, t0.add(const Duration(minutes: 5))),
        isFalse,
      );
      expect(
        policy.remaining(state, t0.add(const Duration(minutes: 6))),
        Duration.zero,
      );
    });

    test(
      'after a lockout the try count starts again but the next lockout doubles',
      () {
        state = fail(5, t0);
        final t1 = t0.add(const Duration(minutes: 5));
        expect(state.failures, 0);
        state = fail(5, t1);
        expect(state.lockedUntil, t1.add(const Duration(minutes: 10)));
        final t2 = t1.add(const Duration(minutes: 10));
        state = fail(5, t2);
        expect(state.lockedUntil, t2.add(const Duration(minutes: 20)));
      },
    );

    test('lockouts double up to one hour and never exceed it', () {
      var now = t0;
      final minutes = <int>[];
      for (var i = 0; i < 7; i++) {
        state = fail(5, now);
        minutes.add(state.lockedUntil!.difference(now).inMinutes);
        now = state.lockedUntil!;
      }
      expect(minutes, [5, 10, 20, 40, 60, 60, 60]);
    });

    test('a correct sign-in clears the count and the doubling', () {
      state = fail(5, t0);
      state = policy.onSuccess(state);
      expect(state, LoginState.fresh);
      state = fail(5, t0);
      expect(state.lockedUntil, t0.add(const Duration(minutes: 5)));
    });

    test(
      'a wrong try while locked is not counted and does not extend the lock',
      () {
        state = fail(5, t0);
        final locked = state;
        final during = t0.add(const Duration(minutes: 1));
        expect(policy.onFailure(state, during), locked);
      },
    );

    test('canAttempt is false only while locked', () {
      state = fail(5, t0);
      expect(policy.canAttempt(state, t0), isFalse);
      expect(
        policy.canAttempt(state, t0.add(const Duration(minutes: 5))),
        isTrue,
      );
      expect(policy.canAttempt(LoginState.fresh, t0), isTrue);
    });

    test(
      'settings can be changed (owner setting later) but must make sense',
      () {
        final strict = LockoutPolicy(
          maxFailures: 3,
          baseLock: Duration(minutes: 15),
        );
        var s = LoginState.fresh;
        for (var i = 0; i < 3; i++) {
          s = strict.onFailure(s, t0);
        }
        expect(s.lockedUntil, t0.add(const Duration(minutes: 15)));
        expect(() => LockoutPolicy(maxFailures: 0), throwsArgumentError);
        expect(
          () => LockoutPolicy(baseLock: Duration.zero),
          throwsArgumentError,
        );
        expect(
          () => LockoutPolicy(
            baseLock: Duration(hours: 2),
            maxLock: Duration(hours: 1),
          ),
          throwsArgumentError,
        );
      },
    );

    test('state survives being saved and loaded', () {
      state = fail(5, t0);
      final again = LoginState.fromJson(state.toJson());
      expect(again, state);
      expect(LoginState.fromJson(LoginState.fresh.toJson()), LoginState.fresh);
    });
  });

  group('idle lock', () {
    final policy = IdleLockPolicy();
    test('default is 5 minutes', () {
      expect(policy.timeout, const Duration(minutes: 5));
    });
    test('locks once the idle time reaches the timeout', () {
      expect(
        policy.shouldLock(
          lastActivity: t0,
          now: t0.add(const Duration(minutes: 4, seconds: 59)),
        ),
        isFalse,
      );
      expect(
        policy.shouldLock(
          lastActivity: t0,
          now: t0.add(const Duration(minutes: 5)),
        ),
        isTrue,
      );
      expect(
        policy.shouldLock(
          lastActivity: t0,
          now: t0.add(const Duration(hours: 1)),
        ),
        isTrue,
      );
    });
    test('a clock that moved backwards does not lock', () {
      expect(
        policy.shouldLock(
          lastActivity: t0,
          now: t0.subtract(const Duration(minutes: 10)),
        ),
        isFalse,
      );
    });
    test('timeout must be positive', () {
      expect(() => IdleLockPolicy(timeout: Duration.zero), throwsArgumentError);
    });
  });
}
