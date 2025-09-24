import "../core/options.dart";
import "../core/endpoints.dart";
import "../core/transport.dart";

/// Accumulate V3 client wrapper.
/// Uses the /v3 endpoint and provides v3-first convenience methods.
/// We model everything as Map<String,dynamic> inputs/outputs to decouple from generated types.
class AccumulateV3 {
  final Transport _tx;

  /// Build a V3 client using a network and options.
  factory AccumulateV3.network(NetworkEndpoint endpoint,
      {AccumulateOptions opts = const AccumulateOptions()}) {
    final url = endpoint.v3();
    return AccumulateV3.custom(url, opts: opts);
  }

  /// Build a V3 client with explicit endpoint (e.g., "https://host/v3").
  AccumulateV3.custom(String v3Endpoint,
      {AccumulateOptions opts = const AccumulateOptions()})
      : _tx = Transport(v3Endpoint, opts);

  /// Raw JSON-RPC call escape hatch for v3 methods.
  Future<dynamic> rawCall(String method, [dynamic params]) =>
      _tx.call(method, params);

  /// V3 primary entrypoints
  Future<dynamic> submit(Map<String, dynamic> envelope) =>
      _tx.call("submit", envelope);
  Future<dynamic> submitMulti(Map<String, dynamic> body) =>
      _tx.call("submit-multi", body);
  Future<dynamic> query(Map<String, dynamic> request) =>
      _tx.call("query", request);
  Future<dynamic> queryBlock(Map<String, dynamic> request) =>
      _tx.call("query-block", request);
  Future<dynamic> queryChain(Map<String, dynamic> request) =>
      _tx.call("query-chain", request);

  void close() => _tx.close();
}
