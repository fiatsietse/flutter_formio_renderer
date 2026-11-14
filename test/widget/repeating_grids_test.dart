import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_formio_renderer/flutter_formio_renderer.dart';

void main() {
  group('Repeating DataGrid and EditGrid Widgets', () {
    testWidgets(
        'adds and removes rows in DataGrid with correct nested serialization',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 1600);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final jsonStr =
          File('test/fixtures/03_nested_and_repeating.json').readAsStringSync();
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

      // Find "Add Another" button for employees
      expect(find.text('Add Another'), findsWidgets);

      // Tap Add Another to add employee
      await tester.tap(find.text('Add Another').first);
      await tester.pumpAndSettle();

      // Row #1 should appear with default values
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('New Employee'), findsOneWidget);

      // Check submission data
      var sub = controller.getSubmission();
      expect(sub.data['employees'], isA<List>());
      expect(sub.data['employees'].length, 1);
      expect(sub.data['employees'][0]['name'], 'New Employee');
      expect(sub.data['employees'][0]['age'], 25);

      // Add a second row
      await tester.tap(find.text('Add Another').first);
      await tester.pumpAndSettle();

      expect(find.text('#2'), findsOneWidget);
      sub = controller.getSubmission();
      expect(sub.data['employees'].length, 2);

      // Remove row 0
      final deleteButtons = find.byIcon(Icons.delete_outline);
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      sub = controller.getSubmission();
      expect(sub.data['employees'].length, 1);
    });

    testWidgets('EditGrid renders rows and toggles inline edit card',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 1600);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final jsonStr =
          File('test/fixtures/03_nested_and_repeating.json').readAsStringSync();
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

      // Tap Add Another for assets (last Add Another button)
      await tester.tap(find.text('Add Another').last);
      await tester.pumpAndSettle();

      // Editing Row #1 mode appears
      expect(find.text('Editing Row #1'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Row is saved in summary mode
      expect(find.textContaining('Row #1'), findsOneWidget);
    });
  });
}
