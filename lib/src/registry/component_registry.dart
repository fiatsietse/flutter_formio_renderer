import 'component_renderer_builder.dart';
import '../widgets/formio_unsupported_widget.dart';

/// Registry mapping Form.io component type strings (e.g. 'textfield', 'panel')
/// to their corresponding native Flutter widget builders.
class FormioComponentRegistry {
  final Map<String, FormioComponentBuilder> _builders = {};

  FormioComponentRegistry();

  /// Registers or overrides a builder for [type].
  void register(String type, FormioComponentBuilder builder) {
    _builders[type.toLowerCase()] = builder;
  }

  /// Removes registration for [type].
  void unregister(String type) {
    _builders.remove(type.toLowerCase());
  }

  /// Checks if [type] has a registered builder.
  bool has(String type) => _builders.containsKey(type.toLowerCase());

  /// Retrieves the builder for [type], or fallback unsupported placeholder.
  FormioComponentBuilder get(String type) {
    final key = type.toLowerCase();
    if (_builders.containsKey(key)) {
      return _builders[key]!;
    }
    return (ctx) => FormioUnsupportedWidget(
          type: type,
          keyName: ctx.state.schema.key,
          dataPath: ctx.state.dataPath.toDotString(),
        );
  }

  /// Copies this registry for custom scoped overrides.
  FormioComponentRegistry copy() {
    final reg = FormioComponentRegistry();
    reg._builders.addAll(_builders);
    return reg;
  }

  /// Shared default registry instance.
  static final FormioComponentRegistry defaultRegistry =
      FormioComponentRegistry();
}
