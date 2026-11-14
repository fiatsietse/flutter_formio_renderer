import '../models/schema/form_schema.dart';
import 'cycle_detector.dart';

/// Manages reactive component dependencies, topological ordering, and cycle detection.
class FormioDependencyGraph {
  /// Map of component key -> set of keys it depends on.
  final Map<String, Set<String>> _dependencies = {};

  /// Reverse map: component key -> set of keys that depend on it.
  final Map<String, Set<String>> _dependents = {};

  /// Detected cycles in the schema.
  final List<DependencyCycle> cycles = [];

  /// Deterministic topological order for evaluation.
  final List<String> evaluationOrder = [];

  FormioDependencyGraph.fromSchema(FormioFormSchema schema) {
    _buildFromSchema(schema);
  }

  /// Returns keys that depend directly or indirectly on [key].
  Set<String> getDependents(String key) {
    return _dependents[key] ?? const {};
  }

  /// Returns keys that [key] depends on.
  Set<String> getDependencies(String key) {
    return _dependencies[key] ?? const {};
  }

  void _buildFromSchema(FormioFormSchema schema) {
    schema.traverse((comp, parents) {
      final key = comp.key;
      final deps = <String>{};

      // 1. Simple conditional
      if (comp.conditional.when != null && comp.conditional.when!.isNotEmpty) {
        deps.add(comp.conditional.when!);
      }

      // 2. JSON Logic conditional
      if (comp.conditional.json != null) {
        _extractVarsFromJsonLogic(comp.conditional.json, deps);
      }

      // 3. Logic rules triggers
      for (final rule in comp.logic) {
        if (rule.trigger.simple?.when != null &&
            rule.trigger.simple!.when!.isNotEmpty) {
          deps.add(rule.trigger.simple!.when!);
        }
        if (rule.trigger.json != null) {
          _extractVarsFromJsonLogic(rule.trigger.json, deps);
        }
      }

      // 4. Calculate value
      if (comp.calculateValue != null) {
        if (comp.calculateValue is Map) {
          _extractVarsFromJsonLogic(comp.calculateValue, deps);
        } else if (comp.calculateValue is String) {
          _extractVarsFromScript(comp.calculateValue as String, deps);
        }
      }

      // 5. Custom conditional script
      if (comp.customConditional != null &&
          comp.customConditional!.isNotEmpty) {
        _extractVarsFromScript(comp.customConditional!, deps);
      }

      // 6. Explicit dependencies property (e.g. "dependencies": ["fieldA", "fieldB"] or "fieldA,fieldB")
      final explicit =
          comp.properties['dependencies'] ?? comp.properties['deps'];
      if (explicit is List) {
        for (final d in explicit) {
          if (d != null && d.toString().isNotEmpty) deps.add(d.toString());
        }
      } else if (explicit is String && explicit.isNotEmpty) {
        for (final d in explicit.split(',')) {
          final trimmed = d.trim();
          if (trimmed.isNotEmpty) deps.add(trimmed);
        }
      }

      _dependencies[key] = deps;
      for (final d in deps) {
        _dependents.putIfAbsent(d, () => <String>{}).add(key);
      }
    });

    // Detect cycles
    cycles.addAll(CycleDetector.findCycles(_dependencies));

    // Compute topological order (breaking cycles safely if found)
    _computeTopologicalOrder();
  }

  static void _extractVarsFromJsonLogic(dynamic rule, Set<String> deps) {
    if (rule == null) return;
    if (rule is Map) {
      for (final entry in rule.entries) {
        if (entry.key == 'var') {
          final val = entry.value;
          if (val is String && val.isNotEmpty) {
            _addVarToDeps(val, deps);
          } else if (val is List && val.isNotEmpty && val.first is String) {
            _addVarToDeps(val.first as String, deps);
          }
        } else {
          _extractVarsFromJsonLogic(entry.value, deps);
        }
      }
    } else if (rule is List) {
      for (final item in rule) {
        _extractVarsFromJsonLogic(item, deps);
      }
    }
  }

  static void _extractVarsFromScript(String script, Set<String> deps) {
    final matches = RegExp(r'(?:data|row)\.([a-zA-Z0-9_]+)').allMatches(script);
    for (final m in matches) {
      final key = m.group(1);
      if (key != null && key.isNotEmpty) {
        deps.add(key);
      }
    }
  }

  static void _addVarToDeps(String varPath, Set<String> deps) {
    // E.g. "data.total" or "row.price" or "total"
    var clean = varPath;
    if (clean.startsWith('data.')) clean = clean.substring(5);
    if (clean.startsWith('row.')) clean = clean.substring(4);
    final dot = clean.indexOf('.');
    final rootKey = dot == -1 ? clean : clean.substring(0, dot);
    if (rootKey.isNotEmpty) {
      deps.add(rootKey);
    }
  }

  void _computeTopologicalOrder() {
    evaluationOrder.clear();
    final inDegree = <String, int>{};
    for (final node in _dependencies.keys) {
      inDegree[node] = _dependencies[node]?.length ?? 0;
    }

    final queue = <String>[];
    for (final node in _dependencies.keys) {
      if ((inDegree[node] ?? 0) == 0) {
        queue.add(node);
      }
    }

    final visited = <String>{};
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      evaluationOrder.add(current);
      visited.add(current);

      final dependents = _dependents[current] ?? const {};
      for (final dep in dependents) {
        inDegree[dep] = (inDegree[dep] ?? 1) - 1;
        if ((inDegree[dep] ?? 0) <= 0 && !visited.contains(dep)) {
          queue.add(dep);
        }
      }
    }

    // Add remaining nodes (e.g. in cycles) to ensure everything gets visited
    for (final node in _dependencies.keys) {
      if (!visited.contains(node)) {
        evaluationOrder.add(node);
      }
    }
  }
}
