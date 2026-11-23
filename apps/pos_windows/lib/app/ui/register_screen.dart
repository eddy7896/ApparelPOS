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
import 'category_chips.dart';
import 'close_shift_screen.dart';
import 'dues_screen.dart';
import 'shift_gate.dart';
import 'status_colors.dart';
import 'ui_tokens.dart';
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

/// How the customer is paying (the mock-up's payment card): one mode for the
/// whole bill, Split across cash, UPI and card, or Pay later (part now, the rest
/// owed; a manager or the owner allows it).
enum _PayMethod { cash, upi, card, split, later }

class _Line {
  _Line(this.item);
  SaleItem item;
  PriceCut? discount;

  /// True when the shop marked this garment's style down (set in Stock, not
  /// typed here); such a garment takes no cashier discount.
  bool get markedDown => item.markdown != null;

  PricedLine? get priced {
    try {
      return priceLine(
        mrp: item.mrp,
        markdown: item.markdown,
        cashierDiscount: markedDown ? null : discount,
      );
    } on PriceCutTooLarge {
      return null;
    }
  }
}

/// A bill put aside with F4 while the cashier serves someone else. It lives
/// only in memory: nothing is saved, no garment is reserved, and it is gone
/// when the counter locks or the app closes.
class _Held {
  _Held({
    required this.lines,
    required this.notes,
    required this.customerName,
    required this.customerPhone,
    required this.customerGstin,
    required this.approver,
    required this.method,
    required this.laterApprover,
  });

  final List<_Line> lines;
  final List<CreditNoteInfo> notes;
  final String customerName;
  final String customerPhone;
  final String customerGstin;
  final Approver? approver;
  final _PayMethod method;
  final Approver? laterApprover;

  Money get total => lines.fold<Money>(
    Money.zero,
    (sum, l) => sum + (l.priced?.finalPrice ?? l.item.mrp),
  );
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
  final _customerGstin = TextEditingController();
  final _lines = <_Line>[];
  final _notes = <CreditNoteInfo>[];
  final _held = <_Held>[];
  Approver? _approver;

  /// Who allowed pay later on this bill (null when the signed-in person may).
  Approver? _laterApprover;
  String? _message;
  bool _busy = false;
  SavedBill? _saved;
  List<StyleStock>? _nameResults;

  /// How many garments of the picked size and color to add at once.
  int _qty = 1;

  _PayMethod _method = _PayMethod.cash;

  /// The shop's categories and the one chosen to narrow the name search.
  List<CategoryNode> _categories = const [];
  String? _catFilter;

