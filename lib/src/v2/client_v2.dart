import "../core/options.dart";
import "../core/endpoints.dart";
import "../core/transport.dart";

/// Accumulate V2 client wrapper.
/// Uses the /v2 endpoint and provides convenience for v2-specific calls.
/// NOTE: We avoid importing generated types publicly; expose Map<String,dynamic> where practical.
class AccumulateV2 {
  final Transport _tx;

  /// Build a V2 client using a network and options.
  factory AccumulateV2.network(NetworkEndpoint endpoint,
      {AccumulateOptions opts = const AccumulateOptions()}) {
    final url = endpoint.v2();
    return AccumulateV2.custom(url, opts: opts);
  }

  /// Build a V2 client with explicit endpoint (e.g., "https://host/v2").
  AccumulateV2.custom(String v2Endpoint,
      {AccumulateOptions opts = const AccumulateOptions()})
      : _tx = Transport(v2Endpoint, opts);

  /// Raw JSON-RPC call escape hatch for v2 (method names are v2).
  Future<dynamic> rawCall(String method, [dynamic params]) =>
      _tx.call(method, params);

  /// Submit via v2 "execute-direct" (envelope).
  /// `params` should be the v2 ExecuteRequest JSON map (envelope).
  Future<dynamic> executeDirect(Map<String, dynamic> params) =>
      _tx.call("execute-direct", params);

  /// Faucet (v2)
  Future<dynamic> faucet(Map<String, dynamic> params) =>
      _tx.call("faucet", params);

  /// Common v2 queries (typed variants exist in generated client; we keep raw for stability).
  Future<dynamic> queryTx(Map<String, dynamic> params) =>
      _tx.call("query-tx", params);
  Future<dynamic> queryTxLocal(Map<String, dynamic> params) =>
      _tx.call("query-tx-local", params);
  Future<dynamic> queryDirectory(Map<String, dynamic> params) =>
      _tx.call("query-directory", params);
  Future<dynamic> queryData(Map<String, dynamic> params) =>
      _tx.call("query-data", params);
  Future<dynamic> queryDataSet(Map<String, dynamic> params) =>
      _tx.call("query-data-set", params);
  Future<dynamic> queryMinorBlocks(Map<String, dynamic> params) =>
      _tx.call("query-minor-blocks", params);
  Future<dynamic> queryMajorBlocks(Map<String, dynamic> params) =>
      _tx.call("query-major-blocks", params);
  Future<dynamic> status() => _tx.call("status", {});
  Future<dynamic> version() => _tx.call("version", {});

  void close() => _tx.close();
}
