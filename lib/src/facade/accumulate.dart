import "../core/options.dart";
import "../core/endpoints.dart";
import "../v2/client_v2.dart";
import "../v3/client_v3.dart";

export "../core/options.dart";
export "../v2/client_v2.dart";
export "../v3/client_v3.dart";
export "../core/endpoints.dart";

/// High-level Accumulate facade exposing both V2 and V3.
/// - Defaults: `submit()` and `query()` route to V3.
/// - V2 is available via the `.v2` property for legacy or specialized flows.
class Accumulate {
  final AccumulateV2 v2;
  final AccumulateV3 v3;

  Accumulate._(this.v2, this.v3);

  /// Construct a client for a well-known network (mainnet/testnet/devnet).
  factory Accumulate.network(
    NetworkEndpoint endpoint, {
    AccumulateOptions v2 = const AccumulateOptions(),
    AccumulateOptions v3 = const AccumulateOptions(),
  }) {
    return Accumulate._(
      AccumulateV2.network(endpoint, opts: v2),
      AccumulateV3.network(endpoint, opts: v3),
    );
  }

  /// Construct clients with explicit endpoints (usually only needed for bespoke envs).
  factory Accumulate.custom({
    required String v2Endpoint,
    required String v3Endpoint,
    AccumulateOptions v2 = const AccumulateOptions(),
    AccumulateOptions v3 = const AccumulateOptions(),
  }) {
    return Accumulate._(
      AccumulateV2.custom(v2Endpoint, opts: v2),
      AccumulateV3.custom(v3Endpoint, opts: v3),
    );
  }

  /// Preferred submission path → V3 submit (envelope with header/body/signature).
  Future<dynamic> submit(Map<String, dynamic> envelope) =>
      this.v3.submit(envelope);

  /// Preferred query path → V3 query (rich query model).
  Future<dynamic> query(Map<String, dynamic> request) => this.v3.query(request);

  /// V2 legacy execute-direct (envelope) available here if needed.
  Future<dynamic> executeDirect(Map<String, dynamic> envelope) =>
      this.v2.executeDirect(envelope);

  void close() {
    v2.close();
    v3.close();
  }
}
