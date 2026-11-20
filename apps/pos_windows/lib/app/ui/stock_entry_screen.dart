// Manager Mode: enter a purchase in a Size x Color grid and print its hangtags.
// Rules and saving are in core_domain (checkPurchase) and StockRepository.
import 'package:core_domain/core_domain.dart';
import 'package:core_domain/hangtag_pdf.dart';
import 'package:flutter/material.dart';

import '../../data/stock_repository.dart';
import '../services.dart';
import '../session_controller.dart';
import 'start_cell_picker.dart';

class _Row {
  _Row(this.size, this.color);

  final String size;
  final String color;
  final qty = TextEditingController();
  final cost = TextEditingController();
  final mrp = TextEditingController();
  bool costDirty = false;
  bool mrpDirty = false;

  String get label => '$size $color';
  String get keyPart => '$size-$color';

  void dispose() {
    qty.dispose();
    cost.dispose();
    mrp.dispose();
  }
}

class StockEntryScreen extends StatefulWidget {
  const StockEntryScreen({
    super.key,
    required this.session,
    required this.services,
  });

  final SessionController session;
  final AppServices services;

  @override
  State<StockEntryScreen> createState() => _StockEntryScreenState();
}

class _StockEntryScreenState extends State<StockEntryScreen> {
  final _supplier = TextEditingController();
  final _style = TextEditingController();
  final _defaultCost = TextEditingController();
  final _defaultMrp = TextEditingController();
  final _rows = <String, _Row>{};
  var _sizes = <String>[];
  var _colors = <String>[];
  final _selectedSizes = <String>{};
  final _selectedColors = <String>{};
  var _loaded = false;
  var _busy = false;
  var _setting = false; // true while the program (not the user) changes a field

  StockRepository get _stock => widget.services.stock;
  Role get _role => widget.session.user!.role;

  @override
  void initState() {
    super.initState();
    for (final c in [_supplier, _style]) {
      c.addListener(_changed);
    }
    _defaultCost.addListener(() => _applyDefault(isCost: true));
    _defaultMrp.addListener(() => _applyDefault(isCost: false));
    _load();
  }

  @override
  void dispose() {
    for (final c in [_supplier, _style, _defaultCost, _defaultMrp]) {
      c.dispose();
    }
    for (final r in _rows.values) {
      r.dispose();
    }
    super.dispose();
  }

