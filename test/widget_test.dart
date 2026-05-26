import 'package:flutter_test/flutter_test.dart';
import 'package:roadsos_ai/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RoadSOSApp());

    // Verify that the app starts at the home screen.
    expect(find.text('RoadSOS AI'), findsWidgets);
  });
}
