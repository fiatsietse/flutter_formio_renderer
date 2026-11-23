import 'package:flutter/material.dart';
import '../models/schema/form_schema.dart';
import '../models/schema/component_schema.dart';
import '../models/submission/formio_submission.dart';
import '../models/validation/validation_result.dart';
import '../state/form_state_manager.dart';
import '../registry/component_renderer_builder.dart';
import '../registry/component_registry.dart';
import '../localization/formio_localizations.dart';
import 'formio_error_summary.dart';

/// Wizard multi-step form navigation and step presentation widget.
class FormioWizard extends StatelessWidget {
  final FormioFormSchema schema;
  final FormioStateManager manager;
  final FormioComponentRegistry registry;
  final void Function(FormioSubmission submission)? onSubmit;
  final void Function(int pageIndex)? onPageChange;
  final void Function(FormioValidationResult result)? onError;

  const FormioWizard({
    super.key,
    required this.schema,
    required this.manager,
    required this.registry,
    this.onSubmit,
    this.onPageChange,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    final pages = manager.wizardPages;
    final visiblePages = manager.visibleWizardPages;
    final strings =
        FormioLocalizations.forLocale(manager.options.locale).strings;

    if (visiblePages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'All wizard pages are conditionally hidden.',
            style: TextStyle(
                fontStyle: FontStyle.italic, color: Colors.grey.shade600),
          ),
        ),
      );
    }

    final currentPageIndex = manager.currentPageIndex;
    final currentPage =
        (currentPageIndex >= 0 && currentPageIndex < pages.length)
            ? pages[currentPageIndex]
            : visiblePages.first;

    final isFirst = manager.isFirstVisiblePage;
    final isLast = manager.isLastVisiblePage;

    // Current page validation errors
    final pageErrors = manager.componentStates.values
        .where((s) => s.pageIndex == currentPageIndex && s.hasErrors)
        .expand((s) => s.errors)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Step Indicator Bar
        _buildStepIndicator(context, visiblePages, currentPage),
        const SizedBox(height: 16),

        // 2. Error Summary Banner (if errors present on current page)
        if (pageErrors.isNotEmpty)
          FormioErrorSummary(
            errors: pageErrors,
            locale: manager.options.locale,
          ),

        // 3. Current Active Page Components
        _buildPageContent(context, currentPage),
        const SizedBox(height: 24),

        // 4. Wizard Navigation Actions (Previous, Next, Submit)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (!isFirst)
              OutlinedButton.icon(
                onPressed: () {
                  final success = manager.previousPage();
                  if (success) {
                    onPageChange?.call(manager.currentPageIndex);
                  }
                },
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(strings.previous),
              )
            else
              const SizedBox.shrink(),
            if (!isLast)
              ElevatedButton.icon(
                onPressed: () {
                  final success = manager.nextPage();
                  if (success) {
                    onPageChange?.call(manager.currentPageIndex);
                  } else {
                    final res = manager.validate(onlyCurrentPage: true);
                    onError?.call(res);
                  }
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(strings.next),
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: manager.isSubmitting
                    ? null
                    : () {
                        final res = manager.validate(onlyCurrentPage: false);
                        if (res.isValid) {
                          manager.setSubmitting(true);
                          final sub = manager.exportSubmission(isDraft: false);
                          onSubmit?.call(sub);
                          manager.setSubmitting(false);
                        } else {
                          onError?.call(res);
                        }
                      },
                icon: manager.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check, size: 18),
                label: Text(strings.submit),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepIndicator(
    BuildContext context,
    List<FormioComponentSchema> visiblePages,
    FormioComponentSchema currentPage,
  ) {
    final theme = Theme.of(context);
    final items = <Widget>[];

    for (var i = 0; i < visiblePages.length; i++) {
      final page = visiblePages[i];
      final isCurrent = page.key == currentPage.key;
      final isPast =
          visiblePages.indexWhere((p) => p.key == currentPage.key) > i;
      final rawTitle = page.rawJson['title']?.toString() ?? page.label;
      final pageTitle = manager.translate(rawTitle);
      final labelText = pageTitle.isNotEmpty ? pageTitle : 'Step ${i + 1}';

      items.add(
        InkWell(
          onTap: () {
            final targetIdx =
                schema.wizardPages.indexWhere((p) => p.key == page.key);
            if (targetIdx != -1) {
              final ok = manager.goToPage(targetIdx);
              if (ok) onPageChange?.call(targetIdx);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isCurrent
                    ? theme.colorScheme.primary
                    : (isPast ? Colors.green.shade600 : Colors.grey.shade300),
                child: isPast
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isCurrent
                              ? theme.colorScheme.onPrimary
                              : Colors.grey.shade700,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Text(
                labelText,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent
                      ? theme.colorScheme.primary
                      : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      );

      if (i < visiblePages.length - 1) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Container(
              width: 24,
              height: 2,
              color: isPast ? Colors.green.shade600 : Colors.grey.shade300,
            ),
          ),
        );
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: items),
    );
  }

  Widget _buildPageContent(BuildContext context, FormioComponentSchema page) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final child in page.components) _renderWizardChild(context, child),
      ],
    );
  }

  Widget _renderWizardChild(BuildContext context, FormioComponentSchema child) {
    final state = manager.getState(child.key);
    if (state == null || state.hidden) return const SizedBox.shrink();

    final childCtx = FormioRenderContext(
      context: context,
      state: state,
      manager: manager,
    );
    final builder = registry.get(child.type);
    return builder(childCtx);
  }
}
