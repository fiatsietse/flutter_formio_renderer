import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_formio_renderer/flutter_formio_renderer.dart';

void main() {
  const genericHtmlFormSchema = '''
{
  "display": "form",
  "components": [
    {
      "type": "htmlelement",
      "key": "banner",
      "tag": "div",
      "content": "<style>@media (max-width:768px){.badge{display:none !important;}}</style><div style=\\"display:flex;align-items:flex-start;gap:12px;background:#fbf5df;border-left:5px solid #9a8b3c;padding:12px 16px;\\"><div class=\\"badge\\" style=\\"width:26px;height:26px;border-radius:50%;background:#9a8b3c;color:#fff;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:14px;\\">?</div><p style=\\"margin:0;font-size:14px;color:#1E2939;\\">Important Notice</p></div>",
      "input": false
    },
    {
      "type": "htmlelement",
      "key": "cardLayout",
      "tag": "div",
      "content": "<div style=\\"display:flex; gap:16px; flex-wrap:nowrap;\\"><div style=\\"flex:1; background:#F9FAFB; border-radius:12px; padding:20px; border:1px solid #f0f0f0;\\"><h3 style=\\"font-size:15px; font-weight:600; margin:0 0 4px;\\">Card Header</h3><p style=\\"font-size:13px; color:#4A5565;\\">Card Body Description</p></div></div>",
      "input": false
    },
    {
      "type": "textfield",
      "key": "fullName",
      "label": "Full Name",
      "input": true
    }
  ]
}
''';

  Widget buildTestHost() {
    return const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: FormioForm(
            schema: genericHtmlFormSchema,
          ),
        ),
      ),
    );
  }

  testWidgets(
      'HTML element properly renders styled infobox, badge, and cards without raw CSS',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 1600);
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestHost());
    await tester.pumpAndSettle();

    // 1. Text content in the banner is rendered
    expect(find.text('Important Notice'), findsOneWidget);

    // 2. Suppresses raw style code and @media rules from display
    expect(find.textContaining('@media'), findsNothing);
    expect(find.textContaining('!important'), findsNothing);
    expect(find.textContaining('display:none'), findsNothing);

    // 3. Circular badge widget is rendered
    expect(find.text('?'), findsOneWidget);

    // 4. Flex card content is rendered
    expect(find.text('Card Header'), findsOneWidget);
    expect(find.text('Card Body Description'), findsOneWidget);

    // 5. Native Form.io textfield is also rendered
    expect(find.text('Full Name'), findsOneWidget);

    // No exceptions
    expect(tester.takeException(), isNull);
  });
}
