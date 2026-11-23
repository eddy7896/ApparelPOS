// Staff management in Manager Mode (owner, 2026-11-22): add cashiers (and, for
// the owner, managers), give a new PIN or password, rename, and turn people off
// and on. The rules (who may manage whom, who cannot be turned off) are in
// core_domain. Turning someone off keeps all their history (E-AUDIT-1). No
// secret, hash or lockout detail is ever returned or written to the audit log.
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';
import 'auth_service.dart';

/// Thrown when a name is blank, too long or has odd characters.
final class InvalidStaffName implements Exception {
  @override
  String toString() => 'InvalidStaffName';
}

/// Thrown when a name is already used by another person (capitals ignored).
final class NameTaken implements Exception {
  NameTaken(this.name);
  final String name;
  @override
  String toString() => 'NameTaken: $name';
}

/// Thrown when a person cannot be turned off right now.
final class CannotTurnOff implements Exception {
  CannotTurnOff(this.block);
  final TurnOffBlock block;
  @override
  String toString() => 'CannotTurnOff: $block';
}

/// One person as the staff screen shows them. No hash, no lockout detail.
final class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.active,
    this.staffCode = 'OP---',
  });
  final String id;
  final String name;
  final Role role;
  final bool active;

  /// The operator ID printed on bills (never the name).
  final String staffCode;
}

class StaffRepository {
  StaffRepository(
    this._db,
    this._auth, {
    required String Function() newId,
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc()),
       _writer = AuditedWriter(_db, now: now, newId: newId);

  final AppDatabase _db;
  final AuthService _auth;
  final DateTime Function() _now;
  final AuditedWriter _writer;

  /// Everyone, people who are on first, then by name. Needs `manageUsers`.
  Future<List<StaffMember>> list({required Role? role}) async {
    require(role, Permission.manageUsers);
    final rows =
        await (_db.select(_db.users)..orderBy([
              (u) => OrderingTerm.desc(u.active),
              (u) => OrderingTerm.asc(u.name),
            ]))
            .get();
    return [
      for (final u in rows)
        StaffMember(
          id: u.id,
          name: u.name,
          role: Role.fromDb(u.role),
          active: u.active,
          staffCode: AuthService.codeOf(u.staffNumber),
        ),
    ];
  }

  void _mayManage(Role? actor, Role target) {
    require(actor, Permission.manageUsers);
    if (!canManageStaff(actor, target)) {
      throw PermissionDenied(actor, Permission.manageUsers);
    }
  }

  Future<UserRow> _user(String id) =>
      (_db.select(_db.users)..where((u) => u.id.equals(id))).getSingle();

  Future<String> _cleanName(String raw, {String? exceptId}) async {
    final clean = cleanPersonName(raw);
    if (clean == null) {
      throw InvalidStaffName();
    }
    final taken = await _db
        .customSelect(
          'SELECT id FROM users WHERE lower(name) = lower(?) AND id != ?',
          variables: [
            Variable<String>(clean),
            Variable<String>(exceptId ?? ''),
          ],
        )
        .get();
    if (taken.isNotEmpty) {
      throw NameTaken(clean);
    }
    return clean;
  }

  /// Adds a person and returns their id. The owner may add any role; a manager
  /// only cashiers. Throws [PermissionDenied], [InvalidStaffName], [NameTaken]
  /// or [WeakSecret] (and then saves nothing).
  Future<String> add({
    required Role? actorRole,
    required String actorId,
    required String name,
    required Role role,
    required String secret,
  }) async {
    _mayManage(actorRole, role);
    final clean = await _cleanName(name);
    return _auth.createUser(
      name: clean,
      role: role,
      secret: secret,
      actor: actorId,
    );
  }

  /// A new PIN or password (clears a lockout). A person may change their own;
  /// otherwise the actor must be allowed to manage that role.
  Future<void> resetSecret({
    required Role? actorRole,
    required String actorId,
    required String userId,
    required String newSecret,
  }) async {
    require(actorRole, Permission.manageUsers);
    final target = await _user(userId);
    if (userId != actorId) {
      _mayManage(actorRole, Role.fromDb(target.role));
    }
    await _auth.changeSecret(
      userId: userId,
      newSecret: newSecret,
      actor: actorId,
    );
  }

  Future<void> rename({
    required Role? actorRole,
    required String actorId,
    required String userId,
    required String name,
  }) async {
    final target = await _user(userId);
    _mayManage(actorRole, Role.fromDb(target.role));
    final clean = await _cleanName(name, exceptId: userId);
    final at = _now();
    await _writer.run<void>(
      action: 'user.rename',
      entityType: 'user',
      entityId: userId,
      actor: actorId,
      body: () async {
        await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
          UsersCompanion(name: Value(clean), updatedAt: Value(at)),
        );
      },
    );
  }

  /// Stops [userId] signing in; all their history stays. Throws
  /// [PermissionDenied] or [CannotTurnOff] (yourself, the last owner, an open
  /// shift). Turning off someone who is already off does nothing.
  Future<void> turnOff({
    required Role? actorRole,
    required String actorId,
    required String userId,
  }) async {
    require(actorRole, Permission.manageUsers);
    final target = await _user(userId);
    final targetRole = Role.fromDb(target.role);
    final owners =
        (await _db
                .customSelect(
                  "SELECT COUNT(*) AS c FROM users WHERE role = 'OWNER' AND active = 1",
                )
                .getSingle())
            .read<int>('c');
    final open =
        (await _db
                .customSelect(
                  'SELECT COUNT(*) AS c FROM shifts s WHERE s.cashier_id = ? '
                  'AND NOT EXISTS (SELECT 1 FROM shift_closes c WHERE c.shift_id = s.id)',
                  variables: [Variable<String>(userId)],
                )
                .getSingle())
            .read<int>('c');
    final block = turnOffBlock(
      actor: actorRole,
      target: targetRole,
      isSelf: userId == actorId,
      isLastActiveOwner:
          targetRole == Role.owner && target.active && owners <= 1,
      hasOpenShift: open > 0,
    );
    if (block == TurnOffBlock.notAllowed) {
      throw PermissionDenied(actorRole, Permission.manageUsers);
    }
    if (block != null) {
      throw CannotTurnOff(block);
    }
    if (!target.active) {
      return;
    }
    await _auth.deactivate(userId: userId, actor: actorId);
  }

  /// Lets [userId] sign in again. Turning on someone who is already on does
  /// nothing.
  Future<void> turnOn({
    required Role? actorRole,
    required String actorId,
    required String userId,
  }) async {
    final target = await _user(userId);
    _mayManage(actorRole, Role.fromDb(target.role));
    if (target.active) {
      return;
    }
    final at = _now();
    await _writer.run<void>(
      action: 'user.activate',
      entityType: 'user',
      entityId: userId,
      actor: actorId,
      body: () async {
        await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
          UsersCompanion(active: const Value(true), updatedAt: Value(at)),
        );
      },
    );
  }
}
