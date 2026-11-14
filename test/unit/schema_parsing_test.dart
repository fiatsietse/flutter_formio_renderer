import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_formio_renderer/flutter_formio_renderer.dart';

void main() {
  group('FormioFormSchema Parsing', () {
    test('parses basic registration fixture', () {
      final jsonStr =
          File('test/fixtures/01_basic_registration.json').readAsStringSync();
      final schema = FormioFormSchema.parse(jsonStr);

      expect(schema.display, 'form');
      expect(schema.title, 'User Registration');
      expect(schema.components.length, 7);

      final firstName = schema.findComponentByKey('firstName')!;
      expect(firstName.type, 'textfield');
      expect(firstName.validate.required, isTrue);
      expect(firstName.validate.minLength, 2);

      final email = schema.findComponentByKey('email')!;
      expect(email.type, 'email');
      expect(email.validate.required, isTrue);
    });

    test('parses wizard fixture and derives wizard pages from panels', () {
      final jsonStr =
          File('test/fixtures/02_conditional_wizard.json').readAsStringSync();
      final schema = FormioFormSchema.parse(jsonStr);

      expect(schema.isWizard, isTrue);
      expect(schema.wizardPages.length, 3);
      expect(schema.wizardPages[0].key, 'page1');
      expect(schema.wizardPages[1].key, 'page2');
      expect(schema.wizardPages[2].key, 'page3');

      final page2 = schema.wizardPages[1];
      expect(page2.conditional.when, 'hasSpouse');
      expect(page2.conditional.eq, 'true');
    });

    test('preserves unrecognized schema properties for extensions', () {
      final jsonMap = {
        'display': 'form',
        'customEnterpriseField': 'corp_9912',
        'components': [
          {
            'type': 'textfield',
            'key': 'customField',
            'label': 'Custom',
            'x-vendor-tag': 'custom-analytics-attr',
            'properties': {'customFlag': true}
          }
        ]
      };

      final schema = FormioFormSchema.parse(jsonMap);
      expect(schema.rawJson['customEnterpriseField'], 'corp_9912');

      final comp = schema.components.first;
      expect(comp.rawJson['x-vendor-tag'], 'custom-analytics-attr');
      expect(comp.properties['customFlag'], isTrue);
    });
  });
}
