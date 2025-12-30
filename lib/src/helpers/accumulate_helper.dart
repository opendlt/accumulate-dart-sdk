import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../facade/accumulate.dart';
import '../crypto/ed25519.dart';
import '../build/builders.dart';
import '../build/context.dart';
import '../util/bytes.dart';

/// High-level helper class for common Accumulate operations
///
/// This class provides simplified methods that automatically handle:
/// - Oracle price fetching for credit purchases
/// - Key page version lookup for signing
/// - SHA256 hashing for key specifications
/// - Common transaction patterns
///
/// Example usage:
/// ```dart
/// final helper = AccumulateHelper(client);
///
/// // Simple credit purchase (auto-fetches oracle)
/// await helper.buyCredits(
///   from: liteTokenAccount,
///   to: keyPageUrl,
///   credits: 500,
///   signer: keypair,
/// );
///
/// // Create ADI with one call
/// await helper.createADI(
///   name: "my-adi",
///   fundingAccount: liteTokenAccount,
///   fundingSigner: liteKeypair,
///   adiSigner: adiKeypair,
/// );
/// ```
class AccumulateHelper {
  final Accumulate client;

  /// Cached oracle price (refreshed on each credit purchase)
  int? _cachedOracle;
  DateTime? _oracleFetchTime;

  /// Oracle cache duration (5 minutes)
  static const Duration oracleCacheDuration = Duration(minutes: 5);

  /// Key page version cache
  final Map<String, _CachedVersion> _versionCache = {};

  /// Version cache duration (30 seconds - shorter because versions change frequently)
  static const Duration versionCacheDuration = Duration(seconds: 30);

  AccumulateHelper(this.client);

  // ============================================================
  // ORACLE & NETWORK HELPERS
  // ============================================================

  /// Get the current oracle price, with caching
  ///
  /// Caches the oracle price for 5 minutes to avoid excessive network calls.
  /// Use [forceRefresh] to bypass the cache.
  Future<int> getOracle({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedOracle != null &&
        _oracleFetchTime != null &&
        now.difference(_oracleFetchTime!) < oracleCacheDuration) {
      return _cachedOracle!;
    }

    final networkStatus = await client.v3.rawCall("network-status", {});
    _cachedOracle = networkStatus["oracle"]["price"] as int;
    _oracleFetchTime = now;
    return _cachedOracle!;
  }

  /// Get network status information
  Future<Map<String, dynamic>> getNetworkStatus() async {
    return await client.v3.rawCall("network-status", {});
  }

  /// Convert credits to ACME amount (for AddCredits transaction)
  ///
  /// This calculates the amount of ACME tokens needed to purchase the
  /// specified number of credits at current oracle rates.
  ///
  /// The oracle price determines credits per ACME. Formula:
  /// amount = (credits * AcmePrecision * CreditsPerDollar) / oraclePrice
  ///
  /// Where:
  /// - AcmePrecision = 10^8 (ACME has 8 decimal places)
  /// - CreditsPerDollar = 100 (100 credits = $0.01 each)
  /// - oraclePrice = current USD price per ACME (from network)
  Future<String> creditsToAmount(int credits) async {
    final oracle = await getOracle();
    // Formula: amount = credits * 10^8 * 100 / oracle
    // Simplified: amount = credits * 10^10 / oracle
    final amount = (BigInt.from(credits) * BigInt.from(10000000000)) ~/ BigInt.from(oracle);
    return amount.toString();
  }

  /// Convert ACME amount to approximate credits at current oracle price
  ///
  /// This is the inverse of creditsToAmount(). Returns the approximate
  /// number of credits that can be purchased with the given ACME amount.
  Future<int> amountToCredits(String amount) async {
    final oracle = await getOracle();
    final tokens = BigInt.tryParse(amount) ?? BigInt.zero;
    // Inverse formula: credits = amount * oracle / 10^10
    final credits = (tokens * BigInt.from(oracle)) ~/ BigInt.from(10000000000);
    return credits.toInt();
  }

  // ============================================================
  // ACCOUNT QUERY HELPERS
  // ============================================================

