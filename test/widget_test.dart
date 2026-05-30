import 'package:flutter_test/flutter_test.dart';

import 'package:hire_ready/main.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const HireReadyApp());
    expect(find.text('HireReady'), findsOneWidget);
  });
}
