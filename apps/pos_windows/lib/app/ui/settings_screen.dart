// Settings (Manager Mode): the shop's stock categories (owner, 2026-11-23). The
// owner or a manager sets up groups and the categories inside them (Men >
// Shirts), and puts each style in one. Categories then drive the quick lookup
// filter, the billing search and the analytics. Rules are in core_domain; the
// data is in CategoryRepository. The shop's name, color and logo are not here:
// they come from the owner's phone app in Release 2.
import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

import '../../data/category_repository.dart';
import '../services.dart';
import '../session_controller.dart';
import 'ui_tokens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.session,
    required this.services,
  });

  final SessionController session;
  final AppServices services;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<CategoryEntry>? _entries;
  List<StyleEntry> _styles = const [];
  String? _message;
  bool _good = false;
  bool _onlyUncategorised = false;

  CategoryRepository? get _repo => widget.services.categories;
  Role? get _role => widget.session.user?.role;
  String get _me => widget.session.user!.userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) {
      return;
    }
    try {
      final entries = await repo.list(role: _role);
      final styles = await repo.styles(role: _role);
      if (mounted) {
        setState(() {
          _entries = entries;
          _styles = styles;
        });
      }
    } on PermissionDenied {
      if (mounted) {
        setState(() => _message = 'You may not change settings.');
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

  Future<void> _run(Future<void> Function() change, String done) async {
    try {
      await change();
      await _load();
      _say(done, good: true);
    } on InvalidCategoryName {
      _say(
        'Type a name of 1 to $maxCategoryNameLength letters, with no line breaks.',
      );
    } on CategoryNameTaken catch (e) {
      _say('"${e.name}" is already used here.');
    } on GroupHasStyles {
      _say(
        'This group already has styles in it. Put them in a category first, '
        'or keep using the group as it is.',
      );
    } on CategoryInUse {
      _say(
        'It still has styles or categories in it. Move or remove them first.',
      );
    } on NotAssignable {
      _say('Styles go in a category, not in a group that has categories.');
    } on TooDeep {
      _say('Only two levels: a group and the categories inside it.');
    } on UnknownCategory {
      _say('That group or category is no longer there.');
      await _load();
    } on PermissionDenied {
      _say('You may not do that.');
    }
  }

  Future<String?> _askName(String title, {String initial = ''}) =>
      showDialog<String>(
        context: context,
        builder: (_) => _NameDialog(title: title, initial: initial),
      );

  Future<void> _addGroup() async {
    final name = await _askName('New group (for example Men)');
    if (name == null) {
      return;
    }
    await _run(() async {
      await _repo!.add(role: _role, actorId: _me, name: name);
    }, 'Group "${cleanCategoryName(name) ?? name}" added.');
  }

  Future<void> _addCategory(CategoryNode group) async {
    final name = await _askName('New category in ${group.name}');
    if (name == null) {
      return;
    }
    await _run(() async {
      await _repo!.add(
        role: _role,
        actorId: _me,
        name: name,
        parentId: group.id,
      );
    }, 'Category "${cleanCategoryName(name) ?? name}" added to ${group.name}.');
  }

  Future<void> _rename(CategoryNode node) async {
    final name = await _askName('Rename ${node.name}', initial: node.name);
    if (name == null) {
      return;
    }
    await _run(
      () => _repo!.rename(role: _role, actorId: _me, id: node.id, name: name),
      'Renamed to ${cleanCategoryName(name) ?? name}.',
    );
  }

  Future<void> _delete(CategoryNode node) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${node.name}?'),
        content: const Text(
          'It must be empty: no styles and no categories in it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    await _run(
      () => _repo!.delete(role: _role, actorId: _me, id: node.id),
      '${node.name} removed.',
    );
  }

  Future<void> _assign(StyleEntry style, String? categoryId) => _run(
    () => _repo!.assignStyle(
      role: _role,
      actorId: _me,
      styleId: style.id,
      categoryId: categoryId,
    ),
    '${style.name} moved.',
  );

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: entries == null
          ? Center(
              child: _message != null
                  ? Text(_message!, key: const Key('settings-message'))
                  : const CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (_message != null)
                  Container(
                    key: const Key('settings-message'),
                    margin: const EdgeInsets.only(bottom: 16),
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
                _categoriesCard(context, entries),
                const SizedBox(height: 16),
                _stylesCard(context, entries),
                const SizedBox(height: 16),
                const Text(
                  "The shop's name, colors and logo are set from the owner's "
                  'phone app (Release 2).',
                  style: TextStyle(color: UiColors.inkMuted),
                ),
              ],
            ),
    );
  }

  Widget _card(
    BuildContext context,
    String title,
    String subtitle,
    Widget child,
  ) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(subtitle),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );

  Widget _categoriesCard(BuildContext context, List<CategoryEntry> entries) {
    final nodes = [for (final e in entries) e.node];
    return _card(
      context,
      'Stock categories',
      'Groups and the categories inside them, for example Men and, inside it, '
          'Shirts and Jeans. Each style goes in one category. They are used for '
          'quick lookup, the billing search and the analytics.',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.icon(
            key: const Key('add-group-button'),
            onPressed: _addGroup,
            icon: const Icon(Icons.create_new_folder),
            label: const Text('Add group'),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Text(
              'No categories yet. Add a group to begin.',
              key: Key('categories-empty'),
            ),
          for (final e in entries)
            Padding(
              key: Key('node-${categoryPath(nodes, e.node.id)}'),
              padding: EdgeInsets.only(
                left: e.node.parentId == null ? 0 : 28,
                bottom: 8,
                top: e.node.parentId == null ? 8 : 0,
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Icon(
                    e.node.parentId == null
                        ? Icons.folder
                        : Icons.label_outline,
                    size: 20,
                    color: UiColors.inkSoft,
                  ),
                  Text(
                    e.node.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: e.node.parentId == null
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                  if (e.styleCount > 0)
                    Text(
                      '${e.styleCount} ${e.styleCount == 1 ? 'style' : 'styles'}',
                      key: Key('count-${categoryPath(nodes, e.node.id)}'),
                      style: const TextStyle(color: UiColors.inkMuted),
                    ),
                  if (e.node.parentId == null)
                    OutlinedButton(
                      key: Key('add-in-${e.node.name}'),
                      onPressed: () => _addCategory(e.node),
                      child: const Text('Add category'),
                    ),
                  OutlinedButton(
                    key: Key('rename-${categoryPath(nodes, e.node.id)}'),
                    onPressed: () => _rename(e.node),
                    child: const Text('Rename'),
                  ),
                  OutlinedButton(
                    key: Key('delete-${categoryPath(nodes, e.node.id)}'),
                    onPressed: () => _delete(e.node),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _stylesCard(BuildContext context, List<CategoryEntry> entries) {
    final nodes = [for (final e in entries) e.node];
    final options = [
      for (final n in nodes)
        if (isAssignable(nodes, n.id)) n,
    ];
    final none = _styles.where((s) => s.categoryId == null).length;
    final shown = [
      for (final s in _styles)
        if (!_onlyUncategorised || s.categoryId == null) s,
    ];
    return _card(
      context,
      'Styles and their categories',
      'Put each style in a category. New stock can pick one when it is entered.',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                key: const Key('filter-styles-all'),
                label: Text('All (${_styles.length})'),
                selected: !_onlyUncategorised,
                onSelected: (_) => setState(() => _onlyUncategorised = false),
              ),
              ChoiceChip(
                key: const Key('filter-styles-none'),
                label: Text('No category ($none)'),
                selected: _onlyUncategorised,
                onSelected: (_) => setState(() => _onlyUncategorised = true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            const Text('No styles to show.', key: Key('styles-empty')),
          for (final s in shown)
            Padding(
              key: Key('style-row-${s.name}'),
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<String?>(
                      key: ValueKey('style-cat-${s.name}-${s.categoryId}'),
                      initialValue: options.any((n) => n.id == s.categoryId)
                          ? s.categoryId
                          : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'Category',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No category'),
                        ),
                        for (final n in options)
                          DropdownMenuItem<String?>(
                            value: n.id,
                            child: Text(categoryPath(nodes, n.id)),
                          ),
                      ],
                      onChanged: (v) => _assign(s, v),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Owns its own text controller so it is disposed after the dialog has closed.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.initial});
  final String title;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      key: const Key('category-name-field'),
      controller: _c,
      autofocus: true,
      decoration: const InputDecoration(labelText: 'Name'),
      onSubmitted: (v) => Navigator.of(context).pop(v),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('category-name-save'),
        onPressed: () => Navigator.of(context).pop(_c.text),
        child: const Text('Save'),
      ),
    ],
  );
}
