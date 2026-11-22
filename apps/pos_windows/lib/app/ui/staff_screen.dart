// Staff in Manager Mode (owner, 2026-11-22): add cashiers (the owner also adds
// managers), give a new PIN or password, rename, and turn people off and on.
// Turning someone off keeps all their history. Counters are not here: a second
// counter waits for Release 2 (sync). All rules live in core_domain and
// StaffRepository; this only collects input and shows results.
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/auth_service.dart';
import '../../data/staff_repository.dart';
import '../services.dart';
import '../session_controller.dart';

String _roleLabel(Role r) => switch (r) {
  Role.cashier => 'Cashier',
  Role.manager => 'Manager',
  Role.owner => 'Owner',
};

String _weakText(WeakSecret e) {
  final p = e.problem;
  if (e.role.usesPin) {
    return switch (p) {
      PinProblem.tooShort => 'The PIN needs at least $minPinLength digits.',
      PinProblem.tooLong => 'The PIN can have at most $maxPinLength digits.',
      _ => 'The PIN must be digits only.',
    };
  }
  return switch (p) {
    PasswordProblem.tooShort =>
      'The password needs at least $minPasswordLength characters.',
    PasswordProblem.tooLong =>
      'The password can have at most $maxPasswordLength characters.',
    _ => 'The password cannot be blank.',
  };
}

