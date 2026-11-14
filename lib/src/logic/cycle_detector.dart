import 'package:meta/meta.dart';

/// Represents a detected dependency cycle among components.
@immutable
class DependencyCycle {
  final List<String> cyclePath;

  const DependencyCycle(this.cyclePath);

  @override
  String toString() => 'Dependency cycle detected: ${cyclePath.join(' -> ')}';
}

/// Detects cycles in directed component dependency graphs.
class CycleDetector {
  /// Analyzes adjacency map `graph` (key -> set of dependencies) and returns all detected cycles.
  static List<DependencyCycle> findCycles(Map<String, Set<String>> graph) {
    final cycles = <DependencyCycle>[];
    final visited = <String, int>{}; // 0 = unvisited, 1 = visiting, 2 = visited
    final currentPath = <String>[];

    void dfs(String node) {
      visited[node] = 1;
      currentPath.add(node);

      final neighbors = graph[node] ?? const {};
      for (final neighbor in neighbors) {
        final state = visited[neighbor] ?? 0;
        if (state == 1) {
          // Found cycle!
          final cycleStart = currentPath.indexOf(neighbor);
          if (cycleStart != -1) {
            final cycle = [...currentPath.sublist(cycleStart), neighbor];
            cycles.add(DependencyCycle(cycle));
          }
        } else if (state == 0) {
          dfs(neighbor);
        }
      }

      currentPath.removeLast();
      visited[node] = 2;
    }

    for (final node in graph.keys) {
      if ((visited[node] ?? 0) == 0) {
        dfs(node);
      }
    }

    return cycles;
  }
}
