import "dart:typed_data";
import "../codec/transaction_codec.dart";
import "../codec/binary_encoder.dart" show SignatureTypeEnum;
import "../crypto/ed25519.dart";
import "../crypto/rcd1.dart";
import "../crypto/secp256k1.dart";
import "../crypto/rsa.dart";
import "../crypto/ecdsa.dart";
import "../protocol/envelope.dart";
import "../util/bytes.dart";
import "../util/validation.dart";
import "../operations/key_page_operations.dart";
import "../operations/account_auth_operations.dart";
import "tx_types.dart";
import "context.dart";

// Re-export operation classes for convenience
export "../operations/key_page_operations.dart";
export "../operations/account_auth_operations.dart";

/// Token recipient for sendTokens and issueTokens
///
/// Matches Go: protocol/general.yml TokenRecipient
class TokenRecipient {
  final String url;
  final String amount;

  const TokenRecipient({required this.url, required this.amount});

  Map<String, dynamic> toJson() => {"url": url, "amount": amount};
}

/// Credit recipient for transferCredits
///
/// Matches Go: protocol/general.yml CreditRecipient
class CreditRecipient {
  final String url;
  final int amount;

  const CreditRecipient({required this.url, required this.amount});

  Map<String, dynamic> toJson() => {"url": url, "amount": amount};
}

/// Transaction body builders for Accumulate v3 operations
///
/// Contains builders for all 23 user transaction types as defined in
/// Go: protocol/user_transactions.yml
class TxBody {
  // ============================================================
  // IDENTITY TRANSACTIONS
  // ============================================================

  /// Create identity (ADI) transaction body
  ///
  /// Creates a new Accumulate Digital Identifier (ADI).
  /// Matches Go: protocol/user_transactions.yml CreateIdentity
  ///
  /// Throws [ValidationException] if inputs are invalid.
  static Map<String, dynamic> createIdentity({
    required String url,
    String? keyBookUrl,
    String? keyBookName,
    String? publicKeyHash,
    List<String>? authorities,
  }) {
    Validate.accUrl(url, 'url');
    if (keyBookUrl != null) Validate.accUrl(keyBookUrl, 'keyBookUrl');
    if (publicKeyHash != null)
      Validate.hexString(publicKeyHash, fieldName: 'publicKeyHash');
    authorities?.forEach((a) => Validate.accUrl(a, 'authorities'));

    return {
      "type": TxTypes.createIdentity,
      "url": url,
      if (keyBookUrl != null) "keyBookUrl": keyBookUrl,
      if (keyBookName != null) "keyBookName": keyBookName,
      if (publicKeyHash != null) "keyHash": publicKeyHash,
      if (authorities != null && authorities.isNotEmpty)
        "authorities": authorities,
    };
  }

  // ============================================================
  // TOKEN TRANSACTIONS
  // ============================================================

  /// Create token account transaction body
  ///
  /// Creates a new token account under an ADI.
  /// Matches Go: protocol/user_transactions.yml CreateTokenAccount
  ///
  /// Throws [ValidationException] if inputs are invalid.
  static Map<String, dynamic> createTokenAccount({
    required String url,
    required String tokenUrl,
    List<String>? authorities,
  }) {
    Validate.accUrl(url, 'url');
    Validate.accUrl(tokenUrl, 'tokenUrl');
    authorities?.forEach((a) => Validate.accUrl(a, 'authorities'));

    return {
      "type": TxTypes.createTokenAccount,
      "url": url,
      "tokenUrl": tokenUrl,
      if (authorities != null && authorities.isNotEmpty)
        "authorities": authorities,
    };
  }

  /// Send tokens transaction body
  ///
  /// Sends tokens to one or more recipients.
  /// Matches Go: protocol/user_transactions.yml SendTokens
  ///
  /// Throws [ValidationException] if inputs are invalid.
  static Map<String, dynamic> sendTokens({
    required List<TokenRecipient> to,
  }) {
    Validate.notEmpty(to, 'to');
    for (final recipient in to) {
      Validate.accUrl(recipient.url, 'recipient.url');
      Validate.amount(recipient.amount, fieldName: 'recipient.amount');
    }

    return {
      "type": TxTypes.sendTokens,
      "to": to.map((r) => r.toJson()).toList(growable: false),
    };
  }

  /// Send tokens to a single recipient (convenience method)
  ///
  /// Throws [ValidationException] if inputs are invalid.
  static Map<String, dynamic> sendTokensSingle({
    required String toUrl,
    required String amount,
  }) {
    Validate.accUrl(toUrl, 'toUrl');
    Validate.amount(amount, fieldName: 'amount');
    return sendTokens(to: [TokenRecipient(url: toUrl, amount: amount)]);
  }

