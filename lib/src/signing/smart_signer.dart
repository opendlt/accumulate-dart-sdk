import "dart:typed_data";
import "../v3/client_v3.dart";
import "../protocol/envelope.dart";
import "../build/context.dart";
import "../build/builders.dart";
import "../codec/transaction_codec.dart";
import "../util/bytes.dart";
import "algorithm.dart";
import "unified_keypair.dart";

/// A smart signer that automatically queries and caches signer version
///
/// This is the main convenience class for signing transactions. It:
/// - Automatically queries the key page for current version before signing
/// - Caches the version to avoid repeated queries
/// - Invalidates cache when key page is updated
/// - Provides simple sign() and signAndSubmit() methods
///
/// Example usage:
/// ```dart
/// // Create a smart signer
/// final signer = SmartSigner(
///   client: client.v3,
///   keypair: UnifiedKeyPair.fromEd25519(myKey),
///   signerUrl: "acc://myadi.acme/book/1",
/// );
///
/// // Sign a transaction - version is auto-queried!
/// final envelope = await signer.sign(
///   principal: "acc://myadi.acme/data",
///   body: TxBody.writeData(entriesHex: ["48656c6c6f"]),
/// );
///
/// // Or sign and submit in one call
/// final result = await signer.signAndSubmit(
///   principal: "acc://myadi.acme/tokens",
///   body: TxBody.sendTokensSingle(toUrl: "acc://recipient.acme/tokens", amount: "1000000"),
/// );
/// ```

/// Detect a submit-time rejection in a V3 `submit` response.
///
/// The network can accept the envelope transport-wise while REJECTING the
/// transaction, returning a per-submission `status` carrying an error (e.g.
/// `unauthorized`). Extracting only `txID` and proceeding to poll meant a
/// rejection surfaced as a timeout with no reason attached — the actionable
/// error was discarded at the moment it arrived.
String? _extractSubmitError(dynamic response) {
  String? fromEntry(dynamic entry) {
    if (entry is! Map) return null;
    final status = entry["status"];
    if (status is Map) {
      if (status["failed"] == true) {
        final err = status["error"];
        if (err is Map && err["message"] != null) return err["message"].toString();
        if (err != null) return err.toString();
        return "transaction rejected at submit";
      }
      final err = status["error"];
      if (err != null) {
        if (err is Map) {
          final msg = err["message"]?.toString() ?? "transaction rejected at submit";
          final code = err["code"] != null ? " (${err["code"]})" : "";
          return "$msg$code";
        }
        return err.toString();
      }
    }
    if (entry["success"] == false) {
      return entry["message"]?.toString() ?? "submit reported success=false";
    }
    return null;
  }

  if (response is List) {
    for (final e in response) {
      final err = fromEntry(e);
      if (err != null) return err;
    }
    return null;
  }
  return fromEntry(response);
}

class SmartSigner {
  final AccumulateV3 _client;
  final UnifiedKeyPair _keypair;
  final String _signerUrl;

  int? _cachedVersion;
  int? _cachedCredits;
  List<String>? _cachedKeyHashes;

  /// Create a smart signer
  ///
  /// Parameters:
  /// - client: The V3 client for querying and submitting
  /// - keypair: The unified key pair to sign with
  /// - signerUrl: The signer URL (usually a key page like "acc://adi.acme/book/1")
  SmartSigner({
    required AccumulateV3 client,
    required UnifiedKeyPair keypair,
    required String signerUrl,
  })  : _client = client,
        _keypair = keypair,
        _signerUrl = signerUrl;

  /// The signature algorithm being used
  SignatureAlgorithm get algorithm => _keypair.algorithm;

  /// The signer URL
  String get signerUrl => _signerUrl;

  /// Query and cache the signer version
  ///
  /// Set [refresh] to true to force a fresh query even if cached.
  Future<int> getSignerVersion({bool refresh = false}) async {
    if (_cachedVersion != null && !refresh) {
      return _cachedVersion!;
    }
    await _queryKeyPage();
    return _cachedVersion!;
  }

