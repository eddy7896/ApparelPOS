// Sign-in rules (E-AUTH-1, E-AUTH-2). Owner decisions, 2026-11-20: a cashier
// picks a name then types a PIN of 6 or more digits; manager and owner passwords
// have at least 10 characters (length only, no other rules); 5 wrong tries lock
// the account for 5 minutes, each later lockout doubles up to 1 hour, a correct
// sign-in clears it; the screen locks after 5 idle minutes. Hashing is done by
// the app (Argon2id); these are the rules around it.

enum PinProblem { tooShort, tooLong, notDigits }

const int minPinLength = 6;
const int maxPinLength = 12;

/// Returns null when [pin] is acceptable, otherwise what is wrong with it.
PinProblem? checkPin(String pin) {
  for (final unit in pin.codeUnits) {
    if (unit < 0x30 || unit > 0x39) {
      return PinProblem.notDigits;
    }
  }
  if (pin.length < minPinLength) {
    return PinProblem.tooShort;
  }
  if (pin.length > maxPinLength) {
    return PinProblem.tooLong;
  }
  return null;
}

enum PasswordProblem { tooShort, tooLong, blank }

const int minPasswordLength = 10;
const int maxPasswordLength = 128;

/// Returns null when [password] is acceptable. Length is counted in characters
/// (Unicode code points); nothing else is required.
PasswordProblem? checkPassword(String password) {
  final length = password.runes.length;
  if (length < minPasswordLength) {
    return PasswordProblem.tooShort;
  }
  if (length > maxPasswordLength) {
    return PasswordProblem.tooLong;
  }
  if (password.trim().isEmpty) {
    return PasswordProblem.blank;
  }
  return null;
}

/// One account's wrong-try record. Immutable; save it and load it back.
final class LoginState {
  const LoginState({this.failures = 0, this.lockCount = 0, this.lockedUntil});

  static const LoginState fresh = LoginState();

  /// Wrong tries since the last lockout or success.
  final int failures;

  /// How many lockouts since the last correct sign-in (drives the doubling).
  final int lockCount;

  /// UTC time the current lock ends, if there is one.
  final DateTime? lockedUntil;

  Map<String, Object?> toJson() => {
    'failures': failures,
    'lockCount': lockCount,
    'lockedUntil': lockedUntil?.toUtc().toIso8601String(),
  };

  factory LoginState.fromJson(Map<String, Object?> json) {
    final until = json['lockedUntil'] as String?;
    return LoginState(
      failures: json['failures'] as int,
      lockCount: json['lockCount'] as int,
      lockedUntil: until == null ? null : DateTime.parse(until).toUtc(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LoginState &&
      other.failures == failures &&
      other.lockCount == lockCount &&
      other.lockedUntil == lockedUntil;

  @override
  int get hashCode => Object.hash(failures, lockCount, lockedUntil);

  @override
  String toString() =>
      'LoginState(failures: $failures, lockCount: $lockCount, lockedUntil: $lockedUntil)';
}

/// How many wrong tries lock an account and for how long. The numbers are
/// settings the owner can change later.
final class LockoutPolicy {
  LockoutPolicy({
    this.maxFailures = 5,
    this.baseLock = const Duration(minutes: 5),
    this.maxLock = const Duration(hours: 1),
  }) {
    if (maxFailures < 1) {
      throw ArgumentError.value(
        maxFailures,
        'maxFailures',
        'must be at least 1',
      );
    }
    if (baseLock <= Duration.zero) {
      throw ArgumentError.value(baseLock, 'baseLock', 'must be positive');
    }
    if (maxLock < baseLock) {
      throw ArgumentError.value(
        maxLock,
        'maxLock',
        'must not be less than baseLock',
      );
    }
  }

  final int maxFailures;
  final Duration baseLock;
  final Duration maxLock;

  /// True while [state] is locked at [now].
  bool isLocked(LoginState state, DateTime now) {
    final until = state.lockedUntil;
    return until != null && now.isBefore(until);
  }

  bool canAttempt(LoginState state, DateTime now) => !isLocked(state, now);

  /// Time left on the lock at [now]; zero if not locked.
  Duration remaining(LoginState state, DateTime now) {
    final until = state.lockedUntil;
    if (until == null || !now.isBefore(until)) {
      return Duration.zero;
    }
    return until.difference(now);
  }

  /// The state after a wrong try at [now]. While locked nothing changes (the
  /// caller should not even check the PIN).
  LoginState onFailure(LoginState state, DateTime now) {
    if (isLocked(state, now)) {
      return state;
    }
    final failures = state.failures + 1;
    if (failures < maxFailures) {
      return LoginState(
        failures: failures,
        lockCount: state.lockCount,
        lockedUntil: state.lockedUntil,
      );
    }
    final lockCount = state.lockCount + 1;
    var length = baseLock;
    for (var i = 1; i < lockCount && length < maxLock; i++) {
      length = length * 2;
    }
    if (length > maxLock) {
      length = maxLock;
    }
    return LoginState(
      failures: 0,
      lockCount: lockCount,
      lockedUntil: now.add(length),
    );
  }

  /// The state after a correct sign-in: everything is cleared.
  LoginState onSuccess(LoginState state) => LoginState.fresh;
}

/// When an idle counter locks itself.
final class IdleLockPolicy {
  IdleLockPolicy({this.timeout = const Duration(minutes: 5)}) {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'must be positive');
    }
  }

  final Duration timeout;

  /// True when [now] is [timeout] or more after [lastActivity]. A clock that
  /// went backwards never locks.
  bool shouldLock({required DateTime lastActivity, required DateTime now}) =>
      now.difference(lastActivity) >= timeout;
}
