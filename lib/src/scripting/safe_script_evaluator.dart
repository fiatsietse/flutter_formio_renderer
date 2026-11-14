import 'script_evaluator.dart';

/// Pure Dart, sandboxed script evaluator for common Form.io expressions.
///
/// Reliably evaluates standard Form.io conditionals, calculations, and assignments
/// without requiring WebViews, external JavaScript runtimes, or network access.
///
/// Features supported:
/// - Visibility conditionals: `show = !data.field;`, `show = !!data.field;`, `show = data.a === 'value';`
/// - Membership checks: `show = ['a', 'b'].indexOf(data.field) !== -1;`, `show = ['a', 'b'].includes(data.field);`
/// - Logical combinations: `show = data.a && data.b;`, `show = data.a || data.b;`
/// - Value calculations: `value = (data.a || '') + (data.b || '');`, `value = (data.a || 0) + (data.b || 0);`
/// - Date validation scripts: `valid = (!input || ...) ? true : 'error.key';`
/// - Harmless DOM scripts: ignores browser/window DOM mutations gracefully.
class SafeScriptEvaluator implements FormioScriptEvaluator {
  const SafeScriptEvaluator();

  @override
  String get engineName => 'Safe Pure-Dart Evaluator';

  @override
  bool get isEnabled => true;

  @override
  Future<FormioScriptResult> evaluate({
    required String script,
    required FormioScriptContext context,
    Duration timeout = const Duration(milliseconds: 500),
  }) async {
    return evaluateSync(script: script, context: context);
  }

  @override
  FormioScriptResult evaluateSync({
    required String script,
    required FormioScriptContext context,
  }) {
    final trimmed = script.trim();
    if (trimmed.isEmpty) {
      return const FormioScriptResult.success(null);
    }

    // 1. Harmless browser/DOM injection scripts (e.g. stickyInjector in web forms)
    if (trimmed.contains('window.__') ||
        trimmed.contains('document.getElementById') ||
        trimmed.contains('document.querySelector') ||
        trimmed.contains('window.addEventListener')) {
      return const FormioScriptResult.success(null);
    }

    try {
      // 2. Custom conditional: "show = <expr>;" or return <expr>;
      if (trimmed.contains('show =') || trimmed.contains('show=')) {
        final expr = _extractAssignedExpression(trimmed, 'show');
        final result = _evaluateBooleanExpression(expr, context);
        return FormioScriptResult.success(result);
      }

      // 3. Calculated value: "value = <expr>;"
      if (trimmed.contains('value =') || trimmed.contains('value=')) {
        final expr = _extractAssignedExpression(trimmed, 'value');
        final result = _evaluateValueExpression(expr, context);
        return FormioScriptResult.success(result);
      }

      // 4. Custom validation: "valid = <expr>;"
      if (trimmed.contains('valid =') || trimmed.contains('valid=')) {
        final expr = _extractAssignedExpression(trimmed, 'valid');
        final result = _evaluateValidationExpression(expr, context);
        return FormioScriptResult.success(result);
      }

      // 5. Direct boolean expression (e.g. "!data.field")
      if (trimmed.startsWith('!') ||
          trimmed.startsWith('data.') ||
          trimmed.startsWith('row.')) {
        final result = _evaluateBooleanExpression(trimmed, context);
        return FormioScriptResult.success(result);
      }

      // If expression is unrecognized, return success(null) or a graceful failure
      return FormioScriptResult.failure(
        'Unsupported script expression: ${trimmed.length > 50 ? "${trimmed.substring(0, 50)}..." : trimmed}',
      );
    } catch (e) {
      return FormioScriptResult.failure('Safe evaluation error: $e');
    }
  }

  String _extractAssignedExpression(String script, String variable) {
    // Look for variable = <expression> [;]
    final regex = RegExp(variable + r'\s*=\s*(.+?)(?:;|$)', dotAll: true);
    final match = regex.firstMatch(script);
    if (match != null) {
      return match.group(1)!.trim();
    }
    return script;
  }

