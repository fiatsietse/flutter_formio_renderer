import 'package:meta/meta.dart';

/// Context provided to a script evaluator during execution.
@immutable
class FormioScriptContext {
  /// Root submission data map.
  final Map<String, dynamic> data;

  /// Row-level data if inside a DataGrid/EditGrid, or same as [data] at root.
  final Map<String, dynamic> row;

  /// Current component value before evaluation.
  final dynamic value;

  /// Schema definition of the component.
  final Map<String, dynamic> component;

  /// Row index if inside a DataGrid or EditGrid, otherwise null.
  final int? rowIndex;

  /// Additional environment parameters or variables.
  final Map<String, dynamic> extra;

  const FormioScriptContext({
    required this.data,
    required this.row,
    this.value,
    this.component = const {},
    this.rowIndex,
    this.extra = const {},
  });

  /// Converts context to a map suitable for JS engines or sandboxed interpreters.
  Map<String, dynamic> toMap() {
    return {
      'data': data,
      'row': row,
      'value': value,
      'component': component,
      if (rowIndex != null) 'rowIndex': rowIndex,
      ...extra,
    };
  }
}

/// Result of evaluating a custom script.
@immutable
class FormioScriptResult {
  /// The evaluated return value or assigned value.
  final dynamic value;

  /// Whether the script completed successfully.
  final bool isSuccess;

  /// Error message if evaluation failed or script was rejected.
  final String? error;

  /// Execution duration, if measured.
  final Duration? duration;

  const FormioScriptResult.success(this.value, {this.duration})
      : isSuccess = true,
        error = null;

  const FormioScriptResult.failure(this.error, {this.duration})
      : isSuccess = false,
        value = null;

  @override
  String toString() => isSuccess ? 'Success($value)' : 'Failure($error)';
}

/// Interface for evaluating schema-provided JavaScript expressions.
///
/// Implementations must enforce sandboxing, resource limits (timeouts),
/// and isolation to prevent malicious code execution.
abstract class FormioScriptEvaluator {
  /// Evaluates an expression or script snippet within the provided [context].
  Future<FormioScriptResult> evaluate({
    required String script,
    required FormioScriptContext context,
    Duration timeout = const Duration(milliseconds: 500),
  });

  /// Synchronous evaluation for simple expressions where supported.
  FormioScriptResult evaluateSync({
    required String script,
    required FormioScriptContext context,
  });

  /// Human-readable name of the evaluator engine (e.g. 'Disabled', 'QuickJS', 'WebView').
  String get engineName;

  /// Whether this evaluator is active and executing JavaScript.
  bool get isEnabled;
}
