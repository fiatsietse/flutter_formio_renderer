import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_formio_renderer/flutter_formio_renderer.dart';

void main() {
  group('SafeScriptEvaluator', () {
    const evaluator = SafeScriptEvaluator();

    test('evaluates boolean negation and truthiness', () {
      // 1. Initial state: field is null -> !data.field is true
      const ctxEmpty = FormioScriptContext(
        data: {},
        row: {},
      );
      final res1 = evaluator.evaluateSync(
        script: 'show = !data.selectedCategory;',
        context: ctxEmpty,
      );
      expect(res1.isSuccess, isTrue);
      expect(res1.value, isTrue);

      // 2. Value selected -> !data.field is false
      const ctxSelected = FormioScriptContext(
        data: {'selectedCategory': 'standard'},
        row: {},
      );
      final res2 = evaluator.evaluateSync(
        script: 'show = !data.selectedCategory;',
        context: ctxSelected,
      );
      expect(res2.isSuccess, isTrue);
      expect(res2.value, isFalse);

      // 3. Value selected -> !!data.field is true
      final res3 = evaluator.evaluateSync(
        script: 'show = !!data.selectedCategory;',
        context: ctxSelected,
      );
      expect(res3.isSuccess, isTrue);
      expect(res3.value, isTrue);
    });

    test('evaluates array membership check via indexOf', () {
      const ctxAllowed = FormioScriptContext(
        data: {'documentType': 'passport'},
        row: {},
      );
      final resAllowed = evaluator.evaluateSync(
        script: "show = ['passport','national_id'].indexOf(data.documentType) !== -1;",
        context: ctxAllowed,
      );
      expect(resAllowed.isSuccess, isTrue);
      expect(resAllowed.value, isTrue);

      const ctxOther = FormioScriptContext(
        data: {'documentType': 'other'},
        row: {},
      );
      final resOther = evaluator.evaluateSync(
        script: "show = ['passport','national_id'].indexOf(data.documentType) !== -1;",
        context: ctxOther,
      );
      expect(resOther.isSuccess, isTrue);
      expect(resOther.value, isFalse);
    });

    test('evaluates calculated string concatenation and fallback values', () {
      const ctxPhone = FormioScriptContext(
        data: {
          'dialCode': '+1',
          'localNumber': '5550199',
        },
        row: {},
      );
      final resPhone = evaluator.evaluateSync(
        script: "value = (data.dialCode||'') + (data.localNumber||'');",
        context: ctxPhone,
      );
      expect(resPhone.isSuccess, isTrue);
      expect(resPhone.value, '+15550199');
    });
  });
}
