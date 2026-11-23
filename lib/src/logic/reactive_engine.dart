import '../models/schema/form_schema.dart';
import '../models/schema/component_schema.dart';
import '../models/schema/logic_rule.dart';
import '../models/options/formio_options.dart';
import '../models/diagnostics/formio_diagnostic.dart';
import '../state/data_tree.dart';
import '../state/component_state.dart';
import '../scripting/script_evaluator.dart';
import '../scripting/safe_script_evaluator.dart';
import 'json_logic/json_logic_engine.dart';
import 'dependency_graph.dart';

/// Reactive logic engine responsible for evaluating conditions, calculated values,
/// logic rules, and dynamic properties in deterministic topological order with cycle safety.
class FormioReactiveEngine {
  final FormioFormSchema schema;
  FormioOptions _options;
  FormioOptions get options => _options;
  final FormioDataTree dataTree;
  final Map<String, FormioComponentState> componentStates;
  final FormioDependencyGraph dependencyGraph;
  final JsonLogicEngine jsonLogic = const JsonLogicEngine();

  FormioReactiveEngine({
    required this.schema,
    required FormioOptions options,
    required this.dataTree,
    required this.componentStates,
    required this.dependencyGraph,
  }) : _options = options;

  /// Updates reactive options at runtime.
  void updateOptions(FormioOptions newOptions) {
    _options = newOptions;
  }

  /// Evaluates all reactive logic rules, conditions, and calculations across the form.
  ///
  /// Safe against infinite recursion: enforces [FormioOptions.maxLogicIterations].
  void evaluateAll() {
    var iteration = 0;
    var hasChanges = true;

    // Report any schema-level cycles detected upfront
    if (dependencyGraph.cycles.isNotEmpty) {
      for (final cycle in dependencyGraph.cycles) {
        options.onDiagnostic?.call(
          FormioDiagnostic(
            level: FormioDiagnosticLevel.warning,
            code: 'CYCLE_DETECTED',
            message: cycle.toString(),
            details: {'cycle': cycle.cyclePath},
          ),
        );
      }
    }

    while (hasChanges && iteration < options.maxLogicIterations) {
      hasChanges = false;
      iteration++;

      // Evaluate in topological order across all matching component states (including grid rows)
      for (final key in dependencyGraph.evaluationOrder) {
        final states = componentStates.values
            .where((s) => s.schema.key == key || s.instanceId == key)
            .toList();

        for (final state in states) {
          final changed = _evaluateComponent(state);
          if (changed) {
            hasChanges = true;
          }
        }
      }
    }

    if (iteration >= options.maxLogicIterations && hasChanges) {
      options.onDiagnostic?.call(
        FormioDiagnostic(
          level: FormioDiagnosticLevel.error,
          code: 'MAX_ITERATIONS_EXCEEDED',
          message:
              'Reactive logic evaluation reached limit of ${options.maxLogicIterations} iterations. Potential cycle or oscillating calculation.',
        ),
      );
    }
  }

  /// Evaluates rules for a single component instance. Returns true if state or value changed.
  bool _evaluateComponent(FormioComponentState state) {
    var changed = false;
    final comp = state.schema;
    final rowContext = _resolveRowContext(state);
    final evalContext = <String, dynamic>{
      'data': dataTree.rawData,
      'row': rowContext,
      'value': dataTree.getValue(state.dataPath),
    };

    // 1. Evaluate Conditional Visibility
    final visibilityChanged = _evaluateVisibility(state, comp, evalContext);
    if (visibilityChanged) changed = true;

    // 2. Evaluate Calculated Value (only if visible or configured to evaluate)
    if (comp.calculateValue != null && !state.hidden) {
      final calcChanged = _evaluateCalculation(state, comp, evalContext);
      if (calcChanged) changed = true;
    }

    // 3. Evaluate Advanced Logic Rules
    for (final rule in comp.logic) {
      final ruleChanged = _evaluateLogicRule(state, comp, rule, evalContext);
      if (ruleChanged) changed = true;
    }

    return changed;
  }

  Map<String, dynamic> _resolveRowContext(FormioComponentState state) {
    if (state.dataPath.length > 2) {
      // Path like items[0].price -> row path is items[0]
      final rowPath = state.dataPath.parent;
      final rowVal = dataTree.getValue(rowPath);
      if (rowVal is Map) return Map<String, dynamic>.from(rowVal);
    }
    return dataTree.rawData;
  }

  bool _evaluateVisibility(
    FormioComponentState state,
    FormioComponentSchema comp,
    Map<String, dynamic> evalContext,
  ) {
    final cond = comp.conditional;
    if (cond.isEmpty) return false;

    bool isVisible = !comp.hidden;

    // A. Simple conditional
    if (cond.hasSimpleCondition) {
      final observedKey = cond.when!;
      final observedPath = state.dataPath.parent.child(observedKey);
      var observedValue = dataTree.getValue(observedPath);
      observedValue ??= dataTree.rawData[observedKey];

      final expectedEq = cond.eq;
      final showWhenMatch = cond.show ?? true;

      final isMatch = _compareLoose(observedValue, expectedEq);
      isVisible = showWhenMatch ? isMatch : !isMatch;
    }

    // B. JSON Logic conditional
    if (cond.hasJsonCondition) {
      final result = jsonLogic.evaluateCondition(cond.json, evalContext);
      final showWhenMatch = cond.show ?? true;
      isVisible = showWhenMatch ? result : !result;
    }

    // C. Custom conditional script
    if (cond.hasCustomScript) {
      final evaluator = options.scriptEvaluator ?? const SafeScriptEvaluator();
      final scriptCtx = FormioScriptContext(
        data: dataTree.rawData,
        row: evalContext['row'] as Map<String, dynamic>,
        value: evalContext['value'],
        component: comp.rawJson,
      );
      final res =
          evaluator.evaluateSync(script: cond.custom!, context: scriptCtx);
      if (res.isSuccess) {
        isVisible = jsonLogic.isTruthy(res.value);
      } else {
        options.onDiagnostic?.call(
          FormioDiagnostic(
            level: FormioDiagnosticLevel.warning,
            code: 'SCRIPT_EVALUATION_FAILED',
            message: 'Custom conditional script failed: ${res.error}',
            componentKey: comp.key,
            dataPath: state.dataPath.toDotString(),
          ),
        );
      }
    }

    final newHidden = !isVisible;
    final hiddenChanged = state.setHidden(newHidden);

    // Apply clearOnHide semantics if component just became hidden
    if (hiddenChanged && newHidden) {
      final shouldClear = comp.clearOnHide ?? options.clearOnHide;
      if (shouldClear) {
        dataTree.removeValue(state.dataPath);
      }
    }

    return hiddenChanged;
  }

