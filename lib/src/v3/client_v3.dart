import "../core/options.dart";
import "../core/endpoints.dart";
import "../core/transport.dart";

// ============================================================
// V3 API OPTIONS CLASSES
// ============================================================
// Matches Go: pkg/api/v3/types_gen.go

/// Options for submit requests
///
/// Matches Go: pkg/api/v3/types_gen.go SubmitOptions
class SubmitOptions {
  /// Verifies that the envelope is well formed before submitting (default yes)
  final bool? verify;

  /// Waits until the envelope is accepted into a block or rejected (default yes)
  final bool? wait;

  const SubmitOptions({this.verify, this.wait});

  Map<String, dynamic> toJson() => {
        if (verify != null) "verify": verify,
        if (wait != null) "wait": wait,
      };
}

/// Options for validate requests
///
/// Matches Go: pkg/api/v3/types_gen.go ValidateOptions
class ValidateOptions {
  /// Fully validates the signatures and transactions (default yes)
  final bool? full;

  const ValidateOptions({this.full});

  Map<String, dynamic> toJson() => {
        if (full != null) "full": full,
      };
}

/// Options for faucet requests
///
/// Matches Go: pkg/api/v3/types_gen.go FaucetOptions
class FaucetOptions {
  /// Optional token URL (defaults to ACME)
  final String? token;

  const FaucetOptions({this.token});

  Map<String, dynamic> toJson() => {
        if (token != null) "token": token,
      };
}

/// Options for node info requests
///
/// Matches Go: pkg/api/v3/types_gen.go NodeInfoOptions
class NodeInfoOptions {
  /// Optional peer ID to query specific peer
  final String? peerID;

  const NodeInfoOptions({this.peerID});

  Map<String, dynamic> toJson() => {
        if (peerID != null) "peerID": peerID,
      };
}

/// Service address for findService
///
/// Matches Go: pkg/api/v3/types_gen.go ServiceAddress
class ServiceAddress {
  /// Service type (e.g., "query", "submit", "node")
  final String type;

  /// Optional argument (e.g., partition name)
  final String? argument;

  const ServiceAddress({required this.type, this.argument});

  Map<String, dynamic> toJson() => {
        "type": type,
        if (argument != null) "argument": argument,
      };
}

/// Options for findService requests
///
/// Matches Go: pkg/api/v3/types_gen.go FindServiceOptions
class FindServiceOptions {
  /// Network name to search
  final String network;

  /// Service address to find
  final ServiceAddress service;

  /// Restrict results to known peers
  final bool? known;

  /// Timeout when querying DHT (in milliseconds)
  final int? timeoutMs;

  const FindServiceOptions({
    required this.network,
    required this.service,
    this.known,
    this.timeoutMs,
  });

  Map<String, dynamic> toJson() => {
        "network": network,
        "service": service.toJson(),
        if (known != null) "known": known,
        if (timeoutMs != null) "timeout": timeoutMs,
      };
}

/// Options for consensus status requests
///
/// Matches Go: pkg/api/v3/types_gen.go ConsensusStatusOptions
class ConsensusStatusOptions {
  /// Node ID to query
  final String nodeID;

  /// Partition name
  final String partition;

  /// Include peer information
  final bool? includePeers;

  /// Include Accumulate-specific information
  final bool? includeAccumulate;

  const ConsensusStatusOptions({
    required this.nodeID,
    required this.partition,
    this.includePeers,
    this.includeAccumulate,
  });

  Map<String, dynamic> toJson() => {
        "nodeID": nodeID,
        "partition": partition,
        if (includePeers != null) "includePeers": includePeers,
        if (includeAccumulate != null) "includeAccumulate": includeAccumulate,
      };
}

/// Options for network status requests
///
/// Matches Go: pkg/api/v3/types_gen.go NetworkStatusOptions
class NetworkStatusOptions {
  /// Partition name to query
  final String partition;

  const NetworkStatusOptions({required this.partition});

  Map<String, dynamic> toJson() => {
        "partition": partition,
      };
}

/// Options for list snapshots requests
///
/// Matches Go: pkg/api/v3/types_gen.go ListSnapshotsOptions
class ListSnapshotsOptions {
  /// Node ID to query
  final String nodeID;

  /// Partition name
  final String partition;

  const ListSnapshotsOptions({required this.nodeID, required this.partition});

  Map<String, dynamic> toJson() => {
        "nodeID": nodeID,
        "partition": partition,
      };
}

/// Options for metrics requests
///
/// Matches Go: pkg/api/v3/types_gen.go MetricsOptions
class MetricsOptions {
  /// Partition name to query
  final String partition;

  /// Span sets the width of the window in blocks
  final int? span;

  const MetricsOptions({required this.partition, this.span});

  Map<String, dynamic> toJson() => {
        "partition": partition,
        if (span != null) "span": span,
      };
}

/// Options for subscribe (event streaming) requests
///
/// Matches Go: pkg/api/v3/types_gen.go SubscribeOptions
class SubscribeOptions {
  /// Partition to subscribe to events from
  final String? partition;

  /// Specific account to watch
  final String? account;

  const SubscribeOptions({this.partition, this.account});

  Map<String, dynamic> toJson() => {
        if (partition != null) "partition": partition,
        if (account != null) "account": account,
      };
}

/// Range options for paginated queries
///
/// Matches Go: pkg/api/v3/types_gen.go RangeOptions
class RangeOptions {
  /// Starting index
  final int? start;

  /// Number of requested results
  final int? count;

  /// Request expanded results
  final bool? expand;

  /// Start from end
  final bool? fromEnd;

  const RangeOptions({this.start, this.count, this.expand, this.fromEnd});

