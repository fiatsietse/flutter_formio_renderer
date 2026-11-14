import 'script_evaluator.dart';

/// Default evaluator that safely rejects arbitrary JavaScript scripts.
///
/// In compliance with secure-by-default design principles, arbitrary JavaScript
/// in Form.io schemas is not executed unless the host application explicitly configures
/// a sandboxed JavaScript evaluator.
class DisabledScriptEvaluator implements FormioScriptEvaluator {
  const DisabledScriptEvaluator();

  @override
  String get engineName => 'Disabled (Default)';

  @override
  bool get isEnabled => false;

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
    final preview =
        script.length > 40 ? '${script.substring(0, 40)}...' : script;
    return FormioScriptResult.failure(
      'JavaScript evaluation is disabled by default for security. '
      'Configure FormioOptions.scriptEvaluator with a sandboxed evaluator '
      'to enable schema scripts: $preview',
    );
  }
}
