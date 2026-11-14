import 'package:meta/meta.dart';
import '../submission/data_path.dart';
import 'validation_error.dart';

/// Represents the aggregate result of a form validation pass.
@immutable
class FormioValidationResult {
  final List<FormioValidationError> errors;

  const FormioValidationResult({this.errors = const []});

  static const FormioValidationResult valid =
      FormioValidationResult(errors: []);

  bool get isValid => errors.isEmpty;
  bool get hasErrors => errors.isNotEmpty;

  /// Returns the first error, if any.
  FormioValidationError? get firstError => errors.isEmpty ? null : errors.first;

  /// Returns all errors for a specific data path.
  List<FormioValidationError> forPath(DataPath path) {
    return errors.where((e) => e.dataPath == path).toList();
  }

  /// Returns all errors for a specific component key.
  List<FormioValidationError> forKey(String key) {
    return errors.where((e) => e.componentKey == key).toList();
  }

  /// Returns all errors occurring on a specific wizard page.
  List<FormioValidationError> forPage(int page) {
    return errors.where((e) => e.pageIndex == page).toList();
  }

  @override
  String toString() => isValid
      ? 'Valid'
      : 'Invalid (${errors.length} errors: ${errors.map((e) => e.message).join(', ')})';
}
