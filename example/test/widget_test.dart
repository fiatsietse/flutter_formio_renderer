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

  testWidgets(
      'ExampleApp switches language dropdown in real-time and updates labels',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 1200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    // 1. Initial form (Basic Registration) has English label
    expect(find.textContaining('First Name'), findsOneWidget);

    // 2. Type user name
    await tester.enterText(find.byType(TextFormField).first, 'John');
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    // 3. Switch language dropdown to French
    await tester.tap(find.text('🇬🇧 EN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🇫🇷 FR').last);
    await tester.pumpAndSettle();

    // 4. Verify label changed to French in real-time
    expect(find.textContaining('Prénom'), findsOneWidget);

    // 5. Verify user typed value is preserved!
    expect(find.text('John'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
