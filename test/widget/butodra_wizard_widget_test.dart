import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_formio_renderer/flutter_formio_renderer.dart';

void main() {
  late String butodraJsonStr;

  setUpAll(() {
    final file = File('test/fixtures/09_delivrance_attestation_butodra.json');
    butodraJsonStr = file.readAsStringSync();
  });

  Widget buildTestHost({
    Locale locale = const Locale('fr'),
    void Function(FormioDiagnostic)? onDiagnostic,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: FormioForm(
            schema: butodraJsonStr,
            options: FormioOptions(
              locale: locale,
              onDiagnostic: onDiagnostic,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'BUTODRA form mounts without setState during build errors and renders wizard',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 1600);
    addTearDown(() => tester.view.resetPhysicalSize());

    final diagnostics = <FormioDiagnostic>[];

    await tester.pumpWidget(
      buildTestHost(
        onDiagnostic: (d) => diagnostics.add(d),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Wizard step tabs are visible and translated to "Description"
    expect(find.text('Description'), findsWidgets);

    // 2. Radio options are rendered with translated labels
    expect(find.text('Procédure normale'), findsOneWidget);
    expect(find.text('Procédure express'), findsOneWidget);

    // 3. Crucial: NO raw CSS code displayed on the page
    expect(find.textContaining('@media'), findsNothing);
    expect(find.textContaining('.sfc-card'), findsNothing);
    expect(find.textContaining('!important'), findsNothing);
    expect(find.textContaining('.formio-component-day'), findsNothing);

    // 4. CSS-styled circular badge '?' is rendered
    expect(find.text('?'), findsOneWidget);

    // 5. Select 'Procédure normale'
    await tester.tap(find.text('Procédure normale'));
    await tester.pumpAndSettle();

    // 6. Styled procedure cards are displayed with translated titles and interpolated values
    expect(find.text("Délai d'exécution"), findsOneWidget);
    expect(find.text('Coût de la procédure'), findsOneWidget);
    expect(find.text('Durée de validité'), findsOneWidget);
    expect(find.textContaining('Entre deux (02) semaines'), findsOneWidget);

    // Switch to express procedure
    await tester.tap(find.text('Procédure express'));
    await tester.pumpAndSettle();
    expect(find.textContaining('72 heures'), findsOneWidget);

    // 7. Divider separator line is rendered
    expect(find.byType(Divider), findsWidgets);

    // 8. Verify Next button exists (translated to 'Suivant' in French)
    expect(find.text('Suivant'), findsOneWidget);

    // No critical errors or unhandled exceptions thrown
    expect(tester.takeException(), isNull);
  });
}
