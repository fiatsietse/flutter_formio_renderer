import 'package:flutter/material.dart';
import '../state/component_state.dart';
import '../theme/formio_theme.dart';
import 'formio_form_scope.dart';

/// Wraps input fields with standard label, required asterisk, description,
/// tooltip icon, and validation error messages.
class FormioFieldWrapper extends StatelessWidget {
  final FormioComponentState state;
  final Widget child;
  final bool showLabel;

  const FormioFieldWrapper({
    super.key,
    required this.state,
    required this.child,
    this.showLabel = true,
  });

  /// Tells the form's state manager when focus leaves the input, so
  /// blur-time validation can run.
  Widget _withBlurReporting(BuildContext context, Widget input) {
    final manager = FormioFormScope.maybeOf(context);
    if (manager == null) return input;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (hasFocus) {
        if (!hasFocus) manager.blur(state);
      },
      child: input,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (state.hidden) {
      return const SizedBox.shrink();
    }

    final theme = FormioTheme.of(context);
    final comp = state.schema;
    final label = state.label;
    final isRequired = state.required;
    final hasErrors = state.hasErrors;
    final tooltipText = state.tooltip ?? comp.tooltip;
    final descriptionText = state.description ?? comp.description;

    return Padding(
      padding: EdgeInsets.only(bottom: theme.fieldSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel && label.isNotEmpty) ...[
            Row(
              children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      text: label,
                      style: theme.labelStyle ??
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                      children: [
                        if (isRequired)
                          TextSpan(
                            text: ' *',
                            style: TextStyle(
                              color: theme.errorColor ??
                                  Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (tooltipText != null && tooltipText.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: tooltipText,
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
          ],
          _withBlurReporting(context, child),
          if (descriptionText != null && descriptionText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              descriptionText,
              style: theme.descriptionStyle ??
                  Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
            ),
          ],
          if (hasErrors) ...[
            const SizedBox(height: 6),
            for (final err in state.errors)
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 14,
                      color: theme.errorColor ??
                          Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        err.message,
                        style: theme.errorStyle ??
                            TextStyle(
                              color: theme.errorColor ??
                                  Theme.of(context).colorScheme.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
