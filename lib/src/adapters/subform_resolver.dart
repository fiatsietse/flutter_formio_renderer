import 'dart:async';
import '../models/schema/form_schema.dart';

/// Pluggable interface to resolve nested subform schemas by form ID or URL.
abstract class FormioSubformResolver {
  /// Resolves the child [FormioFormSchema] given a subform ID, key, or path.
  Future<FormioFormSchema?> resolveSubform(String formIdOrPath);
}

/// Static map-based subform resolver useful for tests and example apps.
class MapSubformResolver implements FormioSubformResolver {
  final Map<String, FormioFormSchema> schemas;

  MapSubformResolver(this.schemas);

  @override
  Future<FormioFormSchema?> resolveSubform(String formIdOrPath) async {
    return schemas[formIdOrPath];
  }
}
