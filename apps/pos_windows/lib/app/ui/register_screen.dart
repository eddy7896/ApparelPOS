// The billing register (P2-4c): scan or type a barcode, bill lines on the left,
// the total and payment on the right, then the saved bill with Print and New
// bill. Rules live in core_domain and SalesRepository; this only collects input
// and shows results. A bill in progress is forgotten when the counter locks.
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/auth_service.dart';
import '../../data/sales_repository.dart';
import '../bill_pdf.dart';
import '../services.dart';
import '../session_controller.dart';

/// The register as its own page (for a manager or owner opening it).
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({
    super.key,
    required this.session,
    required this.services,
  });

  final SessionController session;
  final AppServices services;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Billing')),
    body: RegisterPanel(session: session, services: services),
  );
}

class _Approver {
  const _Approver(this.userId, this.role, this.name);
  final String userId;
  final Role role;
  final String name;
}

class _Line {
  _Line(this.item);
  final SaleItem item;
  PriceCut? discount;

  PricedLine? get priced {
    try {
      return priceLine(mrp: item.mrp, cashierDiscount: discount);
    } on PriceCutTooLarge {
      return null;
    }
  }
}

class RegisterPanel extends StatefulWidget {
  const RegisterPanel({
    super.key,
    required this.session,
    required this.services,
  });

  final SessionController session;
  final AppServices services;

  @override
  State<RegisterPanel> createState() => _RegisterPanelState();
}

class _RegisterPanelState extends State<RegisterPanel> {
  final _barcode = TextEditingController();
  final _barcodeFocus = FocusNode();
  final _cash = TextEditingController();
  final _upi = TextEditingController();
  final _card = TextEditingController();
  final _customerName = TextEditingController();
  final _customerPhone = TextEditingController();
  final _lines = <_Line>[];
  _Approver? _approver;
  String? _message;
  bool _busy = false;
  SavedBill? _saved;
  String? _savedCustomerName;
  String? _savedCustomerPhone;

  AppServices get _s => widget.services;
  Role get _role => widget.session.user!.role;

  @override
  void dispose() {
    for (final c in [
      _barcode,
      _cash,
      _upi,
      _card,
      _customerName,
      _customerPhone,
    ]) {
      c.dispose();
    }
    _barcodeFocus.dispose();
    super.dispose();
  }

  void _say(String text) => setState(() => _message = text);

  // ---- money on screen ------------------------------------------------------

  Money get _total => _lines.fold<Money>(
    Money.zero,
    (sum, l) => sum + (l.priced?.finalPrice ?? l.item.mrp),
  );

  /// Typed payments; null when any box holds something that is not an amount.
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

  Settlement? get _settlement {
    final p = _payments;
    if (p == null) {
      return null;
    }
    try {
      return settle(_total, p);
    } on NonCashOverpayment {
      return null;
    }
  }

  String? get _paymentProblem {
    final p = _payments;
    if (p == null) {
      return 'An amount is not a valid rupee amount.';
    }
    try {
      settle(_total, p);
    } on NonCashOverpayment {
      return 'UPI and card together are more than the total.';
    }
    return null;
  }

  bool get _canComplete =>
      !_busy &&
      _lines.isNotEmpty &&
      _paymentProblem == null &&
      (_settlement?.isPaid ?? false);

  // ---- adding garments ------------------------------------------------------

  Future<void> _scan(String raw) async {
    final code = raw.trim();
    if (code.isEmpty) {
      _barcodeFocus.requestFocus();
      return;
    }
    _barcode.clear();
    widget.session.noteActivity();
    if (_lines.any((l) => l.item.barcode == code)) {
      _say('$code is already on this bill.');
      _barcodeFocus.requestFocus();
      return;
    }
    final item = await _s.sales.lookup(role: _role, barcode: code);
    if (!mounted) {
      return;
    }
    if (item == null) {
      _say('Not found: $code. Check the tag.');
    } else if (item.status == ArticleStatus.sold) {
      _say(
        'Already sold${item.soldOnBill == null ? '' : ' on bill ${item.soldOnBill}'}: $code.',
      );
    } else if (item.status != ArticleStatus.inStock) {
      _say('$code is not in stock (${item.status.dbValue}).');
    } else {
      setState(() {
        _lines.add(_Line(item));
        _message = null;
      });
    }
    _barcodeFocus.requestFocus();
  }

  // ---- discounts ------------------------------------------------------------

