import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_formio_renderer/flutter_formio_renderer.dart';

void main() {
  group('DataPath and FormioDataTree', () {
    test('parses dot and bracket notation paths', () {
      final p1 = DataPath.parse('user.profile.name');
      expect(p1.segments, ['user', 'profile', 'name']);
      expect(p1.toDotString(), 'user.profile.name');

      final p2 = DataPath.parse('items[0].price');
      expect(p2.segments, ['items', 0, 'price']);
      expect(p2.toDotString(), 'items[0].price');
    });

    test('resolves and sets nested map and array values', () {
      final tree = FormioDataTree();
      final path = DataPath.parse('company.employees[0].name');

      final changed = tree.setValue(path, 'Alice');
      expect(changed, isTrue);

      final val = tree.getValue(path);
      expect(val, 'Alice');

      final exported = tree.exportData();
      expect(exported['company']['employees'][0]['name'], 'Alice');
    });

    test('applyDefaultIfAbsent does not overwrite existing submission values',
        () {
      final tree = FormioDataTree({
        'role': 'admin',
        'active': false,
        'bio': '',
      });

      // Existing non-null values must be preserved even if false or empty string
      final changedRole =
          tree.applyDefaultIfAbsent(DataPath.parse('role'), 'viewer');
      expect(changedRole, isFalse);
      expect(tree.getValue(DataPath.parse('role')), 'admin');

      final changedActive =
          tree.applyDefaultIfAbsent(DataPath.parse('active'), true);
      expect(changedActive, isFalse);
      expect(tree.getValue(DataPath.parse('active')), false);

      // Absent path receives default
      final changedNew =
          tree.applyDefaultIfAbsent(DataPath.parse('theme'), 'dark');
      expect(changedNew, isTrue);
      expect(tree.getValue(DataPath.parse('theme')), 'dark');
    });

    test('removes values cleanly on clearOnHide', () {
      final tree = FormioDataTree({
        'user': {'tempField': 'to_be_cleared'}
      });
      final path = DataPath.parse('user.tempField');

      final removed = tree.removeValue(path);
      expect(removed, isTrue);
      expect(tree.getValue(path), isNull);
    });
  });
}
