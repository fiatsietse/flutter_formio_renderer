import 'package:meta/meta.dart';
import 'validation_rules.dart';
import 'conditional_rules.dart';
import 'logic_rule.dart';
import 'select_option.dart';

/// Represents a parsed Form.io component schema.
///
/// Preserves unrecognized properties in [rawJson] to support future extensions
/// and custom component configurations.
@immutable
class FormioComponentSchema {
  /// The component type identifier, e.g. 'textfield', 'number', 'panel', 'datagrid'.
  final String type;

  /// The unique schema key within its scope.
  final String key;

  /// Display label.
  final String label;

  /// Optional input placeholder.
  final String? placeholder;

  /// Optional input description (displayed below field).
  final String? description;

  /// Optional tooltip (displayed via info icon or hover).
  final String? tooltip;

  /// Optional prefix icon or text.
  final String? prefix;

  /// Optional suffix icon or text.
  final String? suffix;

  /// Static default value.
  final dynamic defaultValue;

  /// Custom default value (script or JSON Logic).
  final dynamic customDefaultValue;

  /// Calculated value expression (script or JSON Logic).
  final dynamic calculateValue;

  /// Static hidden flag.
  final bool hidden;

  /// Clear value when hidden. If null, inherits from [FormioOptions.clearOnHide].
  final bool? clearOnHide;

  /// Disabled state.
  final bool disabled;

  /// Whether the field accepts multiple values (stored as array).
  final bool multiple;

  /// Whether the field is protected (passwords, tokens).
  final bool protected;

  /// Persistence mode: true, false, or 'client-only'.
  final dynamic persistent;

  /// Custom CSS class.
  final String? customClass;

  /// Custom key-value properties.
  final Map<String, dynamic> properties;

  /// Validation rules.
  final FormioValidationRules validate;

  /// Conditional visibility rules.
  final FormioConditionalRules conditional;

  /// Custom conditional script.
  final String? customConditional;

  /// Reactive logic rules.
  final List<FormioLogicRule> logic;

  /// Nested child components (for panels, containers, tabs, fieldsets, datagrids).
  final List<FormioComponentSchema> components;

  /// For columns component: each item contains a list of child components and layout settings.
  final List<FormioColumnDefinition> columns;

  /// For table component: rows of table cells (each cell is a list of components).
  final List<List<List<FormioComponentSchema>>> tableRows;

  /// For select, radio, selectboxes: static selectable options.
  final List<SelectOption> options;

  /// Complete un-altered schema map.
  final Map<String, dynamic> rawJson;

  const FormioComponentSchema({
    required this.type,
    required this.key,
    this.label = '',
    this.placeholder,
    this.description,
    this.tooltip,
    this.prefix,
    this.suffix,
    this.defaultValue,
    this.customDefaultValue,
    this.calculateValue,
    this.hidden = false,
    this.clearOnHide,
    this.disabled = false,
    this.multiple = false,
    this.protected = false,
    this.persistent = true,
    this.customClass,
    this.properties = const {},
    this.validate = const FormioValidationRules(),
    this.conditional = const FormioConditionalRules(),
    this.customConditional,
    this.logic = const [],
    this.components = const [],
    this.columns = const [],
    this.tableRows = const [],
    this.options = const [],
    this.rawJson = const {},
  });

  /// True if this component represents a layout-only container that does NOT nest submission data.
  bool get isLayoutComponent {
    return const {
      'panel',
      'fieldset',
      'columns',
      'table',
      'tabs',
      'well',
    }.contains(type.toLowerCase());
  }

  /// True if this component creates a nested map in the submission data tree.
  bool get isDataContainer => type.toLowerCase() == 'container';

  /// True if this component creates a repeating array of maps in the submission data tree.
  bool get isRepeatingGroup =>
      const {'datagrid', 'editgrid'}.contains(type.toLowerCase());

  /// True if this component is display-only and does not store submission data.
  bool get isDisplayOnly => const {
        'content',
        'htmlelement',
        'button',
      }.contains(type.toLowerCase());

  /// Parses a component schema from JSON.
  factory FormioComponentSchema.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString().toLowerCase() ?? 'textfield';
    final key = json['key']?.toString() ??
        'field_${DateTime.now().microsecondsSinceEpoch}';
    final label = json['label']?.toString() ?? '';

