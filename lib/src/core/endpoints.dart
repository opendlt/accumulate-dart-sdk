/// Network endpoints for Accumulate.
enum NetworkEndpoint {
  mainnet("https://mainnet.accumulatenetwork.io"),
  testnet("https://testnet.accumulatenetwork.io"),
  devnet("http://localhost:26660"); // adjust your local dev http port as needed

  final String baseUrl;
  const NetworkEndpoint(this.baseUrl);

  /// Full V2 JSON-RPC endpoint (…/v2)
  String v2() => "${baseUrl.trimEnd("/")}/v2";

  /// Full V3 JSON-RPC endpoint (…/v3)
  String v3() => "${baseUrl.trimEnd("/")}/v3";
}

extension _Trim on String {
  String trimEnd(String suffix) {
    if (endsWith(suffix)) return substring(0, length - suffix.length);
    return this;
  }
}
