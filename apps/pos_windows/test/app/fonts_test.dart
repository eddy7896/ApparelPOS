// The hangtag fonts are bundled twice: once in core_domain (its tests) and once
// here (the app's assets). They must stay the same files (ADR-0017).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final name in ['NotoSans-Regular.ttf', 'NotoSans-Bold.ttf', 'OFL.txt']) {
    test('$name in the app is identical to the copy in core_domain', () {
      final app = File('assets/fonts/$name').readAsBytesSync();
      final core = File('../../packages/core_domain/assets/fonts/$name').readAsBytesSync();
      expect(app, core);
    });
  }
}
