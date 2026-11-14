/// A fast, pure Dart implementation of JSON Logic (jsonlogic.com)
/// tailored for Form.io rule evaluation, conditional visibility,
/// calculated values, and validation.
class JsonLogicEngine {
  const JsonLogicEngine();

  /// Evaluates [rule] against the given [data] context.
  dynamic evaluate(dynamic rule, dynamic data) {
    if (rule == null) return null;
    if (rule is! Map) {
      // Primitive literal (number, string, boolean, etc.)
      return rule;
    }

    if (rule.isEmpty) return null;

    final operator = rule.keys.first.toString();
    final args = rule[operator];

    return _apply(operator, args, data);
  }

  /// Evaluates [rule] and returns a boolean result according to JS truthiness.
  bool evaluateCondition(dynamic rule, dynamic data) {
    final result = evaluate(rule, data);
    return isTruthy(result);
  }

  dynamic _apply(String op, dynamic args, dynamic data) {
    switch (op) {
      // Data access
      case 'var':
        return _applyVar(args, data);

      // Logical / Boolean
      case '==':
        return _applyLooseEqual(args, data);
      case '===':
        return _applyStrictEqual(args, data);
      case '!=':
        return !_applyLooseEqual(args, data);
      case '!==':
        return !_applyStrictEqual(args, data);
      case '!':
        return !isTruthy(_evalArg(args, data));
      case '!!':
        return isTruthy(_evalArg(args, data));
      case 'and':
        return _applyAnd(args, data);
      case 'or':
        return _applyOr(args, data);
      case '?:':
      case 'if':
        return _applyIf(args, data);

      // Numeric comparisons
      case '<':
      case '<=':
      case '>':
      case '>=':
        return _applyComparison(op, args, data);

      // Arithmetic
      case '+':
        return _applyAdd(args, data);
      case '-':
        return _applySub(args, data);
      case '*':
        return _applyMul(args, data);
      case '/':
        return _applyDiv(args, data);
      case '%':
        return _applyMod(args, data);

      // String / Array
      case 'in':
        return _applyIn(args, data);
      case 'cat':
        return _applyCat(args, data);
      case 'substr':
        return _applySubstr(args, data);
      case 'merge':
        return _applyMerge(args, data);

      default:
        // Unsupported operator
        return null;
    }
  }

  dynamic _evalArg(dynamic arg, dynamic data) {
    if (arg is Map) return evaluate(arg, data);
    return arg;
  }

  List<dynamic> _evalArgsList(dynamic args, dynamic data) {
    if (args is List) {
      return args.map((a) => _evalArg(a, data)).toList();
    }
    return [_evalArg(args, data)];
  }

  dynamic _applyVar(dynamic args, dynamic data) {
    String? path;
    dynamic defaultValue;

    if (args is List) {
      if (args.isNotEmpty) path = args[0]?.toString();
      if (args.length > 1) defaultValue = args[1];
    } else if (args != null) {
      path = args.toString();
    }

    if (path == null || path.isEmpty) {
      return data;
    }

    dynamic current = data;
    final parts = path.split('.');
    for (final part in parts) {
      if (current == null) return defaultValue;
      if (current is Map) {
        if (!current.containsKey(part)) return defaultValue;
        current = current[part];
      } else if (current is List) {
        final idx = int.tryParse(part);
        if (idx != null && idx >= 0 && idx < current.length) {
          current = current[idx];
        } else {
          return defaultValue;
        }
      } else {
        return defaultValue;
      }
    }
    return current ?? defaultValue;
  }

  bool _applyLooseEqual(dynamic args, dynamic data) {
    final list = _evalArgsList(args, data);
    if (list.length < 2) return false;
    final a = list[0];
    final b = list[1];

    if (a == b) return true;
    if (a == null || b == null) return false;

    // Numeric comparison
    final numA = num.tryParse(a.toString());
    final numB = num.tryParse(b.toString());
    if (numA != null && numB != null) {
      return numA == numB;
    }

    // String comparison
    return a.toString() == b.toString();
  }

  bool _applyStrictEqual(dynamic args, dynamic data) {
    final list = _evalArgsList(args, data);
    if (list.length < 2) return false;
    final a = list[0];
    final b = list[1];
    return a == b;
  }

  dynamic _applyAnd(dynamic args, dynamic data) {
    if (args is! List || args.isEmpty) return false;
    dynamic lastVal = true;
    for (final arg in args) {
      lastVal = _evalArg(arg, data);
      if (!isTruthy(lastVal)) return lastVal;
    }
    return lastVal;
  }

  dynamic _applyOr(dynamic args, dynamic data) {
    if (args is! List || args.isEmpty) return false;
    dynamic lastVal = false;
    for (final arg in args) {
      lastVal = _evalArg(arg, data);
      if (isTruthy(lastVal)) return lastVal;
    }
    return lastVal;
  }

  dynamic _applyIf(dynamic args, dynamic data) {
    if (args is! List) return null;
    var i = 0;
    while (i < args.length) {
      if (i == args.length - 1) {
        // Fallback trailing else value
        return _evalArg(args[i], data);
      }
      final condition = _evalArg(args[i], data);
      if (isTruthy(condition)) {
        return _evalArg(args[i + 1], data);
      }
      i += 2;
    }
    return null;
  }

