import 'package:meta/meta.dart';
import 'conditional_rules.dart';

/// Form.io Logic Rule Trigger definition.
@immutable
class FormioLogicTrigger {
  /// Trigger type: 'simple', 'javascript', 'json', or 'event'.
  final String type;

  /// Simple trigger condition.
  final FormioConditionalRules? simple;

  /// Custom JavaScript condition expression.
  final String? javascript;

  /// JSON Logic condition rule.
  final dynamic json;

  /// Event name for event-driven triggers.
  final String? event;

  final Map<String, dynamic> raw;

  const FormioLogicTrigger({
    required this.type,
    this.simple,
    this.javascript,
    this.json,
    this.event,
    this.raw = const {},
  });

  factory FormioLogicTrigger.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString().toLowerCase() ?? 'simple';
    return FormioLogicTrigger(
      type: type,
      simple: json['simple'] is Map
          ? FormioConditionalRules.fromJson(
              json['simple'] as Map<String, dynamic>)
          : null,
      javascript: json['javascript']?.toString(),
      json: json['json'],
      event: json['event']?.toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }
}

/// Form.io Logic Rule Action definition.
@immutable
class FormioLogicAction {
  final String name;

  /// Action type: 'property', 'value', 'customAction', or 'mergeComponentSchema'.
  final String type;

  /// Property configuration for 'property' type actions.
  final FormioActionProperty? property;

  /// Target boolean/string state for property actions (e.g. true for required, false for disabled).
  final dynamic state;

  /// Value or expression for 'value' type actions.
  final dynamic value;

  /// Custom script for 'customAction'.
  final String? custom;

  /// Component schema map to merge for 'mergeComponentSchema'.
  final Map<String, dynamic>? schema;

  final Map<String, dynamic> raw;

  const FormioLogicAction({
    required this.name,
    required this.type,
    this.property,
    this.state,
    this.value,
    this.custom,
    this.schema,
    this.raw = const {},
  });

  factory FormioLogicAction.fromJson(Map<String, dynamic> json) {
    return FormioLogicAction(
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'property',
      property: json['property'] is Map
          ? FormioActionProperty.fromJson(
              json['property'] as Map<String, dynamic>)
          : null,
      state: json['state'],
      value: json['value'],
      custom: json['custom']?.toString(),
      schema: json['schema'] is Map
          ? Map<String, dynamic>.from(json['schema'] as Map)
          : null,
      raw: Map<String, dynamic>.from(json),
    );
  }
}

/// Property details for a property-changing action.
@immutable
class FormioActionProperty {
  final String label;

  /// The property identifier, e.g. 'validate.required', 'disabled', 'hidden', 'label', 'title'.
  final String value;

  /// Expected type, e.g. 'boolean', 'string'.
  final String type;

  const FormioActionProperty({
    required this.label,
    required this.value,
    required this.type,
  });

  factory FormioActionProperty.fromJson(Map<String, dynamic> json) {
    return FormioActionProperty(
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      type: json['type']?.toString() ?? 'boolean',
    );
  }
}

/// Complete Form.io Logic Rule definition.
@immutable
class FormioLogicRule {
  final String name;
  final FormioLogicTrigger trigger;
  final List<FormioLogicAction> actions;
  final Map<String, dynamic> raw;

  const FormioLogicRule({
    required this.name,
    required this.trigger,
    required this.actions,
    this.raw = const {},
  });

  factory FormioLogicRule.fromJson(Map<String, dynamic> json) {
    final actionsList = <FormioLogicAction>[];
    if (json['actions'] is List) {
      for (final a in json['actions'] as List) {
        if (a is Map) {
          actionsList
              .add(FormioLogicAction.fromJson(Map<String, dynamic>.from(a)));
        }
      }
    }
    return FormioLogicRule(
      name: json['name']?.toString() ?? '',
      trigger: json['trigger'] is Map
          ? FormioLogicTrigger.fromJson(
              Map<String, dynamic>.from(json['trigger'] as Map))
          : const FormioLogicTrigger(type: 'simple'),
      actions: actionsList,
      raw: Map<String, dynamic>.from(json),
    );
  }
}