  Future<void> _editDiscount(_Line line) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _DiscountDialog(),
    );
    if (text == null || !mounted) {
      return;
    }
    if (text.trim().isEmpty) {
      setState(() {
        line.discount = null;
        _message = null;
      });
      return;
    }
    final cut = parsePriceCut(text);
    if (cut == null) {
      _say('"$text" is not a discount. Type 10% or an amount like 50.');
      return;
    }
    if (cut.amountOff != null && cut.amountOff! > line.item.mrp) {
      _say('A discount cannot be more than the price.');
      return;
    }
    final decision = discountDecision(
      _approver?.role ?? _role,
      cut,
      line.item.mrp,
    );
    if (decision == DiscountDecision.denied) {
      _say('You may not give discounts.');
      return;
    }
    if (decision == DiscountDecision.needsManagerOverride) {
      final approver = await _askManager();
      if (approver == null || !mounted) {
        return;
      }
      _approver = approver;
    }
    setState(() {
      line.discount = cut.isZero ? null : cut;
      _message = null;
    });
  }

  Future<_Approver?> _askManager() async {
    final choices = [
      for (final c in await _s.auth.signInChoices())
        if (can(c.role, Permission.overrideDiscountLimit)) c,
    ];
    if (!mounted) {
      return null;
    }
    if (choices.isEmpty) {
      _say('No manager or owner is set up to approve this discount.');
      return null;
    }
    return showDialog<_Approver>(
      context: context,
      builder: (_) => _ApprovalDialog(auth: _s.auth, choices: choices),
    );
  }

  // ---- saving ---------------------------------------------------------------

  Future<void> _complete() async {
    final payments = _payments;
    if (payments == null || _busy) {
      return;
    }
    setState(() => _busy = true);
    final name = _customerName.text;
    final phone = _customerPhone.text;
    try {
      final bill = await _s.sales.saveBill(
        role: _role,
        cashierId: widget.session.user!.userId,
        lines: [
          for (final l in _lines)
            BillLineInput(l.item.barcode, discount: l.discount),
        ],
        payments: payments,
        customerName: name,
        customerPhone: phone,
        discountApproverRole: _approver?.role,
        discountApprovedBy: _approver?.userId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _saved = bill;
        _savedCustomerName = name;
        _savedCustomerPhone = phone;
        _message = null;
      });
    } on ArticleNotSellable catch (e) {
      _say(
        e.reason == NotSellableReason.alreadySold
            ? '${e.barcode} was sold${e.soldOnBill == null ? '' : ' on bill ${e.soldOnBill}'}. Remove it and try again.'
            : '${e.barcode} cannot be sold. Remove it and try again.',
      );
    } on DiscountNeedsManager {
      _say('A discount needs the manager. Re-enter it to ask for approval.');
    } on BillNotPaid catch (e) {
      _say('Not fully paid: ${formatRupees(e.due)} still due.');
    } on InvalidBill catch (e) {
      _say('${e.message[0].toUpperCase()}${e.message.substring(1)}.');
    } on PermissionDenied {
      _say('You may not do that.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _print() async {
    final bill = _saved;
    if (bill == null) {
      return;
    }
    try {
      final sheet = describeBill(
        bill: bill,
        shopName: await _s.stock.shopName(),
        cashierName: widget.session.user!.name,
        customerName: _savedCustomerName,
        customerPhone: _savedCustomerPhone,
      );
      final pdf = await buildBillPdf(sheet, await _s.fonts());
      await _s.printer.printSheet(pdf, name: 'Bill ${sheet.billNo}');
    } on Object catch (e) {
      if (mounted) {
        _say('Could not print the bill: $e');
      }
    }
  }

  void _newBill() {
    setState(() {
      _lines.clear();
      _approver = null;
      _saved = null;
      _message = null;
      for (final c in [
        _barcode,
        _cash,
        _upi,
        _card,
        _customerName,
        _customerPhone,
      ]) {
        c.clear();
      }
    });
    _barcodeFocus.requestFocus();
  }

  // ---- screens --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final saved = _saved;
    if (saved != null) {
      return _SavedView(
        bill: saved,
        onPrint: _print,
        onNew: _newBill,
        message: _message,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _left(context)),
          const SizedBox(width: 16),
          SizedBox(width: 380, child: _right(context)),
        ],
      ),
    );
  }

  Widget _left(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('barcode-field'),
          controller: _barcode,
          focusNode: _barcodeFocus,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Scan or type the barcode, then Enter',
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
              ? const Center(child: Text('No garments yet. Scan a tag.'))
              : ListView(
                  key: const Key('bill-lines'),
                  children: [for (final l in _lines) _lineTile(l)],
                ),
        ),
      ],
    );
  }

  Widget _lineTile(_Line l) {
    final priced = l.priced;
    final off = priced == null ? Money.zero : priced.discountAmount;
    return Card(
      key: Key('line-${l.item.barcode}'),
      child: ListTile(
        title: Text('${l.item.productName}  ${l.item.size}  ${l.item.color}'),
        subtitle: Text(
          off.paise == 0
              ? 'MRP ${formatRupees(l.item.mrp)}   ${l.item.barcode}'
              : 'MRP ${formatRupees(l.item.mrp)}   off -${formatRupees(off)}   ${l.item.barcode}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatRupees(priced?.finalPrice ?? l.item.mrp),
              key: Key('price-${l.item.barcode}'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            TextButton(
              key: Key('discount-${l.item.barcode}'),
              onPressed: () => _editDiscount(l),
              child: const Text('Discount'),
            ),
            IconButton(
              key: Key('remove-${l.item.barcode}'),
              tooltip: 'Remove',
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _lines.remove(l);
                _message = null;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountField(String key, String label, TextEditingController c) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          key: Key(key),
          controller: c,
          decoration: InputDecoration(
            labelText: label,
            prefixText: '₹ ',
            border: const OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
        ),
      );

  Widget _right(BuildContext context) {
    final settlement = _settlement;
    final problem = _paymentProblem;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Total', style: Theme.of(context).textTheme.titleMedium),
          Text(
            formatRupees(_total),
            key: const Key('total-text'),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 12),
          _amountField('cash-field', 'Cash received', _cash),
          _amountField('upi-field', 'UPI', _upi),
          _amountField('card-field', 'Card', _card),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('exact-cash'),
              onPressed: _lines.isEmpty
                  ? null
                  : () => setState(() {
                      _cash.text =
                          (_total.paise ~/ 100).toString() +
                          ((_total.paise % 100) == 0
                              ? ''
                              : '.${(_total.paise % 100).toString().padLeft(2, '0')}');
                      _upi.clear();
                      _card.clear();
                    }),
              child: const Text('Exact cash'),
            ),
          ),
          if (problem != null)
            Text(
              problem,
              key: const Key('payment-problem'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else if (_lines.isNotEmpty &&
              settlement != null &&
              settlement.change.paise > 0)
            Text(
              'Change to give: ${formatRupees(settlement.change)}',
              key: const Key('change-text'),
              style: Theme.of(context).textTheme.titleMedium,
            )
          else if (_lines.isNotEmpty &&
              settlement != null &&
              !settlement.isPaid)
            Text(
              'Still due: ${formatRupees(settlement.due)}',
              key: const Key('due-text'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('customer-name'),
            controller: _customerName,
            decoration: const InputDecoration(
              labelText: 'Customer name (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('customer-phone'),
            controller: _customerPhone,
            decoration: const InputDecoration(
              labelText: 'Customer phone (optional)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('complete-bill'),
            onPressed: _canComplete ? _complete : null,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Complete bill'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedView extends StatelessWidget {
  const _SavedView({
    required this.bill,
    required this.onPrint,
    required this.onNew,
    required this.message,
  });

  final SavedBill bill;
  final VoidCallback onPrint;
  final VoidCallback onNew;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final change = bill.settlement.change;
    final t = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Bill saved',
              style: t.headlineSmall,
              key: const Key('saved-title'),
            ),
            Text(
              bill.billNumber.format(),
              key: const Key('saved-bill-no'),
              style: t.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final l in bill.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${l.productName} ${l.size} ${l.color}'),
                    ),
                    Text(formatRupees(l.priced.finalPrice)),
                  ],
                ),
              ),
            const Divider(),
            Text(
              'Total ${formatRupees(bill.total)}',
              key: const Key('saved-total'),
              style: t.headlineMedium,
            ),
            if (change.paise > 0)
              Text(
                'Change to give: ${formatRupees(change)}',
                key: const Key('saved-change'),
                style: t.titleLarge,
              ),
            if (message != null)
              Text(
                message!,
                key: const Key('message-banner'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  key: const Key('print-bill'),
                  onPressed: onPrint,
                  icon: const Icon(Icons.print),
                  label: const Text('Print bill'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  key: const Key('new-bill'),
                  onPressed: onNew,
                  child: const Text('New bill'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscountDialog extends StatefulWidget {
  const _DiscountDialog();
  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  final _c = TextEditingController();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Discount'),
    content: TextField(
      key: const Key('discount-input'),
      controller: _c,
      autofocus: true,
      decoration: const InputDecoration(
        labelText: 'Type 10% or an amount like 50 (empty removes it)',
      ),
      onSubmitted: (v) => Navigator.of(context).pop(v),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('discount-apply'),
        onPressed: () => Navigator.of(context).pop(_c.text),
        child: const Text('Apply'),
      ),
    ],
  );
}

class _ApprovalDialog extends StatefulWidget {
  const _ApprovalDialog({required this.auth, required this.choices});
  final AuthService auth;
  final List<SignInChoice> choices;
  @override
  State<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<_ApprovalDialog> {
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
            .pop(_Approver(result.userId, result.role, result.name));
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
        const Text(
          'This discount is over your limit. A manager or the owner must approve it.',
        ),
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
