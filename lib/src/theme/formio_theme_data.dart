import 'package:flutter/material.dart';

/// Customizable visual styling for Form.io forms and wizards.
@immutable
class FormioThemeData {
  final Color? primaryColor;
  final Color? errorColor;
  final TextStyle? labelStyle;
  final TextStyle? descriptionStyle;
  final TextStyle? errorStyle;

  /// Flutter's decoration theme; its concrete type varies between SDK releases.
  final Object? inputDecorationTheme;
  final ButtonStyle? primaryButtonStyle;
  final ButtonStyle? secondaryButtonStyle;

  /// Flutter's card theme; its concrete type varies between SDK releases.
  final Object? cardTheme;
  final double fieldSpacing;
  final double sectionSpacing;

  const FormioThemeData({
    this.primaryColor,
    this.errorColor,
    this.labelStyle,
    this.descriptionStyle,
    this.errorStyle,
    this.inputDecorationTheme,
    this.primaryButtonStyle,
    this.secondaryButtonStyle,
    this.cardTheme,
    this.fieldSpacing = 16.0,
    this.sectionSpacing = 24.0,
  });

  /// Factory deriving defaults from Flutter [ThemeData].
  factory FormioThemeData.fromTheme(ThemeData theme) {
    return FormioThemeData(
      primaryColor: theme.colorScheme.primary,
      errorColor: theme.colorScheme.error,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
      descriptionStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      errorStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
        fontWeight: FontWeight.w500,
      ),
      inputDecorationTheme: theme.inputDecorationTheme,
      cardTheme: theme.cardTheme,
      fieldSpacing: 16.0,
      sectionSpacing: 24.0,
    );
  }
}