    // Child components
    final childComponents = <FormioComponentSchema>[];
    if (json['components'] is List) {
      for (final c in json['components'] as List) {
        if (c is Map) {
          childComponents.add(
              FormioComponentSchema.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }

    // Columns
    final cols = <FormioColumnDefinition>[];
    if (json['columns'] is List) {
      for (final c in json['columns'] as List) {
        if (c is Map) {
          cols.add(
              FormioColumnDefinition.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }

    // Table rows
    final table = <List<List<FormioComponentSchema>>>[];
    if (json['rows'] is List) {
      for (final row in json['rows'] as List) {
        final rowCells = <List<FormioComponentSchema>>[];
        if (row is List) {
          for (final cell in row) {
            final cellComponents = <FormioComponentSchema>[];
            if (cell is Map && cell['components'] is List) {
              for (final c in cell['components'] as List) {
                if (c is Map) {
                  cellComponents.add(FormioComponentSchema.fromJson(
                      Map<String, dynamic>.from(c)));
                }
              }
            }
            rowCells.add(cellComponents);
          }
        }
        table.add(rowCells);
      }
    }

    // Options for select, radio, selectboxes
    final options = <SelectOption>[];
    if (json['values'] is List) {
      for (final opt in json['values'] as List) {
        options.add(SelectOption.fromJson(opt));
      }
    } else if (json['data'] is Map && json['data']['values'] is List) {
      for (final opt in json['data']['values'] as List) {
        options.add(SelectOption.fromJson(opt));
      }
    }

    // Logic rules
    final logicRules = <FormioLogicRule>[];
    if (json['logic'] is List) {
      for (final l in json['logic'] as List) {
        if (l is Map) {
          logicRules
              .add(FormioLogicRule.fromJson(Map<String, dynamic>.from(l)));
        }
      }
    }

    return FormioComponentSchema(
      type: type,
      key: key,
      label: label,
      placeholder: json['placeholder']?.toString(),
      description: json['description']?.toString(),
      tooltip: json['tooltip']?.toString(),
      prefix: json['prefix']?.toString(),
      suffix: json['suffix']?.toString(),
      defaultValue: json['defaultValue'],
      customDefaultValue: json['customDefaultValue'],
      calculateValue: json['calculateValue'],
      hidden: json['hidden'] == true,
      clearOnHide: json.containsKey('clearOnHide')
          ? (json['clearOnHide'] == true)
          : null,
      disabled: json['disabled'] == true,
      multiple: json['multiple'] == true,
      protected: json['protected'] == true,
      persistent: json['persistent'] ?? true,
      customClass: json['customClass']?.toString(),
      properties: json['properties'] is Map
          ? Map<String, dynamic>.from(json['properties'] as Map)
          : const {},
      validate: FormioValidationRules.fromJson(json['validate'] is Map
          ? Map<String, dynamic>.from(json['validate'] as Map)
          : null),
      conditional: FormioConditionalRules.fromJson(
        json['conditional'] is Map
            ? Map<String, dynamic>.from(json['conditional'] as Map)
            : null,
        customScript: json['customConditional']?.toString(),
      ),
      customConditional: json['customConditional']?.toString(),
      logic: logicRules,
      components: childComponents,
      columns: cols,
      tableRows: table,
      options: options,
      rawJson: Map<String, dynamic>.unmodifiable(json),
    );
  }

  Map<String, dynamic> toJson() => rawJson;

  @override
  String toString() => 'FormioComponentSchema($type, key: $key)';
}

/// Column definition for Form.io Columns component.
@immutable
class FormioColumnDefinition {
  final int width;
  final int offset;
  final int push;
  final int pull;
  final List<FormioComponentSchema> components;
  final Map<String, dynamic> raw;

  const FormioColumnDefinition({
    this.width = 6,
    this.offset = 0,
    this.push = 0,
    this.pull = 0,
    this.components = const [],
    this.raw = const {},
  });

  factory FormioColumnDefinition.fromJson(Map<String, dynamic> json) {
    final comps = <FormioComponentSchema>[];
    if (json['components'] is List) {
      for (final c in json['components'] as List) {
        if (c is Map) {
          comps.add(
              FormioComponentSchema.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }
    return FormioColumnDefinition(
      width: (json['width'] as num?)?.toInt() ?? 6,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      push: (json['push'] as num?)?.toInt() ?? 0,
      pull: (json['pull'] as num?)?.toInt() ?? 0,
      components: comps,
      raw: Map<String, dynamic>.from(json),
    );
  }
}
