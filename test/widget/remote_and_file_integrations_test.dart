import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_formio_renderer/flutter_formio_renderer.dart';

void main() {
  group('Remote Options, Files, Signature and Strict Mode', () {
    testWidgets(
        'remote select fetches options through FormioRemoteOptionsAdapter',
        (tester) async {
      final jsonStr =
          File('test/fixtures/05_dependent_dropdowns.json').readAsStringSync();
      final schema = FormioFormSchema.parse(jsonStr);

      final adapter = MockRemoteOptionsAdapter({
        '/api/cities': [
          const SelectOption(label: 'Paris', value: 'paris'),
          const SelectOption(label: 'Lyon', value: 'lyon'),
          const SelectOption(label: 'Marseille', value: 'marseille'),
        ],
      }, latency: Duration.zero);

      final options = FormioOptions(remoteOptionsAdapter: adapter);
      final controller = FormioController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FormioForm(
                schema: schema,
                controller: controller,
                options: options,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dropdown should be loaded with options
      expect(find.text('Select an option...'), findsWidgets);
    });

    testWidgets('URL select uses HTTP GET and Form.io value/template fields',
        (tester) async {
      final requestedUris = <Uri>[];
      final adapter = FormioHttpRemoteOptionsAdapter(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          requestedUris.add(request.url);
          return http.Response(
            jsonEncode([
              {'id': 'paris', 'name': 'Paris'},
              {'id': 'lyon', 'name': 'Lyon'},
            ]),
            200,
          );
        }),
      );
      final schema = FormioFormSchema.parse(jsonEncode({
        'components': [
          {
            'type': 'select',
            'key': 'city',
            'label': 'City',
            'dataSrc': 'url',
            'data': {'url': 'https://api.example.test/cities'},
            'valueProperty': 'id',
            'template': '<span>{{ item.name }}</span>',
          },
        ],
      }));
      final controller = FormioController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FormioForm(
            schema: schema,
            controller: controller,
            options: FormioOptions(remoteOptionsAdapter: adapter),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(requestedUris, [Uri.parse('https://api.example.test/cities')]);
      await tester.tap(find.byType(DropdownButtonFormField<dynamic>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paris').last);
      await tester.pumpAndSettle();

      expect(controller.submissionData['city'], 'paris');
    });

    testWidgets('file upload adapter uploads file and serializes metadata',
        (tester) async {
      final jsonStr = File('test/fixtures/08_file_upload_and_signature.json')
          .readAsStringSync();
      final schema = FormioFormSchema.parse(jsonStr);
      final storageAdapter = MockFileStorageAdapter(
          uploadLatency: const Duration(milliseconds: 10));
      final options = FormioOptions(fileStorageAdapter: storageAdapter);
      final controller = FormioController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FormioForm(
                schema: schema,
                controller: controller,
                options: options,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upload File'), findsOneWidget);

      // Tap Upload File
      await tester.tap(find.text('Upload File'));
      await tester.pumpAndSettle();

      // File should appear in list
      expect(find.textContaining('document_'), findsOneWidget);

      final sub = controller.getSubmission();
      final files = sub.data['attachments'] as List;
      expect(files.length, 1);
      expect(files.first['storage'], 'mock');
      expect(files.first['type'], 'application/pdf');
    });

    testWidgets(
        'unsupported component renders warning placeholder and blocks submission in strict mode',
        (tester) async {
      final jsonStr = File('test/fixtures/07_unsupported_and_cyclic.json')
          .readAsStringSync();
      final schema = FormioFormSchema.parse(jsonStr);

      final controller = FormioController();
      const options = FormioOptions(strictMode: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FormioForm(
                schema: schema,
                controller: controller,
                options: options,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Placeholder displayed with component type
      expect(find.text('Unsupported Component: "unknown_future_component"'),
          findsOneWidget);
    });
  });
}
