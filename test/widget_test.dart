import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathmate/main.dart';

void main() {
  testWidgets('Home page shows initial recognizer UI', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MathMateApp(checkFirstLaunch: false));

    expect(find.text('拍照搜题'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
