import 'package:flutter/foundation.dart';
import '../models/schema/form_schema.dart';
import '../models/schema/component_schema.dart';
import '../models/submission/data_path.dart';
import '../models/submission/formio_submission.dart';
import '../models/options/formio_options.dart';
import '../models/validation/validation_error.dart';
import '../logic/reactive_engine.dart';
import '../logic/dependency_graph.dart';
import '../validation/component_validator.dart';
import 'component_state.dart';
import 'data_tree.dart';

/// Central state manager orchestrating form data, component states,
/// reactive logic, validation, and wizard navigation.
class FormioStateManager with ChangeNotifier {
  final FormioFormSchema schema;
  final FormioOptions options;
  final FormioDataTree dataTree;
  final Map<String, FormioComponentState> componentStates = {};
  final FormioComponentValidator validator = const FormioComponentValidator();

  late final FormioDependencyGraph dependencyGraph;
  late final FormioReactiveEngine reactiveEngine;

  // Wizard state
  int _currentPageIndex = 0;
  List<FormioComponentSchema> _wizardPages = const [];

  // Form submission lifecycle state
  bool _isSubmitting = false;

  FormioStateManager({
    required this.schema,
    FormioOptions options = FormioOptions.defaults,
    Map<String, dynamic>? initialData,
  })  : options = _resolveOptions(schema, options),
        dataTree = FormioDataTree(initialData) {
    dependencyGraph = FormioDependencyGraph.fromSchema(schema);
    reactiveEngine = FormioReactiveEngine(
      schema: schema,
      options: this.options,
      dataTree: dataTree,
      componentStates: componentStates,
      dependencyGraph: dependencyGraph,
    );

    _initializeComponentStates();
    _applyDefaults(initialData == null || initialData.isEmpty);
    reactiveEngine.evaluateAll();

    if (schema.isWizard) {
      _wizardPages = schema.wizardPages;
      _adjustCurrentPageIfHidden();
    }
  }

  static FormioOptions _resolveOptions(
      FormioFormSchema schema, FormioOptions opts) {
    if (schema.rawJson['i18n'] is! Map) return opts;
    final schemaI18n = Map<String, dynamic>.from(schema.rawJson['i18n'] as Map);
    if (opts.i18n == null) {
      return opts.copyWith(i18n: schemaI18n);
    }
    final merged = Map<String, dynamic>.from(schemaI18n);
    merged.addAll(opts.i18n!);
    return opts.copyWith(i18n: merged);
  }

  int get currentPageIndex => _currentPageIndex;
  List<FormioComponentSchema> get wizardPages => _wizardPages;
  bool get isSubmitting => _isSubmitting;

  /// Visible wizard pages (excluding conditionally hidden pages).
  List<FormioComponentSchema> get visibleWizardPages {
    if (!schema.isWizard) return _wizardPages;
    return _wizardPages.where((p) {
      final state = componentStates[p.key];
      return state == null || !state.hidden;
    }).toList();
  }

  bool get isFirstVisiblePage {
    final visible = visibleWizardPages;
    if (visible.isEmpty) return true;
    return visible.first.key == _wizardPages[_currentPageIndex].key;
  }

  bool get isLastVisiblePage {
    final visible = visibleWizardPages;
    if (visible.isEmpty) return true;
    return visible.last.key == _wizardPages[_currentPageIndex].key;
  }

  /// Translates [key] using form options and schema i18n dictionaries.
  String translate(String key, {String? defaultText}) {
    final schemaI18n = schema.rawJson['i18n'] is Map
        ? Map<String, dynamic>.from(schema.rawJson['i18n'] as Map)
        : null;
    return options.translate(key,
        schemaI18n: schemaI18n, defaultText: defaultText);
  }

  /// Retrieves runtime state for a component by key or path.
  FormioComponentState? getState(String key) => componentStates[key];

  /// Reads current value at [path].
  dynamic getValue(DataPath path) => dataTree.getValue(path);

  /// Sets value at [path] and triggers reactive re-evaluation.
  void setValue(DataPath path, dynamic value) {
    final changed = dataTree.setValue(path, value);
    if (changed) {
      reactiveEngine.evaluateAll();
      if (schema.isWizard) {
        _adjustCurrentPageIfHidden();
      }
      if (options.validationTiming == ValidationTiming.onChange) {
        validate(onlyCurrentPage: schema.isWizard);
      }
      notifyListeners();
    }
  }

  /// Bulk updates multiple values.
  void patchValues(Map<String, dynamic> values) {
    for (final entry in values.entries) {
      final path = DataPath.parse(entry.key);
      dataTree.setValue(path, entry.value);
    }
    reactiveEngine.evaluateAll();
    if (schema.isWizard) {
      _adjustCurrentPageIfHidden();
    }
    notifyListeners();
  }

  /// Resets form to initial default values.
  void reset() {
    dataTree.rawData.clear();
    for (final state in componentStates.values) {
      state.reset();
    }
    _applyDefaults(true);
    reactiveEngine.evaluateAll();
    _currentPageIndex = 0;
    notifyListeners();
  }

