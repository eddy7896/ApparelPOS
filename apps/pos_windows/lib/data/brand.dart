// The shop's look as the screens use it (no dart:io, so the browser preview
// compiles). Stored as settings; see brand_repository.dart and core_domain's
// brand rules. The placeholder is used until the owner sets a name, color or logo.
import 'dart:typed_data';

import 'package:core_domain/core_domain.dart';

class Brand {
  Brand({this.name, BrandColor? color, this.logo})
    : color = color ?? BrandColor.tryParse(placeholderBrandColorHex)!;

  /// The look before anything is set.
  static final Brand placeholder = Brand();

  /// The shop name, or null if the owner has not set one.
  final String? name;

  /// The main color (always readable with white text).
  final BrandColor color;

  /// A checked PNG or JPEG, or null.
  final Uint8List? logo;

  /// What screens show: the name, or the placeholder name.
  String get displayName => name ?? placeholderShopName;

  Palette get palette => Palette.fromPrimary(color);

  bool get hasLogo => logo != null;

  /// True when nothing has been set (name, color and logo are all placeholders).
  bool get isPlaceholder =>
      name == null &&
      logo == null &&
      color.hex == BrandColor.tryParse(placeholderBrandColorHex)!.hex;
}
