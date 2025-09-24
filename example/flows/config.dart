import "dart:io";
import "package:opendlt_accumulate/opendlt_accumulate.dart";

class FlowConfig {
  final String v2;
  final String v3;

  FlowConfig._(this.v2, this.v3);

  factory FlowConfig.fromEnv() {
    final net = (Platform.environment["ACC_NET"] ?? "testnet").toLowerCase();
    final ep = net == "mainnet"
        ? NetworkEndpoint.mainnet
        : net == "devnet"
            ? NetworkEndpoint.devnet
            : NetworkEndpoint.testnet;
    return FlowConfig._(ep.v2(), ep.v3());
  }

  Accumulate make() => Accumulate.custom(
        v2Endpoint: v2,
        v3Endpoint: v3,
        v2: const AccumulateOptions(timeoutMs: 20000),
        v3: const AccumulateOptions(timeoutMs: 20000),
      );
}
