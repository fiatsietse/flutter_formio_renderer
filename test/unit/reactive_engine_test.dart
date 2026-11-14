import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_formio_renderer/flutter_formio_renderer.dart';

void main() {
  group('FormioReactiveEngine', () {
    test('toggling a field updates dependent visibility correctly', () {
      final jsonStr =
          File('test/fixtures/02_conditional_wizard.json').readAsStringSync();
      final schema = FormioFormSchema.parse(jsonStr);
      final manager = FormioStateManager(schema: schema);

      final spousePageState = manager.getState('page2')!;
      // Initially hasSpouse is null/false -> page2 is hidden
      expect(spousePageState.hidden, isTrue);

      // Toggle hasSpouse to true
      manager.setValue(DataPath.parse('hasSpouse'), true);
      expect(spousePageState.hidden, isFalse);

      // Toggle back to false
      manager.setValue(DataPath.parse('hasSpouse'), false);
      expect(spousePageState.hidden, isTrue);
    });

    test('hiding a field follows clearOnHide retention semantics', () {
      final schema = FormioFormSchema.parse({
        'display': 'form',
        'components': [
          {'type': 'checkbox', 'key': 'showExtra', 'label': 'Show Extra'},
          {
            'type': 'textfield',
            'key': 'extraDetails',
            'label': 'Extra Details',
            'clearOnHide': true,
            'conditional': {'show': true, 'when': 'showExtra', 'eq': 'true'}
          }
        ]
      });

      final manager = FormioStateManager(schema: schema);

      // 1. Show field and enter data
      manager.setValue(DataPath.parse('showExtra'), true);
      manager.setValue(DataPath.parse('extraDetails'), 'Confidential Info');
      expect(manager.getValue(DataPath.parse('extraDetails')),
          'Confidential Info');

      // 2. Hide field -> value must be cleared because clearOnHide: true
      manager.setValue(DataPath.parse('showExtra'), false);
      expect(manager.getState('extraDetails')!.hidden, isTrue);
      expect(manager.getValue(DataPath.parse('extraDetails')), isNull);
    });

    test('preserves value when clearOnHide is false', () {
      final schema = FormioFormSchema.parse({
        'display': 'form',
        'components': [
          {'type': 'checkbox', 'key': 'showNotes', 'label': 'Show Notes'},
          {
            'type': 'textfield',
            'key': 'persistentNotes',
            'label': 'Persistent Notes',
            'clearOnHide': false,
            'conditional': {'show': true, 'when': 'showNotes', 'eq': 'true'}
          }
        ]
      });

      final manager = FormioStateManager(schema: schema);

      manager.setValue(DataPath.parse('showNotes'), true);
      manager.setValue(DataPath.parse('persistentNotes'), 'Keep This Saved');
      expect(manager.getValue(DataPath.parse('persistentNotes')),
          'Keep This Saved');

      // Hide field -> value must be kept because clearOnHide: false
      manager.setValue(DataPath.parse('showNotes'), false);
      expect(manager.getState('persistentNotes')!.hidden, isTrue);
      expect(manager.getValue(DataPath.parse('persistentNotes')),
          'Keep This Saved');
    });

    test('calculations inside one grid row do not affect another row', () {
      final jsonStr =
          File('test/fixtures/04_calculated_totals.json').readAsStringSync();
      final schema = FormioFormSchema.parse(jsonStr);
      final manager = FormioStateManager(schema: schema);

      final gridComp = schema.findComponentByKey('items')!;

      // Add Row 0: qty = 2, unitPrice = 10 -> lineTotal = 20
      manager.addGridRow(DataPath.parse('items'), gridComp);
      manager.setValue(DataPath.parse('items[0].quantity'), 2);
      manager.setValue(DataPath.parse('items[0].unitPrice'), 10);

      // Add Row 1: qty = 5, unitPrice = 100 -> lineTotal = 500
      manager.addGridRow(DataPath.parse('items'), gridComp);
      manager.setValue(DataPath.parse('items[1].quantity'), 5);
      manager.setValue(DataPath.parse('items[1].unitPrice'), 100);

      expect(manager.getValue(DataPath.parse('items[0].lineTotal')), 20);
      expect(manager.getValue(DataPath.parse('items[1].lineTotal')), 500);

      // Changing Row 0 does NOT change Row 1
      manager.setValue(DataPath.parse('items[0].quantity'), 3);
      expect(manager.getValue(DataPath.parse('items[0].lineTotal')), 30);
      expect(manager.getValue(DataPath.parse('items[1].lineTotal')), 500);
    });

    test('cyclic logic produces a diagnostic instead of hanging or crashing',
        () {
      final jsonStr = File('test/fixtures/07_unsupported_and_cyclic.json')
          .readAsStringSync();
      final schema = FormioFormSchema.parse(jsonStr);

      final diagnostics = <FormioDiagnostic>[];
      final options = FormioOptions(
        maxLogicIterations: 5,
        onDiagnostic: (d) => diagnostics.add(d),
      );

      final manager = FormioStateManager(schema: schema, options: options);

      // Trigger cyclic update
      manager.setValue(DataPath.parse('fieldB'), 'trigger');

      expect(
          diagnostics.any((d) =>
              d.code == 'CYCLE_DETECTED' ||
              d.code == 'MAX_ITERATIONS_EXCEEDED'),
          isTrue);
    });
  });
}
