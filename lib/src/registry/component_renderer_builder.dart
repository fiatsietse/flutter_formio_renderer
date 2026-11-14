import 'package:flutter/widgets.dart';
import '../state/component_state.dart';
import '../state/form_state_manager.dart';

/// Context provided to a component renderer when building native Flutter widgets.
@immutable
class FormioRenderContext {
  final BuildContext context;
  final FormioComponentState state;
  final FormioStateManager manager;

  const FormioRenderContext({
    required this.context,
    required this.state,
    required this.manager,
  });

  /// Reads current value for this component instance.
  dynamic get value => manager.getValue(state.dataPath);

  /// Sets current value for this component instance.
  void setValue(dynamic val) => manager.setValue(state.dataPath, val);
}

/// Function signature for building a native Flutter widget from component schema and state.
typedef FormioComponentBuilder = Widget Function(FormioRenderContext context);
