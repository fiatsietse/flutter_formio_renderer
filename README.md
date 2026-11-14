# Flutter Form.io Renderer (`flutter_formio_renderer`)

A robust, enterprise-ready Flutter renderer for existing Form.io JSON schemas. Renders dynamic forms and multi-step wizards as native Flutter widgets with reactive conditional logic, calculated values, client & server validation, repeating data grids, and pluggable integrations.

[![Flutter CI](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter)](https://flutter.dev)
[![Form.io Compatibility](https://img.shields.io/badge/Form.io%20Target-v4.19.0-green)](https://github.com/formio/formio.js)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Key Features

- **Native Flutter Rendering**: Pure Flutter widgets without webview overhead, HTML rendering risks, or native plugins. Cross-platform support for Android, iOS, Web, macOS, Windows, and Linux.
- **Form.io Pinned Compatibility**: Pinned to the official JavaScript reference renderer `formiojs@4.19.0` (compatible with 4.14.x through 4.19.x specifications).
- **Reactive Logic Engine**:
  - Simple conditional visibility (`show`, `when`, `eq`).
  - Native pure-Dart [JSON Logic](https://jsonlogic.com/) engine.
  - Scoped calculated values (row-level and form-level).
  - Advanced Form.io logic rules with dynamic property mutations (`required`, `disabled`, `hidden`, `label`).
  - Topological evaluation order, cycle detection, and iteration limits (`maxLogicIterations`).
  - Documented `clearOnHide` semantics.
- **Structured Data & Repeaters**:
  - `container`: Nested map in submission payload (`data.address.city`).
  - `datagrid`: Repeating rows of components with row limits and row-local evaluation.
  - `editgrid`: Collapsible row cards with inline modal editing, save and cancel.
  - `multiple: true` on basic fields.
- **Multi-Step Wizards (`display: "wizard"`)**:
  - Auto-derives pages from top-level panels.
  - Step indicator breadcrumbs with direct navigation.
  - Per-step validation (forward navigation validates current step; backward navigation is unblocked).
  - Conditional page visibility with automatic skipping of hidden pages.
  - Final submission full-form validation pass.
- **Robust Validation**:
  - `required`, `minLength`, `maxLength`, `min`, `max`, `pattern` (regex).
  - Format checks for `email`, `url`, and `phoneNumber`.
  - Selection count bounds (`minSelectedCount`, `maxSelectedCount`, `minRows`, `maxRows`).
  - JSON Logic validation rules (`validate.json`).
  - Server-returned field errors mapping (`controller.setServerErrors`).
  - Hidden and disabled fields are excluded from validation.
- **Pluggable Architecture**:
  - Remote dropdown options adapter (`FormioRemoteOptionsAdapter`).
  - File storage adapter (`FormioFileStorageAdapter`).
  - Vector signature pad capture with base64 PNG data URL export.
  - Subform schema resolver (`FormioSubformResolver`).
  - Secure script evaluator interface (`FormioScriptEvaluator`).
- **UX & Accessibility**:
  - Material 3 theme compatibility and custom `FormioThemeData`.
  - Accessible error summary banner and inline error highlights.
  - Built-in English and French localizations (`FormioLocalizations`).
  - Responsive layout for mobile, tablet, and desktop (`columns` component).

---

## Quickstart

### 1. Add dependency

In your `pubspec.yaml`:

```yaml
dependencies:
  flutter_formio_renderer:
    path: path/to/flutter_formio_renderer # or from pub.dev
```

### 2. Render a Form

```dart
import 'package:flutter/material.dart';
import 'package:flutter_formio_renderer/flutter_formio_renderer.dart';

class MyFormScreen extends StatefulWidget {
  const MyFormScreen({super.key});

  @override
  State<MyFormScreen> createState() => _MyFormScreenState();
}

class _MyFormScreenState extends State<MyFormScreen> {
  final FormioController _controller = FormioController();

  final String schemaJson = '''
  {
    "display": "form",
    "components": [
      {
        "type": "textfield",
        "key": "fullName",
        "label": "Full Name",
        "validate": { "required": true }
      },
      {
        "type": "email",
        "key": "email",
        "label": "Email Address",
        "validate": { "required": true }
      },
      {
        "type": "button",
        "key": "submit",
        "label": "Submit Application",
        "action": "submit"
      }
    ]
  }
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Form.io Form')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: FormioForm(
          schema: schemaJson,
          controller: _controller,
          onChange: (data) {
            print('Live Form Data: $data');
          },
          onSubmit: (submission) {
            print('Submission Payload: ${submission.toJson()}');
          },
        ),
      ),
    );
  }
}
```

---

## Submission Formats

`FormioSubmission` provides unambiguous handling for both raw form data dictionaries and Form.io REST envelope payloads:

```dart
// Raw form data map:
final Map<String, dynamic> rawData = controller.submissionData;

// Standard Form.io submission envelope:
final FormioSubmission submission = controller.getSubmission();
final Map<String, dynamic> envelope = submission.toJson();
/*
{
  "_id": "60a7e...",
  "state": "submitted",
  "data": {
    "fullName": "Alice Smith",
    "email": "alice@example.com"
  }
}
*/

// Incomplete draft export (does not block on validation errors):
final FormioSubmission draft = controller.exportDraft();
```

---

## Documentation Links

- [Compatibility Matrix (`COMPATIBILITY.md`)](COMPATIBILITY.md) — Comprehensive status of every component, property, logic rule, and wizard behavior.
- [Script Execution & Security Guide (`SCRIPT_EXECUTION.md`)](SCRIPT_EXECUTION.md) — JavaScript evaluation policies, JSON Logic engine, and sandboxed runtimes.
- [Custom Components & Adapters (`EXTENSIONS.md`)](EXTENSIONS.md) — Extending the registry with custom Flutter widgets, remote select adapters, and storage providers.

---

## Commands for Formatting, Static Analysis, and Testing

```bash
# 1. Format all package and example code
dart format lib test example/lib example/test

# 2. Run static analysis (0 warnings / 0 errors)
flutter analyze lib

# 3. Run all automated tests (34 unit & widget tests)
flutter test

# 4. Run the BUTODRA real-world enterprise wizard tests
flutter test test/unit/butodra_wizard_test.dart test/widget/butodra_wizard_widget_test.dart

# 5. Run the example app tests
cd example
flutter test

# 6. Launch the interactive showcase application
cd example
flutter run -d chrome # or android, ios, macos, windows, linux
```
