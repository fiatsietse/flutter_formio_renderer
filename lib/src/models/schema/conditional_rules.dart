import 'package:meta/meta.dart';

/// Form.io component conditional visibility definition.
@immutable
class FormioConditionalRules {
  /// Whether to show (true) or hide (false) the component when condition is met.
  final bool? show;

  /// The component key to observe.
  final String? when;

  /// The value that [when] component must equal.
  final dynamic eq;

  /// JSON Logic condition rule.
  final dynamic json;

  /// Custom JavaScript condition expression (e.g. `show = data.age >= 18;`).
  final String? custom;

  final Map<String, dynamic> raw;

  const FormioConditionalRules({
    this.show,
    this.when,
    this.eq,
    this.json,
    this.custom,
    this.raw = const {},
  });

  bool get hasSimpleCondition => when != null && when!.isNotEmpty;
  bool get hasJsonCondition => json != null;
  bool get hasCustomScript => custom != null && custom!.isNotEmpty;
  bool get isEmpty =>
      !hasSimpleCondition && !hasJsonCondition && !hasCustomScript;

  factory FormioConditionalRules.fromJson(Map<String, dynamic>? json,
      {String? customScript}) {
    if (json == null && customScript == null) {
      return const FormioConditionalRules();
    }
    final map = json ?? const <String, dynamic>{};
    return FormioConditionalRules(
      show: map['show'] is bool
          ? map['show'] as bool
          : (map['show'] != null
              ? map['show'].toString().toLowerCase() == 'true'
              : null),
      when: map['when']?.toString(),
      eq: map['eq'],
      json: map['json'],
      custom: customScript ?? map['custom']?.toString(),
      raw: Map<String, dynamic>.from(map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (show != null) 'show': show,
      if (when != null) 'when': when,
      if (eq != null) 'eq': eq,
      if (json != null) 'json': json,
      if (custom != null) 'custom': custom,
      ...raw,
    };
  }
}
