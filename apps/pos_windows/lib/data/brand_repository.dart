// Reads and writes the shop's look: shop name, main color, logo. They are
// settings (keys `shop_name`, `brand_color`, `brand_logo`), so they are backed
// up and restored with the database, and the owner's mobile app can set them in
// Release 2 (owner, 2026-11-22). Until then nothing in the Windows app edits
// them except a development-only preview. Rules are in core_domain (brand.dart).
// Nothing here is read from or written to the Windows identity: the data folder
// never follows the shop name (ADR-0018).
import 'dart:convert';
import 'dart:typed_data';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';
import 'brand.dart';

const String _nameKey = 'shop_name';
const String _colorKey = 'brand_color';
const String _logoKey = 'brand_logo';

/// Which part of a new look was refused, and why.
final class InvalidBrand implements Exception {
  InvalidBrand(this.field, this.message);

  /// `name`, `color` or `logo`.
  final String field;
  final String message;
  @override
  String toString() => 'InvalidBrand($field): $message';
}

/// What to change; a null field is left alone.
final class BrandUpdate {
  const BrandUpdate({
    this.name,
    this.colorHex,
    this.logo,
    this.clearLogo = false,
  });
  final String? name;
  final String? colorHex;
  final Uint8List? logo;

  /// True to remove the logo (back to the placeholder mark).
  final bool clearLogo;
}

String logoProblemText(LogoProblem p) => switch (p) {
  LogoProblem.notAPicture => 'The logo must be a PNG or JPEG picture.',
  LogoProblem.tooBig =>
    'The logo file is bigger than ${maxLogoBytes ~/ 1024} KB.',
  LogoProblem.tooSmall =>
    'The logo is smaller than $minLogoSide by $minLogoSide pixels.',
  LogoProblem.tooWide =>
    'The logo is bigger than $maxLogoSide by $maxLogoSide pixels.',
};

class BrandRepository {
  BrandRepository(
    this._db, {
    required String Function() newId,
    DateTime Function()? now,
  }) : _writer = AuditedWriter(_db, now: now, newId: newId);

  final AppDatabase _db;
  final AuditedWriter _writer;

  Future<String?> _get(String name) async => (await (_db.select(
    _db.appSettings,
  )..where((s) => s.name.equals(name))).getSingleOrNull())?.value;

  Future<void> _set(String name, String value) => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(name: name, value: value),
      );

  /// The current look. A stored value that is not valid (a color that is too
  /// light, a logo that is not a picture) is ignored and the placeholder used
  /// instead, so a bad value can never break a screen. Anyone may read it.
  Future<Brand> load() async {
    final nameText = await _get(_nameKey);
    final name = nameText == null ? null : cleanShopName(nameText);
    var color = BrandColor.tryParse(placeholderBrandColorHex)!;
    final colorText = await _get(_colorKey);
    if (colorText != null) {
      final parsed = BrandColor.tryParse(colorText);
      if (parsed != null && parsed.isReadable) {
        color = parsed;
      }
    }
    Uint8List? logo;
    final logoText = await _get(_logoKey);
    if (logoText != null) {
      try {
        final bytes = base64Decode(logoText);
        if (checkLogo(bytes).ok) {
          logo = bytes;
        }
      } on FormatException {
        // not base64: ignore
      }
    }
    return Brand(name: name, color: color, logo: logo);
  }

  /// Changes the look. Needs `manageSettings` (manager, owner). Everything is
  /// checked first; if anything is refused ([InvalidBrand]) nothing is saved.
  /// The audit and outbox rows say which parts changed, never the values.
  Future<Brand> save({
    required Role? role,
    required BrandUpdate update,
    String? actor,
  }) async {
    require(role, Permission.manageSettings);
    String? name;
    BrandColor? color;
    if (update.name != null) {
      name = cleanShopName(update.name!);
      if (name == null) {
        throw InvalidBrand(
          'name',
          'The shop name must be 1 to $maxShopNameLength characters.',
        );
      }
    }
    if (update.colorHex != null) {
      color = BrandColor.tryParse(update.colorHex!);
      if (color == null) {
        throw InvalidBrand('color', 'The color must look like #2B3A9F.');
      }
      if (!color.isReadable) {
        throw InvalidBrand(
          'color',
          'That color is too light for white text. Choose a darker one.',
        );
      }
    }
    if (update.logo != null) {
      final check = checkLogo(update.logo!);
      if (!check.ok) {
        throw InvalidBrand('logo', logoProblemText(check.problem!));
      }
    }
    final changed = [
      if (name != null) 'name',
      if (color != null) 'color',
      if (update.logo != null || update.clearLogo) 'logo',
    ];
    if (changed.isEmpty) {
      return load();
    }
    await _writer.run<void>(
      action: 'brand.update',
      entityType: 'settings',
      entityId: 'brand',
      actor: actor,
      body: () async {
        if (name != null) {
          await _set(_nameKey, name);
        }
        if (color != null) {
          await _set(_colorKey, color.hex);
        }
        if (update.logo != null) {
          await _set(_logoKey, base64Encode(update.logo!));
        } else if (update.clearLogo) {
          await (_db.delete(
            _db.appSettings,
          )..where((s) => s.name.equals(_logoKey))).go();
        }
      },
      details: {'changed': changed},
    );
    return load();
  }
}