  /// Create custom token transaction body
  ///
  /// Creates a new custom token issuer.
  /// Matches Go: protocol/user_transactions.yml CreateToken
  ///
  /// Throws [ValidationException] if inputs are invalid.
  static Map<String, dynamic> createToken({
    required String url,
    required String symbol,
    required int precision,
    String? properties,
    String? supplyLimit,
    List<String>? authorities,
  }) {
    Validate.accUrl(url, 'url');
    Validate.tokenSymbol(symbol, 'symbol');
    Validate.tokenPrecision(precision, 'precision');
    if (supplyLimit != null)
      Validate.amount(supplyLimit, fieldName: 'supplyLimit', allowZero: true);
    authorities?.forEach((a) => Validate.accUrl(a, 'authorities'));

    return {
      "type": TxTypes.createToken,
      "url": url,
      "symbol": symbol,
      "precision": precision,
      if (properties != null) "properties": properties,
      if (supplyLimit != null) "supplyLimit": supplyLimit,
      if (authorities != null && authorities.isNotEmpty)
        "authorities": authorities,
    };
  }

  /// Issue tokens transaction body
  ///
  /// Issues new tokens from a token issuer.
  /// Matches Go: protocol/user_transactions.yml IssueTokens
  static Map<String, dynamic> issueTokens({
    required List<TokenRecipient> to,
  }) =>
      {
        "type": TxTypes.issueTokens,
        "to": to.map((r) => r.toJson()).toList(growable: false),
      };

  /// Issue tokens to a single recipient (convenience method)
  static Map<String, dynamic> issueTokensSingle({
    required String toUrl,
    required String amount,
  }) =>
      issueTokens(to: [TokenRecipient(url: toUrl, amount: amount)]);

  /// Burn tokens transaction body
  ///
  /// Burns (destroys) tokens from a token account.
  /// Matches Go: protocol/user_transactions.yml BurnTokens
  static Map<String, dynamic> burnTokens({
    required String amount,
  }) =>
      {
        "type": TxTypes.burnTokens,
        "amount": amount,
      };

  /// Create lite token account transaction body
  ///
  /// Explicitly creates a lite token account (usually auto-created).
  /// Matches Go: protocol/user_transactions.yml CreateLiteTokenAccount
  static Map<String, dynamic> createLiteTokenAccount() => {
        "type": TxTypes.createLiteTokenAccount,
      };

  // ============================================================
  // DATA TRANSACTIONS
  // ============================================================

  /// Create data account transaction body
  ///
  /// Creates a new data account under an ADI.
  /// Matches Go: protocol/user_transactions.yml CreateDataAccount
  static Map<String, dynamic> createDataAccount({
    required String url,
    List<String>? authorities,
  }) =>
      {
        "type": TxTypes.createDataAccount,
        "url": url,
        if (authorities != null && authorities.isNotEmpty)
          "authorities": authorities,
      };

  /// Write data transaction body
  ///
  /// Writes data entries to a data account.
  /// Each entry should be hex-encoded string (Accumulate uses hex encoding).
  /// Uses DoubleHashDataEntry type (Go protocol general.yml).
  /// Note: "accumulate" type is deprecated; use "doubleHash" instead.
  /// Matches Go: protocol/user_transactions.yml WriteData
  static Map<String, dynamic> writeData({
    required List<String> entriesHex,
    bool? scratch,
    bool? writeToState,
  }) =>
      {
        "type": TxTypes.writeData,
        "entry": {
          "type": "doubleHash",
          "data": entriesHex,
        },
        if (scratch == true) "scratch": true,
        if (writeToState == true) "writeToState": true,
      };

  /// Write data to another account transaction body
  ///
  /// Writes data to a different data account (requires authorization).
  /// Each entry should be hex-encoded string (Accumulate uses hex encoding).
  /// Uses DoubleHashDataEntry type (Go protocol general.yml).
  /// Note: "accumulate" type is deprecated; use "doubleHash" instead.
  /// Matches Go: protocol/user_transactions.yml WriteDataTo
  static Map<String, dynamic> writeDataTo({
    required String recipient,
    required List<String> entriesHex,
  }) =>
      {
        "type": TxTypes.writeDataTo,
        "recipient": recipient,
        "entry": {
          "type": "doubleHash",
          "data": entriesHex,
        },
      };

