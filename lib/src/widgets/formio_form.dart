import 'package:flutter/material.dart';
import '../models/schema/form_schema.dart';
import '../models/schema/component_schema.dart';
import '../models/submission/formio_submission.dart';
import '../models/options/formio_options.dart';
import '../models/validation/validation_result.dart';
import '../models/validation/validation_error.dart';
import '../state/form_state_manager.dart';
import '../state/formio_controller.dart';
import '../registry/component_registry.dart';
import '../registry/component_renderer_builder.dart';
import '../theme/formio_theme.dart';
import '../theme/formio_theme_data.dart';
import '../components/default_components.dart';
import 'formio_wizard.dart';
import 'formio_error_summary.dart';
import 'formio_form_scope.dart';

/// Top-level widget that renders a Form.io JSON schema as native Flutter widgets.
///
/// Supports reactive conditional logic, calculated values, validation,
/// repeating groups (DataGrid / EditGrid), and multi-step wizard navigation.
class FormioForm extends StatefulWidget {
  /// The Form.io schema: either a parsed [FormioFormSchema], a Dart [Map], or a JSON [String].
  final dynamic schema;

  /// Optional controller to programmatically inspect, update, validate, or submit the form.
  final FormioController? controller;

  /// Initial submission data to prefill existing entries.
  final Map<String, dynamic>? initialData;

  /// Whether the entire form is rendered in read-only mode.
  final bool readOnly;

  /// Configuration and compatibility policies.
  final FormioOptions options;

  /// Custom theme and visual overrides.
  final FormioThemeData? theme;

  /// Component registry for custom or overridden component renderers.
  final FormioComponentRegistry? registry;

  /// Invoked whenever form values change.
  final void Function(Map<String, dynamic> data)? onChange;

  /// Invoked on final validated form submission.
  final void Function(FormioSubmission submission)? onSubmit;

  /// Invoked when navigating wizard pages.
  final void Function(int pageIndex)? onPageChange;

  /// Invoked when validation errors occur.
  final void Function(FormioValidationResult result)? onError;

  /// Invoked when a component triggers a custom event.
  final void Function(String event, dynamic payload)? onCustomEvent;

  const FormioForm({
    super.key,
    required this.schema,
    this.controller,
    this.initialData,
    this.readOnly = false,
    this.options = FormioOptions.defaults,
    this.theme,
    this.registry,
    this.onChange,
    this.onSubmit,
    this.onPageChange,
    this.onError,
    this.onCustomEvent,
  });

  @override
  State<FormioForm> createState() => _FormioFormState();
}

class _FormioFormState extends State<FormioForm> {
  late FormioFormSchema _parsedSchema;
  late FormioStateManager _manager;
  late FormioComponentRegistry _registry;

  @override
  void initState() {
    super.initState();
    _initForm();
  }

  void _initForm() {
    // 1. Ensure default components are registered
    registerDefaultComponents();

    _registry = widget.registry ?? FormioComponentRegistry.defaultRegistry;

    // 2. Parse schema
    if (widget.schema is FormioFormSchema) {
      _parsedSchema = widget.schema as FormioFormSchema;
    } else {
      _parsedSchema = FormioFormSchema.parse(widget.schema);
    }

    // 3. Configure options with readOnly
    final effectiveOptions = widget.options.copyWith(readOnly: widget.readOnly);

    // 4. Initialize state manager
    _manager = FormioStateManager(
      schema: _parsedSchema,
      options: effectiveOptions,
      initialData: widget.initialData,
    );

    _wireCallbacks();

    // 5. Attach controller if provided
    widget.controller?.attach(_manager);

    // 6. Listen for changes
    _manager.addListener(_handleStateChange);
  }

  /// Routes submit buttons inside the schema (via [FormioStateManager.submit])
  /// to this widget's [FormioForm.onSubmit] and [FormioForm.onError].
  void _wireCallbacks() {
    _manager.onSubmit = widget.onSubmit;
    _manager.onError = widget.onError;
  }

  void _handleStateChange() {
    widget.onChange?.call(_manager.dataTree.exportData());
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant FormioForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schema != widget.schema ||
        oldWidget.initialData != widget.initialData) {
      _manager.removeListener(_handleStateChange);
      oldWidget.controller?.detach();
      _initForm();
    } else {
      _wireCallbacks();
      if (oldWidget.options != widget.options ||
          oldWidget.readOnly != widget.readOnly) {
        final effectiveOptions =
            widget.options.copyWith(readOnly: widget.readOnly);
        _manager.updateOptions(effectiveOptions);
      }
    }
  }

  @override
  void dispose() {
    _manager.removeListener(_handleStateChange);
    widget.controller?.detach();
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTheme =
        widget.theme ?? FormioThemeData.fromTheme(Theme.of(context));

    Widget content;
    if (_parsedSchema.isWizard) {
      content = FormioWizard(
        schema: _parsedSchema,
        manager: _manager,
        registry: _registry,
        onSubmit: widget.onSubmit,
        onPageChange: widget.onPageChange,
        onError: (res) {
          widget.onError?.call(res);
        },
      );
    } else {
      content = _buildStandardForm(context);
    }

    return FormioTheme(
      data: effectiveTheme,
      child: FormioFormScope(manager: _manager, child: content),
    );
  }

  Widget _buildStandardForm(BuildContext context) {
    final allErrors = _manager.componentStates.values
        .where((s) => s.hasErrors)
        .expand((s) => s.errors)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (allErrors.isNotEmpty)
          FormioErrorSummary(
            errors: allErrors,
            locale: _manager.options.locale,
            onErrorTap: (err) {
              // Focus or scroll to field if possible
            },
          ),
        for (final comp in _parsedSchema.components)
          _renderComponent(context, comp),
      ],
    );
  }

  Widget _renderComponent(BuildContext context, dynamic compSchema) {
    final comp = compSchema is FormioComponentSchema
        ? compSchema
        : FormioComponentSchema.fromJson(
            Map<String, dynamic>.from(compSchema as Map));

    final state = _manager.getState(comp.key);
    if (state == null || state.hidden) {
      return const SizedBox.shrink();
    }

    final renderCtx = FormioRenderContext(
      context: context,
      state: state,
      manager: _manager,
    );

    final builder = _registry.get(comp.type);
    return builder(renderCtx);
  }
}
