import '../models/submission/data_path.dart';

/// Manages the hierarchical submission data map, path resolution, and mutation.
class FormioDataTree {
  final Map<String, dynamic> _root;

  FormioDataTree([Map<String, dynamic>? initialData])
      : _root = initialData != null
            ? _deepCloneMap(initialData)
            : <String, dynamic>{};

  /// Direct read-only view of the root data map.
  Map<String, dynamic> get rawData => _root;

  /// Retrieves the value at [path].
  dynamic getValue(DataPath path) {
    if (path.isRoot) return _root;
    return path.resolve(_root);
  }

  /// Sets the value at [path], creating intermediate maps or lists as needed.
  /// Returns true if value actually changed.
  bool setValue(DataPath path, dynamic value) {
    if (path.isRoot) {
      if (value is Map) {
        _root.clear();
        _root.addAll(Map<String, dynamic>.from(value));
        return true;
      }
      return false;
    }

    final segments = path.segments;
    dynamic current = _root;

    for (var i = 0; i < segments.length - 1; i++) {
      final seg = segments[i];
      final nextSeg = segments[i + 1];

      if (seg is String) {
        if (!current.containsKey(seg) || current[seg] == null) {
          current[seg] = nextSeg is int ? <dynamic>[] : <String, dynamic>{};
        }
        current = current[seg];
      } else if (seg is int) {
        final list = current as List;
        while (list.length <= seg) {
          list.add(nextSeg is int ? <dynamic>[] : <String, dynamic>{});
        }
        current = list[seg];
      }
    }

    final lastSeg = segments.last;
    if (lastSeg is String) {
      if (current is Map) {
        final oldVal = current[lastSeg];
        if (oldVal == value) return false;
        current[lastSeg] = value;
        return true;
      }
    } else if (lastSeg is int) {
      if (current is List) {
        while (current.length <= lastSeg) {
          current.add(null);
        }
        final oldVal = current[lastSeg];
        if (oldVal == value) return false;
        current[lastSeg] = value;
        return true;
      }
    }
    return false;
  }

  /// Applies a default value at [path] ONLY if the path currently does not exist
  /// or contains null/empty. Crucial for:
  /// "Loading and rendering an existing submission must not overwrite its values with defaults."
  bool applyDefaultIfAbsent(DataPath path, dynamic defaultValue) {
    if (defaultValue == null) return false;
    final existing = getValue(path);
    if (existing == null) {
      return setValue(path, defaultValue);
    }
    return false;
  }

  /// Removes the value at [path].
  bool removeValue(DataPath path) {
    if (path.isRoot) {
      _root.clear();
      return true;
    }

    final parent = path.parent;
    final parentVal = getValue(parent);
    final lastSeg = path.last;

    if (parentVal is Map && lastSeg is String) {
      if (parentVal.containsKey(lastSeg)) {
        parentVal.remove(lastSeg);
        return true;
      }
    } else if (parentVal is List && lastSeg is int) {
      if (lastSeg >= 0 && lastSeg < parentVal.length) {
        parentVal[lastSeg] =
            null; // In Form.io, clearing an item inside a row sets it to null/undefined
        return true;
      }
    }
    return false;
  }

  /// Produces a deep-copied snapshot of submission data.
  Map<String, dynamic> exportData() {
    return _deepCloneMap(_root);
  }

  /// Creates a deep copy of a Map.
  static Map<String, dynamic> _deepCloneMap(Map map) {
    final copy = <String, dynamic>{};
    for (final entry in map.entries) {
      final key = entry.key.toString();
      final val = entry.value;
      if (val is Map) {
        copy[key] = _deepCloneMap(val);
      } else if (val is List) {
        copy[key] = _deepCloneList(val);
      } else {
        copy[key] = val;
      }
    }
    return copy;
  }

  /// Creates a deep copy of a List.
  static List<dynamic> _deepCloneList(List list) {
    final copy = <dynamic>[];
    for (final item in list) {
      if (item is Map) {
        copy.add(_deepCloneMap(item));
      } else if (item is List) {
        copy.add(_deepCloneList(item));
      } else {
        copy.add(item);
      }
    }
    return copy;
  }
}