  // ============================================================
  // CREDIT TRANSACTIONS
  // ============================================================

  /// Add credits (buy credits) transaction body
  ///
  /// Burns ACME tokens to add credits to a lite identity or key page.
  /// Matches Go: protocol/user_transactions.yml AddCredits
  ///
  /// Throws [ValidationException] if inputs are invalid.
  static Map<String, dynamic> addCredits({
    required String recipient,
    required String amount,
    int? oracle,
  }) {
    Validate.accUrl(recipient, 'recipient');
    Validate.amount(amount, fieldName: 'amount');
    if (oracle != null) Validate.positiveInt(oracle, fieldName: 'oracle');

    return {
      "type": TxTypes.addCredits,
      "recipient": recipient,
      "amount": amount,
      if (oracle != null) "oracle": oracle,
    };
  }

  /// Alias for addCredits for backwards compatibility
  static Map<String, dynamic> buyCredits({
    required String recipientUrl,
    required String amount,
    int? oracle,
  }) =>
      addCredits(recipient: recipientUrl, amount: amount, oracle: oracle);

  /// Burn credits transaction body
  ///
  /// Burns (destroys) credits from a lite identity or key page.
  /// Matches Go: protocol/user_transactions.yml BurnCredits
  static Map<String, dynamic> burnCredits({
    required int amount,
  }) =>
      {
        "type": TxTypes.burnCredits,
        "amount": amount,
      };

  /// Transfer credits transaction body
  ///
  /// Transfers credits to one or more recipients.
  /// Matches Go: protocol/user_transactions.yml TransferCredits
  static Map<String, dynamic> transferCredits({
    required List<CreditRecipient> to,
  }) =>
      {
        "type": TxTypes.transferCredits,
        "to": to.map((r) => r.toJson()).toList(growable: false),
      };

  /// Transfer credits to a single recipient (convenience method)
  static Map<String, dynamic> transferCreditsSingle({
    required String toUrl,
    required int amount,
  }) =>
      transferCredits(to: [CreditRecipient(url: toUrl, amount: amount)]);

  // ============================================================
  // KEY MANAGEMENT TRANSACTIONS
  // ============================================================

  /// Create key book transaction body
  ///
  /// Creates a new key book under an ADI.
  /// Matches Go: protocol/user_transactions.yml CreateKeyBook
  ///
  /// Throws [ValidationException] if inputs are invalid.
  static Map<String, dynamic> createKeyBook({
    required String url,
    required String publicKeyHash,
    List<String>? authorities,
  }) {
    Validate.accUrl(url, 'url');
    Validate.publicKeyHash(publicKeyHash, 'publicKeyHash');
    authorities?.forEach((a) => Validate.accUrl(a, 'authorities'));

    return {
      "type": TxTypes.createKeyBook,
      "url": url,
      "publicKeyHash": publicKeyHash,
      if (authorities != null && authorities.isNotEmpty)
        "authorities": authorities,
    };
  }

  /// Create key page transaction body
  ///
  /// Creates a new key page under a key book.
  /// Matches Go: protocol/user_transactions.yml CreateKeyPage
  ///
  /// Throws [ValidationException] if inputs are invalid.
  static Map<String, dynamic> createKeyPage({
    required List<KeySpecParams> keys,
  }) {
    Validate.notEmpty(keys, 'keys');

    return {
      "type": TxTypes.createKeyPage,
      "keys": keys.map((k) => k.toJson()).toList(growable: false),
    };
  }

  /// Update key page transaction body
  ///
  /// Updates a key page (add/remove keys, change thresholds, etc.).
  /// Matches Go: protocol/user_transactions.yml UpdateKeyPage
  static Map<String, dynamic> updateKeyPage({
    required List<KeyPageOperation> operations,
  }) =>
      {
        "type": TxTypes.updateKeyPage,
        "operation":
            operations.map((op) => op.toJson()).toList(growable: false),
      };

  /// Update key transaction body
  ///
  /// Updates the key hash for a lite identity.
  /// Matches Go: protocol/user_transactions.yml UpdateKey
  static Map<String, dynamic> updateKey({
    required String newKeyHash,
  }) =>
      {
        "type": TxTypes.updateKey,
        "newKeyHash": newKeyHash,
      };

  // ============================================================
  // ACCOUNT MANAGEMENT TRANSACTIONS
  // ============================================================

