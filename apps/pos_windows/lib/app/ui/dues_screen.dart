// Pay later (udhaar), owner 2026-11-23: who owes what, taking a payment against
// it, and (owner only) writing a debt off. The counter takes the money, so it
// needs an open shift like billing and returns. Rules are in core_domain
// (dues_rules); data in DuesRepository. No cost is shown.
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/dues_repository.dart';
import '../../data/shift_repository.dart';
import '../bill_pdf.dart' show billDateText;
import '../services.dart';
import '../session_controller.dart';
import 'shift_gate.dart';
import 'ui_tokens.dart';

class DuesScreen extends StatelessWidget {
  const DuesScreen({super.key, required this.session, required this.services});

  final SessionController session;
  final AppServices services;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pay later (udhaar)')),
    body: ShiftGate(
      session: session,
      services: services,
      child: DuesPanel(session: session, services: services),
    ),
  );
}

String _dateOnly(DateTime utc) => billDateText(utc).split(' ').first;

class DuesPanel extends StatefulWidget {
  const DuesPanel({super.key, required this.session, required this.services});

  final SessionController session;
  final AppServices services;

  @override
  State<DuesPanel> createState() => _DuesPanelState();
}

class _DuesPanelState extends State<DuesPanel> {
  List<CustomerDues>? _customers;
  Money _total = Money.zero;
  CustomerDetail? _detail;
  String _search = '';
  String? _message;
  bool _good = false;
  bool _busy = false;