  /// Adds a new row to a DataGrid or EditGrid.
  void addGridRow(DataPath gridPath, FormioComponentSchema gridComp) {
    var list = dataTree.getValue(gridPath);
    if (list is! List) {
      list = <dynamic>[];
      dataTree.setValue(gridPath, list);
    }
    final newRowIndex = list.length;
    final rowData = <String, dynamic>{};

    // Apply defaults for row columns
    for (final col in gridComp.components) {
      if (col.defaultValue != null) {
        rowData[col.key] = col.defaultValue;
      }
    }
    list.add(rowData);

    // Register component states for this row
    final rowPath = gridPath.child(newRowIndex);
    for (final col in gridComp.components) {
      final colPath = rowPath.child(col.key);
      final instanceId = '${gridComp.key}:$newRowIndex:${col.key}';
      final state = FormioComponentState(
        schema: col,
        dataPath: colPath,
        instanceId: instanceId,
        pageIndex: _currentPageIndex,
      );
      componentStates[instanceId] = state;
    }

    reactiveEngine.evaluateAll();
    notifyListeners();
  }

  /// Removes a row at [rowIndex] from DataGrid or EditGrid.
  void removeGridRow(
      DataPath gridPath, int rowIndex, FormioComponentSchema gridComp) {
    final list = dataTree.getValue(gridPath);
    if (list is List && rowIndex >= 0 && rowIndex < list.length) {
      list.removeAt(rowIndex);

      // Re-index component states for this grid
      componentStates.removeWhere((k, _) => k.startsWith('${gridComp.key}:'));
      for (var r = 0; r < list.length; r++) {
        final rowPath = gridPath.child(r);
        for (final col in gridComp.components) {
          final colPath = rowPath.child(col.key);
          final instanceId = '${gridComp.key}:$r:${col.key}';
          final state = FormioComponentState(
            schema: col,
            dataPath: colPath,
            instanceId: instanceId,
            pageIndex: _currentPageIndex,
          );
          componentStates[instanceId] = state;
        }
      }

      reactiveEngine.evaluateAll();
      notifyListeners();
    }
  }

  /// Validates the form.
  /// If [onlyCurrentPage] is true, checks only components on [currentPageIndex].
  FormioValidationResult validate({bool onlyCurrentPage = false}) {
    final allErrors = <FormioValidationError>[];

    for (final state in componentStates.values) {
      if (onlyCurrentPage && state.pageIndex != _currentPageIndex) {
        continue;
      }
      if (state.schema.isDisplayOnly || state.schema.isLayoutComponent) {
        continue;
      }

      final val = dataTree.getValue(state.dataPath);
      final rowData = _resolveRowData(state.dataPath);
      final errors = validator.validate(
        state: state,
        value: val,
        formData: dataTree.rawData,
        rowData: rowData,
        options: options,
      );
      state.setErrors(errors);
      allErrors.addAll(errors);
    }

    return FormioValidationResult(errors: allErrors);
  }

  /// Maps server-returned errors back to fields.
  void setServerErrors(Map<String, String> errors) {
    for (final entry in errors.entries) {
      final key = entry.key;
      final msg = entry.value;

      final state = componentStates[key] ??
          componentStates.values.firstWhere(
            (s) => s.dataPath.toDotString() == key || s.schema.key == key,
            orElse: () => componentStates.values.first,
          );

      state.setErrors([
        FormioValidationError(
          componentKey: state.schema.key,
          dataPath: state.dataPath,
          message: msg,
          errorCode: 'server',
          pageIndex: state.pageIndex,
        ),
      ]);
    }
    notifyListeners();
  }

