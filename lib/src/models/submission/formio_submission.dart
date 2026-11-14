import 'package:meta/meta.dart';

/// Represents a Form.io submission envelope or raw submission payload.
///
/// In standard Form.io REST conventions, submissions have the format:
/// ```json
/// {
///   "_id": "60a7e...",
///   "data": { "firstName": "Alice", "email": "alice@example.com" },
///   "metadata": { "timezone": "UTC" },
///   "state": "submitted"
/// }
/// ```
/// This class handles both full envelopes and raw `data` dictionaries.
@immutable
class FormioSubmission {
  /// The submission identifier, if assigned by server.
  final String? id;

  /// The form identifier, if associated.
  final String? formId;

  /// The submission data payload containing field keys and values.
  final Map<String, dynamic> data;

  /// Optional metadata such as client timezone, referrer, submission timestamp, etc.
  final Map<String, dynamic> metadata;

  /// Submission lifecycle state: usually 'submitted' or 'draft'.
  final String state;

  /// Optional creation or update timestamps.
  final DateTime? created;
  final DateTime? modified;

  const FormioSubmission({
    this.id,
    this.formId,
    required this.data,
    this.metadata = const {},
    this.state = 'submitted',
    this.created,
    this.modified,
  });

  /// Creates a [FormioSubmission] wrapping a raw form data map.
  factory FormioSubmission.fromData(Map<String, dynamic> data,
      {String state = 'submitted'}) {
    return FormioSubmission(
      data: Map<String, dynamic>.from(data),
      state: state,
    );
  }

  /// Parses a submission from a Map which might be a full envelope or raw data.
  factory FormioSubmission.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('data') && json['data'] is Map) {
      return FormioSubmission(
        id: json['_id'] as String? ?? json['id'] as String?,
        formId: json['form'] as String? ?? json['formId'] as String?,
        data: Map<String, dynamic>.from(json['data'] as Map),
        metadata: json['metadata'] is Map
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : const {},
        state: json['state'] as String? ?? 'submitted',
        created: json['created'] != null
            ? DateTime.tryParse(json['created'].toString())
            : null,
        modified: json['modified'] != null
            ? DateTime.tryParse(json['modified'].toString())
            : null,
      );
    } else {
      // Treat the entire map as the data payload
      return FormioSubmission(
        data: Map<String, dynamic>.from(json),
        state: 'submitted',
      );
    }
  }

  /// Serializes as a standard Form.io submission envelope.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'data': data,
      'state': state,
    };
    if (id != null) map['_id'] = id;
    if (formId != null) map['form'] = formId;
    if (metadata.isNotEmpty) map['metadata'] = metadata;
    if (created != null) map['created'] = created!.toIso8601String();
    if (modified != null) map['modified'] = modified!.toIso8601String();
    return map;
  }

  /// Creates a copy with optionally updated fields.
  FormioSubmission copyWith({
    String? id,
    String? formId,
    Map<String, dynamic>? data,
    Map<String, dynamic>? metadata,
    String? state,
    DateTime? created,
    DateTime? modified,
  }) {
    return FormioSubmission(
      id: id ?? this.id,
      formId: formId ?? this.formId,
      data: data ?? this.data,
      metadata: metadata ?? this.metadata,
      state: state ?? this.state,
      created: created ?? this.created,
      modified: modified ?? this.modified,
    );
  }

  @override
  String toString() => 'FormioSubmission(id: $id, state: $state, data: $data)';
}
