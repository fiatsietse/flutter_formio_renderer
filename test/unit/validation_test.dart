import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_formio_renderer/flutter_formio_renderer.dart';

void main() {
  group('FormioComponentValidator', () {
    test('validates required fields, minLength, pattern, and customMessage',
        () {
      final schema = FormioFormSchema.parse({
        'display': 'form',
        'components': [
          {
            'type': 'textfield',
            'key': 'code',
            'label': 'Product Code',
            'validate': {
              'required': true,
              'minLength': 4,
              'pattern': '^[A-Z]{2}[0-9]{2}\$',
              'customMessage':
                  '{field} must be 2 uppercase letters followed by 2 digits.'
            }
          }
        ]
      });

      final manager = FormioStateManager(schema: schema);

      // Initially empty -> required error
      var result = manager.validate();
      expect(result.isValid, isFalse);
      expect(result.firstError!.errorCode, 'required');

      // Too short -> minLength error
      manager.setValue(DataPath.parse('code'), 'AB');
      result = manager.validate();
      expect(result.isValid, isFalse);
      expect(result.firstError!.errorCode, 'minLength');

      // Invalid pattern -> customMessage used
      manager.setValue(DataPath.parse('code'), 'abcd');
      result = manager.validate();
      expect(result.isValid, isFalse);
      expect(result.firstError!.message,
          'Product Code must be 2 uppercase letters followed by 2 digits.');

      // Valid format
      manager.setValue(DataPath.parse('code'), 'AB12');
      result = manager.validate();
      expect(result.isValid, isTrue);
    });

    test('validates email and numeric bounds', () {
      final schema = FormioFormSchema.parse({
        'display': 'form',
        'components': [
          {
            'type': 'email',
            'key': 'userEmail',
            'label': 'Email',
            'validate': {'required': true}
          },
          {
            'type': 'number',
            'key': 'age',
            'label': 'Age',
            'validate': {'min': 18, 'max': 65}
          }
        ]
      });

      final manager = FormioStateManager(schema: schema);

      manager.setValue(DataPath.parse('userEmail'), 'invalid-email');
      manager.setValue(DataPath.parse('age'), 16);

      var res = manager.validate();
      expect(res.errors.any((e) => e.errorCode == 'email'), isTrue);
      expect(res.errors.any((e) => e.errorCode == 'min'), isTrue);

      manager.setValue(DataPath.parse('userEmail'), 'john@example.com');
      manager.setValue(DataPath.parse('age'), 28);
      res = manager.validate();
      expect(res.isValid, isTrue);
    });

    test('hidden or disabled fields are not validated', () {
      final schema = FormioFormSchema.parse({
        'display': 'form',
        'components': [
          {
            'type': 'checkbox',
            'key': 'enableSpecial',
            'label': 'Enable Special Field'
          },
          {
            'type': 'textfield',
            'key': 'specialField',
            'label': 'Special Field',
            'validate': {'required': true},
            'conditional': {'show': true, 'when': 'enableSpecial', 'eq': 'true'}
          }
        ]
      });

      final manager = FormioStateManager(schema: schema);

      // When enableSpecial is false, specialField is hidden -> validation must pass!
      var res = manager.validate();
      expect(res.isValid, isTrue);

      // When enableSpecial is true, specialField is visible and required -> validation fails!
      manager.setValue(DataPath.parse('enableSpecial'), true);
      res = manager.validate();
      expect(res.isValid, isFalse);
      expect(res.firstError!.componentKey, 'specialField');
    });

    test('maps server-returned validation errors back to fields', () {
      final schema = FormioFormSchema.parse({
        'display': 'form',
        'components': [
          {'type': 'textfield', 'key': 'username', 'label': 'Username'}
        ]
      });

      final manager = FormioStateManager(schema: schema);
      manager.setValue(DataPath.parse('username'), 'taken_user');

      // Server returns error
      manager.setServerErrors(
          {'username': 'This username is already taken by another user.'});

      final state = manager.getState('username')!;
      expect(state.hasErrors, isTrue);
      expect(state.errors.first.message,
          'This username is already taken by another user.');
      expect(state.errors.first.errorCode, 'server');
    });
  });
}
