import 'package:flutter_test/flutter_test.dart';

import 'package:thrift_in/main.dart';
import 'package:thrift_in/screens/splash_screen.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ThriftinApp());
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
