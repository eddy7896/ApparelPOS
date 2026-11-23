import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:pos_windows/app/brand_theme.dart';
import 'package:pos_windows/data/brand.dart';

void main() {
  test('the theme uses the bundled Inter font', () {
    final theme = brandTheme(Brand.placeholder);
    expect(appFontFamily, 'Inter');
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
    expect(theme.textTheme.titleLarge?.fontFamily, 'Inter');
  });

  test('every Inter file in pubspec.yaml exists, with its licence', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final assets = RegExp(r'asset: (assets/fonts/inter/[\w-]+\.ttf)')
        .allMatches(pubspec)
        .map((m) => m.group(1)!)
        .toList();
    expect(assets, hasLength(5));
    for (final a in assets) {
      expect(File(a).existsSync(), isTrue, reason: a);
    }
    expect(File('assets/fonts/inter/OFL.txt').existsSync(), isTrue);
  });

  test('every font weight the screens ask for is bundled', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final bundled = RegExp(r'weight: (\d+)')
        .allMatches(pubspec)
        .map((m) => int.parse(m.group(1)!))
        .toSet();
    const names = {
      'normal': 400,
      'bold': 700,
      'w400': 400,
      'w500': 500,
      'w600': 600,
      'w700': 700,
      'w800': 800,
    };
    final used = <String>{};
    for (final f
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      for (final m in RegExp(
        r'FontWeight\.(\w+)',
      ).allMatches(f.readAsStringSync())) {
        used.add(m.group(1)!);
      }
    }
    for (final u in used) {
      expect(
        names.containsKey(u),
        isTrue,
        reason: 'FontWeight.$u has no bundled Inter file; add one',
      );
      expect(bundled, contains(names[u]), reason: 'FontWeight.$u');
    }
  });
}
