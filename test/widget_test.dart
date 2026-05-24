import 'package:flutter_test/flutter_test.dart';

import 'package:thrift_in/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ThriftinApp(isLoggedIn: false));

    // Verify that the login screen is shown
    expect(find.text('Thriftin'), findsWidgets);
  });
}
