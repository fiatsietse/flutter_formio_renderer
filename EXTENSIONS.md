# Custom Components and Adapters Guide

`flutter_formio_renderer` is designed with an extensible, modular architecture. You can register custom component renderers, override built-in inputs, connect backend search endpoints, and integrate enterprise file upload systems.

---

## 1. Registering Custom Components

To register a custom component or override an existing one, use `FormioComponentRegistry`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_formio_renderer/flutter_formio_renderer.dart';

Widget buildRatingBar(FormioRenderContext ctx) {
  final currentRating = (ctx.value as num?)?.toDouble() ?? 0.0;
  final isReadOnly = ctx.manager.options.readOnly || ctx.state.disabled;

  return FormioFieldWrapper(
    state: ctx.state,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            icon: Icon(
              i <= currentRating ? Icons.star : Icons.star_border,
              color: Colors.amber,
            ),
            onPressed: isReadOnly
                ? null
                : () {
                    ctx.setValue(i.toDouble());
                  },
          ),
      ],
    ),
  );
}

// In your application startup:
void configureCustomComponents() {
  FormioComponentRegistry.defaultRegistry.register('rating', buildRatingBar);
}
```

Now, any Form.io schema containing `"type": "rating"` will render your custom Flutter widget!

---

## 2. Remote Options Adapter (`FormioRemoteOptionsAdapter`)

Select components configured with `"dataSrc": "url"` use the built-in HTTP GET adapter for absolute URLs. Configure the adapter when the endpoint needs headers or uses a relative URL:

```dart
FormioOptions(
  remoteOptionsAdapter: FormioHttpRemoteOptionsAdapter(
    baseUrl: 'https://api.example.com',
    headers: {'Authorization': 'Bearer $token'},
  ),
);
```

Provide a custom adapter for other authentication or response formats:

```dart
class MyBackendOptionsAdapter implements FormioRemoteOptionsAdapter {
  final String authToken;

  MyBackendOptionsAdapter({required this.authToken});

  @override
  Future<RemoteOptionsResponse> fetchOptions(RemoteOptionsRequest request) async {
    // 1. Build endpoint URL with search queries & dependent form data
    final uri = Uri.parse(request.url);

    // 2. Perform HTTP request with your client (http / dio)
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $authToken',
    });

    final data = jsonDecode(response.body) as List;
    final options = data.map((item) => SelectOption(
      label: item['name'].toString(),
      value: item['id'],
    )).toList();

    return RemoteOptionsResponse(options: options);
  }
}
```

Pass the adapter via `FormioOptions`:

```dart
FormioForm(
  schema: schema,
  options: FormioOptions(
    remoteOptionsAdapter: MyBackendOptionsAdapter(authToken: userToken),
  ),
);
```

---

## 3. Pluggable File Storage (`FormioFileStorageAdapter`)

Form.io `file` components upload files and serialize metadata into the submission:

```dart
class S3FileStorageAdapter implements FormioFileStorageAdapter {
  @override
  Future<FormioFileMetadata> uploadFile(
    FormioUploadRequest request, {
    void Function(double progress)? onProgress,
  }) async {
    // 1. Upload bytes to S3 presigned URL with progress reporting:
    // onProgress?.call(0.5);

    return FormioFileMetadata(
      name: request.name,
      size: request.size,
      type: request.type,
      storage: 's3',
      url: 'https://my-bucket.s3.amazonaws.com/${request.name}',
    );
  }

  @override
  Future<void> deleteFile(FormioFileMetadata file) async {
    // Delete from storage
  }
}
```

---

## 4. Subform Resolver (`FormioSubformResolver`)

When using nested forms (`form` component), implement `FormioSubformResolver` to resolve child schemas by ID:

```dart
class ApiSubformResolver implements FormioSubformResolver {
  @override
  Future<FormioFormSchema?> resolveSubform(String formIdOrPath) async {
    final response = await http.get(Uri.parse('https://api.myformserver.com/form/$formIdOrPath'));
    return FormioFormSchema.parse(response.body);
  }
}
```

---

## 5. Asynchronous Field Validation (`FormioAsyncValidator`)

Validate fields against a live database (e.g. unique username checks):

```dart
class UsernameAsyncValidator implements FormioAsyncValidator {
  @override
  Future<AsyncValidationResult> validate(AsyncValidationRequest request) async {
    if (request.componentKey == 'username') {
      final isAvailable = await checkUsernameAvailability(request.value.toString());
      if (!isAvailable) {
        return AsyncValidationResult.invalid(
          request.requestId,
          'This username is already taken.',
        );
      }
    }
    return AsyncValidationResult.valid(request.requestId);
  }
}
```