  bool _evaluateBooleanExpression(String expr, FormioScriptContext context) {
    var clean = expr.trim();
    while (clean.endsWith(';')) {
      clean = clean.substring(0, clean.length - 1).trim();
    }

    // Double negation: !!data.field or !!row.field
    if (clean.startsWith('!!')) {
      final inner = clean.substring(2).trim();
      final val = _resolveContextValue(inner, context);
      return _isTruthy(val);
    }

    // Single negation: !data.field or !row.field
    if (clean.startsWith('!') &&
        !clean.contains('!==') &&
        !clean.contains('!=')) {
      final inner = clean.substring(1).trim();
      final val = _resolveContextValue(inner, context);
      return !_isTruthy(val);
    }

    // Array indexOf check: ['a', 'b'].indexOf(data.field) !== -1 (or != -1)
    final indexOfNotMatch =
        RegExp(r"\[(.*?)\]\.indexOf\((.*?)\)\s*!==\s*-1").firstMatch(clean) ??
            RegExp(r"\[(.*?)\]\.indexOf\((.*?)\)\s*!=\s*-1").firstMatch(clean);
    if (indexOfNotMatch != null) {
      final itemsStr = indexOfNotMatch.group(1)!;
      final arg = indexOfNotMatch.group(2)!.trim();
      final items = _parseLiteralList(itemsStr);
      final val = _resolveContextValue(arg, context);
      return items.contains(val?.toString());
    }

    // Array indexOf equals -1 (not present)
    final indexOfEqMatch =
        RegExp(r"\[(.*?)\]\.indexOf\((.*?)\)\s*===\s*-1").firstMatch(clean) ??
            RegExp(r"\[(.*?)\]\.indexOf\((.*?)\)\s*==\s*-1").firstMatch(clean);
    if (indexOfEqMatch != null) {
      final itemsStr = indexOfEqMatch.group(1)!;
      final arg = indexOfEqMatch.group(2)!.trim();
      final items = _parseLiteralList(itemsStr);
      final val = _resolveContextValue(arg, context);
      return !items.contains(val?.toString());
    }

    // Array includes check: ['a', 'b'].includes(data.field)
    final includesMatch =
        RegExp(r"\[(.*?)\]\.includes\((.*?)\)").firstMatch(clean);
    if (includesMatch != null) {
      final itemsStr = includesMatch.group(1)!;
      final arg = includesMatch.group(2)!.trim();
      final items = _parseLiteralList(itemsStr);
      final val = _resolveContextValue(arg, context);
      return items.contains(val?.toString());
    }

    // Equality: left === right
    if (clean.contains('===') || clean.contains('==')) {
      final parts =
          clean.contains('===') ? clean.split('===') : clean.split('==');
      final left = _resolveContextValue(parts[0].trim(), context);
      final right = _resolveLiteralOrContextValue(parts[1].trim(), context);
      return left?.toString() == right?.toString();
    }

    // Inequality: left !== right
    if (clean.contains('!==') || clean.contains('!=')) {
      final parts =
          clean.contains('!==') ? clean.split('!==') : clean.split('!=');
      final left = _resolveContextValue(parts[0].trim(), context);
      final right = _resolveLiteralOrContextValue(parts[1].trim(), context);
      return left?.toString() != right?.toString();
    }

    // Logical OR: expr1 || expr2
    if (clean.contains('||')) {
      final parts = clean.split('||');
      for (final p in parts) {
        if (_evaluateBooleanExpression(p.trim(), context)) return true;
      }
      return false;
    }

    // Logical AND: expr1 && expr2
    if (clean.contains('&&')) {
      final parts = clean.split('&&');
      for (final p in parts) {
        if (!_evaluateBooleanExpression(p.trim(), context)) return false;
      }
      return true;
    }

    // Simple context value truthiness
    final val = _resolveContextValue(clean, context);
    return _isTruthy(val);
  }

  dynamic _evaluateValueExpression(String expr, FormioScriptContext context) {
    var clean = expr.trim();
    while (clean.endsWith(';')) {
      clean = clean.substring(0, clean.length - 1).trim();
    }

    // Concatenation: (data.a || '') + (data.b || '')
    if (clean.contains('+')) {
      final parts = clean.split('+');
      final buffer = StringBuffer();
      var hasString = false;
      var sum = 0.0;
      var isNumeric = true;

      for (final part in parts) {
        final piece = _resolvePiece(part.trim(), context);
        if (piece is num) {
          sum += piece;
          buffer.write(piece);
        } else {
          isNumeric = false;
          hasString = true;
          buffer.write(piece?.toString() ?? '');
        }
      }

      if (isNumeric && !hasString) return sum;
      return buffer.toString();
    }

    // Simple fallback: resolve piece
    return _resolvePiece(clean, context);
  }

