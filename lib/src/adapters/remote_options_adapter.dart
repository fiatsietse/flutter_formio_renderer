import 'dart:async';
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

  /// JSON property path to extract the label from each remote item (e.g. 'name' or 'label').
  final String? valueProperty;

  /// Template or property for the display label (e.g. '{{ item.name }}' or 'name').
  final String? selectValues;

  const RemoteOptionsRequest({
    required this.url,
    this.query,
    this.page = 1,
    this.limit = 50,
    this.formData = const {},
    this.rowData = const {},
    this.valueProperty,
    this.selectValues,
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
