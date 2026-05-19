import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:family_workbook/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen renders without layout exceptions in landscape', (WidgetTester tester) async {
    // Set viewport to landscape to match the web browser
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MaterialApp(
      home: HomeScreen(),
    ));

    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    
    // Reset viewport
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
