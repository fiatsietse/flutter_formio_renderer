import 'package:flutter/material.dart';
import 'formio_theme_data.dart';

/// InheritedWidget providing [FormioThemeData] down the widget tree.
class FormioTheme extends InheritedWidget {
  final FormioThemeData data;

  const FormioTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static FormioThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<FormioTheme>();
    if (theme != null) return theme.data;
    return FormioThemeData.fromTheme(Theme.of(context));
  }

  @override
  bool updateShouldNotify(FormioTheme oldWidget) => data != oldWidget.data;
}