  dynamic _evaluateValidationExpression(
      String expr, FormioScriptContext context) {
    // E.g.: (!input || p.length!==3 || d <= new Date()) ? true : 'dateDeNaissance.error.custom'
    // For date bounds or general validation ternary:
    if (expr.contains('?') && expr.contains(':')) {
      final qIdx = expr.indexOf('?');
      final cIdx = expr.lastIndexOf(':');
      final conditionPart = expr.substring(0, qIdx).trim();
      final falsePart = expr.substring(cIdx + 1).trim();

      // Check input value from context
      final inputVal = context.value?.toString();
      if (inputVal == null || inputVal.isEmpty) {
        return true; // Empty inputs handled by required validator
      }

      // Check if this is a past date validation (d <= new Date() or d <= t)
      if (conditionPart.contains('<= new Date()') ||
          conditionPart.contains('<= t')) {
        final date = _parseDateDdMmYyyy(inputVal);
        if (date != null) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final isValid = date.isBefore(today) || date.isAtSameMomentAs(today);
          return isValid ? true : _cleanLiteralString(falsePart);
        }
      }

      // Check if this is a future date validation (d > t)
      if (conditionPart.contains('> t') ||
          conditionPart.contains('> new Date()')) {
        final date = _parseDateDdMmYyyy(inputVal);
        if (date != null) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final isValid = date.isAfter(today);
          return isValid ? true : _cleanLiteralString(falsePart);
        }
      }

      // Default to true
      return true;
    }

    return true;
  }

  DateTime? _parseDateDdMmYyyy(String str) {
    final parts = str.split('/');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  dynamic _resolvePiece(String piece, FormioScriptContext context) {
    var clean = piece.trim();
    if (clean.startsWith('(') && clean.endsWith(')')) {
      clean = clean.substring(1, clean.length - 1).trim();
    }

    // Default fallback: (data.a || '') or (data.a || 0)
    if (clean.contains('||')) {
      final subParts = clean.split('||');
      for (final sp in subParts) {
        final res = _resolveLiteralOrContextValue(sp.trim(), context);
        if (_isTruthy(res)) return res;
      }
      return _resolveLiteralOrContextValue(subParts.last.trim(), context);
    }

    return _resolveLiteralOrContextValue(clean, context);
  }

  dynamic _resolveContextValue(String path, FormioScriptContext context) {
    var clean = path.trim();
    if (clean == 'input') return context.value;
    if (clean.startsWith('data.')) {
      final key = clean.substring(5);
      return context.data[key];
    }
    if (clean.startsWith('row.')) {
      final key = clean.substring(4);
      return context.row[key] ?? context.data[key];
    }
    return context.data[clean];
  }

  dynamic _resolveLiteralOrContextValue(
      String token, FormioScriptContext context) {
    final clean = token.trim();
    if (clean == 'true') return true;
    if (clean == 'false') return false;
    if (clean == 'null' || clean == 'undefined') return null;

    // String literal
    if ((clean.startsWith("'") && clean.endsWith("'")) ||
        (clean.startsWith('"') && clean.endsWith('"'))) {
      return clean.substring(1, clean.length - 1);
    }

    // Numeric literal
    final numVal = num.tryParse(clean);
    if (numVal != null) return numVal;

    return _resolveContextValue(clean, context);
  }

  List<String> _parseLiteralList(String listStr) {
    final items = <String>[];
    final parts = listStr.split(',');
    for (final p in parts) {
      final trimmed = p.trim();
      items.add(_cleanLiteralString(trimmed));
    }
    return items;
  }

  String _cleanLiteralString(String s) {
    var res = s.trim();
    if ((res.startsWith("'") && res.endsWith("'")) ||
        (res.startsWith('"') && res.endsWith('"'))) {
      res = res.substring(1, res.length - 1);
    }
    return res;
  }

  bool _isTruthy(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) {
      return val.trim().isNotEmpty && val != '0' && val != 'false';
    }
    if (val is List) return val.isNotEmpty;
    if (val is Map) return val.isNotEmpty;
    return true;
  }
}
