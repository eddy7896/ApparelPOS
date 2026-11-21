// A manager or the owner types their own password to approve something a
// cashier may not do alone (a big discount, a late return). The check is the
// normal sign-in, so wrong tries count toward the lockout (ADR-0002).
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/auth_service.dart';

/// Who approved.
class Approver {
  const Approver(this.userId, this.role, this.name);
  final String userId;
  final Role role;
  final String name;
}

/// Shows the approval pop-up for people who hold [permission]. Returns who
/// approved, or null if cancelled or nobody can approve (then [onNobody] is
/// called with a message).
Future<Approver?> askApprover(
  BuildContext context,
  AuthService auth, {
  required Permission permission,
  required String message,
  required void Function(String) onNobody,
}) async {
  final choices = [
    for (final c in await auth.signInChoices())
      if (can(c.role, permission)) c,
  ];
  if (!context.mounted) {
    return null;
  }
  if (choices.isEmpty) {
    onNobody('No manager or owner is set up to approve this.');
    return null;
  }
  return showDialog<Approver>(
    context: context,
    builder: (_) =>
        ApprovalDialog(auth: auth, choices: choices, message: message),
  );
}

class ApprovalDialog extends StatefulWidget {
  const ApprovalDialog({
    super.key,
    required this.auth,
    required this.choices,
    required this.message,
  });
  final AuthService auth;
  final List<SignInChoice> choices;

  /// Why approval is needed, shown above the password box.
  final String message;
  @override
  State<ApprovalDialog> createState() => ApprovalDialogState();
}

class ApprovalDialogState extends State<ApprovalDialog> {
  final _password = TextEditingController();
  late SignInChoice _who = widget.choices.first;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.auth.signIn(
      userId: _who.userId,
      secret: _password.text,
    );
    if (!mounted) {
      return;
    }
    switch (result) {
      case SignedIn():
        Navigator.of(context)
            .pop(Approver(result.userId, result.role, result.name));
      case WrongSecret():
        setState(() {
          _busy = false;
          _error = 'Wrong password. ${result.triesLeft} tries left.';
        });
      case AccountLocked():
        setState(() {
          _busy = false;
          _error = 'That account is locked for now.';
        });
      case UnknownUser():
        setState(() {
          _busy = false;
          _error = 'That user is not available.';
        });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Manager approval'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.message),
        const SizedBox(height: 12),
        DropdownButton<SignInChoice>(
          key: const Key('approver-picker'),
          value: _who,
          isExpanded: true,
          items: [
            for (final c in widget.choices)
              DropdownMenuItem(value: c, child: Text(c.name)),
          ],
          onChanged: (c) => setState(() => _who = c!),
        ),
        TextField(
          key: const Key('approver-password'),
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Their password'),
          onSubmitted: (_) => _approve(),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              key: const Key('approval-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('approver-ok'),
        onPressed: _busy ? null : _approve,
        child: const Text('Approve'),
      ),
    ],
  );
}
