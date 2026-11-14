import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_formio_renderer/flutter_formio_renderer.dart';
import 'fixtures_data.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Form.io Renderer Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const FormioShowcaseScreen(),
    );
  }
}

class FormioShowcaseScreen extends StatefulWidget {
  const FormioShowcaseScreen({super.key});

  @override
  State<FormioShowcaseScreen> createState() => _FormioShowcaseScreenState();
}

class _FormioShowcaseScreenState extends State<FormioShowcaseScreen> {
  String _selectedFixtureKey = '01_basic_registration';
  bool _readOnly = false;
  bool _strictMode = false;
  String _language = 'en';

  final FormioController _controller = FormioController();
  Map<String, dynamic> _liveData = {};
  FormioValidationResult? _lastValidationResult;
  final List<FormioDiagnostic> _diagnostics = [];
  String? _lastSubmissionJson;

  // Remote options adapter for fixture 05
  final MockRemoteOptionsAdapter _remoteAdapter = MockRemoteOptionsAdapter({
    '/api/cities': [
      const SelectOption(label: 'New York (US)', value: 'nyc'),
      const SelectOption(label: 'San Francisco (US)', value: 'sf'),
      const SelectOption(label: 'Toronto (CA)', value: 'toronto'),
      const SelectOption(label: 'Montreal (CA)', value: 'montreal'),
      const SelectOption(label: 'Paris (FR)', value: 'paris'),
      const SelectOption(label: 'Lyon (FR)', value: 'lyon'),
    ],
  });

  // Mock file storage adapter for fixture 08
  final MockFileStorageAdapter _fileAdapter = MockFileStorageAdapter();