String _secretHelp(Role r) => r.usesPin
    ? 'PIN: $minPinLength to $maxPinLength digits'
    : 'Password: at least $minPasswordLength characters';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key, required this.session, required this.services});

  final SessionController session;
  final AppServices services;

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List<StaffMember>? _people;
  String? _message;
  bool _good = false;

  StaffRepository? get _repo => widget.services.staff;
  Role? get _role => widget.session.user?.role;
  String get _me => widget.session.user!.userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) {
      return;
    }
    try {
      final list = await repo.list(role: _role);
      if (mounted) {
        setState(() => _people = list);
      }
    } on PermissionDenied {
      if (mounted) {
        setState(() => _message = 'You may not manage staff.');
      }
    }
  }

  void _say(String text, {bool good = false}) {
    if (mounted) {
      setState(() {
        _message = text;
        _good = good;
      });
    }
  }

  /// Runs a change, shows what went wrong in words, then refreshes the list and
  /// the sign-in names.
  Future<void> _run(Future<void> Function() change, String done) async {
    try {
      await change();
      await widget.session.refreshChoices();
      await _load();
      _say(done, good: true);
    } on WeakSecret catch (e) {
      _say(_weakText(e));
    } on NameTaken catch (e) {
      _say('The name "${e.name}" is already used.');
    } on InvalidStaffName {
      _say(
        'Type a name of 1 to $maxPersonNameLength letters, with no line breaks.',
      );
    } on CannotTurnOff catch (e) {
      _say(turnOffText(e.block));
    } on PermissionDenied {
      _say('You may not do that.');
    }
  }

  Future<void> _add(Role role) async {
    final result = await showDialog<_NewPerson>(
      context: context,
      builder: (_) => _PersonDialog(role: role),
    );
    if (result == null) {
      return;
    }
    await _run(
      () => _repo!.add(
        actorRole: _role,
        actorId: _me,
        name: result.name,
        role: role,
        secret: result.secret,
      ),
      '${result.name} was added.',
    );
  }

  Future<void> _reset(StaffMember p) async {
    final result = await showDialog<_NewPerson>(
      context: context,
      builder: (_) => _PersonDialog(role: p.role, existing: p),
    );
    if (result == null) {
      return;
    }
    await _run(
      () => _repo!.resetSecret(
        actorRole: _role,
        actorId: _me,
        userId: p.id,
        newSecret: result.secret,
      ),
      'New ${p.role.usesPin ? 'PIN' : 'password'} saved for ${p.name}.',
    );
  }

  Future<void> _rename(StaffMember p) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(current: p.name),
    );
    if (name == null) {
      return;
    }
    await _run(
      () => _repo!.rename(
        actorRole: _role,
        actorId: _me,
        userId: p.id,
        name: name,
      ),
      'Renamed to ${cleanPersonName(name) ?? name}.',
    );
  }

  Future<void> _turnOff(StaffMember p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Turn off ${p.name}?'),
        content: const Text(
          'They will not be able to sign in. Their bills, returns and shifts '
          'stay as they are, and you can turn them on again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('turn-off-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Turn off'),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    await _run(
      () => _repo!.turnOff(actorRole: _role, actorId: _me, userId: p.id),
      '${p.name} is turned off.',
    );
  }

  Future<void> _turnOn(StaffMember p) => _run(
    () => _repo!.turnOn(actorRole: _role, actorId: _me, userId: p.id),
    '${p.name} is turned on.',
  );

  @override
  Widget build(BuildContext context) {
    final people = _people;
    final scheme = Theme.of(context).colorScheme;
    final isOwner = _role == Role.owner;
    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      body: people == null
          ? Center(
              child: _message != null
                  ? Text(_message!, key: const Key('staff-message'))
                  : const CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      key: const Key('add-cashier-button'),
                      onPressed: () => _add(Role.cashier),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add cashier'),
                    ),
                    if (isOwner)
                      OutlinedButton.icon(
                        key: const Key('add-manager-button'),
                        onPressed: () => _add(Role.manager),
                        icon: const Icon(Icons.manage_accounts),
                        label: const Text('Add manager'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'A second counter (another laptop) waits for Release 2, when '
                  'staff and stock can be shared between counters.',
                ),
                if (_message != null)
                  Container(
                    key: const Key('staff-message'),
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _good
                          ? scheme.primaryContainer
                          : scheme.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _good
                            ? scheme.onPrimaryContainer
                            : scheme.onErrorContainer,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                for (final p in people) _row(context, p),
              ],
            ),
    );
  }

  Widget _row(BuildContext context, StaffMember p) {
    final mine = canManageStaff(_role, p.role);
    final self = p.id == _me;
    return Card(
      key: Key('staff-${p.name}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    self ? '${p.name} (you)' : p.name,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Chip(label: Text(_roleLabel(p.role))),
                if (!p.active) ...[
                  const SizedBox(width: 8),
                  Chip(
                    key: Key('off-${p.name}'),
                    avatar: const Icon(Icons.block, size: 16),
                    label: const Text('Turned off'),
                  ),
                ],
              ],
            ),
            if (mine || self) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (p.active)
                    OutlinedButton(
                      key: Key('reset-${p.name}'),
                      onPressed: () => _reset(p),
                      child: Text(
                        self
                            ? 'Change my ${p.role.usesPin ? 'PIN' : 'password'}'
                            : 'New ${p.role.usesPin ? 'PIN' : 'password'}',
                      ),
                    ),
                  if (mine && p.active)
                    OutlinedButton(
                      key: Key('rename-${p.name}'),
                      onPressed: () => _rename(p),
                      child: const Text('Rename'),
                    ),
                  if (mine && !self && p.active)
                    OutlinedButton(
                      key: Key('turn-off-${p.name}'),
                      onPressed: () => _turnOff(p),
                      child: const Text('Turn off'),
                    ),
                  if (mine && !p.active)
                    FilledButton.tonal(
                      key: Key('turn-on-${p.name}'),
                      onPressed: () => _turnOn(p),
                      child: const Text('Turn on'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewPerson {
  const _NewPerson(this.name, this.secret);
  final String name;
  final String secret;
}

/// Name (new people only), the PIN or password, and it again.
class _PersonDialog extends StatefulWidget {
  const _PersonDialog({required this.role, this.existing});

  final Role role;
  final StaffMember? existing;

  @override
  State<_PersonDialog> createState() => _PersonDialogState();
}

class _PersonDialogState extends State<_PersonDialog> {
  final _name = TextEditingController();
  final _secret = TextEditingController();
  final _again = TextEditingController();
  String? _problem;

  @override
  void dispose() {
    _name.dispose();
    _secret.dispose();
    _again.dispose();
    super.dispose();
  }

  void _save() {
    final pin = widget.role.usesPin;
    if (widget.existing == null && cleanPersonName(_name.text) == null) {
      setState(
        () => _problem =
            'Type a name of 1 to $maxPersonNameLength letters, with no line breaks.',
      );
      return;
    }
    if (_secret.text != _again.text) {
      setState(
        () => _problem =
            'The two ${pin ? 'PINs' : 'passwords'} are not the same.',
      );
      return;
    }
    Navigator.of(context).pop(_NewPerson(_name.text, _secret.text));
  }

  @override
  Widget build(BuildContext context) {
    final pin = widget.role.usesPin;
    final isNew = widget.existing == null;
    return AlertDialog(
      title: Text(
        isNew
            ? 'Add ${_roleLabel(widget.role).toLowerCase()}'
            : 'New ${pin ? 'PIN' : 'password'} for ${widget.existing!.name}',
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isNew)
              TextField(
                key: const Key('staff-name'),
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
            TextField(
              key: const Key('staff-secret'),
              controller: _secret,
              obscureText: true,
              autofocus: !isNew,
              keyboardType: pin ? TextInputType.number : null,
              decoration: InputDecoration(
                labelText: pin ? 'PIN' : 'Password',
                helperText: _secretHelp(widget.role),
              ),
            ),
            TextField(
              key: const Key('staff-secret-again'),
              controller: _again,
              obscureText: true,
              keyboardType: pin ? TextInputType.number : null,
              decoration: InputDecoration(
                labelText: pin
                    ? 'Type the PIN again'
                    : 'Type the password again',
              ),
              onSubmitted: (_) => _save(),
            ),
            if (_problem != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _problem!,
                  key: const Key('staff-dialog-problem'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('staff-save'),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Owns its own text controller so it is disposed after the dialog has closed.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.current});
  final String current;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _c = TextEditingController(text: widget.current);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Rename ${widget.current}'),
    content: TextField(
      key: const Key('rename-field'),
      controller: _c,
      autofocus: true,
      decoration: const InputDecoration(labelText: 'Name'),
      onSubmitted: (v) => Navigator.of(context).pop(v),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('rename-save'),
        onPressed: () => Navigator.of(context).pop(_c.text),
        child: const Text('Save'),
      ),
    ],
  );
}