  bool _evaluateCalculation(
    FormioComponentState state,
    FormioComponentSchema comp,
    Map<String, dynamic> evalContext,
  ) {
    dynamic computedValue;

    if (comp.calculateValue is Map) {
      // JSON Logic calculation
      computedValue = jsonLogic.evaluate(comp.calculateValue, evalContext);
    } else if (comp.calculateValue is String) {
      final script = comp.calculateValue as String;
      final evaluator = options.scriptEvaluator ?? const SafeScriptEvaluator();
      final scriptCtx = FormioScriptContext(
        data: dataTree.rawData,
        row: evalContext['row'] as Map<String, dynamic>,
        value: evalContext['value'],
        component: comp.rawJson,
      );
      final res = evaluator.evaluateSync(script: script, context: scriptCtx);
      if (res.isSuccess) {
        computedValue = res.value;
      } else {
        options.onDiagnostic?.call(
          FormioDiagnostic(
            level: FormioDiagnosticLevel.warning,
            code: 'SCRIPT_CALCULATION_FAILED',
            message: 'Calculate value script failed: ${res.error}',
            componentKey: comp.key,
            dataPath: state.dataPath.toDotString(),
          ),
        );
        return false;
      }
    }

    if (computedValue != null) {
      final current = dataTree.getValue(state.dataPath);
      if (current != computedValue) {
        return dataTree.setValue(state.dataPath, computedValue);
      }
    }
    return false;
  }

  bool _evaluateLogicRule(
    FormioComponentState state,
    FormioComponentSchema comp,
    FormioLogicRule rule,
    Map<String, dynamic> evalContext,
  ) {
    var triggerMatched = false;
    final trigger = rule.trigger;

    switch (trigger.type) {
      case 'simple':
        if (trigger.simple?.when != null) {
          final observedKey = trigger.simple!.when!;
          final observedPath = state.dataPath.parent.child(observedKey);
          var observedVal =
              dataTree.getValue(observedPath) ?? dataTree.rawData[observedKey];
          triggerMatched = _compareLoose(observedVal, trigger.simple!.eq);
        }
        break;

      case 'json':
        if (trigger.json != null) {
          triggerMatched =
              jsonLogic.evaluateCondition(trigger.json, evalContext);
        }
        break;

      case 'javascript':
        if (trigger.javascript != null) {
          final evaluator =
              options.scriptEvaluator ?? const SafeScriptEvaluator();
          final scriptCtx = FormioScriptContext(
            data: dataTree.rawData,
            row: evalContext['row'] as Map<String, dynamic>,
            value: evalContext['value'],
            component: comp.rawJson,
          );
          final res = evaluator.evaluateSync(
              script: trigger.javascript!, context: scriptCtx);
          triggerMatched = res.isSuccess && jsonLogic.isTruthy(res.value);
        }
        break;
    }

    if (!triggerMatched) return false;

    var changed = false;
    for (final action in rule.actions) {
      final actionChanged = _executeAction(state, comp, action, evalContext);
      if (actionChanged) changed = true;
    }
    return changed;
  }

  bool _executeAction(
    FormioComponentState state,
    FormioComponentSchema comp,
    FormioLogicAction action,
    Map<String, dynamic> evalContext,
  ) {
    var changed = false;

    if (action.type == 'property' && action.property != null) {
      final propName = action.property!.value;
      final targetState = action.state;

      switch (propName) {
        case 'disabled':
          if (targetState is bool && state.setDisabled(targetState)) {
            changed = true;
          }
          break;
        case 'hidden':
          if (targetState is bool && state.setHidden(targetState)) {
            changed = true;
          }
          break;
        case 'validate.required':
        case 'required':
          if (targetState is bool && state.setRequired(targetState)) {
            changed = true;
          }
          break;
        case 'label':
        case 'title':
          if (targetState != null && state.setLabel(targetState.toString())) {
            changed = true;
          }
          break;
      }
    } else if (action.type == 'value' && action.value != null) {
      dynamic newVal = action.value;
      if (newVal is Map) {
        newVal = jsonLogic.evaluate(newVal, evalContext);
      }
      final current = dataTree.getValue(state.dataPath);
      if (current != newVal) {
        changed = dataTree.setValue(state.dataPath, newVal);
      }
    }
    return changed;
  }

  bool _compareLoose(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a == null || b == null) return false;

    // Handle string to bool: e.g. "true" == true
    if (a is bool && b is String) return a == (b.toLowerCase() == 'true');
    if (b is bool && a is String) return b == (a.toLowerCase() == 'true');

    // Handle string to num: e.g. "10" == 10
    final numA = num.tryParse(a.toString());
    final numB = num.tryParse(b.toString());
    if (numA != null && numB != null) return numA == numB;

    return a.toString() == b.toString();
  }
}
