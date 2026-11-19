import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import '../models/schema/select_option.dart';

/// Request parameters sent to [FormioRemoteOptionsAdapter].
@immutable
class RemoteOptionsRequest {
  /// The URL or endpoint configured in the select component.
  final String url;

  /// Optional query search string typed by user.
  final String? query;

  /// Optional page number for paginated endpoints.
  final int page;

  /// Optional page size limit.
  final int limit;

  /// Current form submission data (for dependent dropdown query interpolation).
  final Map<String, dynamic> formData;

  /// Current row data if inside a grid.
  final Map<String, dynamic> rowData;

  /// JSON property path to extract the stored value from each remote item.
  final String? valueProperty;

  /// Template or property for the display label (e.g. '{{ item.name }}' or 'name').
  final String? selectValues;

  /// Form.io template used to display each remote item.
  final String? template;

  const RemoteOptionsRequest({
    required this.url,
    this.query,
    this.page = 1,
    this.limit = 50,
    this.formData = const {},
    this.rowData = const {},
    this.valueProperty,
    this.selectValues,
    this.template,
  });
}

/// Response returned from [FormioRemoteOptionsAdapter].
@immutable
class RemoteOptionsResponse {
  /// The list of resolved options.
  final List<SelectOption> options;

  /// Whether more items can be loaded (for infinite scroll / pagination).
  final bool hasMore;

  /// Total count of items if reported by server.
  final int? totalCount;

  const RemoteOptionsResponse({
    required this.options,
    this.hasMore = false,
    this.totalCount,
  });

  static const RemoteOptionsResponse empty = RemoteOptionsResponse(options: []);
}

/// Adapter interface for fetching remote options for Select components.
abstract class FormioRemoteOptionsAdapter {
  /// Fetches options for the given [request].
  ///
  /// Must support cancellation via the returned Future and honor host auth tokens.
  Future<RemoteOptionsResponse> fetchOptions(RemoteOptionsRequest request);
}

/// Fetches remote select options with an HTTP GET request.
///
/// Relative URLs require [baseUrl]. Supply a custom [client] or headers when
/// the endpoint requires authentication or a specialized HTTP configuration.
class FormioHttpRemoteOptionsAdapter implements FormioRemoteOptionsAdapter {
  final http.Client? client;
  final String? baseUrl;
  final Map<String, String> headers;

  const FormioHttpRemoteOptionsAdapter({
    this.client,
    this.baseUrl,
    this.headers = const {},
  });

  @override
  Future<RemoteOptionsResponse> fetchOptions(
      RemoteOptionsRequest request) async {
    final requestUri = Uri.parse(request.url);
    final uri = requestUri.hasScheme
        ? requestUri
        : baseUrl == null
            ? throw ArgumentError.value(
                request.url, 'request.url', 'Must be an absolute URL')
            : Uri.parse(baseUrl!).resolveUri(requestUri);
    final response = client == null
        ? await http.get(uri, headers: headers)
        : await client!.get(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'Failed to load select options (${response.statusCode})',
        uri,
      );
    }

    final decoded = jsonDecode(response.body);
    final items = decoded is List
        ? decoded
        : decoded is Map && decoded['data'] is List
            ? decoded['data'] as List
            : decoded is Map && decoded['items'] is List
                ? decoded['items'] as List
                : throw const FormatException(
                    'Expected a JSON array of select options');

    final options = items.map((item) {
      if (item is! Map) return SelectOption.fromJson(item);
      final raw = Map<String, dynamic>.from(item);
      final fallback = SelectOption.fromJson(raw);
      final value = _readProperty(raw, request.valueProperty) ?? fallback.value;
      final label = _resolveLabel(raw, request.template) ?? fallback.label;
      return SelectOption(
        label: label,
        value: value,
        disabled: raw['disabled'] == true,
        raw: raw,
      );
    }).toList();

    return RemoteOptionsResponse(
      options: options,
      hasMore: false,
      totalCount: options.length,
    );
  }

  static dynamic _readProperty(Map<String, dynamic> item, String? path) {
    if (path == null || path.isEmpty) return null;
    dynamic value = item;
    for (final part in path.split('.')) {
      if (value is! Map || !value.containsKey(part)) return null;
      value = value[part];
    }
    return value;
  }

  static String? _resolveLabel(Map<String, dynamic> item, String? template) {
    if (template == null || template.isEmpty) return null;
    final interpolated = template.replaceAllMapped(
      RegExp(r'\{\{\s*(?:item\.)?([\w.]+)\s*\}\}'),
      (match) => _readProperty(item, match.group(1))?.toString() ?? '',
    );
    final label = interpolated.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    return label.isEmpty ? null : label;
  }
}

/// In-memory / mock adapter useful for testing and offline examples.
class MockRemoteOptionsAdapter implements FormioRemoteOptionsAdapter {
  final Map<String, List<SelectOption>> _datasets;
  final Duration latency;

  MockRemoteOptionsAdapter(this._datasets,
      {this.latency = const Duration(milliseconds: 50)});

  @override
  Future<RemoteOptionsResponse> fetchOptions(
      RemoteOptionsRequest request) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    // Match endpoint or url substring
    final key = _datasets.keys.firstWhere(
      (k) => request.url.contains(k),
      orElse: () => '',
    );
    if (key.isEmpty) {
      return RemoteOptionsResponse.empty;
    }
    var list = _datasets[key] ?? [];
    if (request.query != null && request.query!.isNotEmpty) {
      final q = request.query!.toLowerCase();
      list = list.where((opt) => opt.label.toLowerCase().contains(q)).toList();
    }
    return RemoteOptionsResponse(
        options: list, hasMore: false, totalCount: list.length);
  }
}