  /// The shop's GST settings (GST off until the owner switches it on).
  GstSettings _gst = const GstSettings();
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
    _loadCategories();
    _loadGst();
  }

  Future<void> _loadGst() async {
    try {
      final g = await _s.sales.gstSettings(role: _role);
      if (mounted) {
        setState(() => _gst = g);
      }
    } on PermissionDenied {
      // stays off
    }
  }

  Future<void> _loadCategories() async {
    final cats = _s.categories;
    if (cats == null) {
      return;
    }
    try {
      final list = await cats.list(role: _role);
      if (mounted) {
        setState(() => _categories = [for (final e in list) e.node]);
      }
    } on PermissionDenied {
      // no chips
    }
  }

  /// The name results narrowed to the chosen category.
  List<StyleStock>? get _visibleNameResults {
    final all = _nameResults;
    if (all == null) {
      return null;
    }
    return [
      for (final s in all)
        if (categoryMatches(_categories, _catFilter, s.categoryId)) s,
    ];
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
      _customerGstin,
    ]) {
      c.dispose();
    }
    _barcodeFocus.dispose();
    super.dispose();
  }

  void _say(String text) => setState(() => _message = text);

  // ---- money on screen ------------------------------------------------------

  /// The tax on the garments on the bill (nothing while GST is off), worked
  /// out by the same rule the bill is saved with.
  BillTax get _tax => billTax(
    [for (final l in _lines) l.priced?.finalPrice ?? l.item.mrp],
    _gst,
    ownRatesBp: [for (final l in _lines) l.item.gstBp],
  );

  /// What the customer pays: the prices, plus the tax when it is added on top.
  Money get _total => _tax.total;

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
    // UPI or card for the whole bill: the app records the mode and the amount
    // still to pay; the money is taken on the customer's phone or the machine.
    if (_method == _PayMethod.upi || _method == _PayMethod.card) {
      final due = _toPay;
      return due.paise > 0
          ? [
              Payment(
                _method == _PayMethod.upi ? PaymentMode.upi : PaymentMode.card,
                due,
              ),
            ]
          : [];
    }
    final out = <Payment>[];
    for (final (mode, c) in [
      (PaymentMode.cash, _cash),
      if (_method == _PayMethod.split || _isLater) (PaymentMode.upi, _upi),
      if (_method == _PayMethod.split || _isLater) (PaymentMode.card, _card),
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

  bool get _isLater => _method == _PayMethod.later;

  /// Pay later needs the customer's name and phone.
  bool get _laterCustomerOk =>
      cleanCustomerName(_customerName.text) != null &&
      customerPhoneKey(_customerPhone.text) != null;

  /// True when this bill is being left partly unpaid (pay later chosen and
  /// something is still due).
  bool get _leavesOwed =>
      _isLater && _lines.isNotEmpty && !(_settlement?.isPaid ?? true);

  bool get _canComplete =>
      !_busy &&
      _lines.isNotEmpty &&
      _paymentProblem == null &&
      _settlement != null &&
      (_settlement!.isPaid || (_isLater && _laterCustomerOk));

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
    if (_held.any((h) => h.lines.any((l) => l.item.barcode == code))) {
      _say('$code is on a held bill. Resume that bill to sell it.');
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
    final results = _visibleNameResults;
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
    if (line.markedDown) {
      return;
    }
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
      final changed = await _refreshPrices();
      if (changed != null) {
        _say(changed);
        return;
      }
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
        customerGstin: _gst.enabled ? _customerGstin.text : null,
        discountApproverRole: _approver?.role,
        discountApprovedBy: _approver?.userId,
        payLater: _leavesOwed
            ? PayLaterInput(
                customerName: name,
                customerPhone: phone,
                approverRole: can(_role, Permission.allowPayLater)
                    ? null
                    : _laterApprover?.role,
                approvedBy: can(_role, Permission.allowPayLater)
                    ? null
                    : _laterApprover?.userId,
              )
            : null,
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
    } on DiscountNotAllowed {
      _say('A marked-down garment takes no cashier discount.');
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

  /// Looks every garment up again and takes in any change of markdown (one set
  /// or ended while the bill was open) and of the GST settings. Returns what to
  /// tell the cashier when a price changed, or null when nothing did.
  Future<String?> _refreshPrices() async {
    var markdownChanged = false;
    var ratesChanged = false;
    final g = await _s.sales.gstSettings(role: _role);
    final gstChanged =
        g.enabled != _gst.enabled ||
        g.mode != _gst.mode ||
        g.rateBp != _gst.rateBp ||
        g.rounding != _gst.rounding;
    if (mounted) {
      _gst = g;
    }
    for (final l in _lines) {
      final fresh = await _s.sales.lookup(role: _role, barcode: l.item.barcode);
      if (fresh == null || !mounted) {
        continue;
      }
      final a = l.item.markdown;
      final b = fresh.markdown;
      final same = a == null
          ? b == null
          : b != null &&
                a.basisPoints == b.basisPoints &&
                a.amountOff == b.amountOff;
      if (fresh.gstBp != l.item.gstBp && _gst.enabled) {
        ratesChanged = true;
      }
      l.item = fresh;
      if (!same) {
        markdownChanged = true;
        if (b != null) {
          l.discount = null;
        }
      }
    }
    if ((markdownChanged || gstChanged || ratesChanged) && mounted) {
      setState(() {});
    }
    if (markdownChanged) {
      return 'A markdown changed while this bill was open. Check the new total.';
    }
    if (gstChanged || ratesChanged) {
      return 'The GST settings changed while this bill was open. Check the new total.';
    }
    return null;
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
        operatorCode: widget.session.user!.staffCode,
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

  /// F4: put the bill aside to serve someone else; Resume brings it back.
  void _hold() {
    if (_saved != null || _busy || (_lines.isEmpty && _notes.isEmpty)) {
      return;
    }
    final held = _Held(
      lines: List.of(_lines),
      notes: List.of(_notes),
      customerName: _customerName.text,
      customerPhone: _customerPhone.text,
      customerGstin: _customerGstin.text,
      approver: _approver,
      method: _method,
      laterApprover: _laterApprover,
    );
    _newBill();
    setState(() => _held.add(held));
  }

  void _resume(_Held h) {
    if (_saved != null) {
      return;
    }
    if (_lines.isNotEmpty || _notes.isNotEmpty) {
      _say(
        'Finish or hold the bill on screen before bringing back a held one.',
      );
      return;
    }
    setState(() {
      _held.remove(h);
      _lines.addAll(h.lines);
      _notes.addAll(h.notes);
      _customerName.text = h.customerName;
      _customerPhone.text = h.customerPhone;
      _customerGstin.text = h.customerGstin;
      _approver = h.approver;
      _laterApprover = h.laterApprover;
      _method = h.method;
      _message = null;
    });
    _barcodeFocus.requestFocus();
  }

  void _dropHeld(_Held h) {
    setState(() => _held.remove(h));
    _barcodeFocus.requestFocus();
  }

  /// Esc: close the bill-done popup, or else the name results.
  void _escape() {
    if (_saved != null) {
      _newBill();
    } else if (_nameResults != null) {
      setState(() {
        _nameResults = null;
        _barcode.clear();
      });
      _barcodeFocus.requestFocus();
    }
  }

  void _newBill() {
    setState(() {
      _lines.clear();
      _notes.clear();
      _approver = null;
      _laterApprover = null;
      _saved = null;
      _message = null;
      for (final c in [
        _barcode,
        _cash,
        _upi,
        _card,
        _customerName,
        _customerPhone,
        _customerGstin,
      ]) {
        c.clear();
      }
      _method = _PayMethod.cash;
    });
    _barcodeFocus.requestFocus();
  }

  // ---- screens --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final saved = _saved;
    final active = _lines.isNotEmpty || _notes.isNotEmpty || _held.isNotEmpty;
    final progress = widget.billInProgress;
    if (progress != null && progress.value != active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        progress.value = active;
      });
    }
    // Bill done is a popup over the register (UX-2), not a new screen. The
    // register stays drawn behind but cannot be reached while it is open.
    return CallbackShortcuts(
      bindings: {
        // F2 back to the scan box, F9 complete the bill (as the mock-up).
        const SingleActivator(LogicalKeyboardKey.f2): () {
          if (_saved == null) {
            _barcodeFocus.requestFocus();
          }
        },
        const SingleActivator(LogicalKeyboardKey.f9): () {
          if (_saved == null && _canComplete) {
            _complete();
          }
        },
        // F4 hold the bill, F6 start a fresh search, Esc close the popup.
        const SingleActivator(LogicalKeyboardKey.f4): _hold,
        const SingleActivator(LogicalKeyboardKey.f6): () {
          if (_saved == null) {
            _barcode.clear();
            setState(() => _nameResults = null);
            _barcodeFocus.requestFocus();
          }
        },
        const SingleActivator(LogicalKeyboardKey.escape): _escape,
      },
      child: Stack(
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
      ),
    );
  }

  Widget _left(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const none = InputBorder.none;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The scan card: a 2 dp outline in the main color, always ready.
        Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.primary, width: 2),
          ),
          child: TextField(
            key: const Key('barcode-field'),
            controller: _barcode,
            focusNode: _barcodeFocus,
            autofocus: true,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: _s.stockLookup == null
                  ? 'Scan or type a barcode or credit note, then Enter'
                  : 'Scan a tag, or type an item name',
              helperText:
                  'The scanner is always ready. Press F2 to come back here.',
              border: none,
              enabledBorder: none,
              focusedBorder: none,
              filled: false,
              icon: Icon(Icons.qr_code_scanner, color: scheme.primary),
            ),
            onChanged: _onType,
            onSubmitted: _submit,
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8, left: 4),
          child: Wrap(
            key: Key('shortcut-hints'),
            spacing: 16,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'F4',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' Hold bill'),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'F6',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' New search'),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Esc',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' Close popup'),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_held.isNotEmpty) _heldStrip(),
        if (_nameResults != null) _nameResultsPanel(context),
        if (_message != null)
          Container(
            key: const Key('message-banner'),
            width: double.infinity,
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: UiColors.amberSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _message!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: UiColors.amberInk,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: UiColors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: UiColors.line)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _lines.isEmpty
                              ? 'Garments'
                              : '${_lines.length} ${_lines.length == 1 ? 'garment' : 'garments'}',
                          key: const Key('lines-count'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: UiColors.inkSoft,
                          ),
                        ),
                      ),
                      if (_s.dues != null)
                        TextButton.icon(
                          key: const Key('dues-button'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DuesScreen(
                                session: widget.session,
                                services: _s,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.account_balance_wallet),
                          label: const Text('Pay dues'),
                        ),
                      TextButton.icon(
                        key: const Key('hold-bill'),
                        onPressed: _lines.isEmpty && _notes.isEmpty || _busy
                            ? null
                            : _hold,
                        icon: const Icon(Icons.pause_circle_outline),
                        label: const Text('Hold bill  F4'),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Price',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: UiColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _lines.isEmpty
                      ? const Center(
                          child: Text(
                            'No garments yet. Scan the first tag.',
                            style: TextStyle(
                              fontSize: 18,
                              color: UiColors.inkMuted,
                            ),
                          ),
                        )
                      : ListView(
                          key: const Key('bill-lines'),
                          children: [for (final l in _lines) _lineTile(l)],
                        ),
                ),
              ],
            ),
          ),
        ),
        if (widget.showCloseShift)
          Align(
            alignment: Alignment.centerLeft,
            child: Tooltip(
              message: _lines.isEmpty && _notes.isEmpty && _held.isEmpty
                  ? ''
                  : 'Finish or clear the bill first',
              child: TextButton.icon(
                key: const Key('close-shift-button'),
                onPressed: _lines.isEmpty && _notes.isEmpty && _held.isEmpty
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

  /// The bills put aside, each with Resume and a drop button.
  Widget _heldStrip() {
    return Container(
      key: const Key('held-bills'),
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < _held.length; i++)
            Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: UiColors.amberSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Held ${i + 1}: '
                    '${_held[i].lines.length} '
                    '${_held[i].lines.length == 1 ? 'garment' : 'garments'}, '
                    '${formatRupees(_held[i].total)}',
                    key: Key('held-label-$i'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: UiColors.amberInk,
                    ),
                  ),
                  TextButton(
                    key: Key('held-resume-$i'),
                    onPressed: () => _resume(_held[i]),
                    child: const Text('Resume'),
                  ),
                  IconButton(
                    key: Key('held-drop-$i'),
                    tooltip: 'Drop this held bill',
                    icon: const Icon(Icons.close),
                    onPressed: () => _dropHeld(_held[i]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _nameResultsPanel(BuildContext context) {
    final results = _visibleNameResults!;
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
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryChips(
                    nodes: _categories,
                    selected: _catFilter,
                    onChanged: (v) => setState(() => _catFilter = v),
                  ),
                  Text(
                    _nameResults!.isEmpty
                        ? 'No style like that in the shop.'
                        : 'No style like that in this category.',
                    key: const Key('name-results-empty'),
                  ),
                ],
              ),
            )
          : ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              children: [
                if (_categories.isNotEmpty) ...[
                  CategoryChips(
                    nodes: _categories,
                    selected: _catFilter,
                    onChanged: (v) => setState(() => _catFilter = v),
                  ),
                  const SizedBox(height: 10),
                ],
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
    final markdownOff = priced == null ? Money.zero : priced.markdownAmount;
    final markdown = l.item.markdown;
    final scheme = Theme.of(context).colorScheme;
    final initial = l.item.productName.isEmpty
        ? '?'
        : String.fromCharCode(l.item.productName.runes.first).toUpperCase();
    return Container(
      key: Key('line-${l.item.barcode}'),
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: UiColors.lineSoft)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              initial,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l.item.productName}  ${l.item.size}  ${l.item.color}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  markdown != null && markdownOff.paise > 0
                      ? 'MRP ${formatRupees(l.item.mrp)}   markdown ${markdownLabel(markdown)} -${formatRupees(markdownOff)}   ${l.item.barcode}'
                      : off.paise == 0
                      ? 'MRP ${formatRupees(l.item.mrp)}   ${l.item.barcode}'
                      : 'MRP ${formatRupees(l.item.mrp)}   off -${formatRupees(off)}   ${l.item.barcode}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: UiColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          if (_s.stockLookup != null)
            IconButton(
              key: Key('more-${l.item.barcode}'),
              tooltip: 'Add another ${l.item.size} ${l.item.color}',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _addAnother(l),
            ),
          if (l.markedDown)
            Container(
              key: Key('sale-tag-${l.item.barcode}'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: UiColors.amberSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Sale ${markdownLabel(markdown!)} off',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: UiColors.amberInk,
                ),
              ),
            )
          else
            OutlinedButton(
              key: Key('discount-${l.item.barcode}'),
              style: OutlinedButton.styleFrom(
                backgroundColor: off.paise == 0
                    ? Colors.white
                    : scheme.primaryContainer,
              ),
              onPressed: () => _editDiscount(l),
              child: const Text('Discount'),
            ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (off.paise != 0 || markdownOff.paise != 0)
                  Text(
                    formatRupees(l.item.mrp),
                    style: const TextStyle(
                      fontSize: 14,
                      color: UiColors.inkMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Text(
                  formatRupees(priced?.finalPrice ?? l.item.mrp),
                  key: Key('price-${l.item.barcode}'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
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
    );
  }

  /// One payment mode chip: the chosen one has a 2 dp outline in the main color.
  Widget _methodChip(String key, String label, _PayMethod m) {
    final scheme = Theme.of(context).colorScheme;
    final on = _method == m;
    return OutlinedButton(
      key: Key('method-$key'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        backgroundColor: on ? scheme.primaryContainer : Colors.white,
        foregroundColor: on ? scheme.onPrimaryContainer : UiColors.ink,
        side: BorderSide(
          color: on ? scheme.primary : UiColors.lineStrong,
          width: on ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => _setMethod(m),
      child: Text(label),
    );
  }

  Future<void> _setMethod(_PayMethod m) async {
    if (m == _PayMethod.later &&
        !can(_role, Permission.allowPayLater) &&
        _laterApprover == null) {
      final approver = await askApprover(
        context,
        _s.auth,
        permission: Permission.allowPayLater,
        message:
            'Leaving a bill to be paid later needs a manager or the owner. '
            'They type their own password.',
        onNobody: _say,
      );
      if (approver == null || !mounted) {
        return;
      }
      _laterApprover = approver;
    }
    setState(() {
      _method = m;
      if (m != _PayMethod.split && m != _PayMethod.later) {
        _upi.clear();
        _card.clear();
      }
      if (m == _PayMethod.upi || m == _PayMethod.card) {
        _cash.clear();
      }
    });
  }

  /// A cash amount chip (Exact or a round amount); lit when that amount is
  /// what has been entered.
  Widget _cashChip({
    required String key,
    required String label,
    required bool enabled,
    required Money amount,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final entered = parseRupees(_cash.text.trim());
    final on =
        enabled && entered != null && entered == amount && amount.paise > 0;
    return OutlinedButton(
      key: Key(key),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        backgroundColor: on ? scheme.primaryContainer : Colors.white,
        side: BorderSide(
          color: on ? scheme.primary : UiColors.lineStrong,
          width: on ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: !enabled
          ? null
          : () => setState(() {
              final rupees = amount.paise ~/ 100;
              final paise = amount.paise % 100;
              _cash.text = paise == 0
                  ? '$rupees'
                  : '$rupees.${paise.toString().padLeft(2, '0')}';
              if (_method != _PayMethod.split && !_isLater) {
                _upi.clear();
                _card.clear();
              }
            }),
      child: Text(label),
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
    // The total and payment scroll; Complete bill stays pinned at the bottom
    // so it is always in reach (the mock-up's right column).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total to pay',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                      ),
                      Text(
                        formatRupees(_total),
                        key: const Key('total-text'),
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        _lines.isEmpty
                            ? 'Scan the first tag to begin.'
                            : '${_lines.length} ${_lines.length == 1 ? 'garment' : 'garments'}',
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      if (_gst.enabled && _lines.isNotEmpty)
                        Text(
                          _gst.mode == GstMode.exclusive
                              ? 'Includes GST ${formatRupees(_tax.totalTax)} added to the prices'
                              : 'Includes GST ${formatRupees(_tax.totalTax)}',
                          key: const Key('gst-line'),
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onPrimary,
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: UiColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'How is the customer paying?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: UiColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _methodChip('cash', 'Cash', _PayMethod.cash),
                          _methodChip('upi', 'UPI', _PayMethod.upi),
                          _methodChip('card', 'Card', _PayMethod.card),
                          _methodChip('split', 'Split', _PayMethod.split),
                          if (_s.dues != null)
                            _methodChip('later', 'Pay later', _PayMethod.later),
                        ],
                      ),
                      if (_method == _PayMethod.cash ||
                          _method == _PayMethod.split) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Cash received',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: UiColors.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _cashChip(
                              key: 'exact-cash',
                              label: 'Exact',
                              enabled: _lines.isNotEmpty,
                              amount: _toPay.paise < 0 ? Money.zero : _toPay,
                            ),
                            if (_lines.isNotEmpty)
                              for (final amount in quickCashAmounts(_toPay))
                                _cashChip(
                                  key: 'quick-cash-${amount.paise ~/ 100}',
                                  label: formatRupees(amount),
                                  enabled: true,
                                  amount: amount,
                                ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _amountField(
                          'cash-field',
                          'Or type the cash received',
                          _cash,
                        ),
                      ],
                      if (_isLater) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Paid now (leave empty if nothing is paid yet)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: UiColors.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _amountField('cash-field', 'Cash now', _cash),
                      ],
                      if (_method == _PayMethod.split || _isLater) ...[
                        _amountField('upi-field', 'UPI', _upi),
                        _amountField('card-field', 'Card', _card),
                      ],
                      if (_method == _PayMethod.upi ||
                          _method == _PayMethod.card) ...[
                        const SizedBox(height: 14),
                        Container(
                          key: const Key('non-cash-note'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: UiColors.canvas,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "Take the payment on the customer's phone or card "
                            'machine, then press Complete bill. The app records '
                            'the mode only.',
                            style: TextStyle(
                              fontSize: 15,
                              color: UiColors.inkSoft,
                            ),
                          ),
                        ),
                      ],
                      if (problem != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            problem,
                            key: const Key('payment-problem'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        )
                      else if (_lines.isNotEmpty &&
                          settlement != null &&
                          settlement.change.paise > 0)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: UiColors.successSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Change to give: ${formatRupees(settlement.change)}',
                            key: const Key('change-text'),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: UiColors.successInk,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        )
                      else if (_lines.isNotEmpty &&
                          settlement != null &&
                          !settlement.isPaid)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: UiColors.amberSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _isLater
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'To pay later: ${formatRupees(settlement.due)}',
                                      key: const Key('owed-later'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: UiColors.amberInk,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    Text(
                                      _laterCustomerOk
                                          ? 'Allowed by ${_laterApprover?.name ?? 'you'}.'
                                          : "Type the customer's name and phone number below.",
                                      key: const Key('later-note'),
                                      style: const TextStyle(
                                        color: UiColors.amberInk,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Still due: ${formatRupees(settlement.due)}',
                                  key: const Key('due-text'),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: UiColors.amberInk,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('customer-name'),
                        controller: _customerName,
                        decoration: InputDecoration(
                          labelText: _isLater
                              ? 'Customer name (required)'
                              : 'Customer name (optional)',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        key: const Key('customer-phone'),
                        controller: _customerPhone,
                        decoration: InputDecoration(
                          labelText: _isLater
                              ? 'Phone (required)'
                              : 'Phone (optional)',
                        ),
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                if (_gst.enabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextField(
                      key: const Key('customer-gstin'),
                      controller: _customerGstin,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Customer GSTIN (business buyers, optional)',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...[
          FilledButton(
            key: const Key('complete-bill'),
            style: FilledButton.styleFrom(
              backgroundColor: UiColors.success,
              foregroundColor: Colors.white,
              disabledBackgroundColor: UiColors.lineStrong,
              minimumSize: const Size.fromHeight(68),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: _canComplete ? _complete : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Complete bill'),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white54),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'F9',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 16,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'F2',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' Scan'),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'F9',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' Complete bill'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
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
            const SingleActivator(LogicalKeyboardKey.escape): onNew,
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
                        if (bill.owed.paise > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: UiColors.amberSoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'To pay later: ${formatRupees(bill.owed)}',
                              key: const Key('saved-owed'),
                              style: t.headlineSmall?.copyWith(
                                color: UiColors.amberInk,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
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