  /// Update account auth transaction body
  ///
  /// Updates account authorization settings (add/remove authorities, enable/disable).
  /// Matches Go: protocol/user_transactions.yml UpdateAccountAuth
  static Map<String, dynamic> updateAccountAuth({
    required List<AccountAuthOperation> operations,
  }) =>
      {
        "type": TxTypes.updateAccountAuth,
        "operations":
            operations.map((op) => op.toJson()).toList(growable: false),
      };

  /// Lock account transaction body
  ///
  /// Locks an account until a specific major block height.
  /// Matches Go: protocol/user_transactions.yml LockAccount
  static Map<String, dynamic> lockAccount({
    required int height,
  }) =>
      {
        "type": TxTypes.lockAccount,
        "height": height,
      };

  /// Release locked operation transaction body (type 0x18, Accumulate 1.4.6.7)
  ///
  /// Releases a hash-locked transaction by revealing the preimage of its
  /// header HashLock. [lockedTxId] is the locked transaction's ID
  /// (acc://<hash>@<account>); [preimage] is raw bytes or a hex string.
  /// Matches Go: protocol/user_transactions.yml ReleaseLockedOperation
  static Map<String, dynamic> releaseLockedOperation({
    required String lockedTxId,
    required Object preimage,
  }) {
    if (!lockedTxId.startsWith('acc://')) {
      throw ArgumentError.value(lockedTxId, 'lockedTxId', 'must be an acc:// txid');
    }
    final Uint8List bytes;
    if (preimage is Uint8List) {
      bytes = preimage;
    } else if (preimage is String) {
      bytes = hexTo(preimage);
    } else {
      throw ArgumentError('preimage must be Uint8List or hex String');
    }
    if (bytes.isEmpty) {
      throw ArgumentError.value(preimage, 'preimage', 'must not be empty');
    }
    return {
      "type": TxTypes.releaseLockedOperation,
      "lockedTxID": lockedTxId,
      // Hex, like every other bytes field in a body map, so the envelope is JSON-safe
      // (jsonEncode would turn a Uint8List into an array of ints, which Go rejects).
      "preimage": toHex(bytes),
    };
  }

  // ============================================================
  // SPECIAL TRANSACTIONS
  // ============================================================

  /// ACME faucet transaction body
  ///
  /// Requests tokens from the ACME faucet (testnet only).
  /// Matches Go: protocol/user_transactions.yml AcmeFaucet
  static Map<String, dynamic> acmeFaucet({
    required String url,
  }) =>
      {
        "type": TxTypes.acmeFaucet,
        "url": url,
      };

  /// Network maintenance transaction body
  ///
  /// Performs network maintenance operations (validators only).
  /// Matches Go: protocol/user_transactions.yml NetworkMaintenance
  static Map<String, dynamic> networkMaintenance({
    required List<NetworkMaintenanceOperation> operations,
  }) =>
      {
        "type": TxTypes.networkMaintenance,
        "operations":
            operations.map((op) => op.toJson()).toList(growable: false),
      };

  /// Activate protocol version transaction body
  ///
  /// Activates a new protocol version (validators only).
  /// Matches Go: protocol/user_transactions.yml ActivateProtocolVersion
  static Map<String, dynamic> activateProtocolVersion({
    String? version,
  }) =>
      {
        "type": TxTypes.activateProtocolVersion,
        if (version != null) "version": version,
      };

  /// Remote transaction body
  ///
  /// References a transaction on another partition.
  /// Matches Go: protocol/user_transactions.yml RemoteTransaction
  static Map<String, dynamic> remoteTransaction({
    String? hash,
  }) =>
      {
        "type": TxTypes.remoteTransaction,
        if (hash != null) "hash": hash,
      };
}

