// A form to count drawer cash by notes and coins. Used to open a shift and for
// the blind close. It shows only what the person has typed in: never an
// expected amount (E-SHIFT-1). Each note or coin has a minus button, the
// number (which can also be typed) and a plus button, 48 dp and up, so it
// works by touch and by keyboard (the redesign mock-up, boards 2 and 5).
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui_tokens.dart';

String _label(Denomination d) {
  final rupees = d.value.paise ~/ 100;
  return d.isNote ? '₹$rupees notes' : '₹$rupees coins';
}

/// Where the total and the button sit: under the counts (a popup), or in a
/// column beside them (the close screen).
enum CountLayout { popup, beside }

class CashCountForm extends StatefulWidget {
  const CashCountForm({
    super.key,
    required this.buttonLabel,
    required this.onSubmit,
    this.busy = false,
    this.layout = CountLayout.popup,
    this.blindNote = false,
  });

  final String buttonLabel;
  final Future<void> Function(Map<Denomination, int> counts) onSubmit;
  final bool busy;
  final CountLayout layout;

  /// Says the count is blind (the close screen).
  final bool blindNote;

  @override
  State<CashCountForm> createState() => _CashCountFormState();
}

class _CashCountFormState extends State<CashCountForm> {
  final _controllers = {
    for (final d in Denomination.values) d: TextEditingController(),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<Denomination, int> get _counts => {
    for (final e in _controllers.entries)
      if (e.value.text.trim().isNotEmpty)
        e.key: int.tryParse(e.value.text.trim()) ?? 0,
  };

  Money? get _total {
    try {
      return countCash(_counts);
    } on ArgumentError {
      return null;
    }
  }

  int _count(Denomination d) => int.tryParse(_controllers[d]!.text.trim()) ?? 0;

  void _bump(Denomination d, int by) {
    final next = (_count(d) + by).clamp(0, maxCountPerDenomination);
    setState(() => _controllers[d]!.text = next == 0 ? '' : '$next');
  }

  @override
  Widget build(BuildContext context) {
    final grid = _grid(context);
    if (widget.layout == CountLayout.popup) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          grid,
          const Divider(height: 24, color: UiColors.line),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              _totalBlock(context, light: false),
              _submit(context, minWidth: 220),
            ],
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final side = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _totalBlock(context, light: true),
            ),
            if (widget.blindNote) ...[
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
                child: const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'This count is blind. ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: UiColors.ink,
                        ),
                      ),
                      TextSpan(
                        text:
                            'The app does not show you what the drawer should '
                            'hold. The owner sees the difference later.',
                      ),
                    ],
                  ),
                  style: TextStyle(fontSize: 15, color: UiColors.inkSoft),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _submit(context, minWidth: 0),
          ],
        );
        final countsCard = Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: UiColors.line),
          ),
          child: grid,
        );
        if (box.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [countsCard, const SizedBox(height: 16), side],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: countsCard),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: side),
          ],
        );
      },
    );
  }

  Widget _grid(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    Widget row(Denomination d) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _label(d),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton.outlined(
            key: Key('dec-${d.dbValue}'),
            tooltip: 'One less ${_label(d)}',
            onPressed: () => _bump(d, -1),
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 64,
            child: TextField(
              key: Key('count-${d.dbValue}'),
              controller: _controllers[d],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                isDense: true,
                hintText: '0',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          IconButton.filled(
            key: Key('inc-${d.dbValue}'),
            tooltip: 'One more ${_label(d)}',
            style: IconButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: onPrimary,
            ),
            onPressed: () => _bump(d, 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, box) {
        final two = box.maxWidth >= 520;
        final all = Denomination.values;
        if (!two) {
          return Column(children: [for (final d in all) row(d)]);
        }
        final half = (all.length + 1) ~/ 2;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(children: [for (final d in all.take(half)) row(d)]),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: Column(children: [for (final d in all.skip(half)) row(d)]),
            ),
          ],
        );
      },
    );
  }

  Widget _totalBlock(BuildContext context, {required bool light}) {
    final total = _total;
    final fg = light ? Theme.of(context).colorScheme.onPrimary : UiColors.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          light ? 'You have counted' : 'Counted',
          style: TextStyle(
            fontSize: light ? 16 : 14,
            color: light ? fg : UiColors.inkSoft,
          ),
        ),
        Text(
          total == null
              ? 'A count is too big. Check what you typed.'
              : formatRupees(total),
          key: const Key('count-total'),
          style: TextStyle(
            fontSize: total == null ? 16 : (light ? 52 : 36),
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: fg,
          ),
        ),
      ],
    );
  }

  Widget _submit(BuildContext context, {required double minWidth}) {
    final total = _total;
    return FilledButton(
      key: const Key('count-submit'),
      style: FilledButton.styleFrom(
        backgroundColor: UiColors.success,
        foregroundColor: Colors.white,
        minimumSize: Size(minWidth, 64),
        padding: const EdgeInsets.symmetric(horizontal: 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      onPressed: total == null || widget.busy
          ? null
          : () => widget.onSubmit(_counts),
      child: Text(widget.buttonLabel),
    );
  }
}
