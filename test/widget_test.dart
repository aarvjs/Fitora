import 'package:flutter_test/flutter_test.dart';
import 'package:fitora/main.dart';

void main() {
  testWidgets('Fitora app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FitoraApp());
    expect(find.byType(FitoraApp), findsOneWidget);
  });
}
