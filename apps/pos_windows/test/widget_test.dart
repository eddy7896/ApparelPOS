import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/main.dart';

void main() {
  testWidgets('skeleton shows the title', (tester) async {
    await tester.pumpWidget(const PosApp());
    expect(find.textContaining('Apparel PoS'), findsOneWidget);
  });
}
