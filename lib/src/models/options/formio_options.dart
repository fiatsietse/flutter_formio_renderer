import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../diagnostics/formio_diagnostic.dart';
import '../../scripting/script_evaluator.dart';
import '../../adapters/remote_options_adapter.dart';
import '../../adapters/file_storage_adapter.dart';
import '../../adapters/subform_resolver.dart';

/// Validation timing policy.
enum ValidationTiming {
  /// Validate immediately on every value change.
  onChange,

  /// Validate when a field loses focus.
  onBlur,

  /// Validate only when transitioning wizard steps or submitting.
  onStep,

  /// Validate only when submitting the entire form.
  onSubmit,
}

/// Compatibility and behavioral options for Form.io rendering and evaluation.
@immutable
class FormioOptions {
  /// Whether to clear field values when the component is hidden by conditional logic.
  ///
  /// In Form.io JavaScript reference renderer (v4.x), this is `true` by default
  /// unless `clearOnHide: false` is set on the individual component schema.
  final bool clearOnHide;

  /// In strict mode, any unsupported required components, cyclic logic, or failed script
  /// evaluations will mark the form invalid and block submission.
  final bool strictMode;

  /// When validation should be executed.
  final ValidationTiming validationTiming;

  /// Maximum iterations allowed in the reactive logic engine before reporting a cycle.
  final int maxLogicIterations;

  /// Pluggable script evaluator for custom JavaScript expressions.
  ///
  /// Defaults to [DisabledScriptEvaluator] for zero security risk and pure native speed.
  final FormioScriptEvaluator? scriptEvaluator;

  /// Pluggable remote options adapter for Select components loaded via URL.
  final FormioRemoteOptionsAdapter? remoteOptionsAdapter;

  /// Pluggable file storage provider for File components.
  final FormioFileStorageAdapter? fileStorageAdapter;

  /// Pluggable subform schema resolver for Nested Form components.
  final FormioSubformResolver? subformResolver;

  /// Optional active locale for translation and date/number formatting.
  final Locale? locale;

  /// Optional custom i18n translation dictionary, organized by language code (e.g. `{'fr': {'key': 'val'}}`).
  final Map<String, dynamic>? i18n;

  /// Whether the whole form should be rendered in read-only mode.
  final bool readOnly;

  /// Whether draft export is allowed without passing full validation.
  final bool allowDraftExport;

  /// Diagnostic event handler. Receives warnings, cycle alerts, and unsupported component notes.
  final void Function(FormioDiagnostic diagnostic)? onDiagnostic;

  const FormioOptions({
    this.clearOnHide = true,
    this.strictMode = false,
    this.validationTiming = ValidationTiming.onChange,
    this.maxLogicIterations = 10,
    this.scriptEvaluator,
    this.remoteOptionsAdapter,
    this.fileStorageAdapter,
    this.subformResolver,
    this.locale,
    this.i18n,
    this.readOnly = false,
    this.allowDraftExport = true,
    this.onDiagnostic,
  });

  /// Translates [key] using [locale] across [i18n] and schema-level [schemaI18n].
  String translate(String key,
      {Map<String, dynamic>? schemaI18n, String? defaultText}) {
    final lang = locale?.languageCode ?? 'en';

    // 1. Check options i18n dictionary
    if (i18n != null && i18n![lang] is Map) {
      final langMap = i18n![lang] as Map;
      if (langMap.containsKey(key)) {
        return langMap[key]?.toString() ?? (defaultText ?? key);
      }
    }

    // 2. Check schema-level i18n dictionary
    if (schemaI18n != null && schemaI18n[lang] is Map) {
      final langMap = schemaI18n[lang] as Map;
      if (langMap.containsKey(key)) {
        return langMap[key]?.toString() ?? (defaultText ?? key);
      }
    }

    return defaultText ?? key;
  }

  /// Default options matching standard Form.io 4.19.x client defaults.
  static const FormioOptions defaults = FormioOptions();

  FormioOptions copyWith({
    bool? clearOnHide,
    bool? strictMode,
    ValidationTiming? validationTiming,
    int? maxLogicIterations,
    FormioScriptEvaluator? scriptEvaluator,
    FormioRemoteOptionsAdapter? remoteOptionsAdapter,
    FormioFileStorageAdapter? fileStorageAdapter,
    FormioSubformResolver? subformResolver,
    Locale? locale,
    Map<String, dynamic>? i18n,
    bool? readOnly,
    bool? allowDraftExport,
    void Function(FormioDiagnostic diagnostic)? onDiagnostic,
  }) {
    return FormioOptions(
      clearOnHide: clearOnHide ?? this.clearOnHide,
      strictMode: strictMode ?? this.strictMode,
      validationTiming: validationTiming ?? this.validationTiming,
      maxLogicIterations: maxLogicIterations ?? this.maxLogicIterations,
      scriptEvaluator: scriptEvaluator ?? this.scriptEvaluator,
      remoteOptionsAdapter: remoteOptionsAdapter ?? this.remoteOptionsAdapter,
      fileStorageAdapter: fileStorageAdapter ?? this.fileStorageAdapter,
      subformResolver: subformResolver ?? this.subformResolver,
      locale: locale ?? this.locale,
      i18n: i18n ?? this.i18n,
      readOnly: readOnly ?? this.readOnly,
      allowDraftExport: allowDraftExport ?? this.allowDraftExport,
      onDiagnostic: onDiagnostic ?? this.onDiagnostic,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FormioOptions &&
        other.clearOnHide == clearOnHide &&
        other.strictMode == strictMode &&
        other.validationTiming == validationTiming &&
        other.maxLogicIterations == maxLogicIterations &&
        other.scriptEvaluator == scriptEvaluator &&
        other.remoteOptionsAdapter == remoteOptionsAdapter &&
        other.fileStorageAdapter == fileStorageAdapter &&
        other.subformResolver == subformResolver &&
        other.locale == locale &&
        mapEquals(other.i18n, i18n) &&
        other.readOnly == readOnly &&
        other.allowDraftExport == allowDraftExport;
  }

  @override
  int get hashCode => Object.hash(
        clearOnHide,
        strictMode,
        validationTiming,
        maxLogicIterations,
        scriptEvaluator,
        remoteOptionsAdapter,
        fileStorageAdapter,
        subformResolver,
        locale,
        readOnly,
        allowDraftExport,
      );
}
