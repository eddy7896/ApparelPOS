// The GST card in Settings (P3-4, owner 2026-11-23). GST is OFF until the OWNER
// switches it on; a manager can only read it. EVERY GST RULE IS UNVERIFIED until
// the shop's CA confirms it, and the card says so. Rules: core_domain
// (gst_rules); data: GstRepository. Bills already made are never changed.
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/gst_repository.dart';
import '../services.dart';
import '../session_controller.dart';
import 'ui_tokens.dart';

class GstSettingsCard extends StatefulWidget {
  const GstSettingsCard({
    super.key,
    required this.session,
    required this.services,
  });

  final SessionController session;
  final AppServices services;

  @override
  State<GstSettingsCard> createState() => _GstSettingsCardState();
}

class _GstSettingsCardState extends State<GstSettingsCard> {
  GstSettings? _saved;
  bool _enabled = false;
  GstMode _mode = GstMode.inclusive;
  GstRounding _rounding = GstRounding.perItem;
  Set<GstInvoiceField> _fields = defaultGstInvoiceFields;
  final _gstin = TextEditingController();
  final _address = TextEditingController();
  final _rate = TextEditingController();
  String? _message;
  bool _good = false;

  GstRepository get _repo => widget.services.gst!;
  List<StyleGst> _styleCodes = const [];
  Role? get _role => widget.session.user?.role;
  bool get _canEdit => can(_role, Permission.configureGst);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _gstin.dispose();
    _address.dispose();
    _rate.dispose();
    super.dispose();
  }

  String _rateText(int bp) {
    final label = markdownLabel(PriceCut.percentBp(bp));
    return label.replaceAll('%', '');
  }

  Future<void> _load() async {
    final s = await _repo.settings(role: _role);
    final styles = can(_role, Permission.enterStock)
        ? await _repo.styles(role: _role)
        : const <StyleGst>[];
    if (!mounted) {
      return;
    }
    setState(() {
      _styleCodes = styles;
      _saved = s;
      _enabled = s.enabled;
      _mode = s.mode;
      _rounding = s.rounding;
      _fields = {...s.fields};
      _gstin.text = s.gstin;
      _address.text = s.address;
      _rate.text = _rateText(s.rateBp);
    });
  }

  Future<void> _save() async {
    final bp = parsePriceCut('${_rate.text.trim().replaceAll('%', '')}%')
        ?.basisPoints;
    if (bp == null) {
      setState(() {
        _message = 'Type the rate as a percentage, such as 5.';
        _good = false;
      });
      return;
    }
    try {
      await _repo.save(
        role: _role,
        actorId: widget.session.user!.userId,
        settings: GstSettings(
          enabled: _enabled,
          mode: _mode,
          rateBp: bp,
          rounding: _rounding,
          gstin: _gstin.text,
          address: _address.text,
          fields: _fields,
        ),
      );
      await _load();
      setState(() {
        _message = _enabled
            ? 'GST is on. New bills will carry tax; bills already made do not change.'
            : 'GST is off. Bills already made do not change.';
        _good = true;
      });
    } on InvalidGstSettings catch (e) {
      setState(() {
        _message = gstSettingsProblemText(e.problem);
        _good = false;
      });
    } on PermissionDenied {
      setState(() {
        _message = 'Only the owner may change GST.';
        _good = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = _saved;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          key: const Key('gst-card'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GST',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              key: const Key('gst-unverified'),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: UiColors.amberSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Every GST rule here (the rate, whether the price includes '
                'tax, how tax is rounded, the CGST and SGST split and the '
                'fields on the invoice) is unverified until your CA confirms '
                'it. Ask your CA before you switch this on.',
                style: TextStyle(color: UiColors.amberInk),
              ),
            ),
            const SizedBox(height: 12),
            if (saved == null)
              const CircularProgressIndicator()
            else if (!_canEdit)
              Text(
                saved.enabled
                    ? 'GST is on (${markdownLabel(PriceCut.percentBp(saved.rateBp))}, '
                          '${saved.mode == GstMode.inclusive ? 'tax included in prices' : 'tax added to prices'}). '
                          'Only the owner can change it.'
                    : 'GST is off. Only the owner can change it.',
                key: const Key('gst-readonly'),
              )
            else
              ..._form(context),
            if (saved != null && _styleCodes.isNotEmpty) ..._styleSection(),
          ],
        ),
      ),
    );
  }

  Future<void> _editStyle(StyleGst s) async {
    final result = await showDialog<(String, bool, int?)>(
      context: context,
      builder: (_) => _StyleGstDialog(style: s, canRate: _canEdit),
    );
    if (result == null) {
      return;
    }
    try {
      await _repo.setStyleGst(
        role: _role,
        actorId: widget.session.user!.userId,
        styleId: s.id,
        hsn: result.$1,
        changeRate: result.$2,
        rateBp: result.$3,
      );
      await _load();
      setState(() {
        _message = '${s.name}: saved.';
        _good = true;
      });
    } on InvalidStyleGst {
      setState(() {
        _message = 'The HSN code must be 4 to 8 digits and the rate 0% to 50%.';
        _good = false;
      });
    } on PermissionDenied {
      setState(() {
        _message = 'You may not change that.';
        _good = false;
      });
    }
  }

  /// Each style's HSN code and own rate (the rate is the owner's to change).
  List<Widget> _styleSection() => [
    const SizedBox(height: 20),
    const Text(
      'HSN code and own rate of each style',
      style: TextStyle(fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: 4),
    const Text(
      'A style with no code prints no HSN and shows as "No HSN" in the GST '
      'reports. A style with its own rate uses it instead of the shop rate.',
    ),
    const SizedBox(height: 8),
    for (final s in _styleCodes)
      Padding(
        key: Key('style-gst-${s.name}'),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(s.name)),
            Text(
              '${s.hsn.isEmpty ? 'No HSN' : 'HSN ${s.hsn}'}'
              '${s.rateBp == null ? '' : ', own rate ${markdownLabel(PriceCut.percentBp(s.rateBp!))}'}',
              key: Key('style-gst-text-${s.name}'),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              key: Key('style-gst-edit-${s.name}'),
              onPressed: () => _editStyle(s),
              child: const Text('Edit'),
            ),
          ],
        ),
      ),
    if (_message != null && !_canEdit)
      Container(
        key: const Key('gst-message'),
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _good ? UiColors.successSoft : UiColors.dangerSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(_message!),
      ),
  ];

  List<Widget> _form(BuildContext context) => [
    SwitchListTile(
      key: const Key('gst-switch'),
      contentPadding: EdgeInsets.zero,
      title: const Text('Use GST on new bills'),
      subtitle: Text(
        _enabled
            ? 'On: new bills work out and print tax.'
            : 'Off: bills carry no tax (as they have always been).',
      ),
      value: _enabled,
      onChanged: (v) => setState(() {
        _enabled = v;
        _message = null;
      }),
    ),
    const SizedBox(height: 8),
    TextField(
      key: const Key('gst-gstin'),
      controller: _gstin,
      textCapitalization: TextCapitalization.characters,
      decoration: const InputDecoration(
        labelText: 'Shop GSTIN',
        hintText: '27ABCDE1234F1Z5',
      ),
      onChanged: (_) => setState(() => _message = null),
    ),
    const SizedBox(height: 8),
    TextField(
      key: const Key('gst-address'),
      controller: _address,
      decoration: const InputDecoration(
        labelText: 'Shop address (on the invoice)',
      ),
      onChanged: (_) => setState(() => _message = null),
    ),
    const SizedBox(height: 8),
    TextField(
      key: const Key('gst-rate'),
      controller: _rate,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'GST rate (for example 5)',
        suffixText: '%',
      ),
      onChanged: (_) => setState(() => _message = null),
    ),
    const SizedBox(height: 12),
    const Text(
      'The price on the tag',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 6),
    SegmentedButton<GstMode>(
      segments: const [
        ButtonSegment(
          value: GstMode.inclusive,
          label: Text('Includes tax', key: Key('gst-mode-inclusive')),
        ),
        ButtonSegment(
          value: GstMode.exclusive,
          label: Text('Tax is added', key: Key('gst-mode-exclusive')),
        ),
      ],
      selected: {_mode},
      onSelectionChanged: (s) => setState(() {
        _mode = s.first;
        _message = null;
      }),
    ),
    const SizedBox(height: 12),
    const Text(
      'Tax is worked out',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 6),
    SegmentedButton<GstRounding>(
      segments: const [
        ButtonSegment(
          value: GstRounding.perItem,
          label: Text('On each garment', key: Key('gst-round-item')),
        ),
        ButtonSegment(
          value: GstRounding.perBill,
          label: Text('Once on the bill', key: Key('gst-round-bill')),
        ),
      ],
      selected: {_rounding},
      onSelectionChanged: (s) => setState(() {
        _rounding = s.first;
        _message = null;
      }),
    ),
    const SizedBox(height: 12),
    const Text(
      'Print on the GST invoice',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    Wrap(
      spacing: 8,
      runSpacing: 0,
      children: [
        for (final f in GstInvoiceField.values)
          FilterChip(
            key: Key('gst-field-${f.key}'),
            label: Text(f.label),
            selected: _fields.contains(f),
            onSelected: (v) => setState(() {
              _fields = {..._fields};
              v ? _fields.add(f) : _fields.remove(f);
              _message = null;
            }),
          ),
      ],
    ),
    const SizedBox(height: 16),
    FilledButton(
      key: const Key('gst-save'),
      onPressed: _save,
      child: const Text('Save GST settings'),
    ),
    if (_message != null)
      Container(
        key: const Key('gst-message'),
        margin: const EdgeInsets.only(top: 12),
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
  ];
}

