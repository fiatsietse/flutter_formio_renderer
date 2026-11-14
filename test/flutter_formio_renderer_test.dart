import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_formio_renderer/flutter_formio_renderer.dart';

void main() {
  test('FormioFormSchema parses correctly', () {
    const jsonStr = '''
    {
      "display": "form",
      "components": [
        {
          "type": "textfield",
          "key": "firstName",
          "label": "First Name"
        }
      ]
    }
    ''';
    final schema = FormioFormSchema.parse(jsonStr);
    expect(schema.display, 'form');
    expect(schema.components.length, 1);
    expect(schema.components.first.key, 'firstName');
    expect(schema.components.first.type, 'textfield');
  });
}
