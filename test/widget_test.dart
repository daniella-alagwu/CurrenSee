// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:currensee/main.dart';

void main() {
  testWidgets('App boots into the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CurrenSeeApp());
    await tester.pump();
    expect(find.text('Live rates. Clear insight.'), findsNothing); // fades in later
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });
}