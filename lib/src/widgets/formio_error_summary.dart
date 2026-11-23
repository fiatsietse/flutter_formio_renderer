import 'package:flutter/material.dart';
import '../models/validation/validation_error.dart';
import '../localization/formio_localizations.dart';

/// Accessible summary banner displaying all current validation failures.
class FormioErrorSummary extends StatelessWidget {
  final List<FormioValidationError> errors;
  final void Function(FormioValidationError error)? onErrorTap;
  final Locale? locale;

  const FormioErrorSummary({
    super.key,
    required this.errors,
    this.onErrorTap,
    this.locale,
  });

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final effectiveLocale = locale ?? Localizations.maybeLocaleOf(context);
    final strings = FormioLocalizations.forLocale(effectiveLocale).strings;

    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20.0),
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: theme.colorScheme.error, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.fixErrorsBeforeSubmitting,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final err in errors)
              InkWell(
                onTap: onErrorTap != null ? () => onErrorTap!(err) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Text('• ',
                          style: TextStyle(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          err.message,
                          style: TextStyle(
                              color: theme.colorScheme.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
