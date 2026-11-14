import 'diagnostic_level.dart';

export 'diagnostic_level.dart';

/// Represents a structured diagnostic message emitted by schema parsing, logic engine,
/// script evaluation, or rendering.
class FormioDiagnostic {
  /// The severity of the diagnostic.
  final FormioDiagnosticLevel level;

  /// Short machine-readable code, e.g. 'UNSUPPORTED_COMPONENT', 'CYCLE_DETECTED', 'SCRIPT_EVALUATION_FAILED'.
  final String code;

  /// Human-readable explanation.
  final String message;

  /// The component key associated with this diagnostic, if applicable.
  final String? componentKey;

  /// The data path associated with this diagnostic, if applicable.
  final String? dataPath;

  /// Additional diagnostic metadata or stack details.
  final Map<String, dynamic> details;

  /// Timestamp when diagnostic was emitted.
  final DateTime timestamp;

  FormioDiagnostic({
    required this.level,
    required this.code,
    required this.message,
    this.componentKey,
    this.dataPath,
    this.details = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    final prefix = level.name.toUpperCase();
    final target = componentKey != null
        ? ' [$componentKey]'
        : (dataPath != null ? ' [$dataPath]' : '');
    return 'FormioDiagnostic.$prefix ($code)$target: $message';
  }
}
