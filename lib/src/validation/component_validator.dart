import '../models/options/formio_options.dart';
import '../models/validation/validation_error.dart';
import '../state/component_state.dart';
import '../localization/formio_localizations.dart';
import '../logic/json_logic/json_logic_engine.dart';
import '../scripting/script_evaluator.dart';
import '../scripting/safe_script_evaluator.dart';

/// Pure Dart validation engine for Form.io components.
class FormioComponentValidator {
  final JsonLogicEngine jsonLogic = const JsonLogicEngine();

  const FormioComponentValidator();

  /// Validates a single component instance and returns any validation errors.
  List<FormioValidationError> validate({
    required FormioComponentState state,
    required dynamic value,
    required Map<String, dynamic> formData,
    required Map<String, dynamic> rowData,
    required FormioOptions options,
  }) {
    // Hidden or disabled components are never invalid in Form.io
    if (state.hidden || state.disabled) {
      return const [];
    }

    final errors = <FormioValidationError>[];
    final comp = state.schema;
    final rules = comp.validate;
    final loc = FormioLocalizations.forLocale(options.locale);
    final strings = loc.strings;
    final label = state.label.isNotEmpty ? state.label : comp.key;

    // Helper to format or use customMessage or errors[rule]
    String makeMsg(String defaultTemplate, Map<String, dynamic> params,
        {String? errorCode}) {
      if (errorCode != null && comp.rawJson['errors'] is Map) {
        final errMap = comp.rawJson['errors'] as Map;
        final customErrKey = errMap[errorCode]?.toString();
        if (customErrKey != null && customErrKey.isNotEmpty) {
          final translated = options.translate(customErrKey);
          return FormioLocalizations.format(
              translated, {'field': label, ...params});
        }
      }
      if (rules.customMessage != null &&
          rules.customMessage!.trim().isNotEmpty) {
        final translated = options.translate(rules.customMessage!);
        return FormioLocalizations.format(
            translated, {'field': label, ...params});
      }
      return FormioLocalizations.format(
          defaultTemplate, {'field': label, ...params});
    }

    // 1. Required Validation
    final isRequired = state.required || rules.required;
    final isEmpty = _isValueEmpty(value, comp.type);

    if (isRequired && isEmpty) {
      errors.add(
        FormioValidationError(
          componentKey: comp.key,
          dataPath: state.dataPath,
          message: makeMsg(strings.required, {}, errorCode: 'required'),
          errorCode: 'required',
          pageIndex: state.pageIndex,
        ),
      );
      // In Form.io, if a field is empty and required, usually required is the primary error
      return errors;
    }

    // If empty and not required, skip value-dependent validators
    if (isEmpty) {
      return errors;
    }

    // 2. Length Bounds
    if (value is String) {
      if (rules.minLength != null && value.length < rules.minLength!) {
        errors.add(
          FormioValidationError(
            componentKey: comp.key,
            dataPath: state.dataPath,
            message: makeMsg(strings.minLength, {'min': rules.minLength}),
            errorCode: 'minLength',
            pageIndex: state.pageIndex,
            params: {'min': rules.minLength, 'actual': value.length},
          ),
        );
      }
      if (rules.maxLength != null && value.length > rules.maxLength!) {
        errors.add(
          FormioValidationError(
            componentKey: comp.key,
            dataPath: state.dataPath,
            message: makeMsg(strings.maxLength, {'max': rules.maxLength}),
            errorCode: 'maxLength',
            pageIndex: state.pageIndex,
            params: {'max': rules.maxLength, 'actual': value.length},
          ),
        );
      }
    }

    // 3. Numeric Bounds
    if (value is num ||
        (comp.type == 'number' && num.tryParse(value.toString()) != null)) {
      final n = value is num ? value : num.parse(value.toString());
      if (rules.min != null && n < rules.min!) {
        errors.add(
          FormioValidationError(
            componentKey: comp.key,
            dataPath: state.dataPath,
            message: makeMsg(strings.min, {'min': rules.min}),
            errorCode: 'min',
            pageIndex: state.pageIndex,
            params: {'min': rules.min, 'actual': n},
          ),
        );
      }
      if (rules.max != null && n > rules.max!) {
        errors.add(
          FormioValidationError(
            componentKey: comp.key,
            dataPath: state.dataPath,
            message: makeMsg(strings.max, {'max': rules.max}),
            errorCode: 'max',
            pageIndex: state.pageIndex,
            params: {'max': rules.max, 'actual': n},
          ),
        );
      }
    }

    // 4. Pattern / Regex
    if (rules.pattern != null && rules.pattern!.isNotEmpty && value is String) {
      try {
        final reg = RegExp(rules.pattern!);
        if (!reg.hasMatch(value)) {
          errors.add(
            FormioValidationError(
              componentKey: comp.key,
              dataPath: state.dataPath,
              message: makeMsg(strings.pattern, {'pattern': rules.pattern}),
              errorCode: 'pattern',
              pageIndex: state.pageIndex,
            ),
          );
        }
      } catch (_) {
        // Invalid regex in schema ignored
      }
    }

    // 5. Format Validations (Email, URL, Phone)
    if (comp.type == 'email' && value is String && value.isNotEmpty) {
      final emailRegex = RegExp(
          r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$");
      if (!emailRegex.hasMatch(value)) {
        errors.add(
          FormioValidationError(
            componentKey: comp.key,
            dataPath: state.dataPath,
            message: makeMsg(strings.email, {}),
            errorCode: 'email',
            pageIndex: state.pageIndex,
          ),
        );
      }
    }

    if (comp.type == 'url' && value is String && value.isNotEmpty) {
      final uri = Uri.tryParse(value);
      final hasScheme =
          uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
      if (!hasScheme || uri.host.isEmpty) {
        errors.add(
          FormioValidationError(
            componentKey: comp.key,
            dataPath: state.dataPath,
            message: makeMsg(strings.url, {}),
            errorCode: 'url',
            pageIndex: state.pageIndex,
          ),
        );
      }
    }

    // 6. Selection Counts (SelectBoxes or Select multiple)
    if (comp.type == 'selectboxes' && value is Map) {
      final selectedCount = value.values.where((v) => v == true).length;
      if (rules.minSelectedCount != null &&
          selectedCount < rules.minSelectedCount!) {
        errors.add(
          FormioValidationError(
            componentKey: comp.key,
            dataPath: state.dataPath,
            message:
                makeMsg(strings.minSelected, {'min': rules.minSelectedCount}),
            errorCode: 'minSelectedCount',
            pageIndex: state.pageIndex,
          ),
        );
      }
      if (rules.maxSelectedCount != null &&
          selectedCount > rules.maxSelectedCount!) {
        errors.add(
          FormioValidationError(
            componentKey: comp.key,
            dataPath: state.dataPath,
            message:
                makeMsg(strings.maxSelected, {'max': rules.maxSelectedCount}),
            errorCode: 'maxSelectedCount',
            pageIndex: state.pageIndex,
          ),
        );
      }
    } else if (value is List) {
      // DataGrid / EditGrid row bounds or Multi-Select count
      if (rules.minRows != null && value.length < rules.minRows!) {
        errors.add(
          FormioValidationError(
            componentKey: comp.key,
            dataPath: state.dataPath,
            message: makeMsg(strings.minRows, {'min': rules.minRows}),
            errorCode: 'minRows',
            pageIndex: state.pageIndex,
          ),
        );
      }
      if (rules.maxRows != null && value.length > rules.maxRows!) {
        errors.add(
          FormioValidationError(
            componentKey: comp.key,
            dataPath: state.dataPath,
            message: makeMsg(strings.maxRows, {'max': rules.maxRows}),
            errorCode: 'maxRows',
            pageIndex: state.pageIndex,
          ),
        );
      }
      if (rules.minSelectedCount != null &&
          value.length < rules.minSelectedCount!) {
        errors.add(
          FormioValidationError(
            componentKey: comp.key,
            dataPath: state.dataPath,
            message:
                makeMsg(strings.minSelected, {'min': rules.minSelectedCount}),
            errorCode: 'minSelectedCount',
            pageIndex: state.pageIndex,
          ),
        );
      }
      if (rules.maxSelectedCount != null &&
          value.length > rules.maxSelectedCount!) {
        errors.add(
          FormioValidationError(
            componentKey: comp.key,
            dataPath: state.dataPath,
            message:
                makeMsg(strings.maxSelected, {'max': rules.maxSelectedCount}),
            errorCode: 'maxSelectedCount',
            pageIndex: state.pageIndex,
          ),
        );
      }
    }

    // 7. JSON Logic Validation (`validate.json`)
    if (rules.json != null) {
      final jsonCtx = {
        'input': value,
        'data': formData,
        'row': rowData,
      };
      final isValid = jsonLogic.evaluateCondition(rules.json, jsonCtx);
      if (!isValid) {
        errors.add(
          FormioValidationError(
            componentKey: comp.key,
            dataPath: state.dataPath,
            message: makeMsg(strings.invalidJsonLogic, {}),
            errorCode: 'jsonLogic',
            pageIndex: state.pageIndex,
          ),
        );
      }
    }

    // 8. Custom Script Validation (`validate.custom`)
    if (rules.custom != null && rules.custom!.isNotEmpty) {
      final evaluator = options.scriptEvaluator ?? const SafeScriptEvaluator();
      final scriptCtx = FormioScriptContext(
        data: formData,
        row: rowData,
        value: value,
        component: comp.rawJson,
        extra: {'input': value},
      );
      final res =
          evaluator.evaluateSync(script: rules.custom!, context: scriptCtx);
      if (!res.isSuccess) {
        if (options.strictMode) {
          errors.add(
            FormioValidationError(
              componentKey: comp.key,
              dataPath: state.dataPath,
              message: makeMsg(strings.invalidScript, {}),
              errorCode: 'customScriptFailed',
              pageIndex: state.pageIndex,
            ),
          );
        }
      } else if (res.value != true && res.value != null) {
        final msg = res.value is String
            ? options.translate(res.value as String)
            : makeMsg(strings.invalidScript, {});
        errors.add(
          FormioValidationError(
            componentKey: comp.key,
            dataPath: state.dataPath,
            message: msg,
            errorCode: 'customScript',
            pageIndex: state.pageIndex,
          ),
        );
      }
    }

    return errors;
  }

  static bool _isValueEmpty(dynamic value, String componentType) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is bool) {
      // In Form.io, a required checkbox must be explicitly true
      if (componentType == 'checkbox') return value == false;
      return false;
    }
    if (value is List) return value.isEmpty;
    if (value is Map) {
      if (componentType == 'selectboxes') {
        // True only if at least one checkbox is checked
        return !value.values.any((v) => v == true);
      }
      return value.isEmpty;
    }
    return false;
  }
}