/// Transaction signer that implements Go core's signing algorithm
///
/// This uses binary encoding (MarshalBinary) to match the Go core implementation
/// for computing transaction hashes and signature metadata hashes.
class TxSigner {
  /// Build and sign transaction using Go core's signing algorithm
  ///
  /// Process (matches Go: protocol/signature_utils.go):
  /// 1. Compute signature metadata hash = SHA256(TLV-encoded signature metadata)
  ///    This is used as BOTH the transaction header initiator AND for signing
  /// 2. Create transaction hash using binary-encoded header (with initiator) and body
  ///    txHash = SHA256(SHA256(header.MarshalBinary()) + SHA256(body.MarshalBinary()))
  /// 3. Create signing preimage: SHA256(sigMdHash + txHash)
  /// 4. Sign the preimage with Ed25519
  /// 5. Build complete envelope
  ///
  /// Parameters:
  /// - ctx: Build context with principal, timestamp, and optional header fields
  /// - body: Transaction body map
  /// - keypair: Ed25519 key pair for signing
  /// - signerUrl: Optional signer URL (defaults to ctx.principal)
  /// - signerVersion: Optional signer version (defaults to 1)
  /// - vote: Optional vote for governance transactions
  /// - signatureMemo: Optional memo attached to the signature
  /// - signatureData: Optional metadata attached to the signature
  static Future<Envelope> buildAndSign({
    required BuildContext ctx,
    required Map<String, dynamic> body,
    required Ed25519KeyPair keypair,
    String? signerUrl,
    int signerVersion = 1,
    VoteType? vote,
    String? signatureMemo,
    Uint8List? signatureData,
  }) async {
    final header = ctx.headerJson();

    // Get public key bytes
    final pub = await keypair.publicKeyBytes();

    // Determine the signer URL
    final actualSignerUrl = signerUrl ?? ctx.principal;

    // Compute signature metadata hash using binary encoding
    // This matches Go's signature.Metadata().Hash()
    // Used as BOTH the transaction header initiator AND for signing preimage
    final sigMetadataHash = TransactionCodec.computeSignatureMetadataHash(
      publicKey: pub,
      signer: actualSignerUrl,
      signerVersion: signerVersion,
      timestamp: ctx.timestamp,
      vote: vote?.value ?? 0,
      memo: signatureMemo,
      data: signatureData,
    );
    final initiator = toHex(sigMetadataHash);

    // Create transaction hash using binary encoding
    // Add initiator to header before hashing
    final headerWithInitiator = Map<String, dynamic>.from(header);
    headerWithInitiator["initiator"] = initiator;
    final txHash =
        TransactionCodec.encodeTxForSigning(headerWithInitiator, body);

    // Create signing preimage: SHA256(sigMdHash + txHash)
    final preimage =
        TransactionCodec.createSigningPreimage(sigMetadataHash, txHash);

    // Sign the preimage
    final signature = await keypair.sign(preimage);

    // Create complete signature document
    // V3 API expects hex-encoded publicKey, signature, and transactionHash
    final sdoc = SignatureDoc(
      type: "ed25519",
      publicKey: toHex(pub),
      signature: toHex(signature),
      timestamp: ctx.timestamp,
      transactionHash: toHex(txHash),
      signer: actualSignerUrl,
      signerVersion: signerVersion,
      vote: vote,
      memo: signatureMemo,
      data: signatureData,
    );

    // Build complete transaction
    final tx = {"header": headerWithInitiator, "body": body};

    return Envelope(signatures: [sdoc], transaction: tx);
  }

  /// Build and sign a vote transaction
  ///
  /// Convenience method for voting on pending transactions
  static Future<Envelope> buildVote({
    required BuildContext ctx,
    required Map<String, dynamic> body,
    required Ed25519KeyPair keypair,
    required VoteType vote,
    String? signerUrl,
    int signerVersion = 1,
    String? memo,
  }) async {
    return buildAndSign(
      ctx: ctx,
      body: body,
      keypair: keypair,
      signerUrl: signerUrl,
      signerVersion: signerVersion,
      vote: vote,
      signatureMemo: memo,
    );
  }

  // ============================================================
  // RCD1 SIGNATURE (Factom-style Ed25519)
  // ============================================================

  /// Build and sign transaction with RCD1 key pair
  ///
  /// RCD1 uses Ed25519 signing but with a different key hash algorithm.
  /// Matches Go: protocol/signature.go RCD1Signature
  static Future<Envelope> buildAndSignRCD1({
    required BuildContext ctx,
    required Map<String, dynamic> body,
    required RCD1KeyPair keypair,
    String? signerUrl,
    int signerVersion = 1,
    VoteType? vote,
    String? signatureMemo,
    Uint8List? signatureData,
  }) async {
    final header = ctx.headerJson();
    final pub = await keypair.publicKeyBytes();
    final actualSignerUrl = signerUrl ?? ctx.principal;

    // Use RCD1 signature type (3) for metadata hash
    // This is used as BOTH the transaction header initiator AND for signing
    final sigMetadataHash =
        TransactionCodec.computeSignatureMetadataHashForType(
      signatureType: SignatureTypeEnum.rcd1,
      publicKey: pub,
      signer: actualSignerUrl,
      signerVersion: signerVersion,
      timestamp: ctx.timestamp,
      vote: vote?.value ?? 0,
      memo: signatureMemo,
      data: signatureData,
    );
    final initiator = toHex(sigMetadataHash);

    final headerWithInitiator = Map<String, dynamic>.from(header);
    headerWithInitiator["initiator"] = initiator;
    final txHash =
        TransactionCodec.encodeTxForSigning(headerWithInitiator, body);

    final preimage =
        TransactionCodec.createSigningPreimage(sigMetadataHash, txHash);
    final signature = await keypair.sign(preimage);

    final sdoc = SignatureDoc(
      type: "rcd1",
      publicKey: toHex(pub),
      signature: toHex(signature),
      timestamp: ctx.timestamp,
      transactionHash: toHex(txHash),
      signer: actualSignerUrl,
      signerVersion: signerVersion,
      vote: vote,
      memo: signatureMemo,
      data: signatureData,
    );

    final tx = {"header": headerWithInitiator, "body": body};
    return Envelope(signatures: [sdoc], transaction: tx);
  }

