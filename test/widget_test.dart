import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HabitosApp());
  });
}