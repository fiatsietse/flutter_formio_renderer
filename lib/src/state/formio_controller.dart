import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../models/submission/data_path.dart';
import '../models/submission/formio_submission.dart';
import '../models/validation/validation_result.dart';
import '../models/options/formio_options.dart';
import 'form_state_manager.dart';

/// Public controller to programmatically inspect, update, validate,
/// navigate, and submit Form.io forms.
class FormioController with ChangeNotifier {
  FormioStateManager? _manager;

  /// Internal attachment method invoked by [FormioForm].
  void attach(FormioStateManager manager) {
    _manager = manager;
    _manager!.addListener(notifyListeners);
  }

  /// Internal detachment method.
  void detach() {
    _manager?.removeListener(notifyListeners);
    _manager = null;
  }

  FormioStateManager get _requireManager {
    assert(_manager != null,
        'FormioController is not attached to any FormioForm widget yet.');
    return _manager!;
  }

  /// Reads current form submission data.
  Map<String, dynamic> get submissionData =>
      _requireManager.dataTree.exportData();

  /// Reads value for [keyOrPath] (e.g. 'firstName' or 'items[0].price').
  dynamic getValue(dynamic keyOrPath) {
    final path = keyOrPath is DataPath
        ? keyOrPath
        : DataPath.parse(keyOrPath.toString());
    return _requireManager.getValue(path);
  }

  /// Sets value at [keyOrPath] and executes reactive rules.
  void setValue(dynamic keyOrPath, dynamic value) {
    final path = keyOrPath is DataPath
        ? keyOrPath
        : DataPath.parse(keyOrPath.toString());
    _requireManager.setValue(path, value);
  }

  /// Batch updates multiple fields.
  void patchValues(Map<String, dynamic> values) {
    _requireManager.patchValues(values);
  }

  /// Executes validation.
  /// If [onlyCurrentPage] is true in wizard mode, validates only the current active step.
  FormioValidationResult validate({bool onlyCurrentPage = false}) {
    return _requireManager.validate(onlyCurrentPage: onlyCurrentPage);
  }

  /// Validates the whole form and, when valid, calls the form's `onSubmit`
  /// with the submission (or `onError` when invalid). Returns the result.
  FormioValidationResult submit() {
    return _requireManager.submit();
  }

  /// Resets the form to its initial default state.
  void reset() {
    _requireManager.reset();
  }

  /// Produces a finalized Form.io submission payload envelope.
  FormioSubmission getSubmission({bool isDraft = false}) {
    return _requireManager.exportSubmission(isDraft: isDraft);
  }

  /// Exports an incomplete draft submission without requiring validation.
  FormioSubmission exportDraft() {
    return _requireManager.exportSubmission(isDraft: true);
  }

  /// Maps backend or server-returned validation errors back onto form fields.
  void setServerErrors(Map<String, String> errors) {
    _requireManager.setServerErrors(errors);
  }

  /// Dynamically updates the form locale in real-time while preserving form data.
  void setLocale(Locale locale) {
    _requireManager
        .updateOptions(_requireManager.options.copyWith(locale: locale));
  }

  /// Dynamically updates runtime form options (e.g. locale, readOnly) while preserving form data.
  void updateOptions(FormioOptions options) {
    _requireManager.updateOptions(options);
  }

  // --- Wizard Navigation ---

  /// Current active wizard page index.
  int get currentPageIndex => _requireManager.currentPageIndex;

  /// Total number of wizard pages.
  int get pageCount => _requireManager.wizardPages.length;

  /// Whether current active page is the first visible page.
  bool get isFirstPage => _requireManager.isFirstVisiblePage;

  /// Whether current active page is the final visible page.
  bool get isLastPage => _requireManager.isLastVisiblePage;

  /// Advances to next wizard page after validating current page.
  bool nextPage() => _requireManager.nextPage();

  /// Navigates to previous wizard page.
  bool previousPage() => _requireManager.previousPage();

  /// Directly navigates to [pageIndex].
  bool goToPage(int pageIndex) => _requireManager.goToPage(pageIndex);

  @override
  void dispose() {
    detach();
    super.dispose();
  }
}