  /// Query any account and return its data
  Future<Map<String, dynamic>?> getAccount(String url) async {
    try {
      final result = await client.v3.query({
        "scope": url,
        "query": {"@type": "DefaultQuery"}
      });
      return result["account"] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// Get the current version of a key page
  ///
  /// Returns 1 if the key page doesn't exist or version can't be determined.
  /// Uses caching to avoid excessive network calls.
  Future<int> getKeyPageVersion(String keyPageUrl, {bool forceRefresh = false}) async {
    final now = DateTime.now();

    // Check cache first
    if (!forceRefresh && _versionCache.containsKey(keyPageUrl)) {
      final cached = _versionCache[keyPageUrl]!;
      if (now.difference(cached.fetchTime) < versionCacheDuration) {
        return cached.version;
      }
    }

    // Fetch from network
    final account = await getAccount(keyPageUrl);
    final version = account?["version"] as int? ?? 1;

    // Update cache
    _versionCache[keyPageUrl] = _CachedVersion(version, now);

    return version;
  }

  /// Invalidate version cache for a specific key page
  ///
  /// Call this after modifying a key page to ensure the next operation
  /// fetches the updated version.
  void invalidateVersionCache(String keyPageUrl) {
    _versionCache.remove(keyPageUrl);
  }

  /// Clear all version caches
  void clearVersionCache() {
    _versionCache.clear();
  }

  /// Get key page details including keys, threshold, and credits
  Future<KeyPageInfo?> getKeyPageInfo(String keyPageUrl) async {
    final account = await getAccount(keyPageUrl);
    if (account == null) return null;

    return KeyPageInfo(
      url: account["url"] as String? ?? keyPageUrl,
      version: account["version"] as int? ?? 1,
      threshold: account["acceptThreshold"] as int? ?? account["threshold"] as int? ?? 1,
      credits: account["creditBalance"] as int? ?? account["credits"] as int? ?? 0,
      keys: (account["keys"] as List?)?.map((k) {
        if (k is Map) {
          return k["publicKeyHash"] as String? ?? k["publicKey"] as String? ?? "";
        }
        return k.toString();
      }).toList() ?? [],
    );
  }

  /// Get token account balance
  Future<BigInt> getBalance(String tokenAccountUrl) async {
    final account = await getAccount(tokenAccountUrl);
    if (account == null) return BigInt.zero;

    final balance = account["balance"];
    if (balance is String) return BigInt.parse(balance);
    if (balance is int) return BigInt.from(balance);
    return BigInt.zero;
  }

  /// Get credit balance for a lite identity or key page
  Future<int> getCreditBalance(String url) async {
    final account = await getAccount(url);
    if (account == null) return 0;

    return account["creditBalance"] as int? ?? account["credits"] as int? ?? 0;
  }

  // ============================================================
  // CREDIT OPERATIONS (Auto-Oracle)
  // ============================================================

  /// Buy credits with automatic oracle fetching
  ///
  /// Automatically fetches the current oracle price and calculates
  /// the correct ACME amount to burn.
  ///
  /// Parameters:
  /// - [from]: The ACME token account to burn from
  /// - [to]: The recipient (lite identity or key page)
  /// - [credits]: Number of credits to purchase
  /// - [signer]: The keypair to sign with
  /// - [signerUrl]: Optional signer URL (for ADI accounts)
  ///
  /// Returns the transaction ID if successful.
  Future<String?> buyCredits({
    required String from,
    required String to,
    required int credits,
    required Ed25519KeyPair signer,
    String? signerUrl,
  }) async {
    final oracle = await getOracle();

    // Calculate ACME amount using oracle price
    // Formula: amount = credits * 10^10 / oracle
    final amount = (BigInt.from(credits) * BigInt.from(10000000000)) ~/ BigInt.from(oracle);

    // Get signer version if signing from a key page
    int signerVersion = 1;
    final actualSignerUrl = signerUrl ?? from;
    if (actualSignerUrl.contains("/book/")) {
      signerVersion = await getKeyPageVersion(actualSignerUrl);
    }

    final body = TxBody.buyCredits(
      recipientUrl: to,
      amount: amount.toString(),
      oracle: oracle,
    );

    final ctx = BuildContext(
      principal: from,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      memo: "Buy $credits credits",
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: body,
      keypair: signer,
      signerUrl: signerUrl,
      signerVersion: signerVersion,
    );

    final response = await client.v3.submit(envelope.toJson());
    return _extractTxId(response);
  }

  // ============================================================
  // IDENTITY OPERATIONS
  // ============================================================

  /// Create an ADI (Accumulate Digital Identifier) with a single call
  ///
  /// Automatically computes the SHA256 hash of the public key.
  ///
  /// Parameters:
  /// - [name]: The ADI name (without .acme suffix)
  /// - [fundingAccount]: The lite token account paying for creation
  /// - [fundingSigner]: The keypair for the funding account
  /// - [adiSigner]: The keypair that will control the ADI
  /// - [bookName]: Optional key book name (default: "book")
  ///
  /// Returns the transaction ID if successful.
  Future<String?> createADI({
    required String name,
    required String fundingAccount,
    required Ed25519KeyPair fundingSigner,
    required Ed25519KeyPair adiSigner,
    String bookName = "book",
  }) async {
    final identityUrl = "acc://$name.acme";
    final bookUrl = "$identityUrl/$bookName";

    // Compute SHA256 hash of the ADI signer's public key
    final publicKey = await adiSigner.publicKeyBytes();
    final keyHash = sha256.convert(publicKey).bytes;
    final keyHashHex = toHex(Uint8List.fromList(keyHash));

    final body = TxBody.createIdentity(
      url: identityUrl,
      keyBookUrl: bookUrl,
      publicKeyHash: keyHashHex,
    );

    final ctx = BuildContext(
      principal: fundingAccount,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      memo: "Create ADI: $name",
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: body,
      keypair: fundingSigner,
    );

    final response = await client.v3.submit(envelope.toJson());
    return _extractTxId(response);
  }

  // ============================================================
  // TOKEN ACCOUNT OPERATIONS
  // ============================================================

  /// Create a token account under an ADI
  ///
  /// Parameters:
  /// - [adiUrl]: The ADI URL (e.g., "acc://my-adi.acme")
  /// - [accountName]: The account name
  /// - [tokenUrl]: The token URL (default: ACME)
  /// - [signer]: The keypair to sign with
  /// - [keyPageUrl]: The key page URL for signing
  ///
  /// Returns the transaction ID if successful.
  Future<String?> createTokenAccount({
    required String adiUrl,
    required String accountName,
    required Ed25519KeyPair signer,
    required String keyPageUrl,
    String tokenUrl = "acc://ACME",
  }) async {
    final accountUrl = "$adiUrl/$accountName";
    final signerVersion = await getKeyPageVersion(keyPageUrl);

    final body = TxBody.createTokenAccount(
      url: accountUrl,
      tokenUrl: tokenUrl,
    );

    final ctx = BuildContext(
      principal: adiUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      memo: "Create token account: $accountName",
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: body,
      keypair: signer,
      signerUrl: keyPageUrl,
      signerVersion: signerVersion,
    );

    final response = await client.v3.submit(envelope.toJson());
    return _extractTxId(response);
  }

  /// Send tokens from one account to another
  ///
  /// Parameters:
  /// - [from]: Source token account
  /// - [to]: Destination token account
  /// - [amount]: Amount to send (as string for precision)
  /// - [signer]: The keypair to sign with
  /// - [signerUrl]: Optional key page URL (required for ADI accounts)
  ///
  /// Returns the transaction ID if successful.
  Future<String?> sendTokens({
    required String from,
    required String to,
    required String amount,
    required Ed25519KeyPair signer,
    String? signerUrl,
  }) async {
    int signerVersion = 1;
    final actualSignerUrl = signerUrl ?? from;
    if (actualSignerUrl.contains("/book/")) {
      signerVersion = await getKeyPageVersion(actualSignerUrl);
    }

    final body = TxBody.sendTokensSingle(toUrl: to, amount: amount);

    final ctx = BuildContext(
      principal: from,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      memo: "Send $amount tokens",
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: body,
      keypair: signer,
      signerUrl: signerUrl,
      signerVersion: signerVersion,
    );

    final response = await client.v3.submit(envelope.toJson());
    return _extractTxId(response);
  }

  /// Create a token account and fund it in one call
  ///
  /// This is a composite operation that:
  /// 1. Creates a token account under the ADI
  /// 2. Waits for the account to be created
  /// 3. Sends tokens to the new account
  ///
  /// Parameters:
  /// - [adiUrl]: The ADI URL (e.g., "acc://my-adi.acme")
  /// - [accountName]: Name for the new token account
  /// - [adiKeypair]: Keypair that controls the ADI
  /// - [keyPageUrl]: Key page URL for signing ADI operations
  /// - [fundingSource]: Token account to send initial tokens from
  /// - [fundingAmount]: Amount of tokens to send
  /// - [fundingSigner]: Keypair for the funding source
  /// - [fundingSignerUrl]: Optional key page for funding source (if ADI)
  /// - [tokenUrl]: Token type (default: ACME)
  /// - [processingDelay]: Wait time between operations
  ///
  /// Returns the new token account URL if successful.
  Future<String?> createAndFundTokenAccount({
    required String adiUrl,
    required String accountName,
    required Ed25519KeyPair adiKeypair,
    required String keyPageUrl,
    required String fundingSource,
    required String fundingAmount,
    required Ed25519KeyPair fundingSigner,
    String? fundingSignerUrl,
    String tokenUrl = "acc://ACME",
    Duration processingDelay = const Duration(seconds: 15),
  }) async {
    // Step 1: Create the token account
    final createTxId = await createTokenAccount(
      adiUrl: adiUrl,
      accountName: accountName,
      signer: adiKeypair,
      keyPageUrl: keyPageUrl,
      tokenUrl: tokenUrl,
    );

    if (createTxId == null) return null;

    // Step 2: Wait for creation to settle
    await Future.delayed(processingDelay);

    // Step 3: Send tokens to the new account
    final newAccountUrl = "$adiUrl/$accountName";
    final sendTxId = await sendTokens(
      from: fundingSource,
      to: newAccountUrl,
      amount: fundingAmount,
      signer: fundingSigner,
      signerUrl: fundingSignerUrl,
    );

    if (sendTxId == null) return null;

    return newAccountUrl;
  }

  /// Execute multi-hop token transfers
  ///
  /// Transfers tokens through multiple accounts in sequence.
  /// Useful for moving tokens from lite -> ADI -> ADI or similar flows.
  ///
  /// Example:
  /// ```dart
  /// await helper.transferTokensMultiHop(hops: [
  ///   TransferHop(from: liteAccount, to: adiAccount1, amount: "1000000000", signer: liteKeypair),
  ///   TransferHop(from: adiAccount1, to: adiAccount2, amount: "500000000", signer: adiKeypair, signerUrl: keyPageUrl),
  /// ]);
  /// ```
  ///
  /// Returns list of transaction IDs for each hop.
  Future<List<String?>> transferTokensMultiHop({
    required List<TransferHop> hops,
    Duration processingDelayBetweenHops = const Duration(seconds: 15),
  }) async {
    final txIds = <String?>[];

    for (int i = 0; i < hops.length; i++) {
      final hop = hops[i];
      final txId = await sendTokens(
        from: hop.from,
        to: hop.to,
        amount: hop.amount,
        signer: hop.signer,
        signerUrl: hop.signerUrl,
      );
      txIds.add(txId);

      // Wait between hops (except after the last one)
      if (i < hops.length - 1) {
        await Future.delayed(processingDelayBetweenHops);
      }
    }

    return txIds;
  }

  // ============================================================
  // DATA ACCOUNT OPERATIONS
  // ============================================================

  /// Create a data account under an ADI
  Future<String?> createDataAccount({
    required String adiUrl,
    required String accountName,
    required Ed25519KeyPair signer,
    required String keyPageUrl,
  }) async {
    final accountUrl = "$adiUrl/$accountName";
    final signerVersion = await getKeyPageVersion(keyPageUrl);

    final body = TxBody.createDataAccount(url: accountUrl);

    final ctx = BuildContext(
      principal: adiUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      memo: "Create data account: $accountName",
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: body,
      keypair: signer,
      signerUrl: keyPageUrl,
      signerVersion: signerVersion,
    );

    final response = await client.v3.submit(envelope.toJson());
    return _extractTxId(response);
  }

  /// Write data to a data account
  ///
  /// Parameters:
  /// - [dataAccountUrl]: The data account URL
  /// - [data]: List of data entries (as strings, will be hex-encoded)
  /// - [signer]: The keypair to sign with
  /// - [keyPageUrl]: The key page URL for signing
  /// - [asHex]: If true, data is already hex-encoded; if false, will encode as UTF-8 then hex
  ///
  /// Returns the transaction ID if successful.
  Future<String?> writeData({
    required String dataAccountUrl,
    required List<String> data,
    required Ed25519KeyPair signer,
    required String keyPageUrl,
    bool asHex = false,
  }) async {
    final signerVersion = await getKeyPageVersion(keyPageUrl);

    // Convert data to hex if not already
    final hexData = asHex
        ? data
        : data.map((s) => toHex(Uint8List.fromList(s.codeUnits))).toList();

    final body = TxBody.writeData(entriesHex: hexData);

    final ctx = BuildContext(
      principal: dataAccountUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      memo: "Write data entry",
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: body,
      keypair: signer,
      signerUrl: keyPageUrl,
      signerVersion: signerVersion,
    );

    final response = await client.v3.submit(envelope.toJson());
    return _extractTxId(response);
  }

  // ============================================================
  // KEY MANAGEMENT OPERATIONS
  // ============================================================

  /// Add a key to a key page
  ///
  /// Automatically hashes the public key with SHA256.
  /// Invalidates the version cache after successful submission.
  Future<String?> addKey({
    required String keyPageUrl,
    required Ed25519KeyPair newKey,
    required Ed25519KeyPair signer,
  }) async {
    final signerVersion = await getKeyPageVersion(keyPageUrl);

    // Compute SHA256 hash of the new key
    final publicKey = await newKey.publicKeyBytes();
    final keyHash = sha256.convert(publicKey).bytes;

    final keySpec = KeySpecParams(keyHash: Uint8List.fromList(keyHash));
    final body = TxBody.updateKeyPage(
      operations: [AddKeyOperation(entry: keySpec)],
    );

    final ctx = BuildContext(
      principal: keyPageUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      memo: "Add key to key page",
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: body,
      keypair: signer,
      signerUrl: keyPageUrl,
      signerVersion: signerVersion,
    );

    final response = await client.v3.submit(envelope.toJson());
    final txId = _extractTxId(response);

    // Invalidate cache since key page version will change
    if (txId != null) invalidateVersionCache(keyPageUrl);

    return txId;
  }

  /// Remove a key from a key page
  ///
  /// Automatically hashes the public key with SHA256.
  /// Invalidates the version cache after successful submission.
  Future<String?> removeKey({
    required String keyPageUrl,
    required Ed25519KeyPair keyToRemove,
    required Ed25519KeyPair signer,
  }) async {
    final signerVersion = await getKeyPageVersion(keyPageUrl);

    // Compute SHA256 hash of the key to remove
    final publicKey = await keyToRemove.publicKeyBytes();
    final keyHash = sha256.convert(publicKey).bytes;

    final keySpec = KeySpecParams(keyHash: Uint8List.fromList(keyHash));
    final body = TxBody.updateKeyPage(
      operations: [RemoveKeyOperation(entry: keySpec)],
    );

    final ctx = BuildContext(
      principal: keyPageUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      memo: "Remove key from key page",
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: body,
      keypair: signer,
      signerUrl: keyPageUrl,
      signerVersion: signerVersion,
    );

    final response = await client.v3.submit(envelope.toJson());
    final txId = _extractTxId(response);

    // Invalidate cache since key page version will change
    if (txId != null) invalidateVersionCache(keyPageUrl);

    return txId;
  }

  /// Set the signature threshold for a key page
  ///
  /// Invalidates the version cache after successful submission.
  Future<String?> setThreshold({
    required String keyPageUrl,
    required int threshold,
    required Ed25519KeyPair signer,
  }) async {
    final signerVersion = await getKeyPageVersion(keyPageUrl);

    final body = TxBody.updateKeyPage(
      operations: [SetThresholdKeyPageOperation(threshold: threshold)],
    );

    final ctx = BuildContext(
      principal: keyPageUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      memo: "Set threshold to $threshold",
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: body,
      keypair: signer,
      signerUrl: keyPageUrl,
      signerVersion: signerVersion,
    );

    final response = await client.v3.submit(envelope.toJson());
    final txId = _extractTxId(response);

    // Invalidate cache since key page version will change
    if (txId != null) invalidateVersionCache(keyPageUrl);

    return txId;
  }

  /// Create a new key page under a key book
  Future<String?> createKeyPage({
    required String keyBookUrl,
    required Ed25519KeyPair initialKey,
    required Ed25519KeyPair signer,
    required String signerKeyPageUrl,
  }) async {
    final signerVersion = await getKeyPageVersion(signerKeyPageUrl);

    // Compute SHA256 hash of the initial key
    final publicKey = await initialKey.publicKeyBytes();
    final keyHash = sha256.convert(publicKey).bytes;

    final keySpec = KeySpecParams(keyHash: Uint8List.fromList(keyHash));
    final body = TxBody.createKeyPage(keys: [keySpec]);

    final ctx = BuildContext(
      principal: keyBookUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      memo: "Create new key page",
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: body,
      keypair: signer,
      signerUrl: signerKeyPageUrl,
      signerVersion: signerVersion,
    );

    final response = await client.v3.submit(envelope.toJson());
    return _extractTxId(response);
  }

  /// Create a new key book under an ADI
  Future<String?> createKeyBook({
    required String adiUrl,
    required String bookName,
    required Ed25519KeyPair initialKey,
    required Ed25519KeyPair signer,
    required String signerKeyPageUrl,
  }) async {
    final signerVersion = await getKeyPageVersion(signerKeyPageUrl);
    final bookUrl = "$adiUrl/$bookName";

    // Compute SHA256 hash of the initial key
    final publicKey = await initialKey.publicKeyBytes();
    final keyHash = sha256.convert(publicKey).bytes;
    final keyHashHex = toHex(Uint8List.fromList(keyHash));

    final body = TxBody.createKeyBook(
      url: bookUrl,
      publicKeyHash: keyHashHex,
    );

    final ctx = BuildContext(
      principal: adiUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      memo: "Create key book: $bookName",
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: body,
      keypair: signer,
      signerUrl: signerKeyPageUrl,
      signerVersion: signerVersion,
    );

    final response = await client.v3.submit(envelope.toJson());
    return _extractTxId(response);
  }

  // ============================================================
  // CUSTOM TOKEN OPERATIONS
  // ============================================================

  /// Create a custom token issuer
  Future<String?> createToken({
    required String adiUrl,
    required String tokenName,
    required String symbol,
    required int precision,
    required Ed25519KeyPair signer,
    required String keyPageUrl,
    String? supplyLimit,
  }) async {
    final signerVersion = await getKeyPageVersion(keyPageUrl);
    final tokenUrl = "$adiUrl/$tokenName";

    final body = TxBody.createToken(
      url: tokenUrl,
      symbol: symbol,
      precision: precision,
      supplyLimit: supplyLimit,
    );

    final ctx = BuildContext(
      principal: adiUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      memo: "Create token: $symbol",
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: body,
      keypair: signer,
      signerUrl: keyPageUrl,
      signerVersion: signerVersion,
    );

    final response = await client.v3.submit(envelope.toJson());
    return _extractTxId(response);
  }

  /// Issue tokens from a token issuer
  Future<String?> issueTokens({
    required String tokenUrl,
    required String toAccount,
    required String amount,
    required Ed25519KeyPair signer,
    required String keyPageUrl,
  }) async {
    final signerVersion = await getKeyPageVersion(keyPageUrl);

    final body = TxBody.issueTokensSingle(toUrl: toAccount, amount: amount);

    final ctx = BuildContext(
      principal: tokenUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      memo: "Issue $amount tokens",
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: body,
      keypair: signer,
      signerUrl: keyPageUrl,
      signerVersion: signerVersion,
    );

    final response = await client.v3.submit(envelope.toJson());
    return _extractTxId(response);
  }

  // ============================================================
  // FAUCET (DevNet only)
  // ============================================================

  /// Request tokens from the faucet (DevNet only)
  ///
  /// Requests ACME tokens multiple times to accumulate a balance.
  Future<List<String>> faucet(String tokenAccountUrl, {int times = 1}) async {
    final txIds = <String>[];
    for (int i = 0; i < times; i++) {
      try {
        final response = await client.v2.faucet({
          'type': 'acmeFaucet',
          'url': tokenAccountUrl,
        });
        final txId = response['txid'] as String?;
        if (txId != null) txIds.add(txId);
        if (i < times - 1) {
          await Future.delayed(Duration(seconds: 2));
        }
      } catch (e) {
        // Continue on error
      }
    }
    return txIds;
  }

  /// Fund account from faucet until it reaches minimum balance (DevNet only)
  ///
  /// Keeps requesting from faucet until the account has at least [minimumBalance].
  /// Useful for ensuring an account is properly funded before operations.
  ///
  /// Parameters:
  /// - [tokenAccountUrl]: The token account to fund
  /// - [minimumBalance]: Minimum balance required (in smallest units, e.g., 1000000000 = 10 ACME)
  /// - [maxAttempts]: Maximum faucet attempts before giving up
  /// - [delayBetweenAttempts]: Delay between faucet calls
  /// - [settlementDelay]: Delay after reaching target to ensure settlement
  ///
  /// Returns true if minimum balance was reached, false otherwise.
  Future<bool> fundUntilBalance({
    required String tokenAccountUrl,
    required BigInt minimumBalance,
    int maxAttempts = 10,
    Duration delayBetweenAttempts = const Duration(seconds: 3),
    Duration settlementDelay = const Duration(seconds: 10),
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      // Check current balance
      final balance = await getBalance(tokenAccountUrl);
      if (balance >= minimumBalance) {
        await Future.delayed(settlementDelay);
        return true;
      }

      // Request from faucet
      await faucet(tokenAccountUrl, times: 1);
      await Future.delayed(delayBetweenAttempts);
    }

    // Final check
    final finalBalance = await getBalance(tokenAccountUrl);
    return finalBalance >= minimumBalance;
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Wait for a transaction to be confirmed
  ///
  /// Polls the transaction status until it's delivered or times out.
  Future<bool> waitForTx(String txId, {Duration timeout = const Duration(seconds: 30)}) async {
    final startTime = DateTime.now();
    while (DateTime.now().difference(startTime) < timeout) {
      try {
        final result = await client.v3.query({
          "scope": txId,
          "query": {"@type": "DefaultQuery"}
        });

        final status = result["status"];
        if (status != null) {
          final delivered = status["delivered"] as bool? ?? false;
          if (delivered) return true;
        }
      } catch (e) {
        // Continue polling
      }
      await Future.delayed(Duration(seconds: 2));
    }
    return false;
  }

  /// Compute SHA256 hash of a public key
  static Uint8List hashPublicKey(Uint8List publicKey) {
    return Uint8List.fromList(sha256.convert(publicKey).bytes);
  }

  /// Convert bytes to hex string (use toHex from bytes.dart directly)
  static String bytesToHex(Uint8List bytes) => toHex(bytes);

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  String? _extractTxId(dynamic response) {
    if (response is List && response.isNotEmpty) {
      final firstResult = response[0];
      if (firstResult is Map && firstResult["status"] != null) {
        return firstResult["status"]["txID"]?.toString();
      }
    } else if (response is Map) {
      return (response["txid"] ?? response["transactionHash"])?.toString();
    }
    return null;
  }
}

/// Key page information
class KeyPageInfo {
  final String url;
  final int version;
  final int threshold;
  final int credits;
  final List<String> keys;

  KeyPageInfo({
    required this.url,
    required this.version,
    required this.threshold,
    required this.credits,
    required this.keys,
  });

  int get keyCount => keys.length;

  @override
  String toString() {
    return 'KeyPageInfo(url: $url, version: $version, threshold: $threshold, credits: $credits, keys: ${keys.length})';
  }
}

/// Internal class for caching key page versions
class _CachedVersion {
  final int version;
  final DateTime fetchTime;

  _CachedVersion(this.version, this.fetchTime);
}

/// Represents a single hop in a multi-hop token transfer
///
/// Used with [AccumulateHelper.transferTokensMultiHop] to define
/// each step in a token transfer chain.
class TransferHop {
  /// Source token account URL
  final String from;

  /// Destination token account URL
  final String to;

  /// Amount to transfer (in smallest units)
  final String amount;

  /// Keypair to sign the transaction
  final Ed25519KeyPair signer;

  /// Key page URL (required for ADI accounts, null for lite accounts)
  final String? signerUrl;

  TransferHop({
    required this.from,
    required this.to,
    required this.amount,
    required this.signer,
    this.signerUrl,
  });
}