/// Edits a style's HSN code and (for the owner) its own rate.
class _StyleGstDialog extends StatefulWidget {
  const _StyleGstDialog({required this.style, required this.canRate});
  final StyleGst style;
  final bool canRate;

  @override
  State<_StyleGstDialog> createState() => _StyleGstDialogState();
}

class _StyleGstDialogState extends State<_StyleGstDialog> {
  late final _hsn = TextEditingController(text: widget.style.hsn);
  late final _rate = TextEditingController(
    text: widget.style.rateBp == null
        ? ''
        : markdownLabel(PriceCut.percentBp(widget.style.rateBp!))
              .replaceAll('%', ''),
  );
  String? _error;

  @override
  void dispose() {
    _hsn.dispose();
    _rate.dispose();
    super.dispose();
  }

  void _save() {
    final hsnText = _hsn.text.trim();
    if (hsnText.isNotEmpty && cleanHsn(hsnText) == null) {
      setState(() => _error = 'The HSN code must be 4 to 8 digits.');
      return;
    }
    int? bp;
    var change = false;
    if (widget.canRate) {
      final t = _rate.text.trim().replaceAll('%', '');
      if (t.isNotEmpty) {
        bp = parsePriceCut('$t%')?.basisPoints;
        if (bp == null || bp > maxGstRateBp) {
          setState(
            () => _error = 'Type the rate as a percentage between 0 and 50.',
          );
          return;
        }
      }
      change = bp != widget.style.rateBp;
    }
    Navigator.of(context).pop((hsnText, change, bp));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('GST codes for ${widget.style.name}'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('style-hsn'),
            controller: _hsn,
            decoration: const InputDecoration(
              labelText: 'HSN code (4 to 8 digits, empty for none)',
            ),
          ),
          if (widget.canRate)
            TextField(
              key: const Key('style-rate'),
              controller: _rate,
              decoration: const InputDecoration(
                labelText: 'Own GST rate % (empty uses the shop rate)',
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                key: const Key('style-gst-error'),
                style: const TextStyle(color: UiColors.dangerInk),
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
        key: const Key('style-gst-save'),
        onPressed: _save,
        child: const Text('Save'),
      ),
    ],
  );
}
