// The returns screen (P2-5c): scan a sold garment, choose what happens to it
// and how the refund is paid, finish the return. Past the 7-day window a
// manager or owner types their password. A credit note refund prints a slip;
// an exchange opens the register with that note applied. Rules are in
// core_domain and ReturnsRepository; this only collects input and shows
// results. A return in progress is forgotten when the counter locks.
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/returns_repository.dart';
import '../credit_note_slip.dart';
import '../services.dart';
import '../session_controller.dart';
import 'approval_dialog.dart';
import 'register_screen.dart';
import 'shift_gate.dart';

/// How the customer is paid out. An exchange is a credit note that the
/// register applies to the new bill at once.
enum RefundChoice {
  cash('Cash', RefundMode.cash),
  upi('UPI', RefundMode.upi),
  card('Card', RefundMode.card),
  creditNote('Credit note', RefundMode.creditNote),
  exchange('Exchange', RefundMode.creditNote);

  const RefundChoice(this.label, this.mode);
  final String label;
  final RefundMode mode;
}

class _RetLine {
  _RetLine(this.candidate);
  final ReturnCandidate candidate;
  ReturnOutcome outcome = ReturnOutcome.restock;
  final note = TextEditingController();
}

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({
    super.key,
    required this.session,
    required this.services,
  });

  final SessionController session;
  final AppServices services;

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  final _barcode = TextEditingController();
  final _focus = FocusNode();
  final _lines = <_RetLine>[];
  RefundChoice? _choice;
  Approver? _approver;
  String? _message;
  bool _busy = false;
  SavedReturn? _saved;
  RefundChoice? _savedChoice;

  AppServices get _s => widget.services;
  Role get _role => widget.session.user!.role;

  @override
  void dispose() {
    _barcode.dispose();
    _focus.dispose();
    for (final l in _lines) {
      l.note.dispose();
    }
    super.dispose();
  }

  void _say(String text) => setState(() => _message = text);

  Money get _total =>
      refundTotal([for (final l in _lines) l.candidate.netPrice]);

  bool get _needsApproval =>
      _lines.any((l) => l.candidate.timing == ReturnTiming.needsApproval) &&
      !can(_role, Permission.approveLateReturn);

  bool get _canComplete =>
      !_busy &&
      _lines.isNotEmpty &&
      _choice != null &&
      _lines.every(
        (l) =>
            l.outcome == ReturnOutcome.restock || l.note.text.trim().isNotEmpty,
      );

  Future<void> _scan(String raw) async {
    final code = raw.trim();
    if (code.isEmpty) {
      _focus.requestFocus();
      return;
    }
    _barcode.clear();
    widget.session.noteActivity();
    if (_lines.any((l) => l.candidate.barcode == code)) {
      _say('$code is already in this return.');
      _focus.requestFocus();
      return;
    }
    try {
      final c = await _s.returns.lookup(role: _role, barcode: code);
      if (!mounted) {
        return;
      }
      if (c == null) {
        _say('Not found: $code. Check the tag.');
      } else {
        setState(() {
          _lines.add(_RetLine(c));
          _message = null;
        });
      }
    } on GarmentNotReturnable catch (e) {
      if (mounted) {
        _say(
          e.reason == NotReturnableReason.alreadyReturned
              ? '$code was already returned.'
              : '$code was never sold, so it cannot be returned.',
        );
      }
    }
    _focus.requestFocus();
  }

  Future<void> _complete() async {
    final choice = _choice;
    if (choice == null || _busy) {
      return;
    }
    if (_needsApproval && _approver == null) {
      final who = await askApprover(
        context,
        _s.auth,
        permission: Permission.approveLateReturn,
        message:
            'This garment was sold more than $defaultReturnWindowDays days ago. A manager or the owner must approve the return.',
        onNobody: _say,
      );
      if (who == null || !mounted) {
        return;
      }
      _approver = who;
    }
    setState(() => _busy = true);
    try {
      final saved = await _s.returns.saveReturn(
        role: _role,
        cashierId: widget.session.user!.userId,
        items: [
          for (final l in _lines)
            ReturnItemInput(
              l.candidate.barcode,
              l.outcome,
              note: l.note.text.trim().isEmpty ? null : l.note.text,
            ),
        ],
        refundMode: choice.mode,
        approverRole: _approver?.role,
        approvedBy: _approver?.userId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _saved = saved;
        _savedChoice = choice;
        _message = null;
      });
    } on ReturnNeedsApproval {
      _say('A manager or the owner must approve this return.');
    } on GarmentNotReturnable catch (e) {
      _say('${e.barcode} can no longer be returned. Remove it and try again.');
    } on InvalidReturn catch (e) {
      _say('${e.message[0].toUpperCase()}${e.message.substring(1)}.');
    } on PermissionDenied {
      _say('You may not do that.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _printSlip() async {
    final note = _saved?.creditNote;
    if (note == null) {
      return;
    }
    try {
      final slip = describeSlip(
        note: note,
        shopName: await _s.stock.shopName(),
      );
      final pdf = await buildCreditNoteSlipPdf(slip, await _s.fonts());
      await _s.printer.printSheet(pdf, name: 'Credit note ${slip.noteNumber}');
    } on Object catch (e) {
      if (mounted) {
        _say('Could not print the credit note: $e');
      }
    }
  }

  void _startExchange() {
    final note = _saved?.creditNote;
    if (note == null) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => RegisterScreen(
          session: widget.session,
          services: _s,
          creditNoteCode: note.code,
        ),
      ),
    );
  }

  void _newReturn() {
    setState(() {
      for (final l in _lines) {
        l.note.dispose();
      }
      _lines.clear();
      _choice = null;
      _approver = null;
      _saved = null;
      _savedChoice = null;
      _message = null;
    });
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Returns')),
    body: ShiftGate(
      session: widget.session,
      services: _s,
      child: _saved != null ? _savedView(context) : _form(context),
    ),
  );

  Widget _form(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  key: const Key('return-barcode-field'),
                  controller: _barcode,
                  focusNode: _focus,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText:
                        'Scan or type the barcode of the garment, then Enter',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code_scanner),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: _scan,
                ),
                if (_message != null)
                  Container(
                    key: const Key('message-banner'),
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    color: scheme.errorContainer,
                    child: Text(
                      _message!,
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: _lines.isEmpty
                      ? const Center(
                          child: Text('No garments yet. Scan a tag.'),
                        )
                      : ListView(
                          key: const Key('return-lines'),
                          children: [for (final l in _lines) _lineTile(l)],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(width: 380, child: _right(context)),
        ],
      ),
    );
  }

  Widget _lineTile(_RetLine l) {
    final c = l.candidate;
    final late = c.timing == ReturnTiming.needsApproval;
    return Card(
      key: Key('return-line-${c.barcode}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${c.productName}  ${c.size}  ${c.color}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  formatRupees(c.netPrice),
                  key: Key('refund-${c.barcode}'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  key: Key('return-remove-${c.barcode}'),
                  tooltip: 'Remove',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _lines.remove(l);
                    l.note.dispose();
                    _message = null;
                  }),
                ),
              ],
            ),
            Text('Sold on bill ${c.billNo}   ${c.barcode}'),
            if (late)
              Text(
                'Sold more than $defaultReturnWindowDays days ago: needs a manager or the owner.',
                key: Key('late-${c.barcode}'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 8),
            SegmentedButton<ReturnOutcome>(
              key: Key('outcome-${c.barcode}'),
              segments: const [
                ButtonSegment(
                  value: ReturnOutcome.restock,
                  label: Text('Back in stock'),
                ),
                ButtonSegment(
                  value: ReturnOutcome.damaged,
                  label: Text('Damaged'),
                ),
              ],
              selected: {l.outcome},
              onSelectionChanged: (s) => setState(() => l.outcome = s.first),
            ),
            if (l.outcome == ReturnOutcome.damaged)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  key: Key('note-${c.barcode}'),
                  controller: l.note,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'What is wrong with it? (required)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _right(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Refund', style: Theme.of(context).textTheme.titleMedium),
        Text(
          formatRupees(_total),
          key: const Key('refund-total'),
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 12),
        const Text('Pay out as'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in RefundChoice.values)
              ChoiceChip(
                key: Key('refund-mode-${c.name}'),
                label: Text(c.label),
                selected: _choice == c,
                onSelected: (_) => setState(() => _choice = c),
              ),
          ],
        ),
        if (_lines.any((l) => l.candidate.timing == ReturnTiming.needsApproval))
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('A manager or the owner will be asked to approve.'),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('complete-return'),
          onPressed: _canComplete ? _complete : null,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Complete return'),
          ),
        ),
      ],
    ),
  );

  Widget _savedView(BuildContext context) {
    final saved = _saved!;
    final choice = _savedChoice!;
    final t = Theme.of(context).textTheme;
    final note = saved.creditNote;
    final String payout = switch (choice) {
      RefundChoice.cash => 'Give back ${formatRupees(saved.total)} in cash.',
      RefundChoice.upi => 'Send ${formatRupees(saved.total)} back by UPI.',
      RefundChoice.card => 'Refund ${formatRupees(saved.total)} to the card.',
      RefundChoice.creditNote || RefundChoice.exchange =>
        'Credit note for ${formatRupees(saved.total)} issued.',
    };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Return saved',
              style: t.headlineSmall,
              key: const Key('return-saved-title'),
            ),
            const SizedBox(height: 12),
            for (final l in saved.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${l.productName} ${l.size} ${l.color}'),
                    ),
                    Text(formatRupees(l.netPrice)),
                  ],
                ),
              ),
            const Divider(),
            Text(payout, key: const Key('payout-text'), style: t.titleLarge),
            if (note != null) ...[
              const SizedBox(height: 8),
              Text('Code ${note.code}', key: const Key('note-code')),
              Text(
                'Valid till ${note.lastDay.day.toString().padLeft(2, '0')}-${note.lastDay.month.toString().padLeft(2, '0')}-${note.lastDay.year}',
                key: const Key('note-valid-till'),
              ),
            ],
            if (_message != null)
              Text(
                _message!,
                key: const Key('message-banner'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (note != null)
                  OutlinedButton.icon(
                    key: const Key('print-slip'),
                    onPressed: _printSlip,
                    icon: const Icon(Icons.print),
                    label: const Text('Print credit note'),
                  ),
                if (choice == RefundChoice.exchange)
                  FilledButton(
                    key: const Key('start-exchange'),
                    onPressed: _startExchange,
                    child: const Text('Start new bill with this credit note'),
                  ),
                FilledButton.tonal(
                  key: const Key('new-return'),
                  onPressed: _newReturn,
                  child: const Text('New return'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
