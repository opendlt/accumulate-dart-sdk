/* Enhanced Transport with:
 * - Configurable User-Agent header
 * - Retries with exponential backoff for transient network errors
 * - Respect AccumulateOptions.timeoutMs and headers
 */
import "dart:async";
import "dart:io";
import "package:http/http.dart" as http;
import "../generated/api/json_rpc_client.dart" as gen; // keep generated internal
import "../generated/runtime/errors.dart" show JsonRpcErrorMapper, AccError;
import "options.dart";

/// Hardened transport wrapper over generated JsonRpcClient.
class Transport {
  final gen.JsonRpcClient _inner;
  final AccumulateOptions _opts;
  static const String _userAgent = "opendlt-accumulate-dart/1.0.0";

  Transport(String serverUrl, this._opts)
      : _inner = gen.JsonRpcClient(serverUrl, httpClient: _decorateHttp(_opts));

  static http.Client _decorateHttp(AccumulateOptions opts) {
    final base = opts.httpClient ?? http.Client();
    return _HeaderClient(base, {
      "User-Agent": _userAgent,
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
    try {
      return await _withRetry(() => _inner.call(method, params));
    } on gen.JsonRpcException catch (e) {
      throw _mapRpc(e);
    }
  }

  Future<List<dynamic>> batch(List<gen.JsonRpcRequest> requests) async {
    try {
      return await _withRetry(() => _inner.batch(requests));
    } on gen.JsonRpcException catch (e) {
      throw _mapRpc(e);
    }
  }

  /// Map a low-level JSON-RPC exception to the typed [AccError] taxonomy, so
  /// callers can `catch (ValidationError)` / `catch (ApiError)` etc. instead of
  /// pattern-matching on a flat exception. (Wires the previously-unused
  /// JsonRpcErrorMapper into the live path.)
  AccError _mapRpc(gen.JsonRpcException e) {
    final data = e.data is Map<String, dynamic> ? e.data as Map<String, dynamic> : null;
    return JsonRpcErrorMapper.mapRpcError({
      "code": e.code,
      "message": e.message,
      "data": data,
    });
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
