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
      'ExampleApp switches to BUTODRA wizard fixture and renders properly',
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

    // Select BUTODRA fixture
    final butodraItem =
        find.text('9. BUTODRA Member Certificate (Wizard)').last;
    await tester.tap(butodraItem);
    await tester.pumpAndSettle();

    // Verify BUTODRA is displayed with translated labels (English by default)
    expect(find.text('9. BUTODRA Member Certificate (Wizard)'), findsWidgets);
    expect(find.text('Normal procedure'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