  /// Get cached credits (queries if not cached)
  Future<int> getCredits({bool refresh = false}) async {
    if (_cachedCredits != null && !refresh) {
      return _cachedCredits!;
    }
    await _queryKeyPage();
    return _cachedCredits ?? 0;
  }

  /// Check if this key is on the key page
  Future<bool> isKeyOnPage({bool refresh = false}) async {
    if (_cachedKeyHashes == null || refresh) {
      await _queryKeyPage();
    }
    final myKeyHash = toHex(await _keypair.publicKeyHash);
    return _cachedKeyHashes?.any((hash) =>
      hash.toLowerCase() == myKeyHash.toLowerCase()) ?? false;
  }

  /// Invalidate the cached version
  ///
  /// Call this after updating the key page (adding/removing keys, etc.)
  void invalidateCache() {
    _cachedVersion = null;
    _cachedCredits = null;
    _cachedKeyHashes = null;
  }

  /// Query key page and cache results
  /// Retries on 404 errors (key page may not be synced yet)
  Future<void> _queryKeyPage({int maxRetries = 5, Duration retryDelay = const Duration(seconds: 3)}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final result = await _client.rawCall("query", {
          "scope": _signerUrl,
          "query": {"queryType": "default"}
        });

        final account = result["account"] as Map<String, dynamic>?;
        if (account != null) {
          _cachedVersion = account["version"] as int?;
          _cachedCredits = account["creditBalance"] as int?;

          final keys = account["keys"] as List?;
          if (keys != null) {
            _cachedKeyHashes = keys
                .map((k) => k["publicKeyHash"]?.toString() ?? "")
                .where((h) => h.isNotEmpty)
                .toList();
          }
        }

        // Default to version 1 if not found
        _cachedVersion ??= 1;
        return;
      } catch (e) {
        // Check if it's a 404 error (key page not found yet)
        final errorStr = e.toString();
        if (errorStr.contains("-33404") || errorStr.contains("not found")) {
          if (attempt < maxRetries - 1) {
            await Future.delayed(retryDelay);
            continue;
          }
        }
        // Rethrow if not a 404 or out of retries
        rethrow;
      }
    }
  }

  /// Sign a transaction
  ///
  /// Automatically queries signer version before signing.
  /// This is the main method to use for signing.
  ///
  /// Parameters:
  /// - principal: The account URL initiating the transaction
  /// - body: The transaction body map
  /// - memo: Optional transaction memo
  /// - metadata: Optional binary metadata bytes
  /// - expire: Optional expiration time (transaction expires after this time)
  /// - holdUntil: Optional minor block number to hold transaction until
  /// - authorities: Optional list of additional authority URLs
  /// - vote: Optional vote for governance transactions
  /// - signatureMemo: Optional memo attached to the signature
  /// - signatureData: Optional metadata attached to the signature
  Future<Envelope> signExisting(Envelope envelope) async {
    // Co-sign an EXISTING envelope, appending this signer's signature.
    //
    // This is what a multi-signature (M-of-N) flow needs, and it is NOT the same
    // as calling [sign] twice. `sign` derives the transaction's `initiator` from
    // the FIRST signer's metadata and bakes it into the header, so the
    // transaction hash is a function of that signer. Signing the same body again
    // with a different key therefore produces a *different transaction*, and
    // neither one ever reaches the threshold.
    //
    // A co-signer must instead sign a preimage over the EXISTING transaction
    // hash, using its own signature metadata:
    //
    //     preimage = SHA256(cosignerSigMetadataHash + existingTxHash)
    //
    // The hash is read from the envelope's first signature rather than
    // recomputed, so this is exact for every transaction type — including
    // writeData/writeDataTo, whose body hash uses a different algorithm.
    if (envelope.signatures.isEmpty) {
      throw ArgumentError(
          "envelope has no existing signature to co-sign; sign it first");
    }
    final txHashHex = envelope.signatures.first.transactionHash;
    if (txHashHex.isEmpty) {
      throw ArgumentError("existing signature has no transactionHash");
    }
    final txHash = fromHex(txHashHex);

    final pub = await _keypair.publicKeyBytes();
    final pubHex = toHex(pub);

    // Refuse a duplicate: the same key signing twice does not advance the
    // threshold, and the node rejects the envelope.
    if (envelope.signatures.any((s) => s.publicKey == pubHex)) {
      throw ArgumentError(
          "this key has already signed the envelope; a threshold needs DISTINCT signers");
    }

    final signerVersion = await getSignerVersion();
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    // The co-signer's OWN metadata — its signer URL, version and timestamp.
    // Deliberately not the transaction's initiator.
    final sigMetadataHash = TransactionCodec.computeSignatureMetadataHash(
      publicKey: pub,
      signer: _signerUrl,
      signerVersion: signerVersion,
      timestamp: timestamp,
    );

    final preimage =
        TransactionCodec.createSigningPreimage(sigMetadataHash, txHash);
    final signature = await _keypair.signRaw(preimage);

    return Envelope(
      transaction: envelope.transaction,
      signatures: [
        ...envelope.signatures,
        SignatureDoc(
          type: "ed25519",
          publicKey: pubHex,
          signature: toHex(signature),
          timestamp: timestamp,
          transactionHash: txHashHex,
          signer: _signerUrl,
          signerVersion: signerVersion,
        ),
      ],
    );
  }

  Future<Envelope> sign({
    required String principal,
    required Map<String, dynamic> body,
    String? memo,
    Uint8List? metadata,
    DateTime? expire,
    int? holdUntil,
    List<String>? authorities,
    VoteType? vote,
    String? signatureMemo,
    Uint8List? signatureData,
  }) async {
    final version = await getSignerVersion();

    final ctx = BuildContext(
      principal: principal,
      timestamp: DateTime.now().microsecondsSinceEpoch,
      memo: memo,
      metadata: metadata,
      expire: expire != null ? ExpireOptions(atTime: expire) : null,
      holdUntil: holdUntil != null ? HoldUntilOptions(minorBlock: holdUntil) : null,
      authorities: authorities,
    );

    return _keypair.sign(
      ctx: ctx,
      body: body,
      signerUrl: _signerUrl,
      signerVersion: version,
      vote: vote,
      signatureMemo: signatureMemo,
      signatureData: signatureData,
    );
  }

  /// Sign a transaction with a pre-built BuildContext
  ///
  /// Use this when you need full control over the BuildContext,
  /// including custom timestamps or advanced header options.
  Future<Envelope> signWithContext({
    required BuildContext ctx,
    required Map<String, dynamic> body,
    VoteType? vote,
    String? signatureMemo,
    Uint8List? signatureData,
  }) async {
    final version = await getSignerVersion();

    return _keypair.sign(
      ctx: ctx,
      body: body,
      signerUrl: _signerUrl,
      signerVersion: version,
      vote: vote,
      signatureMemo: signatureMemo,
      signatureData: signatureData,
    );
  }

  /// Sign and submit a transaction in one call
  ///
  /// This is the most convenient method - handles everything automatically.
  ///
  /// Returns the submit response from the network.
  Future<dynamic> signAndSubmit({
    required String principal,
    required Map<String, dynamic> body,
    String? memo,
    Uint8List? metadata,
    DateTime? expire,
    int? holdUntil,
    List<String>? authorities,
    VoteType? vote,
    String? signatureMemo,
    Uint8List? signatureData,
  }) async {
    final envelope = await sign(
      principal: principal,
      body: body,
      memo: memo,
      metadata: metadata,
      expire: expire,
      holdUntil: holdUntil,
      authorities: authorities,
      vote: vote,
      signatureMemo: signatureMemo,
      signatureData: signatureData,
    );

    return _client.submit(envelope.toJson());
  }

  /// Sign and submit, then wait for delivery
  ///
  /// This is the most robust method - signs, submits, and polls for confirmation.
  ///
  /// Returns the final transaction status after delivery.
  Future<TransactionResult> signSubmitAndWait({
    required String principal,
    required Map<String, dynamic> body,
    String? memo,
    Uint8List? metadata,
    DateTime? expire,
    int? holdUntil,
    List<String>? authorities,
    VoteType? vote,
    String? signatureMemo,
    Uint8List? signatureData,
    int maxAttempts = 30,
    Duration pollInterval = const Duration(seconds: 2),
  }) async {
    final envelope = await sign(
      principal: principal,
      body: body,
      memo: memo,
      metadata: metadata,
      expire: expire,
      holdUntil: holdUntil,
      authorities: authorities,
      vote: vote,
      signatureMemo: signatureMemo,
      signatureData: signatureData,
    );

    final response = await _client.submit(envelope.toJson());

    // Surface a submit-time rejection immediately rather than polling to a
    // bare timeout.
    final submitError = _extractSubmitError(response);
    if (submitError != null) {
      return TransactionResult(
        success: false,
        txid: null,
        error: 'Transaction rejected at submit: $submitError',
      );
    }

    // Extract txid from response
    // The response is a List with two entries:
    // [0] = transaction result with txID like acc://hash@account/path
    // [1] = signature result with txID like acc://hash@account
    // We want the transaction hash without the path suffix
    String? txid;
    if (response is List && response.isNotEmpty) {
      // Try to get the second entry (signature tx) which doesn't have path suffix
      if (response.length > 1) {
        txid = response[1]?["status"]?["txID"]?.toString();
      }
      // Fall back to first entry
      txid ??= response[0]?["status"]?["txID"]?.toString();
    } else if (response is Map) {
      txid = response["status"]?["txID"]?.toString();
    }

    if (txid == null) {
      return TransactionResult(
        success: false,
        txid: null,
        error: "No txid in response",
        response: response,
      );
    }

    // Extract just the hash for querying - format: acc://hash@unknown
    String queryTxid = txid;
    if (txid.startsWith("acc://") && txid.contains("@")) {
      final hash = txid.split("@")[0].replaceAll("acc://", "");
      queryTxid = "acc://$hash@unknown";
    }

    // Poll for delivery
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final result = await _client.rawCall("query", {
          "scope": queryTxid,
          "query": {"queryType": "default"}
        });

        // Check status - can be a string or a map
        final statusValue = result["status"];
        bool delivered = false;
        bool failed = false;
        String? errorMsg;

        if (statusValue is String) {
          // Status is a simple string like "delivered" or "pending"
          delivered = statusValue == "delivered";
          failed = false;
        } else if (statusValue is Map) {
          // Status is a map with delivered/failed fields
          delivered = statusValue["delivered"] == true;
          failed = statusValue["failed"] == true;
          if (failed) {
            final errorObj = statusValue["error"];
            if (errorObj is Map) {
              errorMsg = errorObj["message"]?.toString();
            } else if (errorObj is String) {
              errorMsg = errorObj;
            }
          }
        }

        if (delivered) {
          return TransactionResult(
            success: !failed,
            txid: txid,
            error: errorMsg,
            response: result,
          );
        }
      } catch (e) {
        // Transaction might not be indexed yet
      }

      await Future.delayed(pollInterval);
    }

    return TransactionResult(
      success: false,
      txid: txid,
      error: "Timeout waiting for delivery",
      response: null,
    );
  }

  /// Sign, submit, and wait using a pre-built BuildContext
  ///
  /// Use this when you need full control over the BuildContext.
  Future<TransactionResult> signSubmitAndWaitWithContext({
    required BuildContext ctx,
    required Map<String, dynamic> body,
    VoteType? vote,
    String? signatureMemo,
    Uint8List? signatureData,
    int maxAttempts = 30,
    Duration pollInterval = const Duration(seconds: 2),
  }) async {
    final envelope = await signWithContext(
      ctx: ctx,
      body: body,
      vote: vote,
      signatureMemo: signatureMemo,
      signatureData: signatureData,
    );

    final response = await _client.submit(envelope.toJson());

    // Surface a submit-time rejection immediately rather than polling to a
    // bare timeout.
    final submitError = _extractSubmitError(response);
    if (submitError != null) {
      return TransactionResult(
        success: false,
        txid: null,
        error: 'Transaction rejected at submit: $submitError',
      );
    }

    // Extract txid from response
    String? txid;
    if (response is List && response.isNotEmpty) {
      if (response.length > 1) {
        txid = response[1]?["status"]?["txID"]?.toString();
      }
      txid ??= response[0]?["status"]?["txID"]?.toString();
    } else if (response is Map) {
      txid = response["status"]?["txID"]?.toString();
    }

    if (txid == null) {
      return TransactionResult(
        success: false,
        txid: null,
        error: "No txid in response",
        response: response,
      );
    }

    // Extract just the hash for querying
    String queryTxid = txid;
    if (txid.startsWith("acc://") && txid.contains("@")) {
      final hash = txid.split("@")[0].replaceAll("acc://", "");
      queryTxid = "acc://$hash@unknown";
    }

    // Poll for delivery
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final result = await _client.rawCall("query", {
          "scope": queryTxid,
          "query": {"queryType": "default"}
        });

        final statusValue = result["status"];
        bool delivered = false;
        bool failed = false;
        String? errorMsg;

        if (statusValue is String) {
          delivered = statusValue == "delivered";
        } else if (statusValue is Map) {
          delivered = statusValue["delivered"] == true;
          failed = statusValue["failed"] == true;
          if (failed) {
            final errorObj = statusValue["error"];
            if (errorObj is Map) {
              errorMsg = errorObj["message"]?.toString();
            } else if (errorObj is String) {
              errorMsg = errorObj;
            }
          }
        }

        if (delivered) {
          return TransactionResult(
            success: !failed,
            txid: txid,
            error: errorMsg,
            response: result,
          );
        }
      } catch (e) {
        // Transaction might not be indexed yet
      }

      await Future.delayed(pollInterval);
    }

    return TransactionResult(
      success: false,
      txid: txid,
      error: "Timeout waiting for delivery",
      response: null,
    );
  }

  /// Add a new key to the key page
  ///
  /// Convenience method for UpdateKeyPage with add operation.
  /// Automatically invalidates cache after success.
  Future<TransactionResult> addKey(UnifiedKeyPair newKey) async {
    final keyHash = await newKey.publicKeyHash;

    final body = TxBody.updateKeyPage(
      operations: [AddKeyOperation(entry: KeySpecParams(keyHash: keyHash))],
    );

    final result = await signSubmitAndWait(
      principal: _signerUrl,
      body: body,
    );

    if (result.success) {
      invalidateCache();
    }

    return result;
  }

  /// Remove a key from the key page
  ///
  /// Convenience method for UpdateKeyPage with remove operation.
  /// Automatically invalidates cache after success.
  Future<TransactionResult> removeKey(Uint8List keyHash) async {
    final body = TxBody.updateKeyPage(
      operations: [RemoveKeyOperation(entry: KeySpecParams(keyHash: keyHash))],
    );

    final result = await signSubmitAndWait(
      principal: _signerUrl,
      body: body,
    );

    if (result.success) {
      invalidateCache();
    }

    return result;
  }

  /// Update the signing threshold
  ///
  /// Convenience method for UpdateKeyPage with setThreshold operation.
  /// Automatically invalidates cache after success.
  Future<TransactionResult> setThreshold(int threshold) async {
    final body = TxBody.updateKeyPage(
      operations: [SetThresholdKeyPageOperation(threshold: threshold)],
    );

    final result = await signSubmitAndWait(
      principal: _signerUrl,
      body: body,
    );

    if (result.success) {
      invalidateCache();
    }

    return result;
  }
}

/// Result of a signed and submitted transaction
class TransactionResult {
  /// Whether the transaction was delivered successfully
  final bool success;

  /// The transaction ID
  final String? txid;

  /// Error message if failed
  final String? error;

  /// The raw response from the network
  final dynamic response;

  TransactionResult({
    required this.success,
    required this.txid,
    this.error,
    this.response,
  });

  @override
  String toString() {
    if (success) {
      return "TransactionResult(success, txid: $txid)";
    } else {
      return "TransactionResult(failed, error: $error, txid: $txid)";
    }
  }
}
