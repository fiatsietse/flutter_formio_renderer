import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_formio_renderer/flutter_formio_renderer.dart';

void main() {
  group('FormioWizard Widget Navigation', () {
    testWidgets(
        'advancing requires current page to be valid and blocks if invalid',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 1600);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final jsonStr =
          File('test/fixtures/02_conditional_wizard.json').readAsStringSync();
      final schema = FormioFormSchema.parse(jsonStr);
      final controller = FormioController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FormioForm(
                schema: schema,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Page 1 is visible
      expect(find.text('Personal Details'), findsOneWidget);
      expect(find.textContaining('Full Name'), findsOneWidget);

      // Attempt to advance to Next step without filling required fullName
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Must remain on Page 1 because fullName is required
      expect(controller.currentPageIndex, 0);
      expect(find.textContaining('Full Name is required'), findsWidgets);

      // Fill in fullName
      controller.setValue('fullName', 'John Doe');
      await tester.pumpAndSettle();

      // Now Next succeeds! hasSpouse is false -> Page 2 is hidden and skipped -> Lands directly on Page 3 (Confirmation)!
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(controller.currentPageIndex, 2);
      expect(find.text('Confirmation'), findsOneWidget);
      expect(find.textContaining('Confirm Application'), findsOneWidget);
    });

    testWidgets('backward navigation is allowed without validation barriers',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 1600);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final jsonStr =
          File('test/fixtures/02_conditional_wizard.json').readAsStringSync();
      final schema = FormioFormSchema.parse(jsonStr);
      final controller = FormioController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FormioForm(
                schema: schema,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill page 1 and advance to page 3
      controller.setValue('fullName', 'John Doe');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(controller.currentPageIndex, 2);

      // Page 3 has required confirm checkbox that is currently false.
      // Pressing Previous must succeed without validation block!
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();

      expect(controller.currentPageIndex, 0);
      expect(find.text('Personal Details'), findsOneWidget);
    });

    testWidgets('shows conditionally hidden page when prerequisite is enabled',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 1600);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final jsonStr =
          File('test/fixtures/02_conditional_wizard.json').readAsStringSync();
      final schema = FormioFormSchema.parse(jsonStr);
      final controller = FormioController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FormioForm(
                schema: schema,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.setValue('fullName', 'John Doe');
      // Enable spouse
      controller.setValue('hasSpouse', true);
      await tester.pumpAndSettle();

      // Advancing now goes to Page 2 (Spouse Details)!
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(controller.currentPageIndex, 1);
      expect(find.text('Spouse Details'), findsOneWidget);
      expect(find.textContaining('Spouse Name'), findsOneWidget);
    });
  });
}
