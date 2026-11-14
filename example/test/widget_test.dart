import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('ExampleApp mounts and renders showcase screen',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Flutter Form.io Renderer'), findsOneWidget);
    expect(find.text('1. Basic Registration Form'), findsOneWidget);
  });

  testWidgets(
      'ExampleApp switches to conditional wizard fixture and renders properly',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 1200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    // Tap on the fixture dropdown
    await tester.tap(find.text('1. Basic Registration Form'));
    await tester.pumpAndSettle();

    // Select Conditional Wizard fixture
    final wizardItem =
        find.text('2. Conditional Multi-Step Wizard').last;
    await tester.tap(wizardItem);
    await tester.pumpAndSettle();

    // Verify Wizard is displayed with step navigation buttons
    expect(find.text('2. Conditional Multi-Step Wizard'), findsWidgets);
    expect(find.text('Next'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
