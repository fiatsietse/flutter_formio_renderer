import 'package:meta/meta.dart';

/// Form.io component validation rules definition.
@immutable
class FormioValidationRules {
  final bool required;
  final int? minLength;
  final int? maxLength;
  final num? min;
  final num? max;
  final int? minWords;
  final int? maxWords;
  final String? pattern;
  final String? customMessage;
  final String? custom; // Custom JS expression
  final dynamic json; // JSON Logic rule
  final int? minSelectedCount;
  final int? maxSelectedCount;
  final int? minRows;
  final int? maxRows;
  final Map<String, dynamic> raw;

  const FormioValidationRules({
    this.required = false,
    this.minLength,
    this.maxLength,
    this.min,
    this.max,
    this.minWords,
    this.maxWords,
    this.pattern,
    this.customMessage,
    this.custom,
    this.json,
    this.minSelectedCount,
    this.maxSelectedCount,
    this.minRows,
    this.maxRows,
    this.raw = const {},
  });

  factory FormioValidationRules.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FormioValidationRules();
    return FormioValidationRules(
      required: json['required'] == true,
      minLength: (json['minLength'] as num?)?.toInt(),
      maxLength: (json['maxLength'] as num?)?.toInt(),
      min: json['min'] as num?,
      max: json['max'] as num?,
      minWords: (json['minWords'] as num?)?.toInt(),
      maxWords: (json['maxWords'] as num?)?.toInt(),
      pattern: json['pattern']?.toString(),
      customMessage: json['customMessage']?.toString(),
      custom: json['custom']?.toString(),
      json: json['json'],
      minSelectedCount: (json['minSelectedCount'] as num?)?.toInt(),
      maxSelectedCount: (json['maxSelectedCount'] as num?)?.toInt(),
      minRows: (json['minRows'] as num?)?.toInt(),
      maxRows: (json['maxRows'] as num?)?.toInt(),
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (required) 'required': true,
      if (minLength != null) 'minLength': minLength,
      if (maxLength != null) 'maxLength': maxLength,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      if (minWords != null) 'minWords': minWords,
      if (maxWords != null) 'maxWords': maxWords,
      if (pattern != null) 'pattern': pattern,
      if (customMessage != null) 'customMessage': customMessage,
      if (custom != null) 'custom': custom,
      if (json != null) 'json': json,
      if (minSelectedCount != null) 'minSelectedCount': minSelectedCount,
      if (maxSelectedCount != null) 'maxSelectedCount': maxSelectedCount,
      if (minRows != null) 'minRows': minRows,
      if (maxRows != null) 'maxRows': maxRows,
      ...raw,
    };
  }

  FormioValidationRules copyWith({
    bool? required,
    int? minLength,
    int? maxLength,
    num? min,
    num? max,
    int? minWords,
    int? maxWords,
    String? pattern,
    String? customMessage,
    String? custom,
    dynamic json,
    int? minSelectedCount,
    int? maxSelectedCount,
    int? minRows,
    int? maxRows,
  }) {
    return FormioValidationRules(
      required: required ?? this.required,
      minLength: minLength ?? this.minLength,
      maxLength: maxLength ?? this.maxLength,
      min: min ?? this.min,
      max: max ?? this.max,
      minWords: minWords ?? this.minWords,
      maxWords: maxWords ?? this.maxWords,
      pattern: pattern ?? this.pattern,
      customMessage: customMessage ?? this.customMessage,
      custom: custom ?? this.custom,
      json: json ?? this.json,
      minSelectedCount: minSelectedCount ?? this.minSelectedCount,
      maxSelectedCount: maxSelectedCount ?? this.maxSelectedCount,
      minRows: minRows ?? this.minRows,
      maxRows: maxRows ?? this.maxRows,
      raw: raw,
    );
  }
}