  // ============================================================
  // BTC SIGNATURE (Bitcoin-style secp256k1)
  // ============================================================

  /// Build and sign transaction with BTC key pair
  ///
  /// Uses secp256k1 curve with DER-encoded signatures.
  /// BTC uses 33-byte compressed SEC1 public key format.
  /// Matches Go: protocol/signature.go BTCSignature
  static Future<Envelope> buildAndSignBTC({
    required BuildContext ctx,
    required Map<String, dynamic> body,
    required Secp256k1KeyPair keypair,
    String? signerUrl,
    int signerVersion = 1,
    VoteType? vote,
    String? signatureMemo,
    Uint8List? signatureData,
  }) async {
    final header = ctx.headerJson();
    // BTC uses compressed public key (33 bytes)
    final pub = keypair.publicKeyBytes;
    final actualSignerUrl = signerUrl ?? ctx.principal;

    // Use BTC signature type (4) for metadata hash
    // This is used as BOTH the transaction header initiator AND for signing
    final sigMetadataHash =
        TransactionCodec.computeSignatureMetadataHashForType(
      signatureType: SignatureTypeEnum.btc,
      publicKey: pub,
      signer: actualSignerUrl,
      signerVersion: signerVersion,
      timestamp: ctx.timestamp,
      vote: vote?.value ?? 0,
      memo: signatureMemo,
      data: signatureData,
    );
    final initiator = toHex(sigMetadataHash);

    final headerWithInitiator = Map<String, dynamic>.from(header);
    headerWithInitiator["initiator"] = initiator;
    final txHash =
        TransactionCodec.encodeTxForSigning(headerWithInitiator, body);

    final preimage =
        TransactionCodec.createSigningPreimage(sigMetadataHash, txHash);
    final signature = keypair.signBTC(preimage);

    final sdoc = SignatureDoc(
      type: "btc",
      publicKey: toHex(pub),
      signature: toHex(signature),
      timestamp: ctx.timestamp,
      transactionHash: toHex(txHash),
      signer: actualSignerUrl,
      signerVersion: signerVersion,
      vote: vote,
      memo: signatureMemo,
      data: signatureData,
    );

    final tx = {"header": headerWithInitiator, "body": body};
    return Envelope(signatures: [sdoc], transaction: tx);
  }

  // ============================================================
  // ETH SIGNATURE (Ethereum-style secp256k1)
  // ============================================================

  /// Build and sign transaction with ETH key pair (V1 - DER format)
  ///
  /// Uses secp256k1 curve with DER-encoded signature (like BTC).
  /// ETH uses 65-byte uncompressed public key format (0x04 + X + Y).
  ///
  /// Use this method for networks that have NOT enabled V2 Baikonur upgrade.
  /// Most current networks (including DevNet) require V1 format.
  ///
  /// Matches Go: protocol/signature.go SignEthAsDer() / ethSignatureV1.Verify()
  static Future<Envelope> buildAndSignETHv1({
    required BuildContext ctx,
    required Map<String, dynamic> body,
    required Secp256k1KeyPair keypair,
    String? signerUrl,
    int signerVersion = 1,
    VoteType? vote,
    String? signatureMemo,
    Uint8List? signatureData,
  }) async {
    final header = ctx.headerJson();
    // ETH uses uncompressed public key (65 bytes: 0x04 + X + Y)
    final pub = keypair.uncompressedPublicKeyBytes;
    final actualSignerUrl = signerUrl ?? ctx.principal;

    // Use ETH signature type for metadata hash
    final sigMetadataHash =
        TransactionCodec.computeSignatureMetadataHashForType(
      signatureType: SignatureTypeEnum.eth,
      publicKey: pub,
      signer: actualSignerUrl,
      signerVersion: signerVersion,
      timestamp: ctx.timestamp,
      vote: vote?.value ?? 0,
      memo: signatureMemo,
      data: signatureData,
    );
    final initiator = toHex(sigMetadataHash);

    final headerWithInitiator = Map<String, dynamic>.from(header);
    headerWithInitiator["initiator"] = initiator;
    final txHash =
        TransactionCodec.encodeTxForSigning(headerWithInitiator, body);

    final preimage =
        TransactionCodec.createSigningPreimage(sigMetadataHash, txHash);
    // V1 uses DER-encoded signature (same as BTC)
    final signature = keypair.signETHv1(preimage);

    final sdoc = SignatureDoc(
      type: "eth",
      publicKey: toHex(pub),
      signature: toHex(signature),
      timestamp: ctx.timestamp,
      transactionHash: toHex(txHash),
      signer: actualSignerUrl,
      signerVersion: signerVersion,
      vote: vote,
      memo: signatureMemo,
      data: signatureData,
    );

    final tx = {"header": headerWithInitiator, "body": body};
    return Envelope(signatures: [sdoc], transaction: tx);
  }

