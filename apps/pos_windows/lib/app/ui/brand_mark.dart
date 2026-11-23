// The shop's mark: its logo, or a rounded square with the first letter of its
// name in the main color, and optionally the name beside it. Built from the
// Brand, never hard-coded.
import 'package:flutter/material.dart';

import '../../data/brand.dart';

Color _color(int rgb) => Color(0xFF000000 | rgb);

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    required this.brand,
    this.size = 36,
    this.showName = true,
    this.nameStyle,
  });

  final Brand brand;
  final double size;
  final bool showName;
  final TextStyle? nameStyle;

  Widget _initial() {
    final p = brand.palette;
    final first = brand.displayName.runes.isEmpty
        ? '?'
        : String.fromCharCode(brand.displayName.runes.first).toUpperCase();
    return Container(
      key: const Key('brand-initial'),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _color(p.primary),
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Text(
        first,
        style: TextStyle(
          color: _color(p.onPrimary),
          fontWeight: FontWeight.w800,
          fontSize: size * 0.45,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logo = brand.logo;
    final mark = logo == null
        ? _initial()
        : SizedBox(
            key: const Key('brand-logo'),
            width: size,
            height: size,
            child: Image.memory(
              logo,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _initial(),
            ),
          );
    if (!showName) {
      return Semantics(label: brand.displayName, child: mark);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            brand.displayName,
            key: const Key('brand-name'),
            overflow: TextOverflow.ellipsis,
            style:
                nameStyle ??
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ),
      ],
    );
  }
}
