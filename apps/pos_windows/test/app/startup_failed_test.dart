import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:pos_windows/app/startup_failed.dart';

void main() {
  testWidgets('a start-up failure shows the reason, not a blank window', (
    tester,
  ) async {
    await tester.pumpWidget(StartupFailedApp(error: StateError('no such vfs')));
    expect(find.byKey(const Key('startup-failed-title')), findsOneWidget);
    expect(find.textContaining('no such vfs'), findsOneWidget);
  });
}