  void _changed() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _load() async {
    await _stock.seedDefaultOptions();
    final sizes = await _stock.sizes();
    final colors = await _stock.colors();
    final shop = await _stock.shopName();
    if (!mounted) {
      return;
    }
    setState(() {
      _sizes = sizes;
      _colors = colors;
      _loaded = true;
    });
    if (shop == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _askShopName());
    }
  }

  Future<void> _askShopName() async {
    if (!mounted) {
      return;
    }
    final field = TextEditingController();
    String? error;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Shop name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This is printed at the top of every hangtag.'),
              TextField(
                key: const Key('shop-name-field'),
                controller: field,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Shop name',
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              key: const Key('shop-name-save'),
              onPressed: () async {
                if (field.text.trim().isEmpty) {
                  setLocal(() => error = 'Enter the shop name.');
                  return;
                }
                await _stock.setShopName(role: _role, name: field.text);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    field.dispose();
  }

  Future<void> _addOption({required bool size}) async {
    final field = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(size ? 'Add a size' : 'Add a color'),
        content: TextField(
          key: const Key('add-option-field'),
          controller: field,
          autofocus: true,
          decoration: InputDecoration(labelText: size ? 'Size' : 'Color'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('add-option-save'),
            onPressed: () => Navigator.of(context).pop(field.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    field.dispose();
    if (name == null || name.trim().isEmpty) {
      return;
    }
    if (size) {
      await _stock.addSize(role: _role, name: name);
    } else {
      await _stock.addColor(role: _role, name: name);
    }
    final sizes = await _stock.sizes();
    final colors = await _stock.colors();
    if (mounted) {
      setState(() {
        _sizes = sizes;
        _colors = colors;
      });
    }
  }

  void _toggle(Set<String> set, String value) {
    setState(() {
      set.contains(value) ? set.remove(value) : set.add(value);
      _syncRows();
    });
  }

  /// One row per chosen size and color, in list order. Keeps typed values.
  void _syncRows() {
    final wanted = <String>[];
    for (final s in _sizes.where(_selectedSizes.contains)) {
      for (final c in _colors.where(_selectedColors.contains)) {
        wanted.add('$s|$c');
      }
    }
    for (final key in _rows.keys.toList()) {
      if (!wanted.contains(key)) {
        _rows.remove(key)!.dispose();
      }
    }
    for (final key in wanted) {
      _rows.putIfAbsent(key, () {
        final parts = key.split('|');
        final row = _Row(parts[0], parts[1]);
        _setting = true;
        row.cost.text = _defaultCost.text;
        row.mrp.text = _defaultMrp.text;
        _setting = false;
        row.qty.addListener(_changed);
        row.cost.addListener(() {
          if (!_setting) {
            row.costDirty = true;
          }
          _changed();
        });
        row.mrp.addListener(() {
          if (!_setting) {
            row.mrpDirty = true;
          }
          _changed();
        });
        return row;
      });
    }
    // Keep rows in display order.
    final ordered = {for (final k in wanted) k: _rows[k]!};
    _rows
      ..clear()
      ..addAll(ordered);
  }

  void _applyDefault({required bool isCost}) {
    _setting = true;
    for (final row in _rows.values) {
      if (isCost && !row.costDirty) {
        row.cost.text = _defaultCost.text;
      }
      if (!isCost && !row.mrpDirty) {
        row.mrp.text = _defaultMrp.text;
      }
    }
    _setting = false;
    _changed();
  }

  // ---- checking -------------------------------------------------------------

  ({PurchaseDraft draft, List<String> errors, List<String> warnings}) _check() {
    final rowList = _rows.values.toList();
    final errors = <String>[];
    final warnings = <String>[];
    final lines = <PurchaseLine>[];
    final parseProblem = <int>{};
    for (var i = 0; i < rowList.length; i++) {
      final r = rowList[i];
      final cost = parseRupees(r.cost.text);
      final mrp = parseRupees(r.mrp.text);
      if (cost == null) {
        errors.add(
          'Enter the cost as rupees, like 250 or 250.50, for ${r.label}.',
        );
        parseProblem.add(i);
      }
      if (mrp == null) {
        errors.add(
          'Enter the MRP as rupees, like 499 or 499.50, for ${r.label}.',
        );
        parseProblem.add(i);
      }
      lines.add(
        PurchaseLine(
          size: r.size,
          color: r.color,
          quantity: int.tryParse(r.qty.text.trim()) ?? 0,
          cost: cost ?? Money.zero,
          mrp: mrp ?? Money.zero,
        ),
      );
    }
    final draft = PurchaseDraft(
      supplier: _supplier.text,
      style: _style.text,
      lines: lines,
    );
    for (final issue in checkPurchase(draft)) {
      final label = issue.lineIndex == null
          ? ''
          : rowList[issue.lineIndex!].label;
      switch (issue.problem) {
        case PurchaseProblem.noLines:
          errors.add('Choose at least one size and one color.');
        case PurchaseProblem.blankSupplier:
          errors.add('Enter the supplier.');
        case PurchaseProblem.blankStyle:
          errors.add('Enter the style name.');
        case PurchaseProblem.badQuantity:
          errors.add('Enter a quantity of at least 1 for $label.');
        case PurchaseProblem.tooManyForOneLot:
          errors.add('One purchase can hold at most 10,000 garments.');
        case PurchaseProblem.mrpBelowCost:
          if (!parseProblem.contains(issue.lineIndex)) {
            warnings.add('Check: the MRP is below the cost for $label.');
          }
        case PurchaseProblem.negativeMoney:
        case PurchaseProblem.blankSize:
        case PurchaseProblem.blankColor:
        case PurchaseProblem.duplicateLine:
          errors.add('Something is wrong with $label.');
      }
    }
    return (draft: draft, errors: errors, warnings: warnings);
  }

  // ---- saving and printing --------------------------------------------------

  Future<void> _save(PurchaseDraft draft) async {
    setState(() => _busy = true);
    try {
      final result = await _stock.receivePurchase(
        role: _role,
        draft: draft,
        actor: widget.session.user!.userId,
      );
      if (!mounted) {
        return;
      }
      await _afterSave(result);
    } on InvalidPurchase {
      _toast('The purchase has a problem. Check the messages.');
    } on RangeExhausted {
      _toast(
        'This counter has no barcode lots left. The lot range must be extended.',
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _afterSave(PurchaseResult result) async {
    var startCell = 1;
    final print = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          key: const Key('saved-dialog'),
          title: Text('Saved ${result.garments} garments (lot ${result.lot})'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Print the hangtags now? Pick the first free cell on the sticker sheet.',
                ),
                const SizedBox(height: 8),
                StartCellPicker(
                  selected: startCell,
                  onSelected: (n) => setLocal(() => startCell = n),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              key: const Key('skip-print'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              key: const Key('print-labels'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Print labels'),
            ),
          ],
        ),
      ),
    );
    if (print == true) {
      await _print(result, startCell - 1);
    }
    if (mounted) {
      _reset();
    }
  }

  Future<void> _print(PurchaseResult result, int startCell) async {
    try {
      final labels = await _stock.labelsForBatch(
        role: _role,
        batchId: result.batchId,
      );
      final fonts = await widget.services.fonts();
      final pdf = await buildHangtagPdf(
        layout: SheetLayout.a4ThreeByEight(),
        labels: labels,
        startCell: startCell,
        regularFont: fonts.regular,
        boldFont: fonts.bold,
      );
      await widget.services.printer.printSheet(pdf, name: 'Hangtags');
    } on MissingGlyph catch (e) {
      _toast('The tag font cannot draw "${e.character}". Use English letters.');
    } on ShopNameMissing {
      _toast('Set the shop name first.');
    }
  }

  void _reset() {
    setState(() {
      _supplier.clear();
      _style.clear();
      _setting = true;
      _defaultCost.clear();
      _defaultMrp.clear();
      _setting = false;
      _selectedSizes.clear();
      _selectedColors.clear();
      _syncRows();
    });
  }

  void _toast(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // ---- screen ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stock entry')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final check = _check();
    final total = check.draft.lines.fold<int>(
      0,
      (sum, l) => sum + (l.quantity > 0 ? l.quantity : 0),
    );
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Stock entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('supplier-field'),
                        controller: _supplier,
                        decoration: const InputDecoration(
                          labelText: 'Supplier',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        key: const Key('style-field'),
                        controller: _style,
                        decoration: const InputDecoration(
                          labelText: 'Style (for example Cotton Kurta)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _chips(
                  'Sizes',
                  _sizes,
                  _selectedSizes,
                  'size',
                  () => _addOption(size: true),
                ),
                const SizedBox(height: 8),
                _chips(
                  'Colors',
                  _colors,
                  _selectedColors,
                  'color',
                  () => _addOption(size: false),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 220,
                      child: TextField(
                        key: const Key('default-cost'),
                        controller: _defaultCost,
                        decoration: const InputDecoration(
                          labelText: 'Cost for all rows (₹)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        key: const Key('default-mrp'),
                        controller: _defaultMrp,
                        decoration: const InputDecoration(
                          labelText: 'MRP for all rows (₹)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Change a row to give it its own cost or MRP.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final r in _rows.values) _rowWidget(r),
                const SizedBox(height: 16),
                Text(
                  'Total: $total garments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final e in check.errors)
                  Text(e, style: TextStyle(color: scheme.error)),
                for (final w in check.warnings)
                  Text(w, style: const TextStyle(color: Color(0xFF8A5A00))),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    key: const Key('save-purchase'),
                    onPressed: (_busy || check.errors.isNotEmpty)
                        ? null
                        : () => _save(check.draft),
                    child: const Text('Save purchase'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chips(
    String title,
    List<String> all,
    Set<String> selected,
    String kind,
    VoidCallback onAdd,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(width: 64, child: Text(title)),
        for (final o in all)
          FilterChip(
            key: Key('$kind-chip-$o'),
            label: Text(o),
            selected: selected.contains(o),
            onSelected: (_) => _toggle(selected, o),
          ),
        ActionChip(
          key: Key('add-$kind'),
          avatar: const Icon(Icons.add, size: 16),
          label: Text('Add $kind'),
          onPressed: onAdd,
        ),
      ],
    );
  }

  Widget _rowWidget(_Row r) {
    InputDecoration deco(String label) =>
        InputDecoration(labelText: label, isDense: true);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        key: Key('row-${r.keyPart}'),
        children: [
          SizedBox(
            width: 140,
            child: Text(r.label, style: Theme.of(context).textTheme.titleSmall),
          ),
          SizedBox(
            width: 110,
            child: TextField(
              key: Key('qty-${r.keyPart}'),
              controller: r.qty,
              decoration: deco('Quantity'),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 150,
            child: TextField(
              key: Key('cost-${r.keyPart}'),
              controller: r.cost,
              decoration: deco('Cost (₹)'),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 150,
            child: TextField(
              key: Key('mrp-${r.keyPart}'),
              controller: r.mrp,
              decoration: deco('MRP (₹)'),
            ),
          ),
        ],
      ),
    );
  }
}
