import 'dart:async';
import 'package:meta/meta.dart';
import '../models/submission/data_path.dart';

/// Request parameters for asynchronous validation.
@immutable
class AsyncValidationRequest {
  final String componentKey;
  final DataPath dataPath;
  final dynamic value;
  final Map<String, dynamic> formData;
  final int requestId;

  const AsyncValidationRequest({
    required this.componentKey,
    required this.dataPath,
    required this.value,
    required this.formData,
    required this.requestId,
  });
}

/// Result returned from asynchronous validation.
@immutable
class AsyncValidationResult {
  final int requestId;
  final bool isValid;
  final String? errorMessage;

  const AsyncValidationResult({
    required this.requestId,
    required this.isValid,
    this.errorMessage,
  });

  static AsyncValidationResult valid(int requestId) =>
      AsyncValidationResult(requestId: requestId, isValid: true);

  static AsyncValidationResult invalid(int requestId, String message) =>
      AsyncValidationResult(
          requestId: requestId, isValid: false, errorMessage: message);
}

/// Interface for asynchronous validations (e.g. unique username / email checks against backend).
abstract class FormioAsyncValidator {
  Future<AsyncValidationResult> validate(AsyncValidationRequest request);
}
