import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_formio_renderer/flutter_formio_renderer.dart';

void main() {
  const testSchemaWithI18n = '''
{
  "display": "form",
  "components": [
    {
      "type": "textfield",
      "key": "firstName",
      "label": "First Name",
      "placeholder": "Enter first name",
      "description": "Your legal given name",
      "validate": { "required": true }
    },
    {
      "type": "radio",
      "key": "contactPreference",
      "label": "Contact Preference",
      "values": [
        { "label": "Email", "value": "email" },
        { "label": "Phone", "value": "phone" }
      ]
    },
    {
      "type": "button",
      "key": "submit",
      "label": "Register",
      "action": "submit"
    }
  ],
  "i18n": {
    "en": {
      "First Name": "First Name",
      "Enter first name": "Enter first name",
      "Your legal given name": "Your legal given name",
      "Contact Preference": "Contact Preference",
      "Email": "Email",
      "Phone": "Phone",
      "Register": "Register"
    },
    "fr": {
      "First Name": "Prénom",
      "Enter first name": "Entrez votre prénom",
      "Your legal given name": "Votre prénom légal",
      "Contact Preference": "Préférence de contact",
      "Email": "Courriel",
      "Phone": "Téléphone",
      "Register": "S'inscrire"
    }
  }
}
''';

  testWidgets(
      'FormioForm updates translations in realtime without losing user-entered data',
      (tester) async {
    final controller = FormioController();
    Locale currentLocale = const Locale('en');

    late StateSetter parentSetState;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              parentSetState = setState;
              return FormioForm(
                schema: testSchemaWithI18n,
                controller: controller,
                options: FormioOptions(locale: currentLocale),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initial English labels and placeholders
    expect(find.textContaining('First Name'), findsOneWidget);
    expect(find.text('Your legal given name'), findsOneWidget);
    expect(find.text('Contact Preference'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);

    // 2. User types into the text field
    await tester.enterText(find.byType(TextFormField).first, 'Alice');
    await tester.pumpAndSettle();
    expect(controller.getValue('firstName'), 'Alice');

    // 3. Select radio option
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    expect(controller.getValue('contactPreference'), 'email');

    // 4. Trigger validation so error shows if any (none yet, but let's test)
    // Now switch locale to French in parent state
    parentSetState(() {
      currentLocale = const Locale('fr');
    });
    await tester.pumpAndSettle();

    // 5. Verify ALL labels and options updated to French in real-time
    expect(find.textContaining('Prénom'), findsOneWidget);
    expect(find.text('Votre prénom légal'), findsOneWidget);
    expect(find.text('Préférence de contact'), findsOneWidget);
    expect(find.text('Courriel'), findsOneWidget);
    expect(find.text('Téléphone'), findsOneWidget);
    expect(find.text("S'inscrire"), findsOneWidget);

    // 6. CRUCIAL: Verify user-typed data was NOT lost during locale switch!
    expect(find.text('Alice'), findsOneWidget);
    expect(controller.getValue('firstName'), 'Alice');
    expect(controller.getValue('contactPreference'), 'email');

    // 7. Test error summary translation
    controller.setValue('firstName', '');
    controller.validate();
    await tester.pumpAndSettle();
    expect(find.text('Veuillez corriger les erreurs avant de soumettre le formulaire.'),
        findsOneWidget);

    // 8. Verify programmatic controller.setLocale also updates in real-time
    controller.setLocale(const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text('Please fix the errors before submitting the form.'),
        findsOneWidget);
    expect(find.textContaining('First Name'), findsWidgets);
    expect(find.text('Register'), findsOneWidget);
  });
}
