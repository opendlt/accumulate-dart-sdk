/// Network endpoints for Accumulate.
///
/// ## Security Considerations
///
/// **Production Networks (mainnet, testnet):**
/// - Always use HTTPS for production networks
/// - TLS encryption protects transaction data and signatures in transit
/// - Prevents man-in-the-middle attacks that could intercept private keys or modify transactions
///
/// **Development Network (devnet):**
/// - Uses HTTP by default for local development convenience
/// - **WARNING:** Never use HTTP endpoints in production environments
/// - HTTP traffic is unencrypted and vulnerable to interception
/// - Only acceptable when connecting to localhost or trusted local networks
///
/// **Custom Endpoints:**
/// - When using custom RPC endpoints, always prefer HTTPS
/// - For local DevNet containers, HTTP on localhost is acceptable
/// - Example: `http://127.0.0.1:26660` for local Docker DevNet
///
/// ## Example Usage
/// ```dart
/// // Production - uses HTTPS
/// final mainnetClient = Accumulate(NetworkEndpoint.mainnet.v3());
///
/// // Local development - HTTP acceptable for localhost
/// final devClient = Accumulate(NetworkEndpoint.devnet.v3());
///
/// // Custom secure endpoint
/// final customClient = Accumulate("https://my-secure-node.example.com/v3");
/// ```
enum NetworkEndpoint {
  /// Accumulate mainnet - production network with real ACME tokens.
  /// Uses HTTPS for secure communication.
  mainnet("https://mainnet.accumulatenetwork.io"),

  /// Accumulate testnet - test network for development and testing.
  /// Uses HTTPS for secure communication.
  testnet("https://testnet.accumulatenetwork.io"),

  /// Local development network.
  /// Uses HTTP which is acceptable ONLY for localhost connections.
  /// **Do not use HTTP for remote connections in production.**
  devnet("http://localhost:26660");

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