  DuesRepository get _repo => widget.services.dues!;
  Role? get _role => widget.session.user?.role;
  String get _me => widget.session.user!.userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? keep}) async {
    try {
      final list = await _repo.customers(role: _role);
      final total = await _repo.totalOwed(role: _role);
      final id = keep ?? _detail?.customer.id;
      final detail = id == null
          ? null
          : await _repo.detail(role: _role, customerId: id);
      if (mounted) {
        setState(() {
          _customers = list;
          _total = total;
          // A customer who has just paid up stays on screen until another is
          // picked, so the cashier sees "Owes nothing now".
          _detail = detail;
        });
      }
    } on PermissionDenied {
      if (mounted) {
        setState(() => _message = 'You may not see this.');
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

  Future<void> _pick(CustomerDues c) async {
    final d = await _repo.detail(role: _role, customerId: c.id);
    if (mounted) {
      setState(() {
        _detail = d;
        _message = null;
      });
    }
  }

  Future<void> _takePayment() async {
    final d = _detail;
    if (d == null || _busy) {
      return;
    }
    final payments = await showDialog<List<Payment>>(
      context: context,
      builder: (_) =>
          _PaymentDialog(name: d.customer.name, owed: d.customer.owed),
    );
    if (payments == null || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await _repo.receivePayment(
        role: _role,
        userId: _me,
        customerId: d.customer.id,
        payments: payments,
      );
      await _load(keep: d.customer.id);
      _say(
        'Took ${formatRupees(r.applied)} from ${d.customer.name}. '
        '${r.remaining.paise == 0 ? 'Nothing is owed now.' : 'Still owed: ${formatRupees(r.remaining)}.'}'
        '${r.change.paise > 0 ? ' Give ${formatRupees(r.change)} change.' : ''}',
        good: true,
      );
    } on NonCashOverpayment {
      _say('UPI and card together are more than is owed.');
    } on NothingOwed {
      _say('This customer owes nothing now.');
      await _load(keep: d.customer.id);
    } on InvalidDues catch (e) {
      _say('${e.message[0].toUpperCase()}${e.message.substring(1)}.');
    } on NoOpenShift {
      _say('Open your shift before taking money.');
    } on PermissionDenied {
      _say('You may not do that.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _writeOff() async {
    final d = _detail;
    if (d == null || _busy) {
      return;
    }
    final result = await showDialog<(Money, String)>(
      context: context,
      builder: (_) =>
          _WriteOffDialog(name: d.customer.name, owed: d.customer.owed),
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await _repo.writeOff(
        role: _role,
        actorId: _me,
        customerId: d.customer.id,
        amount: result.$1,
        note: result.$2,
      );
      await _load(keep: d.customer.id);
      _say(
        'Wrote off ${formatRupees(result.$1)} for ${d.customer.name}.',
        good: true,
      );
    } on NothingOwed {
      _say('This customer owes nothing now.');
      await _load(keep: d.customer.id);
    } on InvalidDues catch (e) {
      _say('${e.message[0].toUpperCase()}${e.message.substring(1)}.');
    } on PermissionDenied {
      _say('Only the owner may write off a debt.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = _customers;
    if (customers == null) {
      return Center(
        child: _message != null
            ? Text(_message!, key: const Key('dues-message'))
            : const CircularProgressIndicator(),
      );
    }
    final q = _search.trim().toLowerCase();
    final qDigits = q.replaceAll(RegExp(r'[^0-9]'), '');
    final shown = [
      for (final c in customers)
        if (q.isEmpty ||
            c.name.toLowerCase().contains(q) ||
            (qDigits.isNotEmpty && c.phone.contains(qDigits)))
          c,
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_message != null)
            Container(
              key: const Key('dues-message'),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _good ? UiColors.successSoft : UiColors.dangerSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _message!,
                style: TextStyle(
                  color: _good ? UiColors.successInk : UiColors.dangerInk,
                ),
              ),
            ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 420, child: _left(context, shown, customers)),
                const SizedBox(width: 16),
                Expanded(child: _right(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _left(
    BuildContext context,
    List<CustomerDues> shown,
    List<CustomerDues> all,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Everyone owes',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              formatRupees(_total),
              key: const Key('dues-total'),
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              '${all.length} ${all.length == 1 ? 'customer' : 'customers'}',
              key: const Key('dues-count'),
              style: const TextStyle(color: UiColors.inkMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('dues-search'),
              decoration: const InputDecoration(
                labelText: 'Find by name or phone',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: all.isEmpty
                  ? const Center(
                      child: Text(
                        'Nobody owes anything.',
                        key: Key('dues-empty'),
                      ),
                    )
                  : shown.isEmpty
                  ? const Center(
                      child: Text('No one matches.', key: Key('dues-none')),
                    )
                  : ListView(
                      children: [
                        for (final c in shown)
                          ListTile(
                            key: Key('dues-customer-${c.phone}'),
                            selected: _detail?.customer.id == c.id,
                            title: Text(
                              c.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${c.phone}   ${c.billCount} ${c.billCount == 1 ? 'bill' : 'bills'}'
                              '${c.oldestBillAt == null ? '' : ', since ${_dateOnly(c.oldestBillAt!)}'}',
                            ),
                            trailing: Text(
                              formatRupees(c.owed),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            onTap: () => _pick(c),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static const _kindNames = {
    'OWED': 'Left to pay later',
    'PAYMENT': 'Paid',
    'RETURN_OFFSET': 'Garment returned',
    'WRITE_OFF': 'Written off',
  };

  Widget _right(BuildContext context) {
    final d = _detail;
    if (d == null) {
      return const Card(
        margin: EdgeInsets.zero,
        child: Center(
          child: Text(
            'Pick a customer to see their bills and take a payment.',
            key: Key('dues-pick'),
          ),
        ),
      );
    }
    final c = d.customer;
    final canWriteOff = can(_role, Permission.writeOffDebt);
    return Card(
      margin: EdgeInsets.zero,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            c.name,
            key: const Key('detail-name'),
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(c.phone, key: const Key('detail-phone')),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.owed.paise > 0
                  ? UiColors.amberSoft
                  : UiColors.successSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              c.owed.paise > 0
                  ? 'Owes ${formatRupees(c.owed)}'
                  : 'Owes nothing now',
              key: const Key('detail-owed'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: c.owed.paise > 0
                    ? UiColors.amberInk
                    : UiColors.successInk,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton(
                key: const Key('take-payment'),
                onPressed: c.owed.paise > 0 && !_busy ? _takePayment : null,
                child: const Text('Take payment'),
              ),
              if (canWriteOff)
                OutlinedButton(
                  key: const Key('write-off'),
                  onPressed: c.owed.paise > 0 && !_busy ? _writeOff : null,
                  child: const Text('Write off'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Bills still owing',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          if (d.bills.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('None.'),
            ),
          for (final b in d.bills)
            Padding(
              key: Key('due-bill-${b.billNo}'),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${b.billNo}   ${_dateOnly(b.billedAt)}   bill ${formatRupees(b.total)}',
                    ),
                  ),
                  Text(
                    formatRupees(b.outstanding),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          const Text('History', style: TextStyle(fontWeight: FontWeight.w700)),
          for (var i = 0; i < d.history.length; i++)
            Padding(
              key: Key('history-$i'),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_dateOnly(d.history[i].at)}   '
                      '${_kindNames[d.history[i].kind] ?? d.history[i].kind}   '
                      '${d.history[i].billNo}'
                      '${d.history[i].note == null ? '' : '   (${d.history[i].note})'}',
                    ),
                  ),
                  Text(
                    d.history[i].amount.paise > 0
                        ? '+${formatRupees(d.history[i].amount)}'
                        : '-${formatRupees(Money(-d.history[i].amount.paise))}',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// How much the customer hands over, in cash, UPI and card.
class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.name, required this.owed});
  final String name;
  final Money owed;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _cash = TextEditingController();
  final _upi = TextEditingController();
  final _card = TextEditingController();

  @override
  void dispose() {
    for (final c in [_cash, _upi, _card]) {
      c.dispose();
    }
    super.dispose();
  }

  /// The payments typed; null when a box is not an amount.
  List<Payment>? get _payments {
    final out = <Payment>[];
    for (final (mode, c) in [
      (PaymentMode.cash, _cash),
      (PaymentMode.upi, _upi),
      (PaymentMode.card, _card),
    ]) {
      final t = c.text.trim();
      if (t.isEmpty) {
        continue;
      }
      final m = parseRupees(t);
      if (m == null) {
        return null;
      }
      if (m.paise > 0) {
        out.add(Payment(mode, m));
      }
    }
    return out;
  }

  ({String? problem, Settlement? settlement}) get _state {
    final p = _payments;
    if (p == null) {
      return (
        problem: 'An amount is not a valid rupee amount.',
        settlement: null,
      );
    }
    if (p.isEmpty) {
      return (problem: null, settlement: null);
    }
    try {
      return (problem: null, settlement: settle(widget.owed, p));
    } on NonCashOverpayment {
      return (
        problem: 'UPI and card together are more than is owed.',
        settlement: null,
      );
    }
  }

  Widget _field(String key, String label, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      key: Key(key),
      controller: c,
      decoration: InputDecoration(labelText: label, prefixText: '₹ '),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final st = _state;
    final s = st.settlement;
    final ready = st.problem == null && s != null;
    return AlertDialog(
      title: Text('Payment from ${widget.name}'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Owes ${formatRupees(widget.owed)}',
                key: const Key('pay-owes'),
              ),
              const SizedBox(height: 8),
              ActionChip(
                key: const Key('pay-all'),
                label: Text('Pay all in cash (${formatRupees(widget.owed)})'),
                onPressed: () => setState(() {
                  _cash.text =
                      '${widget.owed.paise ~/ 100}'
                      '${widget.owed.paise % 100 == 0 ? '' : '.${(widget.owed.paise % 100).toString().padLeft(2, '0')}'}';
                  _upi.clear();
                  _card.clear();
                }),
              ),
              const SizedBox(height: 12),
              _field('pay-cash', 'Cash', _cash),
              _field('pay-upi', 'UPI', _upi),
              _field('pay-card', 'Card', _card),
              if (st.problem != null)
                Text(
                  st.problem!,
                  key: const Key('pay-problem'),
                  style: const TextStyle(color: UiColors.dangerInk),
                )
              else if (s != null)
                Text(
                  'Takes ${formatRupees(widget.owed - s.due)} off. '
                  '${s.due.paise == 0 ? 'Nothing is owed after this.' : 'Still owed after: ${formatRupees(s.due)}.'}'
                  '${s.change.paise > 0 ? ' Give ${formatRupees(s.change)} change.' : ''}',
                  key: const Key('pay-preview'),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('pay-save'),
          onPressed: ready ? () => Navigator.of(context).pop(_payments) : null,
          child: const Text('Take payment'),
        ),
      ],
    );
  }
}

/// How much to write off, and why.
class _WriteOffDialog extends StatefulWidget {
  const _WriteOffDialog({required this.name, required this.owed});
  final String name;
  final Money owed;

  @override
  State<_WriteOffDialog> createState() => _WriteOffDialogState();
}

class _WriteOffDialogState extends State<_WriteOffDialog> {
  late final _amount = TextEditingController(
    text:
        '${widget.owed.paise ~/ 100}'
        '${widget.owed.paise % 100 == 0 ? '' : '.${(widget.owed.paise % 100).toString().padLeft(2, '0')}'}',
  );
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _save() {
    final m = parseRupees(_amount.text.trim());
    if (m == null || m.paise <= 0) {
      setState(() => _error = 'Type an amount above zero.');
      return;
    }
    if (m > widget.owed) {
      setState(() => _error = 'That is more than the customer owes.');
      return;
    }
    final why = _reason.text.trim();
    if (why.isEmpty) {
      setState(() => _error = 'Say why the debt is written off.');
      return;
    }
    if (why.length > 200) {
      setState(() => _error = 'The reason is longer than 200 characters.');
      return;
    }
    Navigator.of(context).pop((m, why));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Write off for ${widget.name}'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Owes ${formatRupees(widget.owed)}. The money is not paid; the '
            'bills and this record stay.',
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('writeoff-amount'),
            controller: _amount,
            decoration: const InputDecoration(
              labelText: 'Amount to write off',
              prefixText: '₹ ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('writeoff-reason'),
            controller: _reason,
            decoration: const InputDecoration(labelText: 'Why (required)'),
            onChanged: (_) => setState(() => _error = null),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              key: const Key('writeoff-error'),
              style: const TextStyle(color: UiColors.dangerInk),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('writeoff-save'),
        onPressed: _save,
        child: const Text('Write off'),
      ),
    ],
  );
}
