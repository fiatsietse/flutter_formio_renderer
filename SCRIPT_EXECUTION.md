# Script Evaluation and JavaScript Compatibility Guide

Existing Form.io form definitions often include JavaScript expressions in properties such as `calculateValue`, `customConditional`, or `validate.custom`. This document outlines the security architecture, default execution policies, and integration options for executing scripts with `flutter_formio_renderer`.

---

## 1. Security-by-Default Architecture

In compliance with mobile and enterprise security standards, **arbitrary JavaScript execution is disabled by default**:

```dart
// Default configuration uses DisabledScriptEvaluator
const options = FormioOptions(
  scriptEvaluator: DisabledScriptEvaluator(),
);
```

### Why?
1. **Security & Sandboxing**: Untrusted schemas loaded from third-party servers could attempt prototype pollution, infinite loops, or unauthorized memory access.
2. **Deterministic Cross-Platform Performance**: Running a full JavaScript runtime on every keypress introduces heavy memory and CPU overhead on low-end mobile devices.
3. **No Native Webview Dependency**: Flutter forms render cleanly without requiring platform-specific webviews or JNI/Objective-C bridges.

---

## 2. Recommended Alternative: Pure Dart JSON Logic

Form.io natively supports [JSON Logic](https://jsonlogic.com/) for conditionals, calculated values, and validation rules. `flutter_formio_renderer` includes a high-performance, pure Dart implementation of JSON Logic:

```json
{
  "type": "number",
  "key": "lineTotal",
  "label": "Line Total",
  "calculateValue": {
    "*": [
      { "var": "row.quantity" },
      { "var": "row.unitPrice" }
    ]
  }
}
```

This runs with **zero isolation risk**, executes in microseconds, and requires no external JavaScript runtime.

---

## 3. The `FormioScriptEvaluator` Interface

When host applications require legacy JavaScript execution, they can implement the pluggable `FormioScriptEvaluator` interface:

```dart
abstract class FormioScriptEvaluator {
  /// Evaluates an expression or script within the provided context.
  Future<FormioScriptResult> evaluate({
    required String script,
    required FormioScriptContext context,
    Duration timeout = const Duration(milliseconds: 500),
  });

  /// Synchronous evaluation for simple expressions.
  FormioScriptResult evaluateSync({
    required String script,
    required FormioScriptContext context,
  });

  String get engineName;
  bool get isEnabled;
}
```

### Execution Context Contract
The following variables are injected into the execution context:

| Variable | Type | Description |
|---|---|---|
| `data` | `Map<String, dynamic>` | The root submission data dictionary. |
| `row` | `Map<String, dynamic>` | The current row data dictionary (if inside a DataGrid/EditGrid). |
| `value` | `dynamic` | The current field value before execution. |
| `component` | `Map<String, dynamic>` | The raw schema definition of the component. |
| `rowIndex` | `int?` | The row index if inside a repeating grid. |
| `input` | `dynamic` | Alias for `value` during validation passes. |

---

## 4. Attaching a Sandboxed Engine (e.g., QuickJS or Flutter JS)

To connect an embedded engine (such as QuickJS via FFI or a headless JS context):

```dart
class QuickJsEvaluator implements FormioScriptEvaluator {
  @override
  String get engineName => 'QuickJS Sandboxed Engine';

  @override
  bool get isEnabled => true;

  @override
  FormioScriptResult evaluateSync({
    required String script,
    required FormioScriptContext context,
  }) {
    // 1. Create isolated QuickJS runtime
    // 2. Inject context: data, row, value, component
    // 3. Set memory limit and instruction quota (e.g. 50ms)
    // 4. Return evaluated result:
    return const FormioScriptResult.success(42);
  }

  @override
  Future<FormioScriptResult> evaluate({
    required String script,
    required FormioScriptContext context,
    Duration timeout = const Duration(milliseconds: 500),
  }) async {
    return evaluateSync(script: script, context: context);
  }
}
```

Then supply it to `FormioOptions`:

```dart
FormioForm(
  schema: mySchema,
  options: FormioOptions(
    scriptEvaluator: QuickJsEvaluator(),
  ),
);
```

---

## 5. Strict Mode & Failure Policies

If a schema includes a JavaScript rule and no evaluator is configured (or the evaluator encounters an error/timeout):

- **Default (Permissive) Mode**: Emits a structured `FormioDiagnostic` warning with code `SCRIPT_EVALUATION_FAILED`. The evaluation falls back safely without crashing.
- **Strict Mode (`strictMode: true`)**: The validation rule fails with an error (`errorCode: customScriptFailed`) and **blocks submission**. Unsupported required behavior will never silently succeed.
