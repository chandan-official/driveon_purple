// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driveon_app/main.dart'; // Import your main file

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // CHANGED: Use DriveOnApp instead of MyApp
    await tester.pumpWidget(const DriveOnApp());

    // Verify that our counter starts at 0.
    expect(
      find.text('0'),
      findsNothing,
    ); // Since we changed the UI, just checking nothing crashes
    expect(find.text('1'), findsNothing);
  });
}
