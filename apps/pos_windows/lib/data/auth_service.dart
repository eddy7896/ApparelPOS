// Sign-in for the counter: users, Argon2id hashes, lockout saved per user.
// E-AUTH-1 (PIN of exactly 6 digits, Argon2id), E-AUTH-2 (lockout). Rules are in
// core_domain; this file connects them to the database. No secret, hash or
// wrong guess is ever written to the audit log or the outbox.
import 'package:core_domain/core_domain.dart';
import 'package:core_domain/credential_hasher.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';

/// Thrown when a PIN or password does not meet the rules.
final class WeakSecret implements Exception {
  WeakSecret(this.role, this.problem);
  final Role role;

  /// A [PinProblem] (cashier) or [PasswordProblem] (manager, owner).
  final Object problem;
  @override
  String toString() => 'WeakSecret: $problem for $role';
}

sealed class SignInResult {
  const SignInResult();
}

final class SignedIn extends SignInResult {
  const SignedIn({
    required this.userId,
    required this.name,
    required this.role,
    this.staffCode = 'OP---',
  });
  final String userId;
  final String name;
  final Role role;

  /// The operator ID printed on bills instead of the name ("OP001").
  final String staffCode;
}

final class WrongSecret extends SignInResult {
  const WrongSecret(this.triesLeft);
  final int triesLeft;
}

final class AccountLocked extends SignInResult {
  const AccountLocked(this.until);
  final DateTime until;
}

final class UnknownUser extends SignInResult {
  const UnknownUser();
}

/// One line on the sign-in screen.
final class SignInChoice {
  const SignInChoice({
    required this.userId,
    required this.name,
    required this.role,
  });
  final String userId;
  final String name;
  final Role role;
}

class AuthService {
  AuthService(
    this._db, {
    required String Function() newId,
    DateTime Function()? now,
    CredentialHasher? hasher,
    LockoutPolicy? policy,
  }) : _newId = newId,
       _now = now ?? (() => DateTime.now().toUtc()),
       _hasher = hasher ?? CredentialHasher(),
       _policy = policy ?? LockoutPolicy(),
       _writer = AuditedWriter(_db, now: now, newId: newId);

  final AppDatabase _db;
  final String Function() _newId;
  final DateTime Function() _now;
  final CredentialHasher _hasher;
  final LockoutPolicy _policy;
  final AuditedWriter _writer;

  void _checkSecret(Role role, String secret) {
    final Object? problem = role.usesPin
        ? checkPin(secret)
        : checkPassword(secret);
    if (problem != null) {
      throw WeakSecret(role, problem);
    }
  }

  /// "OP001" for a staff number ("OP---" for a row that somehow has none).
  static String codeOf(int? number) =>
      number == null ? 'OP---' : formatStaffCode(number);

  /// Adds a user. Returns the new user's id. Throws [WeakSecret] if the PIN or
  /// password breaks the rules.
  Future<String> createUser({
    required String name,
    required Role role,
    required String secret,
    String? actor,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be blank');
    }
    _checkSecret(role, secret);
    final hash = _hasher.hash(secret);
    final id = _newId();
    final at = _now();
    // The next operator number, taken inside the same transaction as the insert.
    final highest =
        (await _db
                .customSelect(
                  'SELECT COALESCE(MAX(staff_number), 0) AS m FROM users',
                )
                .getSingle())
            .read<int>('m');
    final number = highest + 1;
    await _writer.run<void>(
      action: 'user.create',
      entityType: 'user',
      entityId: id,
      actor: actor,
      details: {
        'name': cleanName,
        'role': role.dbValue,
        'staffCode': formatStaffCode(number),
      },
      body: () async {
        await _db
            .into(_db.users)
            .insert(
              UsersCompanion.insert(
                id: id,
                name: cleanName,
                role: role.dbValue,
                credentialHash: hash,
                staffNumber: Value(number),
                createdAt: at,
                updatedAt: at,
              ),
            );
      },
    );
    return id;
  }

  /// Checks [secret] for [userId]. A locked account is not even checked.
  Future<SignInResult> signIn({
    required String userId,
    required String secret,
  }) async {
    final user =
        await (_db.select(_db.users)
              ..where((u) => u.id.equals(userId) & u.active.equals(true)))
            .getSingleOrNull();
    if (user == null) {
      return const UnknownUser();
    }
    final now = _now();
    final state = LoginState(
      failures: user.failures,
      lockCount: user.lockCount,
      lockedUntil: user.lockedUntil?.toUtc(),
    );
    if (_policy.isLocked(state, now)) {
      return AccountLocked(state.lockedUntil!);
    }

    if (_hasher.verify(user.credentialHash, secret)) {
      final newHash = _hasher.needsRehash(user.credentialHash)
          ? _hasher.hash(secret)
          : null;
      await _writer.runLocal<void>(
        action: 'auth.signin',
        entityType: 'user',
        entityId: user.id,
        actor: user.id,
        body: () =>
            _save(user.id, _policy.onSuccess(state), now, newHash: newHash),
      );
      return SignedIn(
        userId: user.id,
        name: user.name,
        role: Role.fromDb(user.role),
        staffCode: codeOf(user.staffNumber),
      );
    }

    final next = _policy.onFailure(state, now);
    final newlyLocked = _policy.isLocked(next, now);
    if (newlyLocked) {
      await _writer.runLocal<void>(
        action: 'auth.locked',
        entityType: 'user',
        entityId: user.id,
        details: {'until': next.lockedUntil!.toIso8601String()},
        body: () => _save(user.id, next, now),
      );
      return AccountLocked(next.lockedUntil!);
    }
    await _save(user.id, next, now);
    return WrongSecret(_policy.maxFailures - next.failures);
  }

  Future<void> _save(
    String userId,
    LoginState state,
    DateTime now, {
    String? newHash,
  }) {
    return (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        failures: Value(state.failures),
        lockCount: Value(state.lockCount),
        lockedUntil: Value(state.lockedUntil),
        credentialHash: newHash == null ? const Value.absent() : Value(newHash),
        updatedAt: Value(now),
      ),
    );
  }

  /// Sets a new PIN or password and clears any lock.
  Future<void> changeSecret({
    required String userId,
    required String newSecret,
    required String actor,
  }) async {
    final user = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(userId))).getSingle();
    final role = Role.fromDb(user.role);
    _checkSecret(role, newSecret);
    final hash = _hasher.hash(newSecret);
    final at = _now();
    await _writer.run<void>(
      action: 'user.secret_changed',
      entityType: 'user',
      entityId: userId,
      actor: actor,
      body: () => _save(userId, LoginState.fresh, at, newHash: hash),
    );
  }

  /// Stops a user signing in. Their past sales keep their name.
  Future<void> deactivate({required String userId, required String actor}) {
    final at = _now();
    return _writer.run<void>(
      action: 'user.deactivate',
      entityType: 'user',
      entityId: userId,
      actor: actor,
      body: () async {
        await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
          UsersCompanion(active: const Value(false), updatedAt: Value(at)),
        );
      },
    );
  }

  /// Who appears on the sign-in screen: active users, by name. No hashes.
  Future<List<SignInChoice>> signInChoices() async {
    final users =
        await (_db.select(_db.users)
              ..where((u) => u.active.equals(true))
              ..orderBy([(u) => OrderingTerm.asc(u.name)]))
            .get();
    return [
      for (final u in users)
        SignInChoice(userId: u.id, name: u.name, role: Role.fromDb(u.role)),
    ];
  }
}