  /// Build and sign transaction with ETH key pair (V2 - RSV format)
  ///
  /// Uses secp256k1 curve with recoverable signature format (65 bytes: r + s + v).
  /// ETH uses 65-byte uncompressed public key format (0x04 + X + Y).
  ///
  /// Requires V2 Baikonur upgrade to be enabled on the network.
  /// Use buildAndSignETHv1 for older networks.
  ///
  /// Matches Go: protocol/signature.go SignETH() / ETHSignature.Verify()
  static Future<Envelope> buildAndSignETH({
    required BuildContext ctx,
    required Map<String, dynamic> body,
    required Secp256k1KeyPair keypair,
    String? signerUrl,
    int signerVersion = 1,
    VoteType? vote,
    String? signatureMemo,
    Uint8List? signatureData,
  }) async {
    final header = ctx.headerJson();
    // ETH uses uncompressed public key (65 bytes: 0x04 + X + Y)
    final pub = keypair.uncompressedPublicKeyBytes;
    final actualSignerUrl = signerUrl ?? ctx.principal;

    // Use ETH signature type (6) for metadata hash
    // This is used as BOTH the transaction header initiator AND for signing
    final sigMetadataHash =
        TransactionCodec.computeSignatureMetadataHashForType(
      signatureType: SignatureTypeEnum.eth,
      publicKey: pub,
      signer: actualSignerUrl,
      signerVersion: signerVersion,
      timestamp: ctx.timestamp,
      vote: vote?.value ?? 0,
      memo: signatureMemo,
      data: signatureData,
    );
    final initiator = toHex(sigMetadataHash);

    final headerWithInitiator = Map<String, dynamic>.from(header);
    headerWithInitiator["initiator"] = initiator;
    final txHash =
        TransactionCodec.encodeTxForSigning(headerWithInitiator, body);

    final preimage =
        TransactionCodec.createSigningPreimage(sigMetadataHash, txHash);
    final signature = keypair.signETH(preimage);

    final sdoc = SignatureDoc(
      type: "eth",
      publicKey: toHex(pub),
      signature: toHex(signature),
      timestamp: ctx.timestamp,
      transactionHash: toHex(txHash),
      signer: actualSignerUrl,
      signerVersion: signerVersion,
      vote: vote,
      memo: signatureMemo,
      data: signatureData,
    );

    final tx = {"header": headerWithInitiator, "body": body};
    return Envelope(signatures: [sdoc], transaction: tx);
  }

  // ============================================================
  // RSA SIGNATURE (RSA-SHA256)
  // ============================================================

