import 'package:core_domain/core_domain.dart';
import 'package:flutter/foundation.dart';

import '../data/brand.dart';
import '../data/brand_repository.dart';

/// Holds the shop's current look and tells the app when it changes, so the
/// theme and the name and logo on screen follow the settings.
class BrandController extends ChangeNotifier {
  BrandController(this._repo, {Brand? initial})
    : _brand = initial ?? Brand.placeholder;

  final BrandRepository _repo;
  Brand _brand;

  Brand get brand => _brand;

  /// Reads the settings again (after a save, or after a restore).
  Future<void> reload() async {
    _brand = await _repo.load();
    notifyListeners();
  }

  /// Saves a new look (manager or owner only) and shows it at once. Throws
  /// [PermissionDenied] or [InvalidBrand]; nothing changes then.
  Future<void> save({
    required Role? role,
    required BrandUpdate update,
    String? actor,
  }) async {
    _brand = await _repo.save(role: role, update: update, actor: actor);
    notifyListeners();
  }
}
