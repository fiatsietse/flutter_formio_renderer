import 'dart:convert';
import 'package:meta/meta.dart';
import 'component_schema.dart';

/// Represents a parsed Form.io form or wizard schema.
@immutable
class FormioFormSchema {
  /// Display mode: 'form' (standard) or 'wizard' (multi-step).
  final String display;

  /// Optional form title.
  final String? title;

  /// Machine name or identifier.
  final String? name;

  /// Optional endpoint or URL path.
  final String? path;

  /// Top-level components in this schema.
  final List<FormioComponentSchema> components;

  /// Unaltered source JSON map.
  final Map<String, dynamic> rawJson;

  const FormioFormSchema({
    this.display = 'form',
    this.title,
    this.name,
    this.path,
    required this.components,
    this.rawJson = const {},
  });

  /// True if this schema is configured as a multi-step wizard.
  bool get isWizard => display.toLowerCase() == 'wizard';

  /// Parses a form schema from either a Dart `Map<String, dynamic>` or a JSON string.
  factory FormioFormSchema.parse(dynamic input) {
    Map<String, dynamic> map;
    if (input is String) {
      final decoded = jsonDecode(input);
      if (decoded is! Map) {
        throw FormatException(
            'Form.io schema must be a JSON object, got ${decoded.runtimeType}');
      }
      map = Map<String, dynamic>.from(decoded);
    } else if (input is Map) {
      map = Map<String, dynamic>.from(input);
    } else {
      throw ArgumentError(
          'Expected String or Map for FormioFormSchema, got ${input.runtimeType}');
    }

    final display = map['display']?.toString().toLowerCase() ?? 'form';
    final title = map['title']?.toString();
    final name = map['name']?.toString();
    final path = map['path']?.toString();

    final comps = <FormioComponentSchema>[];
    if (map['components'] is List) {
      for (final c in map['components'] as List) {
        if (c is Map) {
          comps.add(
              FormioComponentSchema.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }

    return FormioFormSchema(
      display: display,
      title: title,
      name: name,
      path: path,
      components: List.unmodifiable(comps),
      rawJson: Map<String, dynamic>.unmodifiable(map),
    );
  }

  /// In Form.io wizards, top-level components of type 'panel' represent wizard pages.
  /// If top-level components are not panels, each top-level component is treated as a page.
  List<FormioComponentSchema> get wizardPages {
    if (!isWizard) return components;
    final panels = components.where((c) => c.type == 'panel').toList();
    if (panels.isNotEmpty) {
      return panels;
    }
    // Fallback: treat each top-level component as a page
    return components;
  }

  /// Finds a component by its schema key anywhere in the component hierarchy.
  FormioComponentSchema? findComponentByKey(String key) {
    return _findInList(components, key);
  }

  static FormioComponentSchema? _findInList(
      List<FormioComponentSchema> list, String key) {
    for (final c in list) {
      if (c.key == key) return c;
      if (c.components.isNotEmpty) {
        final found = _findInList(c.components, key);
        if (found != null) return found;
      }
      for (final col in c.columns) {
        final found = _findInList(col.components, key);
        if (found != null) return found;
      }
      for (final row in c.tableRows) {
        for (final cell in row) {
          final found = _findInList(cell, key);
          if (found != null) return found;
        }
      }
    }
    return null;
  }

  /// Traverses the entire component tree and invokes [visitor] for each component.
  void traverse(
      void Function(FormioComponentSchema component,
              List<FormioComponentSchema> parents)
          visitor) {
    void visit(
        FormioComponentSchema comp, List<FormioComponentSchema> parents) {
      visitor(comp, parents);
      final nextParents = [...parents, comp];
      for (final child in comp.components) {
        visit(child, nextParents);
      }
      for (final col in comp.columns) {
        for (final child in col.components) {
          visit(child, nextParents);
        }
      }
      for (final row in comp.tableRows) {
        for (final cell in row) {
          for (final child in cell) {
            visit(child, nextParents);
          }
        }
      }
    }

    for (final comp in components) {
      visit(comp, const []);
    }
  }

  Map<String, dynamic> toJson() => rawJson;

  @override
  String toString() =>
      'FormioFormSchema(display: $display, components: ${components.length})';
}
