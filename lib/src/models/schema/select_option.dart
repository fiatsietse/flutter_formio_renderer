import 'package:meta/meta.dart';

/// Represents a selectable option in Select, Radio, or SelectBoxes components.
@immutable
class SelectOption {
  /// The user-facing display text.
  final String label;

  /// The underlying stored value.
  final dynamic value;

  /// Optional disabled state for this specific option.
  final bool disabled;

  /// Optional raw JSON or extra metadata.
  final Map<String, dynamic> raw;

  const SelectOption({
    required this.label,
    required this.value,
    this.disabled = false,
    this.raw = const {},
  });

  factory SelectOption.fromJson(dynamic json) {
    if (json is Map) {
      final label = json['label']?.toString() ??
          json['name']?.toString() ??
          json['value']?.toString() ??
          '';
      final value = json.containsKey('value')
          ? json['value']
          : (json['id'] ?? json['key'] ?? label);
      return SelectOption(
        label: label,
        value: value,
        disabled: json['disabled'] == true,
        raw: Map<String, dynamic>.from(json),
      );
    } else if (json != null) {
      final str = json.toString();
      return SelectOption(label: str, value: json);
    } else {
      return const SelectOption(label: '', value: '');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      if (disabled) 'disabled': true,
      ...raw,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectOption &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'SelectOption($label: $value)';
}
