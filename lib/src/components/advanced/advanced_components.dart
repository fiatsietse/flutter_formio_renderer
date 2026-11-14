import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../registry/component_renderer_builder.dart';
import '../../widgets/formio_field_wrapper.dart';
import '../../widgets/signature_pad.dart';
import '../../adapters/file_storage_adapter.dart';
import '../../models/schema/form_schema.dart';
import '../../widgets/formio_form.dart';

/// File upload component renderer with pluggable storage adapter.
Widget buildFile(FormioRenderContext ctx) {
  return FormioFieldWrapper(
    state: ctx.state,
    child: _FormioFileWidget(ctx: ctx),
  );
}

/// Signature capture component renderer.
Widget buildSignature(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  final isReadOnly = ctx.manager.options.readOnly || ctx.state.disabled;
  final height = (comp.rawJson['height'] as num?)?.toDouble() ?? 160.0;

  return FormioFieldWrapper(
    state: ctx.state,
    child: FormioSignaturePad(
      initialDataUrl: ctx.value?.toString(),
      readOnly: isReadOnly,
      height: height,
      onChanged: (dataUrl) => ctx.setValue(dataUrl),
    ),
  );
}

/// Nested subform component renderer.
Widget buildNestedForm(FormioRenderContext ctx) {
  return FormioFieldWrapper(
    state: ctx.state,
    child: _FormioNestedFormWidget(ctx: ctx),
  );
}

// ---------------- Helpers ----------------

class _FormioFileWidget extends StatefulWidget {
  final FormioRenderContext ctx;

  const _FormioFileWidget({required this.ctx});

  @override
  State<_FormioFileWidget> createState() => _FormioFileWidgetState();
}

class _FormioFileWidgetState extends State<_FormioFileWidget> {
  double? _uploadProgress;
  String? _uploadError;

  @override
  Widget build(BuildContext context) {
    final comp = widget.ctx.state.schema;
    final isReadOnly =
        widget.ctx.manager.options.readOnly || widget.ctx.state.disabled;
    final adapter = widget.ctx.manager.options.fileStorageAdapter ??
        MockFileStorageAdapter();

    final rawVal = widget.ctx.value;
    final fileList = <FormioFileMetadata>[];
    if (rawVal is List) {
      for (final item in rawVal) {
        if (item is Map) {
          fileList.add(
              FormioFileMetadata.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_uploadProgress != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: LinearProgressIndicator(value: _uploadProgress),
          ),
          Text('Uploading... ${(_uploadProgress! * 100).toInt()}%',
              style: const TextStyle(fontSize: 12)),
        ],
        if (_uploadError != null)
          Text(_uploadError!,
              style: const TextStyle(color: Colors.red, fontSize: 12)),
        for (final file in fileList)
          ListTile(
            dense: true,
            leading: const Icon(Icons.insert_drive_file),
            title: Text(file.name),
            subtitle: Text('${(file.size / 1024).toStringAsFixed(1)} KB'),
            trailing: isReadOnly
                ? null
                : IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      await adapter.deleteFile(file);
                      final updated = fileList
                          .where((f) => f.name != file.name)
                          .map((f) => f.toJson())
                          .toList();
                      widget.ctx.setValue(updated);
                    },
                  ),
          ),
        if (!isReadOnly) ...[
          const SizedBox(height: 6),
          OutlinedButton.icon(
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Upload File'),
            onPressed: _uploadProgress != null
                ? null
                : () async {
                    // Simulate file pick & upload
                    setState(() {
                      _uploadProgress = 0.1;
                      _uploadError = null;
                    });
                    try {
                      final dummyBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
                      final meta = await adapter.uploadFile(
                        FormioUploadRequest(
                          name:
                              'document_${DateTime.now().millisecondsSinceEpoch}.pdf',
                          size: 15360,
                          type: 'application/pdf',
                          bytes: dummyBytes,
                          componentConfig: comp.rawJson,
                        ),
                        onProgress: (p) {
                          if (mounted) setState(() => _uploadProgress = p);
                        },
                      );
                      final updated = [
                        ...fileList.map((f) => f.toJson()),
                        meta.toJson()
                      ];
                      widget.ctx.setValue(updated);
                      if (mounted) setState(() => _uploadProgress = null);
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _uploadProgress = null;
                          _uploadError = e.toString();
                        });
                      }
                    }
                  },
          ),
        ],
      ],
    );
  }
}

class _FormioNestedFormWidget extends StatefulWidget {
  final FormioRenderContext ctx;

  const _FormioNestedFormWidget({required this.ctx});

  @override
  State<_FormioNestedFormWidget> createState() =>
      _FormioNestedFormWidgetState();
}

class _FormioNestedFormWidgetState extends State<_FormioNestedFormWidget> {
  FormioFormSchema? _subformSchema;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubform();
  }

  Future<void> _loadSubform() async {
    final comp = widget.ctx.state.schema;
    final formId =
        comp.rawJson['form']?.toString() ?? comp.rawJson['src']?.toString();
    final resolver = widget.ctx.manager.options.subformResolver;

    if (resolver != null && formId != null && formId.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final schema = await resolver.resolveSubform(formId);
        if (mounted) {
          setState(() {
            _subformSchema = schema;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      }
      return;
    }

    // Direct embedded components
    if (comp.components.isNotEmpty) {
      _subformSchema = FormioFormSchema(components: comp.components);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LinearProgressIndicator();
    }
    if (_error != null) {
      return Text('Subform load error: $_error',
          style: const TextStyle(color: Colors.red));
    }
    if (_subformSchema == null) {
      return const Text('No subform configured');
    }

    final currentData = widget.ctx.value is Map
        ? Map<String, dynamic>.from(widget.ctx.value as Map)
        : <String, dynamic>{};

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey.shade200),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: FormioForm(
        schema: _subformSchema!,
        initialData: currentData,
        readOnly: widget.ctx.manager.options.readOnly,
        options: widget.ctx.manager.options,
        onChange: (subData) {
          widget.ctx.setValue(subData);
        },
      ),
    );
  }
}
