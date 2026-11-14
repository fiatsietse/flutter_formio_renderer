import 'package:meta/meta.dart';
import '../submission/data_path.dart';

export 'validation_result.dart';

/// Represents a single validation failure on a component or data path.
@immutable
class FormioValidationError {
  /// The schema key of the invalid component.
  final String componentKey;

  /// The concrete submission data path of the invalid value.
  final DataPath dataPath;

  /// The localized error message shown to users.
  final String message;

  /// Error code, e.g. 'required', 'minLength', 'maxLength', 'min', 'max', 'pattern', 'custom', 'server'.
  final String errorCode;

  /// Optional wizard page index on which this error lives.
  final int? pageIndex;

  /// Additional parameters (e.g. min, max, pattern, current length).
  final Map<String, dynamic> params;

  const FormioValidationError({
    required this.componentKey,
    required this.dataPath,
    required this.message,
    required this.errorCode,
    this.pageIndex,
    this.params = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormioValidationError &&
          runtimeType == other.runtimeType &&
          componentKey == other.componentKey &&
          dataPath == other.dataPath &&
          errorCode == other.errorCode;

  @override
  int get hashCode =>
      componentKey.hashCode ^ dataPath.hashCode ^ errorCode.hashCode;

  @override
  String toString() =>
      'FormioValidationError($componentKey at $dataPath: $message [$errorCode])';
}
