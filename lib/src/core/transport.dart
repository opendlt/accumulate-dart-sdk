/* Enhanced Transport with:
 * - Configurable User-Agent header
 * - Retries with exponential backoff for transient network errors
 * - Respect AccumulateOptions.timeoutMs and headers
 */
import "dart:async";
import "dart:convert";
import "dart:io";
import "package:http/http.dart" as http;
import "../json_rpc_client.dart" as gen; // keep generated internal
import "options.dart";

/// Hardened transport wrapper over generated JsonRpcClient.
class Transport {
  final gen.JsonRpcClient _inner;
  final AccumulateOptions _opts;
  final String _userAgent;

  Transport(String serverUrl, this._opts)
      : _userAgent = "opendlt-accumulate-dart/1.0.0",
        _inner = gen.JsonRpcClient(serverUrl, httpClient: _decorateHttp(_opts));

  static http.Client _decorateHttp(AccumulateOptions opts) {
    final base = opts.httpClient ?? http.Client();
    return _HeaderClient(base, {
      "User-Agent": "opendlt-accumulate-dart/1.0.0",
      ...opts.headers,
    });
  }

  Future<T> _withRetry<T>(Future<T> Function() run,
      {int maxRetries = 3,
      Duration baseDelay = const Duration(milliseconds: 200)}) async {
    int attempt = 0;
    while (true) {
      try {
        final fut = run();
        return await fut.timeout(Duration(milliseconds: _opts.timeoutMs));
      } on TimeoutException catch (_) {
        if (++attempt > maxRetries) rethrow;
      } on SocketException catch (_) {
        if (++attempt > maxRetries) rethrow;
      } on HttpException catch (_) {
        if (++attempt > maxRetries) rethrow;
      }
      await Future.delayed(baseDelay * (1 << (attempt - 1)));
    }
  }

  Future<dynamic> call(String method, [dynamic params]) async {
    return _withRetry(() => _inner.call(method, params));
  }

  Future<List<dynamic>> batch(List<gen.JsonRpcRequest> requests) async {
    return _withRetry(() => _inner.batch(requests));
  }

  void close() => _inner.close();
}

class _HeaderClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> _headers;
  _HeaderClient(this._inner, this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    _headers.forEach((k, v) => request.headers.putIfAbsent(k, () => v));
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
