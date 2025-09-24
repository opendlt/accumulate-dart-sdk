import "package:http/http.dart" as http;

/// Options for constructing clients (timeouts, headers, custom http client).
class AccumulateOptions {
  /// Request timeout in milliseconds (default: 30000).
  final int timeoutMs;

  /// Extra headers to send with every request.
  final Map<String, String> headers;

  /// Optional custom HTTP client (caller-owned). If null, SDK owns its client.
  final http.Client? httpClient;

  const AccumulateOptions({
    this.timeoutMs = 30000,
    this.headers = const {},
    this.httpClient,
  });

  AccumulateOptions copyWith({
    int? timeoutMs,
    Map<String, String>? headers,
    http.Client? httpClient,
  }) =>
      AccumulateOptions(
        timeoutMs: timeoutMs ?? this.timeoutMs,
        headers: headers ?? this.headers,
        httpClient: httpClient ?? this.httpClient,
      );
}
