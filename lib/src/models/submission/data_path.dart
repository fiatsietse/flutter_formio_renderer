import 'package:meta/meta.dart';

/// Represents a path into the nested submission data tree.
///
/// Can contain both String keys (for maps/objects) and int indices (for arrays/lists).
/// For example: `DataPath(['users', 0, 'email'])` corresponds to `users[0].email`.
@immutable
class DataPath {
  final List<dynamic> segments;

  const DataPath([this.segments = const []]);

  /// Creates a [DataPath] from a dot-and-bracket notation string such as `items[0].price` or `user.name`.
  factory DataPath.parse(String path) {
    if (path.isEmpty) return const DataPath([]);
    final segments = <dynamic>[];
    final regex = RegExp(r'([a-zA-Z0-9_-]+)|\[(\d+)\]');
    for (final match in regex.allMatches(path)) {
      if (match.group(2) != null) {
        segments.add(int.parse(match.group(2)!));
      } else if (match.group(1) != null) {
        segments.add(match.group(1)!);
      }
    }
    return DataPath(List.unmodifiable(segments));
  }

  /// Empty root path.
  static const DataPath root = DataPath([]);

  bool get isRoot => segments.isEmpty;

  int get length => segments.length;

  dynamic get last => segments.isEmpty ? null : segments.last;

  /// Returns a new [DataPath] with [segment] appended.
  DataPath child(dynamic segment) {
    assert(
        segment is String || segment is int, 'Segment must be String or int');
    return DataPath(List.unmodifiable([...segments, segment]));
  }

  /// Returns the parent path, or `root` if this path is already root.
  DataPath get parent {
    if (segments.length <= 1) return root;
    return DataPath(
        List.unmodifiable(segments.sublist(0, segments.length - 1)));
  }

  /// Formats this path as standard dot-and-bracket notation: e.g. `items[0].name`.
  String toDotString() {
    if (segments.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (seg is int) {
        buffer.write('[$seg]');
      } else {
        if (i > 0 && segments[i - 1] is! int) {
          buffer.write('.');
        } else if (i > 0 && segments[i - 1] is int) {
          buffer.write('.');
        }
        buffer.write(seg);
      }
    }
    return buffer.toString();
  }

  /// Resolves the value at this path from a root map or list [rootData].
  dynamic resolve(dynamic rootData) {
    dynamic current = rootData;
    for (final segment in segments) {
      if (current == null) return null;
      if (segment is int) {
        if (current is List && segment >= 0 && segment < current.length) {
          current = current[segment];
        } else {
          return null;
        }
      } else if (segment is String) {
        if (current is Map) {
          current = current[segment];
        } else {
          return null;
        }
      }
    }
    return current;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataPath &&
          runtimeType == other.runtimeType &&
          _listEquals(segments, other.segments);

  @override
  int get hashCode => segments.fold(0, (prev, elem) => prev ^ elem.hashCode);

  @override
  String toString() => toDotString();

  static bool _listEquals(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