  /// Advances to the next visible wizard page after validating current page.
  bool nextPage() {
    if (!schema.isWizard) return false;

    // Validate current page first
    final result = validate(onlyCurrentPage: true);
    if (result.hasErrors) {
      notifyListeners();
      return false;
    }

    final nextIdx = _findNextVisiblePageIndex(_currentPageIndex);
    if (nextIdx != null) {
      _currentPageIndex = nextIdx;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Navigates to the previous visible wizard page (without validation barriers).
  bool previousPage() {
    if (!schema.isWizard) return false;

    final prevIdx = _findPreviousVisiblePageIndex(_currentPageIndex);
    if (prevIdx != null) {
      _currentPageIndex = prevIdx;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Directly navigates to [pageIndex] if within bounds.
  bool goToPage(int pageIndex) {
    if (!schema.isWizard) return false;
    if (pageIndex < 0 || pageIndex >= _wizardPages.length) return false;

    // Validate if navigating forward
    if (pageIndex > _currentPageIndex) {
      final res = validate(onlyCurrentPage: true);
      if (res.hasErrors) return false;
    }

    _currentPageIndex = pageIndex;
    _adjustCurrentPageIfHidden();
    notifyListeners();
    return true;
  }

  /// Exports current data as an envelope or raw draft.
  FormioSubmission exportSubmission({bool isDraft = false}) {
    return FormioSubmission(
      data: dataTree.exportData(),
      state: isDraft ? 'draft' : 'submitted',
      formId: schema.rawJson['_id']?.toString() ?? schema.name,
    );
  }

  /// Marks submission start/end for progress spinners and duplicate-submit prevention.
  void setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  void _initializeComponentStates() {
    componentStates.clear();

    void visit(
        FormioComponentSchema comp, DataPath currentPath, int pageIndex) {
      final isLayout = comp.isLayoutComponent;
      final isContainer = comp.isDataContainer;
      final isRepeating = comp.isRepeatingGroup;

      DataPath childPath;
      if (isLayout) {
        childPath = currentPath; // Layout does not nest data
      } else if (isContainer) {
        childPath = currentPath.child(comp.key);
      } else if (isRepeating) {
        childPath = currentPath.child(comp.key);
      } else {
        childPath = currentPath.child(comp.key);
      }

      final instanceId = comp.key;
      final state = FormioComponentState(
        schema: comp,
        dataPath: childPath,
        instanceId: instanceId,
        pageIndex: pageIndex,
      );
      if (comp.label.isNotEmpty) {
        final translatedLabel = translate(comp.label);
        if (translatedLabel != comp.label) {
          state.setLabel(translatedLabel);
        }
      }
      componentStates[instanceId] = state;

      // If repeating group, initialize rows already in dataTree
      if (isRepeating) {
        final existing = dataTree.getValue(childPath);
        if (existing is List) {
          for (var r = 0; r < existing.length; r++) {
            final rowPath = childPath.child(r);
            for (final col in comp.components) {
              final colPath = rowPath.child(col.key);
              final instanceId = '${comp.key}:$r:${col.key}';
              final colState = FormioComponentState(
                schema: col,
                dataPath: colPath,
                instanceId: instanceId,
                pageIndex: pageIndex,
              );
              if (col.label.isNotEmpty) {
                final translatedLabel = translate(col.label);
                if (translatedLabel != col.label) {
                  colState.setLabel(translatedLabel);
                }
              }
              componentStates[instanceId] = colState;
            }
          }
        }
      }

      // Child components for container or layout
      if (!isRepeating) {
        for (final child in comp.components) {
          visit(child, childPath, pageIndex);
        }
        for (final col in comp.columns) {
          for (final child in col.components) {
            visit(child, childPath, pageIndex);
          }
        }
        for (final row in comp.tableRows) {
          for (final cell in row) {
            for (final child in cell) {
              visit(child, childPath, pageIndex);
            }
          }
        }
      }
    }

    if (schema.isWizard) {
      final pages = schema.wizardPages;
      for (var p = 0; p < pages.length; p++) {
        final pageComp = pages[p];
        // Register page panel state itself
        componentStates[pageComp.key] = FormioComponentState(
          schema: pageComp,
          dataPath: DataPath.root,
          instanceId: pageComp.key,
          pageIndex: p,
        );
        for (final child in pageComp.components) {
          visit(child, DataPath.root, p);
        }
      }
    } else {
      for (final comp in schema.components) {
        visit(comp, DataPath.root, 0);
      }
    }
  }

  void _applyDefaults(bool isNewSubmission) {
    for (final state in componentStates.values) {
      if (state.schema.defaultValue != null) {
        if (isNewSubmission) {
          dataTree.applyDefaultIfAbsent(
              state.dataPath, state.schema.defaultValue);
        }
      }
    }
  }

  Map<String, dynamic> _resolveRowData(DataPath path) {
    if (path.length > 2) {
      final rowVal = dataTree.getValue(path.parent);
      if (rowVal is Map) return Map<String, dynamic>.from(rowVal);
    }
    return dataTree.rawData;
  }

  int? _findNextVisiblePageIndex(int fromIndex) {
    for (var i = fromIndex + 1; i < _wizardPages.length; i++) {
      final p = _wizardPages[i];
      final state = componentStates[p.key];
      if (state == null || !state.hidden) return i;
    }
    return null;
  }

  int? _findPreviousVisiblePageIndex(int fromIndex) {
    for (var i = fromIndex - 1; i >= 0; i--) {
      final p = _wizardPages[i];
      final state = componentStates[p.key];
      if (state == null || !state.hidden) return i;
    }
    return null;
  }

  void _adjustCurrentPageIfHidden() {
    if (!schema.isWizard || _wizardPages.isEmpty) return;
    final current = _wizardPages[_currentPageIndex];
    final state = componentStates[current.key];
    if (state != null && state.hidden) {
      final next = _findNextVisiblePageIndex(_currentPageIndex) ??
          _findPreviousVisiblePageIndex(_currentPageIndex);
      if (next != null) {
        _currentPageIndex = next;
      }
    }
  }

  @override
  void dispose() {
    for (final state in componentStates.values) {
      state.dispose();
    }
    super.dispose();
  }
}
