// GST settings (P3-4, owner 2026-11-23): off until the OWNER switches it on
// (`configureGst` is owner-only). EVERY RULE IS UNVERIFIED until the CA
// confirms (SSOT rule 14, E-GST-1). The settings live in `app_settings`; bills
// copy the tax they used onto each line, so changing or switching off GST never
// touches a bill already made (ADR-0007 point 3 and 5). The rules are in
// core_domain (gst_rules). No cost is read here.
import 'package:core_domain/core_domain.dart';

import 'app_database.dart';

/// Thrown when the settings cannot be switched on; [problem] says why.
final class InvalidGstSettings implements Exception {
  InvalidGstSettings(this.problem);
  final GstSettingsProblem problem;
  @override
  String toString() => 'InvalidGstSettings: ${problem.name}';
}

/// The shop's GST settings as stored; anything missing is the default (GST off).
Future<GstSettings> readGstSettings(AppDatabase db) async {
  final rows = await db.select(db.appSettings).get();
  final m = {for (final r in rows) r.name: r.value};
  final fields = <GstInvoiceField>{
    for (final f in GstInvoiceField.values)
      if (m.containsKey('gst_field_${f.key}')
          ? m['gst_field_${f.key}'] == '1'
          : defaultGstInvoiceFields.contains(f))
        f,
  };
  return GstSettings(
    enabled: m['gst_enabled'] == '1',
    mode: GstMode.fromDb(m['gst_mode']) ?? GstMode.inclusive,
    rateBp: int.tryParse(m['gst_rate_bp'] ?? '') ?? defaultGstRateBp,
    rounding: GstRounding.fromDb(m['gst_rounding']) ?? GstRounding.perItem,
    gstin: m['gstin'] ?? '',
    address: m['shop_address'] ?? '',
    fields: fields,
  );
}

class GstRepository {
  GstRepository(
    this._db, {
    required String Function() newId,
    DateTime Function()? now,
  }) : _writer = AuditedWriter(_db, now: now, newId: newId);

  final AppDatabase _db;
  final AuditedWriter _writer;

  /// The settings. Needs `viewStockAndPrices` (the counter needs the rate and
  /// mode to show the total; the GSTIN is printed on the bill anyway).
  Future<GstSettings> settings({required Role? role}) async {
    require(role, Permission.viewStockAndPrices);
    return readGstSettings(_db);
  }

  /// Saves the settings. Owner only (`configureGst`). Switching on needs a good
  /// GSTIN, address and rate ([InvalidGstSettings]); switched off, the choices
  /// are kept as typed. Bills already made are not touched.
  Future<void> save({
    required Role? role,
    required String actorId,
    required GstSettings settings,
  }) async {
    require(role, Permission.configureGst);
    final clean = settings.copyWith(
      gstin: settings.gstin.trim().toUpperCase(),
      address: settings.address.trim(),
    );
    if (clean.enabled) {
      final problem = gstSettingsProblem(clean);
      if (problem != null) {
        throw InvalidGstSettings(problem);
      }
    }
    await _writer.run<void>(
      action: 'gst.settings',
      entityType: 'gst_settings',
      entityId: 'shop',
      actor: actorId,
      details: {
        'enabled': clean.enabled,
        'mode': clean.mode.dbValue,
        'rateBp': clean.rateBp,
        'rounding': clean.rounding.dbValue,
      },
      body: () async {
        Future<void> put(String name, String value) => _db
            .into(_db.appSettings)
            .insertOnConflictUpdate(
              AppSettingsCompanion.insert(name: name, value: value),
            );
        await put('gst_enabled', clean.enabled ? '1' : '0');
        await put('gst_mode', clean.mode.dbValue);
        await put('gst_rate_bp', '${clean.rateBp}');
        await put('gst_rounding', clean.rounding.dbValue);
        await put('gstin', clean.gstin);
        await put('shop_address', clean.address);
        for (final f in GstInvoiceField.values) {
          await put('gst_field_${f.key}', clean.fields.contains(f) ? '1' : '0');
        }
      },
    );
  }
}