  /// Build and sign transaction with RSA key pair
  ///
  /// Uses PKCS#1 v1.5 signature scheme with SHA-256.
  /// RSA uses PKCS#1 DER-encoded public key format.
  /// Matches Go: protocol/signature.go RsaSha256Signature
  ///
  /// IMPORTANT: RSA signatures CANNOT initiate transactions in Accumulate.
  /// They can only be used as additional signatures on transactions initiated
  /// by other signature types (Ed25519, RCD1, BTC, ETH).
  /// See Go: protocol/signature.go RsaSha256Signature.Initiator() returns ErrCannotInitiate
  static Future<Envelope> buildAndSignRSA({
    required BuildContext ctx,
    required Map<String, dynamic> body,
    required RsaKeyPair keypair,
    String? signerUrl,
    int signerVersion = 1,
    VoteType? vote,
    String? signatureMemo,
    Uint8List? signatureData,
  }) async {
    final header = ctx.headerJson();
    final pub = keypair.publicKeyBytes;
    final actualSignerUrl = signerUrl ?? ctx.principal;

    // Use RSA signature type (9) for metadata hash
    // This is used as BOTH the transaction header initiator AND for signing
    // Note: RSA can't actually initiate in Go, but we compute it for consistency
    final sigMetadataHash =
        TransactionCodec.computeSignatureMetadataHashForType(
      signatureType: SignatureTypeEnum.rsaSha256,
      publicKey: pub,
      signer: actualSignerUrl,
      signerVersion: signerVersion,
      timestamp: ctx.timestamp,
      vote: vote?.value ?? 0,
      memo: signatureMemo,
      data: signatureData,
    );
    final initiator = toHex(sigMetadataHash);

    final headerWithInitiator = Map<String, dynamic>.from(header);
    headerWithInitiator["initiator"] = initiator;
    final txHash =
        TransactionCodec.encodeTxForSigning(headerWithInitiator, body);

    final preimage =
        TransactionCodec.createSigningPreimage(sigMetadataHash, txHash);
    final signature = keypair.sign(preimage);

    final sdoc = SignatureDoc(
      type: "rsaSha256",
      publicKey: toHex(pub),
      signature: toHex(signature),
      timestamp: ctx.timestamp,
      transactionHash: toHex(txHash),
      signer: actualSignerUrl,
      signerVersion: signerVersion,
      vote: vote,
      memo: signatureMemo,
      data: signatureData,
    );

    final tx = {"header": headerWithInitiator, "body": body};
    return Envelope(signatures: [sdoc], transaction: tx);
  }

  // ============================================================
  // ECDSA SIGNATURE (ECDSA-SHA256)
  // ============================================================

  /// Build and sign transaction with ECDSA key pair
  ///
  /// Uses ECDSA with P-256, P-384, or P-521 curve and SHA-256 hash.
  /// ECDSA uses SPKI DER-encoded public key format.
  /// Matches Go: protocol/signature.go EcdsaSha256Signature
  ///
  /// IMPORTANT: ECDSA signatures CANNOT initiate transactions in Accumulate.
  /// They can only be used as additional signatures on transactions initiated
  /// by other signature types (Ed25519, RCD1, BTC, ETH).
  /// See Go: protocol/signature.go EcdsaSha256Signature.Initiator() returns ErrCannotInitiate
  static Future<Envelope> buildAndSignECDSA({
    required BuildContext ctx,
    required Map<String, dynamic> body,
    required EcdsaKeyPair keypair,
    String? signerUrl,
    int signerVersion = 1,
    VoteType? vote,
    String? signatureMemo,
    Uint8List? signatureData,
  }) async {
    final header = ctx.headerJson();
    final pub = keypair.publicKeyBytes;
    final actualSignerUrl = signerUrl ?? ctx.principal;

    // Use ECDSA signature type (10) for metadata hash
    // This is used as BOTH the transaction header initiator AND for signing
    // Note: ECDSA can't actually initiate in Go, but we compute it for consistency
    final sigMetadataHash =
        TransactionCodec.computeSignatureMetadataHashForType(
      signatureType: SignatureTypeEnum.ecdsaSha256,
      publicKey: pub,
      signer: actualSignerUrl,
      signerVersion: signerVersion,
      timestamp: ctx.timestamp,
      vote: vote?.value ?? 0,
      memo: signatureMemo,
      data: signatureData,
    );
    final initiator = toHex(sigMetadataHash);

    final headerWithInitiator = Map<String, dynamic>.from(header);
    headerWithInitiator["initiator"] = initiator;
    final txHash =
        TransactionCodec.encodeTxForSigning(headerWithInitiator, body);

    final preimage =
        TransactionCodec.createSigningPreimage(sigMetadataHash, txHash);
    final signature = keypair.sign(preimage);

    final sdoc = SignatureDoc(
      type: "ecdsaSha256",
      publicKey: toHex(pub),
      signature: toHex(signature),
      timestamp: ctx.timestamp,
      transactionHash: toHex(txHash),
      signer: actualSignerUrl,
      signerVersion: signerVersion,
      vote: vote,
      memo: signatureMemo,
      data: signatureData,
    );

    final tx = {"header": headerWithInitiator, "body": body};
    return Envelope(signatures: [sdoc], transaction: tx);
  }
}
