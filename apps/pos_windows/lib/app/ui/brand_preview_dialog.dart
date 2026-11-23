// DEVELOPMENT ONLY. Lets someone try a shop name, main color and logo in a debug
// run (browser preview or `flutter run`) to see the look. A release build never
// shows it (`AppServices.brandPreview` is `kDebugMode`). The shop's real name,
// color and logo are set from the owner's mobile app in Release 2 (owner,
// 2026-11-22); this is not that screen.
import 'dart:typed_data';

import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/brand_repository.dart';
import '../services.dart';
import '../session_controller.dart';

class BrandPreviewDialog extends StatefulWidget {
  const BrandPreviewDialog({
    super.key,
    required this.session,
    required this.services,
  });

  final SessionController session;
  final AppServices services;

  @override
  State<BrandPreviewDialog> createState() => _BrandPreviewDialogState();
}

class _BrandPreviewDialogState extends State<BrandPreviewDialog> {
  late final _name = TextEditingController(
    text: widget.services.currentBrand.name ?? '',
  );
  late final _hex = TextEditingController(
    text: widget.services.currentBrand.color.hex,
  );
  List<int>? _logo;
  bool _clearLogo = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _hex.dispose();
    super.dispose();
  }

  String get _hexNote {
    final c = BrandColor.tryParse(_hex.text);
    if (c == null) {
      return 'Type a color like #2B3A9F.';
    }
    return c.isReadable
        ? 'Readable with white text.'
        : 'Too light for white text. Choose a darker color.';
  }

  Future<void> _chooseLogo() async {
    final bytes = await widget.services.pickers.logoFile();
    if (bytes != null && mounted) {
      setState(() {
        _logo = bytes;
        _clearLogo = false;
        _error = null;
      });
    }
  }

  Future<void> _apply() async {
    final user = widget.session.user;
    try {
      await widget.services.brand!.save(
        role: user?.role,
        actor: user?.userId,
        update: BrandUpdate(
          name: _name.text.trim().isEmpty ? null : _name.text,
          colorHex: _hex.text,
          logo: _logo == null ? null : Uint8List.fromList(_logo!),
          clearLogo: _clearLogo,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on InvalidBrand catch (e) {
      setState(() => _error = e.message);
    } on PermissionDenied {
      setState(() => _error = 'Only the manager or the owner can change this.');
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Try a look (development only)'),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This only exists in development runs. The shop sets its real look from the owner\'s mobile app.',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('preview-name'),
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Shop name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < testedBrandColors.length; i++)
                  ChoiceChip(
                    key: Key('preview-color-$i'),
                    label: Text(testedBrandColors[i].name),
                    selected:
                        BrandColor.tryParse(_hex.text) ==
                        testedBrandColors[i].color,
                    onSelected: (_) => setState(() {
                      _hex.text = testedBrandColors[i].color.hex;
                      _error = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('preview-hex'),
              controller: _hex,
              decoration: const InputDecoration(
                labelText: 'Main color',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_hexNote, key: const Key('preview-hex-note')),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton(
                  key: const Key('preview-logo'),
                  onPressed: _chooseLogo,
                  child: Text(_logo == null ? 'Choose logo' : 'Logo chosen'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  key: const Key('preview-remove-logo'),
                  onPressed: () => setState(() {
                    _logo = null;
                    _clearLogo = true;
                  }),
                  child: const Text('Remove logo'),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  key: const Key('preview-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
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
        key: const Key('preview-apply'),
        onPressed: _apply,
        child: const Text('Apply'),
      ),
    ],
  );
}
