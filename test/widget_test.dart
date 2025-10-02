// Basic smoke test for the Flutter Image Gallery app.
//
// This test verifies that the app starts without crashing and displays
// the main UI components.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_image_gallery/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // The app shows a loading screen during initialization
    // Just verify that something is rendered (no crash)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for initialization to complete (with a reasonable timeout)
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // After initialization, we should have some content
    // The exact content depends on the initialization state
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
