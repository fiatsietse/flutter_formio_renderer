import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_formio_renderer/flutter_formio_renderer.dart';

void main() {
  group('JsonLogicEngine', () {
    const engine = JsonLogicEngine();

    test('evaluates var expressions against nested data context', () {
      final context = {
        'data': {
          'user': {'name': 'Alice', 'age': 30},
          'tags': ['flutter', 'formio']
        },
        'row': {'price': 49.99}
      };

      expect(engine.evaluate({'var': 'data.user.name'}, context), 'Alice');
      expect(engine.evaluate({'var': 'data.user.age'}, context), 30);
      expect(engine.evaluate({'var': 'row.price'}, context), 49.99);
      expect(engine.evaluate({'var': 'data.tags.0'}, context), 'flutter');
      expect(
          engine.evaluate({
            'var': ['missing', 'defaultVal']
          }, context),
          'defaultVal');
    });

    test('evaluates arithmetic and comparisons', () {
      final context = {'qty': 3, 'price': 15};
      expect(
          engine.evaluate({
            '*': [
              {'var': 'qty'},
              {'var': 'price'}
            ]
          }, context),
          45);
      expect(
          engine.evaluate({
            '+': [10, 20, 5]
          }, {}),
          35);
      expect(
          engine.evaluate({
            '-': [50, 15]
          }, {}),
          35);
      expect(
          engine.evaluate({
            '/': [100, 4]
          }, {}),
          25);
      expect(
          engine.evaluate({
            '%': [10, 3]
          }, {}),
          1);

      expect(
          engine.evaluate({
            '<': [10, 20]
          }, {}),
          isTrue);
      expect(
          engine.evaluate({
            '>=': [20, 20]
          }, {}),
          isTrue);
      expect(
          engine.evaluate({
            '<=': [10, 15, 20]
          }, {}),
          isTrue); // between
    });

    test('evaluates boolean logic and conditions', () {
      expect(
          engine.evaluate({
            'and': [true, true, true]
          }, {}),
          isTrue);
      expect(
          engine.evaluate({
            'and': [true, false, true]
          }, {}),
          isFalse);
      expect(
          engine.evaluate({
            'or': [false, true, false]
          }, {}),
          isTrue);
      expect(engine.evaluate({'!': false}, {}), isTrue);
      expect(engine.evaluate({'!!': 'non-empty'}, {}), isTrue);

      expect(
        engine.evaluate({
          'if': [
            {
              '==': [
                {'var': 'role'},
                'admin'
              ]
            },
            'Full Access',
            'Restricted Access'
          ]
        }, {
          'role': 'admin'
        }),
        'Full Access',
      );
    });

    test('evaluates in, cat, substr', () {
      expect(
          engine.evaluate({
            'in': [
              'apple',
              ['banana', 'apple', 'orange']
            ]
          }, {}),
          isTrue);
      expect(
          engine.evaluate({
            'in': ['sub', 'substring']
          }, {}),
          isTrue);
      expect(
          engine.evaluate({
            'cat': ['Hello ', 'World', '!']
          }, {}),
          'Hello World!');
      expect(
          engine.evaluate({
            'substr': ['Antigravity', 0, 4]
          }, {}),
          'Anti');
    });
  });
}