  Map<String, dynamic> toJson() => {
        if (start != null) "start": start,
        if (count != null) "count": count,
        if (expand != null) "expand": expand,
        if (fromEnd != null) "fromEnd": fromEnd,
      };
}

// ============================================================
// V3 CLIENT
// ============================================================

/// Accumulate V3 client wrapper.
/// Uses the /v3 endpoint and provides v3-first convenience methods.
/// Implements all Go core API v3 services.
///
/// Matches Go: pkg/api/v3/api.go
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

  // ============================================================
  // SUBMITTER SERVICE
  // ============================================================
  // Matches Go: pkg/api/v3/api.go Submitter interface

  /// Submit an envelope for execution.
  ///
  /// Matches Go: Submitter.Submit()
  Future<dynamic> submit(Map<String, dynamic> envelope,
      {SubmitOptions? options}) {
    final params = Map<String, dynamic>.from(envelope);
    if (options != null) {
      params.addAll(options.toJson());
    }
    return _tx.call("submit", params);
  }

  /// Submit multiple envelopes for execution.
  Future<dynamic> submitMulti(Map<String, dynamic> body) =>
      _tx.call("submit-multi", body);

  // ============================================================
  // VALIDATOR SERVICE
  // ============================================================
  // Matches Go: pkg/api/v3/api.go Validator interface

  /// Pre-validate a transaction without submitting.
  ///
  /// Checks if an envelope is expected to succeed.
  /// Matches Go: Validator.Validate()
  Future<dynamic> validate(Map<String, dynamic> envelope,
      {ValidateOptions? options}) {
    final params = Map<String, dynamic>.from(envelope);
    if (options != null) {
      params.addAll(options.toJson());
    }
    return _tx.call("validate", params);
  }

  // ============================================================
  // QUERIER SERVICE
  // ============================================================
  // Matches Go: pkg/api/v3/api.go Querier interface

  /// Query the state of an account or transaction.
  ///
  /// Matches Go: Querier.Query()
  Future<dynamic> query(Map<String, dynamic> request) =>
      _tx.call("query", request);

  /// Query a specific block.
  Future<dynamic> queryBlock(Map<String, dynamic> request) =>
      _tx.call("query-block", request);

  /// Query a chain.
  Future<dynamic> queryChain(Map<String, dynamic> request) =>
      _tx.call("query-chain", request);

  // ============================================================
  // FAUCET SERVICE
  // ============================================================
  // Matches Go: pkg/api/v3/api.go Faucet interface

  /// Request tokens from the faucet (testnet only).
  ///
  /// Matches Go: Faucet.Faucet()
  Future<dynamic> faucet(String accountUrl, {FaucetOptions? options}) {
    final params = <String, dynamic>{"account": accountUrl};
    if (options != null) {
      params.addAll(options.toJson());
    }
    return _tx.call("faucet", params);
  }

  // ============================================================
  // NODE SERVICE
  // ============================================================
  // Matches Go: pkg/api/v3/api.go NodeService interface

  /// Get information about the network node.
  ///
  /// Matches Go: NodeService.NodeInfo()
  Future<dynamic> nodeInfo({NodeInfoOptions? options}) {
    final params = options?.toJson() ?? <String, dynamic>{};
    return _tx.call("node-info", params);
  }

  /// Search for nodes that provide a given service.
  ///
  /// Matches Go: NodeService.FindService()
  Future<dynamic> findService(FindServiceOptions options) {
    return _tx.call("find-service", options.toJson());
  }

  // ============================================================
  // CONSENSUS SERVICE
  // ============================================================
  // Matches Go: pkg/api/v3/api.go ConsensusService interface

  /// Get the status of the consensus node.
  ///
  /// Matches Go: ConsensusService.ConsensusStatus()
  Future<dynamic> consensusStatus(ConsensusStatusOptions options) {
    return _tx.call("consensus-status", options.toJson());
  }

  // ============================================================
  // NETWORK SERVICE
  // ============================================================
  // Matches Go: pkg/api/v3/api.go NetworkService interface

  /// Get the status of the network.
  ///
  /// Returns oracle, globals, network definition, routing table, etc.
  /// Matches Go: NetworkService.NetworkStatus()
  Future<dynamic> networkStatus(NetworkStatusOptions options) {
    return _tx.call("network-status", options.toJson());
  }

  // ============================================================
  // SNAPSHOT SERVICE
  // ============================================================
  // Matches Go: pkg/api/v3/api.go SnapshotService interface

  /// List available snapshots.
  ///
  /// Matches Go: SnapshotService.ListSnapshots()
  Future<dynamic> listSnapshots(ListSnapshotsOptions options) {
    return _tx.call("list-snapshots", options.toJson());
  }

  // ============================================================
  // METRICS SERVICE
  // ============================================================
  // Matches Go: pkg/api/v3/api.go MetricsService interface

  /// Get network metrics such as transactions per second.
  ///
  /// Matches Go: MetricsService.Metrics()
  Future<dynamic> metrics(MetricsOptions options) {
    return _tx.call("metrics", options.toJson());
  }

  // ============================================================
  // EVENT SERVICE
  // ============================================================
  // Matches Go: pkg/api/v3/api.go EventService interface
  //
  // Note: Full event streaming requires WebSocket support.
  // This provides a basic subscribe call; for production streaming,
  // use a WebSocket connection to the /v3/subscribe endpoint.

  /// Subscribe to event notifications.
  ///
  /// Note: This is a basic subscribe call. For continuous event streaming,
  /// use WebSocket connections directly.
  /// Matches Go: EventService.Subscribe()
  Future<dynamic> subscribe(SubscribeOptions options) {
    return _tx.call("subscribe", options.toJson());
  }

  /// Close the client and release resources.
  void close() => _tx.close();
}