  dynamic _applyComparison(String op, dynamic args, dynamic data) {
    final list = _evalArgsList(args, data);
    if (list.length == 2) {
      final a = _toNum(list[0]);
      final b = _toNum(list[1]);
      if (a == null || b == null) return false;
      switch (op) {
        case '<':
          return a < b;
        case '<=':
          return a <= b;
        case '>':
          return a > b;
        case '>=':
          return a >= b;
      }
    } else if (list.length == 3 && op == '<=') {
      // Between: a <= b <= c
      final a = _toNum(list[0]);
      final b = _toNum(list[1]);
      final c = _toNum(list[2]);
      if (a == null || b == null || c == null) return false;
      return a <= b && b <= c;
    } else if (list.length == 3 && op == '<') {
      final a = _toNum(list[0]);
      final b = _toNum(list[1]);
      final c = _toNum(list[2]);
      if (a == null || b == null || c == null) return false;
      return a < b && b < c;
    }
    return false;
  }

  dynamic _applyAdd(dynamic args, dynamic data) {
    if (args is! List) {
      // Unary plus
      final val = _evalArg(args, data);
      return _toNum(val) ?? 0;
    }
    num sum = 0;
    for (final arg in args) {
      final val = _evalArg(arg, data);
      final n = _toNum(val);
      if (n != null) sum += n;
    }
    return sum;
  }

  dynamic _applySub(dynamic args, dynamic data) {
    final list = _evalArgsList(args, data);
    if (list.length == 1) {
      final n = _toNum(list[0]);
      return n != null ? -n : 0;
    }
    if (list.length >= 2) {
      final a = _toNum(list[0]) ?? 0;
      final b = _toNum(list[1]) ?? 0;
      return a - b;
    }
    return 0;
  }

  dynamic _applyMul(dynamic args, dynamic data) {
    final list = _evalArgsList(args, data);
    if (list.isEmpty) return 0;
    num prod = 1;
    for (final item in list) {
      final n = _toNum(item) ?? 0;
      prod *= n;
    }
    return prod;
  }

  dynamic _applyDiv(dynamic args, dynamic data) {
    final list = _evalArgsList(args, data);
    if (list.length >= 2) {
      final a = _toNum(list[0]) ?? 0;
      final b = _toNum(list[1]) ?? 1;
      if (b == 0) return 0;
      return a / b;
    }
    return 0;
  }

  dynamic _applyMod(dynamic args, dynamic data) {
    final list = _evalArgsList(args, data);
    if (list.length >= 2) {
      final a = _toNum(list[0]) ?? 0;
      final b = _toNum(list[1]) ?? 1;
      if (b == 0) return 0;
      return a % b;
    }
    return 0;
  }

  dynamic _applyIn(dynamic args, dynamic data) {
    final list = _evalArgsList(args, data);
    if (list.length < 2) return false;
    final item = list[0];
    final container = list[1];
    if (container is String) {
      return container.contains(item?.toString() ?? '');
    } else if (container is List) {
      return container.contains(item);
    } else if (container is Map) {
      return container.containsKey(item?.toString());
    }
    return false;
  }

  dynamic _applyCat(dynamic args, dynamic data) {
    final list = _evalArgsList(args, data);
    return list.map((e) => e?.toString() ?? '').join();
  }

  dynamic _applySubstr(dynamic args, dynamic data) {
    final list = _evalArgsList(args, data);
    if (list.isEmpty) return '';
    final str = list[0]?.toString() ?? '';
    final start = list.length > 1 ? (_toNum(list[1])?.toInt() ?? 0) : 0;
    final length = list.length > 2 ? _toNum(list[2])?.toInt() : null;

    final actualStart = start < 0
        ? (str.length + start).clamp(0, str.length)
        : start.clamp(0, str.length);
    if (length == null) {
      return str.substring(actualStart);
    }
    final end = (actualStart + length).clamp(0, str.length);
    return str.substring(actualStart, end);
  }

  dynamic _applyMerge(dynamic args, dynamic data) {
    final list = _evalArgsList(args, data);
    final merged = <dynamic>[];
    for (final item in list) {
      if (item is List) {
        merged.addAll(item);
      } else if (item != null) {
        merged.add(item);
      }
    }
    return merged;
  }

  num? _toNum(dynamic val) {
    if (val == null) return null;
    if (val is num) return val;
    return num.tryParse(val.toString());
  }

  /// Determines truthiness according to JavaScript semantics:
  /// false, 0, -0, 0.0, "", null, undefined, NaN are falsy. Everything else is truthy.
  /// Note: Empty arrays and empty maps are truthy in JS, but empty arrays in JSON Logic can be falsy.
  /// Here we adhere to standard JS/Form.io truthiness.
  bool isTruthy(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val;
    if (val is num) return val != 0 && !val.isNaN;
    if (val is String) return val.isNotEmpty;
    if (val is List) return val.isNotEmpty;
    return true;
  }
}
