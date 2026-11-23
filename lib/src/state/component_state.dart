import 'package:flutter/foundation.dart';
import '../models/schema/component_schema.dart';
import '../models/submission/data_path.dart';
import '../models/validation/validation_error.dart';

/// Runtime dynamic state for a single component instance.
///
/// Keeps the source schema immutable while allowing conditional logic,
/// calculated values, and server errors to modify runtime attributes.
class FormioComponentState with ChangeNotifier {
  /// The static schema definition.
  final FormioComponentSchema schema;

  /// The concrete submission data path for this instance (e.g. `items[0].qty`).
  final DataPath dataPath;

  /// Unique stable runtime instance identity.
  final String instanceId;

  /// Optional wizard page index on which this component is placed.
  final int pageIndex;

  /// Current dynamic visibility.
  bool _hidden;

  /// Current dynamic disabled state.
  bool _disabled;

  /// Current dynamic required state.
  bool _required;

  /// Dynamic display label (can be overridden by logic rules).
  String _label;

  /// Dynamic description text.
  String? _description;

  /// Dynamic tooltip text.
  String? _tooltip;

  /// Validation errors currently attached to this component instance.
  List<FormioValidationError> _errors = const [];

  /// Whether this field has been touched or blurred by the user.
  bool _isTouched = false;

  /// Whether async validation is in flight.
  bool _isAsyncValidating = false;

  FormioComponentState({
    required this.schema,
    required this.dataPath,
    required this.instanceId,
    this.pageIndex = 0,
  })  : _hidden = schema.hidden,
        _disabled = schema.disabled,
        _required = schema.validate.required,
        _label = schema.label,
        _description = schema.description,
        _tooltip = schema.tooltip;

  bool get hidden => _hidden;
  bool get disabled => _disabled;
  bool get required => _required;
  String get label => _label;
  String? get description => _description;
  String? get tooltip => _tooltip;
  List<FormioValidationError> get errors => _errors;
  bool get hasErrors => _errors.isNotEmpty;
  bool get isTouched => _isTouched;
  bool get isAsyncValidating => _isAsyncValidating;

  /// Updates visibility flag. Returns true if changed.
  bool setHidden(bool value) {
    if (_hidden == value) return false;
    _hidden = value;
    notifyListeners();
    return true;
  }

  /// Updates disabled flag. Returns true if changed.
  bool setDisabled(bool value) {
    if (_disabled == value) return false;
    _disabled = value;
    notifyListeners();
    return true;
  }

  /// Updates required flag. Returns true if changed.
  bool setRequired(bool value) {
    if (_required == value) return false;
    _required = value;
    notifyListeners();
    return true;
  }

  /// Updates label. Returns true if changed.
  bool setLabel(String value) {
    if (_label == value) return false;
    _label = value;
    notifyListeners();
    return true;
  }

  /// Updates description. Returns true if changed.
  bool setDescription(String? value) {
    if (_description == value) return false;
    _description = value;
    notifyListeners();
    return true;
  }

  /// Updates tooltip. Returns true if changed.
  bool setTooltip(String? value) {
    if (_tooltip == value) return false;
    _tooltip = value;
    notifyListeners();
    return true;
  }

  /// Sets validation errors.
  void setErrors(List<FormioValidationError> errors) {
    _errors = List.unmodifiable(errors);
    notifyListeners();
  }

  /// Clears validation errors.
  void clearErrors() {
    if (_errors.isNotEmpty) {
      _errors = const [];
      notifyListeners();
    }
  }

  void markTouched() {
    if (!_isTouched) {
      _isTouched = true;
      notifyListeners();
    }
  }

  void setAsyncValidating(bool validating) {
    if (_isAsyncValidating != validating) {
      _isAsyncValidating = validating;
      notifyListeners();
    }
  }

  /// Resets state to schema initial values.
  void reset() {
    _hidden = schema.hidden;
    _disabled = schema.disabled;
    _required = schema.validate.required;
    _label = schema.label;
    _errors = const [];
    _isTouched = false;
    _isAsyncValidating = false;
    notifyListeners();
  }
}
