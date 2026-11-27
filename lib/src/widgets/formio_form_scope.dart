import 'package:flutter/widgets.dart';
import '../state/form_state_manager.dart';

/// Makes the [FormioStateManager] of the enclosing form available to
/// descendant widgets, such as [FormioFieldWrapper] reporting focus loss.
class FormioFormScope extends InheritedWidget {
  final FormioStateManager manager;

  const FormioFormScope({
    super.key,
    required this.manager,
    required super.child,
  });

  /// The manager of the nearest enclosing form, or null outside a form.
  static FormioStateManager? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FormioFormScope>()
        ?.manager;
  }

  @override
  bool updateShouldNotify(FormioFormScope oldWidget) =>
      manager != oldWidget.manager;
}
