import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_formio_renderer/flutter_formio_renderer.dart';

void main() {
  late String butodraJsonStr;
  late FormioFormSchema schema;

  setUpAll(() {
    final file = File('test/fixtures/09_delivrance_attestation_butodra.json');
    butodraJsonStr = file.readAsStringSync();
    schema = FormioFormSchema.parse(butodraJsonStr);
  });

  group('BUTODRA Real-World Wizard Schema', () {
    test('parses wizard definition, title, and detects panels as wizard pages',
        () {
      expect(schema.title, "Délivrance de l'attestation de membre BUTODRA");
      expect(schema.isWizard, isTrue);
      expect(schema.display, 'wizard');

      // Check wizard pages: 5 panels
      final pages = schema.wizardPages;
      expect(pages.length, 5);
      expect(pages[0].key, 'stepIntro');
      expect(pages[1].key, 'informationsPersonnelles');
      expect(pages[2].key, 'informationsSurLaDemande');
      expect(pages[3].key, 'piecesAFournir');
      expect(pages[4].key, 'stepRecap');
    });

    test('has embedded i18n dictionary for French and English', () {
      expect(schema.rawJson['i18n'], isNotNull);
      final i18n = schema.rawJson['i18n'] as Map<String, dynamic>;
      expect(i18n.containsKey('fr'), isTrue);
      expect(i18n.containsKey('en'), isTrue);

      final fr = i18n['fr'] as Map<String, dynamic>;
      expect(fr['stepIntro.title'], 'Description');
      expect(
          fr['quelTypeDeProcedureSouhaitezVous.normale'], 'Procédure normale');
      expect(
          fr['quelTypeDeProcedureSouhaitezVous.express'], 'Procédure express');
      expect(fr['quelTypeDeProcedureSouhaitezVous.error.required'],
          'Veuillez renseigner cette information pour continuer');
    });

    test(
        'SafeScriptEvaluator evaluates BUTODRA conditional and calculation scripts',
        () {
      const evaluator = SafeScriptEvaluator();

      // 1. Initial state: radio is null -> !data.x is true
      const ctxEmpty = FormioScriptContext(
        data: {},
        row: {},
      );
      final res1 = evaluator.evaluateSync(
        script: 'show = !data.quelTypeDeProcedureSouhaitezVous;',
        context: ctxEmpty,
      );
      expect(res1.isSuccess, isTrue);
      expect(res1.value, isTrue);

      // 2. Radio selected -> !data.x is false
      const ctxSelected = FormioScriptContext(
        data: {'quelTypeDeProcedureSouhaitezVous': 'normale'},
        row: {},
      );
      final res2 = evaluator.evaluateSync(
        script: 'show = !data.quelTypeDeProcedureSouhaitezVous;',
        context: ctxSelected,
      );
      expect(res2.isSuccess, isTrue);
      expect(res2.value, isFalse);

      // 3. Radio selected -> !!data.x is true
      final res3 = evaluator.evaluateSync(
        script: 'show = !!data.quelTypeDeProcedureSouhaitezVous;',
        context: ctxSelected,
      );
      expect(res3.isSuccess, isTrue);
      expect(res3.value, isTrue);

      // 4. Piece type membership check: ['passeport','cni'].indexOf(data.typeDePiece1) !== -1
      const ctxCni = FormioScriptContext(
        data: {'typeDePiece1': 'cni'},
        row: {},
      );
      final resCni = evaluator.evaluateSync(
        script: "show = ['passeport','cni'].indexOf(data.typeDePiece1) !== -1;",
        context: ctxCni,
      );
      expect(resCni.isSuccess, isTrue);
      expect(resCni.value, isTrue);

      const ctxOther = FormioScriptContext(
        data: {'typeDePiece1': 'autre'},
        row: {},
      );
      final resOther = evaluator.evaluateSync(
        script: "show = ['passeport','cni'].indexOf(data.typeDePiece1) !== -1;",
        context: ctxOther,
      );
      expect(resOther.isSuccess, isTrue);
      expect(resOther.value, isFalse);

      // 5. Telephone calculation: value = (data.a || '') + (data.b || '')
      const ctxPhone = FormioScriptContext(
        data: {
          'telephoneDemandeurIndicatif': '+228',
          'telephoneDemandeurNumeroLocal': '90000000',
        },
        row: {},
      );
      final resPhone = evaluator.evaluateSync(
        script:
            "value = (data.telephoneDemandeurIndicatif||'') + (data.telephoneDemandeurNumeroLocal||'');",
        context: ctxPhone,
      );
      expect(resPhone.isSuccess, isTrue);
      expect(resPhone.value, '+22890000000');
    });

    test(
        'FormioStateManager reactively updates visibility of procedure details and translates labels',
        () {
      const options = FormioOptions(
        locale: Locale('fr'),
      );
      final manager = FormioStateManager(
        schema: schema,
        options: options,
      );

      // Initially, procedure is not selected:
      // htmlInfoboxDescription is VISIBLE
      final infoBox = manager.getState('htmlInfoboxDescription');
      expect(infoBox, isNotNull);
      expect(infoBox!.hidden, isFalse);

      // html2, conditions, pieces are HIDDEN
      final html2 = manager.getState('html2');
      expect(html2, isNotNull);
      expect(html2!.hidden, isTrue);

      // Select 'normale'
      manager.setValue(
          DataPath.parse('quelTypeDeProcedureSouhaitezVous'), 'normale');

      // Now infobox should be hidden, and html2 should be visible!
      expect(infoBox.hidden, isTrue);
      expect(html2.hidden, isFalse);

      // Check translation of step title
      final title = manager.translate('stepIntro.title');
      expect(title, 'Description');

      // Check validation error translation
      manager.setValue(
          DataPath.parse('quelTypeDeProcedureSouhaitezVous'), null);
      final validationRes = manager.validate(onlyCurrentPage: true);
      expect(validationRes.isValid, isFalse);
      final reqErr = validationRes.errors.firstWhere(
        (e) => e.componentKey == 'quelTypeDeProcedureSouhaitezVous',
      );
      expect(reqErr.message,
          'Veuillez renseigner cette information pour continuer');
    });
  });
}
