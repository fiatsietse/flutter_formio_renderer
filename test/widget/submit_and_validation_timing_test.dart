import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_formio_renderer/flutter_formio_renderer.dart';

Map<String, dynamic> _schema() => {
      'display': 'form',
      'components': [
        {
          'type': 'textfield',
          'key': 'firstName',
          'label': 'First Name',
          'input': true,
          'validate': {'required': true},
        },
        {
          'type': 'textfield',
          'key': 'lastName',
          'label': 'Last Name',
          'input': true,
          'validate': {'required': true},
        },
        {
          'type': 'button',
          'key': 'submit',
          'label': 'Send',
          'action': 'submit',
          'input': true,
        },
      ],
    };

Future<void> _pumpForm(
  WidgetTester tester, {
  FormioOptions options = FormioOptions.defaults,
  FormioController? controller,
  void Function(FormioSubmission)? onSubmit,
  void Function(FormioValidationResult)? onError,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1200, 1600);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: FormioForm(
            schema: _schema(),
            options: options,
            controller: controller,
            onSubmit: onSubmit,
            onError: onError,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _field(int index) => find.byType(TextFormField).at(index);

void main() {
  group('Submit button on a non-wizard form (#1)', () {
    testWidgets('calls onSubmit with the data when the form is valid',
        (tester) async {
      FormioSubmission? submitted;
      await _pumpForm(tester, onSubmit: (s) => submitted = s);

      await tester.enterText(_field(0), 'Ada');
      await tester.enterText(_field(1), 'Lovelace');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(submitted, isNotNull);
      expect(submitted!.data['firstName'], 'Ada');
      expect(submitted!.data['lastName'], 'Lovelace');
    });

    testWidgets('calls onError and shows errors when the form is invalid',
        (tester) async {
      var submitCalls = 0;
      FormioValidationResult? error;
      await _pumpForm(
        tester,
        onSubmit: (_) => submitCalls++,
        onError: (r) => error = r,
      );

      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(submitCalls, 0);
      expect(error, isNotNull);
      expect(error!.forKey('firstName'), isNotEmpty);
      expect(error!.forKey('lastName'), isNotEmpty);
      expect(find.textContaining('Last Name is required'), findsWidgets);
    });

    testWidgets('FormioController.submit goes through the same path',
        (tester) async {
      final controller = FormioController();
      FormioSubmission? submitted;
      await _pumpForm(tester,
          controller: controller, onSubmit: (s) => submitted = s);

      controller.setValue('firstName', 'Ada');
      controller.setValue('lastName', 'Lovelace');
      final result = controller.submit();

      expect(result.isValid, isTrue);
      expect(submitted?.data['lastName'], 'Lovelace');
    });
  });

  group('ValidationTiming.onChange (#2)', () {
    testWidgets('typing in one field does not flag fields not yet reached',
        (tester) async {
      await _pumpForm(tester);

      await tester.enterText(_field(0), 'A');
      await tester.pumpAndSettle();

      expect(find.textContaining('Last Name is required'), findsNothing);
      expect(find.textContaining('First Name is required'), findsNothing);
    });

    testWidgets('the changed field is still validated', (tester) async {
      await _pumpForm(tester);

      await tester.enterText(_field(0), 'A');
      await tester.enterText(_field(0), '');
      await tester.pumpAndSettle();

      expect(find.textContaining('First Name is required'), findsWidgets);
      expect(find.textContaining('Last Name is required'), findsNothing);
    });

    testWidgets('after a failed submit, fixing a field clears its error',
        (tester) async {
      await _pumpForm(tester);

      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Last Name is required'), findsWidgets);

      await tester.enterText(_field(1), 'Lovelace');
      await tester.pumpAndSettle();

      expect(find.textContaining('Last Name is required'), findsNothing);
      expect(find.textContaining('First Name is required'), findsWidgets);
    });
  });

  group('ValidationTiming.onBlur (#3)', () {
    const onBlur = FormioOptions(validationTiming: ValidationTiming.onBlur);

    testWidgets('does not validate while typing', (tester) async {
      await _pumpForm(tester, options: onBlur);

      await tester.enterText(_field(0), 'A');
      await tester.enterText(_field(0), '');
      await tester.pumpAndSettle();

      expect(find.textContaining('First Name is required'), findsNothing);
    });

    testWidgets('validates a field when it loses focus', (tester) async {
      await _pumpForm(tester, options: onBlur);

      await tester.tap(_field(0));
      await tester.pumpAndSettle();
      await tester.tap(_field(1));
      await tester.pumpAndSettle();

      expect(find.textContaining('First Name is required'), findsWidgets);
      // The field that just got focus has not been left yet.
      expect(find.textContaining('Last Name is required'), findsNothing);
    });

    testWidgets('an error clears as soon as the value is fixed',
        (tester) async {
      await _pumpForm(tester, options: onBlur);

      await tester.tap(_field(0));
      await tester.tap(_field(1));
      await tester.pumpAndSettle();
      expect(find.textContaining('First Name is required'), findsWidgets);

      await tester.enterText(_field(0), 'Ada');
      await tester.pumpAndSettle();

      expect(find.textContaining('First Name is required'), findsNothing);
    });
  });

  group('ValidationTiming.onSubmit', () {
    testWidgets('neither typing nor blur validates', (tester) async {
      await _pumpForm(tester,
          options:
              const FormioOptions(validationTiming: ValidationTiming.onSubmit));

      await tester.enterText(_field(0), 'A');
      await tester.enterText(_field(0), '');
      await tester.tap(_field(1));
      await tester.pumpAndSettle();

      expect(find.textContaining('is required'), findsNothing);
    });
  });
}
