// The billing register (P2-4c): scan or type a barcode, bill lines on the left,
// the total and payment on the right, then the saved bill with Print and New
// bill. Rules live in core_domain and SalesRepository; this only collects input
// and shows results. A bill in progress is forgotten when the counter locks.
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/sales_repository.dart';
import '../../data/stock_lookup_repository.dart';
import '../bill_pdf.dart';
import 'approval_dialog.dart';
import 'close_shift_screen.dart';
import 'shift_gate.dart';
import 'status_colors.dart';
import '../services.dart';
import '../session_controller.dart';

/// The register as its own page (for a manager or owner opening it).
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({
    super.key,
    required this.session,
    required this.services,
    this.creditNoteCode,
  });

  final SessionController session;
  final AppServices services;

  /// A credit note to apply at once (an exchange starts this way).
  final String? creditNoteCode;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Billing')),
    body: ShiftGate(
      session: session,
      services: services,
      child: RegisterPanel(
        session: session,
        services: services,
        creditNoteCode: creditNoteCode,
      ),
    ),
  );
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
    this.creditNoteCode,
    this.billInProgress,
    this.showCloseShift = true,
  });

  final SessionController session;
  final AppServices services;

  /// A credit note to apply as soon as the register opens (an exchange).
  final String? creditNoteCode;

  /// Told whether a bill is being made, so the top bar can enable Pause and
  /// Close shift only between bills.
  final ValueNotifier<bool>? billInProgress;

  /// False when the top bar carries the Close shift button (Sales Mode).
  final bool showCloseShift;

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
  final _notes = <CreditNoteInfo>[];
  Approver? _approver;
  String? _message;
  bool _busy = false;
  SavedBill? _saved;
  List<StyleStock>? _nameResults;

  /// How many garments of the picked size and color to add at once.
  int _qty = 1;
  String? _savedCustomerName;
  String? _savedCustomerPhone;

  AppServices get _s => widget.services;
  Role get _role => widget.session.user!.role;

  @override
  void initState() {
    super.initState();
    final code = widget.creditNoteCode;
    if (code != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _addNote(code));
    }
  }

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

  /// How much of each credit note this bill takes, in the order added: the
  /// smaller of its balance and what is still to pay (the rest stays on it).
  List<(CreditNoteInfo, Money)> get _noteUses {
    var due = _total;
    final out = <(CreditNoteInfo, Money)>[];
    for (final n in _notes) {
      final use = useCredit(balance: n.balance, due: due);
      out.add((n, use.used));
      due -= use.used;
    }
    return out;
  }

  Money get _notesTotal =>
      _noteUses.fold<Money>(Money.zero, (sum, u) => sum + u.$2);

  /// What the typed payments must cover after the credit notes.
  Money get _toPay => _total - _notesTotal;

  List<Payment> get _allPayments => [
    ...?_payments,
    if (_notesTotal.paise > 0) Payment(PaymentMode.creditNote, _notesTotal),
  ];

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
      return settle(_total, _allPayments);
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
      settle(_total, _allPayments);
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
    _nameResults = null;
    widget.session.noteActivity();
    if (CreditNoteCode.tryParse(code) != null) {
      await _addNote(code);
      _barcodeFocus.requestFocus();
      return;
    }
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

  static final _digitsOnly = RegExp(r'^\d+$');

  /// Typing letters searches the shop's styles by name (Stock lookup rules:
  /// cashier-safe, no cost); typing digits is a barcode or credit note.
  Future<void> _onType(String text) async {
    final t = text.trim();
    final repo = _s.stockLookup;
    if (repo == null || t.isEmpty || _digitsOnly.hasMatch(t)) {
      if (_nameResults != null) {
        setState(() => _nameResults = null);
      }
      return;
    }
    final results = await repo.search(role: _role, query: t);
    if (!mounted || _barcode.text.trim() != t) {
      return; // the text changed while searching
    }
    setState(() => _nameResults = results);
  }

  /// Enter in the field: digits are scanned; letters pick the only match, or
  /// ask the cashier to choose from the list.
  Future<void> _submit(String raw) async {
    final t = raw.trim();
    if (t.isEmpty || _digitsOnly.hasMatch(t) || _s.stockLookup == null) {
      await _scan(raw);
      return;
    }
    final results = _nameResults;
    final choices = [
      for (final s in results ?? const <StyleStock>[])
        for (final v in s.variants)
          if (v.inStock > 0) v,
    ];
    if (choices.length == 1) {
      await _addByName(choices.single);
    } else if (results != null && results.isEmpty) {
      _say('No style like "$t" in the shop.');
    } else {
      _say('Choose the size and color from the list below.');
    }
    _barcodeFocus.requestFocus();
  }

  /// Puts one in-stock garment of the chosen size and color on the bill (the
  /// lowest barcode not already on it). Every usual check still applies.
  Future<void> _addByName(VariantStock v, {int? count}) async {
    final want = clampGarmentCount(count ?? _qty);
    final onBill = {for (final l in _lines) l.item.barcode};
    final codes = pickGarments(v.barcodes, onBill, want);
    if (codes.isEmpty) {
      _say(
        v.inStock == 0
            ? 'None left in ${v.size} ${v.color}.'
            : 'All of ${v.size} ${v.color} that can be listed are already on this bill. Scan the tag.',
      );
      _barcodeFocus.requestFocus();
      return;
    }
    final before = _lines.length;
    for (final code in codes) {
      await _scan(code);
      if (!mounted) {
        return;
      }
    }
    final added = _lines.length - before;
    setState(() => _qty = 1);
    if (added == 0) {
      // the usual message from the scan (already sold, not found) stays
      if (_message == null) {
        _say('Could not add ${v.size} ${v.color}.');
      }
    } else if (added < want) {
      _say(
        'Only $added of $want could be added: the rest are not in stock '
        'or are already on this bill.',
      );
    }
    _barcodeFocus.requestFocus();
  }

  /// One more garment of the same style, size and color as [l].
  Future<void> _addAnother(_Line l) async {
    final repo = _s.stockLookup;
    if (repo == null) {
      return;
    }
    final found = await repo.search(role: _role, query: l.item.barcode);
    if (!mounted) {
      return;
    }
    final variants = [
      for (final s in found)
        if (s.name == l.item.productName)
          for (final v in s.variants)
            if (v.size == l.item.size && v.color == l.item.color) v,
    ];
    if (variants.isEmpty) {
      _say('Could not find another ${l.item.size} ${l.item.color}.');
      return;
    }
    await _addByName(variants.first, count: 1);
  }

  Future<void> _addNote(String code) async {
    if (_notes.any((n) => n.code == code)) {
      _say('That credit note is already on this bill.');
      return;
    }
    final info = await _s.sales.lookupCreditNote(role: _role, code: code);
    if (!mounted) {
      return;
    }
    if (info == null) {
      _say('Credit note not found: $code.');
    } else if (!info.valid) {
      _say('This credit note has expired.');
    } else if (info.balance.paise <= 0) {
      _say('This credit note has nothing left on it.');
    } else {
      setState(() {
        _notes.add(info);
        _message = null;
      });
    }
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

  Future<Approver?> _askManager() => askApprover(
    context,
    _s.auth,
    permission: Permission.overrideDiscountLimit,
    message: 'This discount is over your limit. A manager or the owner must approve it.',
    onNobody: _say,
  );

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
        creditNotes: [
          for (final (n, used) in _noteUses)
            if (used.paise > 0) CreditNoteUseInput(n.code, used),
        ],
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
      final pdf = await buildBillPdf(
        sheet,
        await _s.fonts(),
        logo: _s.currentBrand.logo,
      );
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
      _notes.clear();
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
    final active = _lines.isNotEmpty || _notes.isNotEmpty;
    final progress = widget.billInProgress;
    if (progress != null && progress.value != active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        progress.value = active;
      });
    }
    // Bill done is a popup over the register (UX-2), not a new screen. The
    // register stays drawn behind but cannot be reached while it is open.
    return Stack(
      children: [
        ExcludeFocus(
          excluding: saved != null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _left(context)),
                const SizedBox(width: 16),
                SizedBox(width: 400, child: _right(context)),
              ],
            ),
          ),
        ),
        if (saved != null)
          _SavedPopup(
            bill: saved,
            onPrint: _print,
            onNew: _newBill,
            message: _message,
          ),
      ],
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
          decoration: InputDecoration(
            labelText: _s.stockLookup == null
                ? 'Scan or type a barcode or credit note, then Enter'
                : 'Scan a tag, or type an item name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.qr_code_scanner),
          ),
          onChanged: _onType,
          onSubmitted: _submit,
        ),
        if (_nameResults != null) _nameResultsPanel(context),
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
        if (widget.showCloseShift)
          Align(
            alignment: Alignment.centerLeft,
            child: Tooltip(
              message: _lines.isEmpty && _notes.isEmpty
                  ? ''
                  : 'Finish or clear the bill first',
              child: TextButton.icon(
                key: const Key('close-shift-button'),
                onPressed: _lines.isEmpty && _notes.isEmpty
                    ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CloseShiftScreen(
                            session: widget.session,
                            services: _s,
                          ),
                        ),
                      )
                    : null,
                icon: const Icon(Icons.lock_clock),
                label: const Text('Close shift'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _nameResultsPanel(BuildContext context) {
    final results = _nameResults!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('name-results'),
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        color: scheme.surfaceContainerLowest,
      ),
      child: results.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No style like that in the shop.',
                key: Key('name-results-empty'),
              ),
            )
          : ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              children: [
                Row(
                  children: [
                    const Text('How many'),
                    IconButton(
                      key: const Key('qty-minus'),
                      tooltip: 'One fewer',
                      onPressed: () =>
                          setState(() => _qty = clampGarmentCount(_qty - 1)),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$_qty',
                      key: const Key('qty-value'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      key: const Key('qty-plus'),
                      tooltip: 'One more',
                      onPressed: () =>
                          setState(() => _qty = clampGarmentCount(_qty + 1)),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    const Text('of the size and color you pick'),
                  ],
                ),
                for (final s in results)
                  Padding(
                    key: Key('name-style-${s.name}'),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final v in s.variants)
                              OutlinedButton(
                                key: Key('pick-${s.name}-${v.size}-${v.color}'),
                                onPressed: v.inStock == 0
                                    ? null
                                    : () => _addByName(v),
                                child: Text(
                                  v.inStock == 0
                                      ? '${v.size} ${v.color}  none left'
                                      : '${v.size} ${v.color}  ${formatRupees(v.mrp)}  ${v.inStock} left',
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
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
            if (_s.stockLookup != null)
              IconButton(
                key: Key('more-${l.item.barcode}'),
                tooltip: 'Add another ${l.item.size} ${l.item.color}',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _addAnother(l),
              ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                Text(
                  formatRupees(_total),
                  key: const Key('total-text'),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          for (final (n, used) in _noteUses)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Credit note ${n.code}: -${formatRupees(used)} '
                      '(${formatRupees(n.balance - used)} stays on it)',
                      key: Key('note-applied-${n.code}'),
                    ),
                  ),
                  IconButton(
                    key: Key('note-remove-${n.code}'),
                    tooltip: 'Remove credit note',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _notes.remove(n)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          _amountField('cash-field', 'Cash received', _cash),
          _amountField('upi-field', 'UPI', _upi),
          _amountField('card-field', 'Card', _card),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const Key('exact-cash'),
                onPressed: _lines.isEmpty
                    ? null
                    : () => setState(() {
                        final due = _toPay.paise < 0 ? Money.zero : _toPay;
                        _cash.text =
                            (due.paise ~/ 100).toString() +
                            ((due.paise % 100) == 0
                                ? ''
                                : '.${(due.paise % 100).toString().padLeft(2, '0')}');
                        _upi.clear();
                        _card.clear();
                      }),
                child: const Text('Exact cash'),
              ),
              if (_lines.isNotEmpty)
                for (final amount in quickCashAmounts(_toPay))
                  OutlinedButton(
                    key: Key('quick-cash-${amount.paise ~/ 100}'),
                    onPressed: () => setState(() {
                      _cash.text = (amount.paise ~/ 100).toString();
                      _upi.clear();
                      _card.clear();
                    }),
                    child: Text(formatRupees(amount)),
                  ),
            ],
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
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: successColor, fontWeight: FontWeight.w800),
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

class _SavedPopup extends StatelessWidget {
  const _SavedPopup({
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
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        const ModalBarrier(color: Colors.black54, dismissible: false),
        CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter): onNew,
            const SingleActivator(LogicalKeyboardKey.numpadEnter): onNew,
            const SingleActivator(LogicalKeyboardKey.keyP): onPrint,
          },
          child: Focus(
            autofocus: true,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Material(
                  key: const Key('bill-done-popup'),
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  elevation: 12,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: successColor,
                              size: 44,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bill saved',
                                  style: t.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                  key: const Key('saved-title'),
                                ),
                                Text(
                                  bill.billNumber.format(),
                                  key: const Key('saved-bill-no'),
                                  style: t.titleMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (change.paise > 0)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: successColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'Change to give: ${formatRupees(change)}',
                              key: const Key('saved-change'),
                              style: t.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        for (final l in bill.lines)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${l.productName} ${l.size} ${l.color}',
                                  ),
                                ),
                                Text(formatRupees(l.priced.finalPrice)),
                              ],
                            ),
                          ),
                        const Divider(),
                        Text(
                          'Total ${formatRupees(bill.total)}',
                          key: const Key('saved-total'),
                          style: t.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (message != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              message!,
                              key: const Key('message-banner'),
                              style: TextStyle(color: scheme.error),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                key: const Key('new-bill'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 64),
                                  textStyle: t.titleLarge,
                                ),
                                onPressed: onNew,
                                child: const Text('New bill  (Enter)'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                key: const Key('print-bill'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 64),
                                  textStyle: t.titleMedium,
                                ),
                                onPressed: onPrint,
                                icon: const Icon(Icons.print),
                                label: const Text('Print bill  (P)'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
