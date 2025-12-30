import "dart:typed_data";
import "../v3/client_v3.dart";
import "../util/bytes.dart";
import "smart_signer.dart";
import "unified_keypair.dart";

/// Detailed key page state information
///
/// This class provides detailed information about a key page including
/// individual key details like delegate URLs and last used timestamps.
class KeyPageState {
  /// The key page URL
  final String url;

  /// Current version of the key page
  final int version;

  /// Credit balance
  final int creditBalance;

  /// Accept threshold for transactions
  final int acceptThreshold;

  /// List of keys on the page with detailed information
  final List<KeyEntry> keys;

  KeyPageState({
    required this.url,
    required this.version,
    required this.creditBalance,
    required this.acceptThreshold,
    required this.keys,
  });

  /// Check if a key hash is on this page
  bool hasKey(String keyHash) {
    final normalizedHash = keyHash.toLowerCase();
    return keys.any((k) => k.keyHash.toLowerCase() == normalizedHash);
  }

  /// Check if a unified key pair is on this page
  Future<bool> hasKeyPair(UnifiedKeyPair keypair) async {
    final hash = toHex(await keypair.publicKeyHash);
    return hasKey(hash);
  }

  @override
  String toString() {
    return "KeyPageState(url: $url, version: $version, credits: $creditBalance, "
        "threshold: $acceptThreshold, keys: ${keys.length})";
  }
}

/// Detailed information about a single key on a key page
class KeyEntry {
  /// The key hash (hex string)
  final String keyHash;

  /// Delegate URL if this is a delegated key
  final String? delegate;

  /// Last used timestamp (microseconds)
  final int? lastUsedOn;

  KeyEntry({
    required this.keyHash,
    this.delegate,
    this.lastUsedOn,
  });

  @override
  String toString() {
    return "KeyEntry(hash: $keyHash${delegate != null ? ", delegate: $delegate" : ""})";
  }
}

/// Helper class for managing keys on key pages
///
/// Provides convenient methods for:
/// - Querying key page state
/// - Adding/removing keys
/// - Managing thresholds
/// - Creating signers for keys on the page
///
/// Example usage:
/// ```dart
/// final manager = KeyManager(
///   client: client.v3,
///   keyPageUrl: "acc://myadi.acme/book/1",
/// );
///
/// // Query current state
/// final state = await manager.getKeyPageState();
/// print("Keys on page: ${state.keys.length}");
///
/// // Add a new key using an existing key to sign
/// final adminKey = UnifiedKeyPair.fromEd25519(myAdminKey);
/// await manager.addKey(adminKey, newKey);
///
/// // Create a signer for a key on this page
/// final signer = manager.createSigner(myKey);
/// ```
class KeyManager {
  final AccumulateV3 _client;
  final String _keyPageUrl;

  /// Create a key manager for a specific key page
  KeyManager({
    required AccumulateV3 client,
    required String keyPageUrl,
  })  : _client = client,
        _keyPageUrl = keyPageUrl;

  /// The key page URL this manager controls
  String get keyPageUrl => _keyPageUrl;

  /// Query the current key page state with detailed key information
  Future<KeyPageState> getKeyPageState() async {
    final result = await _client.rawCall("query", {
      "scope": _keyPageUrl,
      "query": {"queryType": "default"}
    });

    final account = result["account"] as Map<String, dynamic>;

    final keysRaw = account["keys"] as List? ?? [];
    final keys = keysRaw.map((k) {
      return KeyEntry(
        keyHash: k["publicKeyHash"]?.toString() ?? "",
        delegate: k["delegate"]?.toString(),
        lastUsedOn: k["lastUsedOn"] as int?,
      );
    }).toList();

    return KeyPageState(
      url: _keyPageUrl,
      version: account["version"] as int? ?? 1,
      creditBalance: account["creditBalance"] as int? ?? 0,
      acceptThreshold: account["acceptThreshold"] as int? ?? 1,
      keys: keys,
    );
  }

  /// Create a smart signer for a key on this page
  SmartSigner createSigner(UnifiedKeyPair keypair) {
    return SmartSigner(
      client: _client,
      keypair: keypair,
      signerUrl: _keyPageUrl,
    );
  }

  /// Add a new key to the key page
  ///
  /// [signingKey] is the existing key used to authorize the operation.
  /// [newKey] is the new key to add.
  Future<TransactionResult> addKey(
    UnifiedKeyPair signingKey,
    UnifiedKeyPair newKey,
  ) async {
    final signer = createSigner(signingKey);
    return signer.addKey(newKey);
  }

  /// Add a new key by hash
  ///
  /// [signingKey] is the existing key used to authorize the operation.
  /// [keyHash] is the hash of the new key to add.
  Future<TransactionResult> addKeyHash(
    UnifiedKeyPair signingKey,
    Uint8List keyHash,
  ) async {
    final signer = createSigner(signingKey);

    final body = {
      "type": "updateKeyPage",
      "operation": [
        {
          "type": "add",
          "entry": {"keyHash": toHex(keyHash)}
        }
      ]
    };

    return signer.signSubmitAndWait(
      principal: _keyPageUrl,
      body: body,
    );
  }

  /// Remove a key from the key page
  ///
  /// [signingKey] is the existing key used to authorize the operation.
  /// [keyHash] is the hash of the key to remove.
  Future<TransactionResult> removeKeyHash(
    UnifiedKeyPair signingKey,
    Uint8List keyHash,
  ) async {
    final signer = createSigner(signingKey);
    return signer.removeKey(keyHash);
  }

  /// Set the accept threshold
  ///
  /// [signingKey] is the existing key used to authorize the operation.
  /// [threshold] is the new threshold value.
  Future<TransactionResult> setThreshold(
    UnifiedKeyPair signingKey,
    int threshold,
  ) async {
    final signer = createSigner(signingKey);
    return signer.setThreshold(threshold);
  }

  /// Check if a key is on this page
  Future<bool> hasKey(UnifiedKeyPair keypair) async {
    final state = await getKeyPageState();
    return state.hasKeyPair(keypair);
  }

  /// Get the key hash for a unified key pair (for display)
  static Future<String> getKeyHashHex(UnifiedKeyPair keypair) async {
    return toHex(await keypair.publicKeyHash);
  }
}
