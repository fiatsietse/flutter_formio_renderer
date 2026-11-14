import 'dart:async';
import 'dart:typed_data';
import 'package:meta/meta.dart';

/// Metadata representing an uploaded file in a Form.io submission.
@immutable
class FormioFileMetadata {
  /// File display name.
  final String name;

  /// File size in bytes.
  final int size;

  /// MIME type (e.g. 'image/png', 'application/pdf').
  final String type;

  /// Storage provider identifier (e.g. 'url', 's3', 'base64', 'mock').
  final String storage;

  /// Download or preview URL if available.
  final String? url;

  /// Optional base64 or custom payload data.
  final dynamic data;

  /// Original raw metadata if restored from existing submission.
  final Map<String, dynamic> raw;

  const FormioFileMetadata({
    required this.name,
    required this.size,
    required this.type,
    this.storage = 'url',
    this.url,
    this.data,
    this.raw = const {},
  });

  factory FormioFileMetadata.fromJson(Map<String, dynamic> json) {
    return FormioFileMetadata(
      name: json['name']?.toString() ?? 'file',
      size: (json['size'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'application/octet-stream',
      storage: json['storage']?.toString() ?? 'url',
      url: json['url']?.toString(),
      data: json['data'],
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'size': size,
      'type': type,
      'storage': storage,
      if (url != null) 'url': url,
      if (data != null) 'data': data,
      ...raw,
    };
  }

  @override
  String toString() => 'FormioFileMetadata($name, size=$size, type=$type)';
}

/// Request to upload a file through [FormioFileStorageAdapter].
class FormioUploadRequest {
  final String name;
  final int size;
  final String type;
  final Uint8List bytes;
  final Map<String, dynamic> componentConfig;

  const FormioUploadRequest({
    required this.name,
    required this.size,
    required this.type,
    required this.bytes,
    this.componentConfig = const {},
  });
}

/// Pluggable interface for file upload and storage.
abstract class FormioFileStorageAdapter {
  /// Uploads a file, providing progress updates (0.0 to 1.0).
  Future<FormioFileMetadata> uploadFile(
    FormioUploadRequest request, {
    void Function(double progress)? onProgress,
  });

  /// Deletes a previously uploaded file.
  Future<void> deleteFile(FormioFileMetadata file);
}

/// In-memory mock storage adapter for tests and example application.
class MockFileStorageAdapter implements FormioFileStorageAdapter {
  final List<FormioFileMetadata> uploadedFiles = [];
  final Duration uploadLatency;

  MockFileStorageAdapter(
      {this.uploadLatency = const Duration(milliseconds: 200)});

  @override
  Future<FormioFileMetadata> uploadFile(
    FormioUploadRequest request, {
    void Function(double progress)? onProgress,
  }) async {
    // Simulate upload progression
    onProgress?.call(0.25);
    await Future<void>.delayed(uploadLatency ~/ 3);
    onProgress?.call(0.75);
    await Future<void>.delayed(uploadLatency ~/ 3);
    onProgress?.call(1.0);

    final metadata = FormioFileMetadata(
      name: request.name,
      size: request.size,
      type: request.type,
      storage: 'mock',
      url: 'https://storage.mock.local/${request.name}',
    );
    uploadedFiles.add(metadata);
    return metadata;
  }

  @override
  Future<void> deleteFile(FormioFileMetadata file) async {
    uploadedFiles.removeWhere((f) => f.name == file.name);
  }
}
