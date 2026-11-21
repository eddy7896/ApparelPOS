// A form to count drawer cash by notes and coins. Used to open a shift and,
// later, for the blind close. It shows only what the person has typed in: never
// an expected amount (E-SHIFT-1).
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String _label(Denomination d) {
  final rupees = d.value.paise ~/ 100;
  return d.isNote ? '₹$rupees notes' : '₹$rupees coins';
}

class CashCountForm extends StatefulWidget {
  const CashCountForm({
    super.key,
    required this.buttonLabel,
    required this.onSubmit,
    this.busy = false,
  });

  final String buttonLabel;
  final Future<void> Function(Map<Denomination, int> counts) onSubmit;
  final bool busy;

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

  @override
  Widget build(BuildContext context) {
    final total = _total;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final d in Denomination.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(width: 120, child: Text(_label(d))),
                const Text('×  '),
                SizedBox(
                  width: 120,
                  child: TextField(
                    key: Key('count-${d.dbValue}'),
                    controller: _controllers[d],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Text(
          total == null
              ? 'A count is too big. Check what you typed.'
              : 'Total counted: ${formatRupees(total)}',
          key: const Key('count-total'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('count-submit'),
          onPressed: total == null || widget.busy
              ? null
              : () => widget.onSubmit(_counts),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(widget.buttonLabel),
          ),
        ),
      ],
    );
  }
}