  Map<String, dynamic>? _getInitialDataForFixture(String key) {
    if (key == '06_existing_submission') {
      return {
        'username': 'bob_admin',
        'role': 'admin',
        'active': true,
        'bio': 'Senior Site Reliability Engineer & Flutter Enthusiast',
      };
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final schemaJson = ExampleFixtures.all[_selectedFixtureKey] ??
        ExampleFixtures.basicRegistration;
    final initialData = _getInitialDataForFixture(_selectedFixtureKey);

    final options = FormioOptions(
      strictMode: _strictMode,
      locale: Locale(_language),
      remoteOptionsAdapter: _remoteAdapter,
      fileStorageAdapter: _fileAdapter,
      onDiagnostic: (d) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _diagnostics.add(d);
            });
          }
        });
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Form.io Renderer'),
        actions: [
          // Locale Switcher
          DropdownButton<String>(
            value: _language,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('🇬🇧 EN')),
              DropdownMenuItem(value: 'fr', child: Text('🇫🇷 FR')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _language = val);
            },
          ),
          const SizedBox(width: 8),
          // ReadOnly Switch
          Row(
            children: [
              const Text('Read-Only', style: TextStyle(fontSize: 12)),
              Switch(
                value: _readOnly,
                onChanged: (val) => setState(() => _readOnly = val),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Strict Mode Switch
          Row(
            children: [
              const Text('Strict Mode', style: TextStyle(fontSize: 12)),
              Switch(
                value: _strictMode,
                onChanged: (val) => setState(() => _strictMode = val),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Left: Form Workspace
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fixture selector dropdown
                  Card(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.description_outlined),
                          const SizedBox(width: 12),
                          const Text('Select Fixture: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedFixtureKey,
                              underline: const SizedBox.shrink(),
                              items: const [
                                DropdownMenuItem(
                                    value: '01_basic_registration',
                                    child: Text('1. Basic Registration Form')),
                                DropdownMenuItem(
                                    value: '02_conditional_wizard',
                                    child: Text(
                                        '2. Conditional Multi-Step Wizard')),
                                DropdownMenuItem(
                                    value: '03_nested_and_repeating',
                                    child: Text(
                                        '3. Nested Containers & Repeating Grids')),
                                DropdownMenuItem(
                                    value: '04_calculated_totals',
                                    child: Text(
                                        '4. Calculated Totals & Line Items')),
                                DropdownMenuItem(
                                    value: '05_dependent_dropdowns',
                                    child:
                                        Text('5. Dependent Remote Dropdowns')),
                                DropdownMenuItem(
                                    value: '06_existing_submission',
                                    child: Text(
                                        '6. Pre-filled Existing Submission')),
                                DropdownMenuItem(
                                    value: '07_unsupported_and_cyclic',
                                    child: Text(
                                        '7. Cyclic Logic & Strict Mode Diagnostics')),
                                DropdownMenuItem(
                                    value: '08_file_upload_and_signature',
                                    child:
                                        Text('8. File Upload & Signature Pad')),
                                DropdownMenuItem(
                                    value: '09_delivrance_attestation_butodra',
                                    child: Text(
                                        '9. BUTODRA Member Certificate (Wizard)')),
                              ],
                              onChanged: (key) {
                                if (key != null) {
                                  setState(() {
                                    _selectedFixtureKey = key;
                                    _liveData = {};
                                    _lastValidationResult = null;
                                    _lastSubmissionJson = null;
                                    _diagnostics.clear();
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // The FormioForm Widget!
                  FormioForm(
                    key: ValueKey(
                        '${_selectedFixtureKey}_${_language}_$_readOnly'),
                    schema: schemaJson,
                    controller: _controller,
                    initialData: initialData,
                    readOnly: _readOnly,
                    options: options,
                    onChange: (data) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => _liveData = data);
                        }
                      });
                    },
                    onSubmit: (sub) {
                      final json = const JsonEncoder.withIndent('  ')
                          .convert(sub.toJson());
                      setState(() => _lastSubmissionJson = json);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Form Submitted Successfully!')),
                      );
                    },
                    onError: (res) {
                      setState(() => _lastValidationResult = res);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Bottom Action Toolbar
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.rule),
                        label: const Text('Validate Form'),
                        onPressed: () {
                          final res = _controller.validate();
                          setState(() => _lastValidationResult = res);
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset Form'),
                        onPressed: () {
                          _controller.reset();
                          setState(() {
                            _liveData = {};
                            _lastValidationResult = null;
                            _lastSubmissionJson = null;
                          });
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.drafts_outlined),
                        label: const Text('Export Draft'),
                        onPressed: () {
                          final draft = _controller.exportDraft();
                          final json = const JsonEncoder.withIndent('  ')
                              .convert(draft.toJson());
                          setState(() => _lastSubmissionJson = json);
                        },
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.send),
                        label: const Text('Submit Envelope'),
                        onPressed: () {
                          final res = _controller.validate();
                          setState(() => _lastValidationResult = res);
                          if (res.isValid) {
                            final sub = _controller.getSubmission();
                            final json = const JsonEncoder.withIndent('  ')
                                .convert(sub.toJson());
                            setState(() => _lastSubmissionJson = json);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Right: Live Inspector Drawer
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(left: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    color: Colors.grey.shade200,
                    child: const Row(
                      children: [
                        Icon(Icons.terminal, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Live Inspection & Payloads',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          const TabBar(
                            tabs: [
                              Tab(text: 'Live Data'),
                              Tab(text: 'Submission'),
                              Tab(text: 'Diagnostics'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                // Tab 1: Live Data Tree
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: SelectableText(
                                    _liveData.isEmpty
                                        ? '// No values entered yet'
                                        : const JsonEncoder.withIndent('  ')
                                            .convert(_liveData),
                                    style: const TextStyle(
                                        fontFamily: 'monospace', fontSize: 13),
                                  ),
                                ),
                                // Tab 2: Exported Submission
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: SelectableText(
                                    _lastSubmissionJson ??
                                        '// Press "Submit Envelope" or "Export Draft" to serialize',
                                    style: const TextStyle(
                                        fontFamily: 'monospace', fontSize: 13),
                                  ),
                                ),
                                // Tab 3: Diagnostics & Validation
                                ListView(
                                  padding: const EdgeInsets.all(12.0),
                                  children: [
                                    if (_lastValidationResult != null) ...[
                                      Text(
                                        'Validation Status: ${_lastValidationResult!.isValid ? "VALID" : "INVALID (${_lastValidationResult!.errors.length} errors)"}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _lastValidationResult!.isValid
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      for (final err
                                          in _lastValidationResult!.errors)
                                        Text(
                                            '• [${err.errorCode}] ${err.dataPath}: ${err.message}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.red)),
                                      const Divider(),
                                    ],
                                    const Text('Diagnostics Log:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    if (_diagnostics.isEmpty)
                                      const Text('No warnings or cycle alerts.',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                    for (final d in _diagnostics)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 6.0),
                                        child: Text(d.toString(),
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontFamily: 'monospace')),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
