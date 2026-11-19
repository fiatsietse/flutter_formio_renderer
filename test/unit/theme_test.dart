import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_formio_renderer/flutter_formio_renderer.dart';

void main() {
  test('FormioThemeData preserves theme data across Flutter versions', () {
    final theme = ThemeData();
    final formioTheme = FormioThemeData.fromTheme(theme);

    expect(formioTheme.inputDecorationTheme, same(theme.inputDecorationTheme));
    expect(formioTheme.cardTheme, same(theme.cardTheme));
  });
}
