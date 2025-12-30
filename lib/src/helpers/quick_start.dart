import '../facade/accumulate.dart';
import '../crypto/ed25519.dart';
import '../util/acc_url.dart';
import 'accumulate_helper.dart';

/// Ultra-simplified API for common Accumulate workflows
///
/// This class provides one-liner methods for the most common operations,
/// abstracting away all the complexity of key hashing, version tracking,
/// oracle fetching, etc.
///
/// Example - Complete ADI setup in 5 lines:
/// ```dart
/// final acc = QuickStart.devnet();
/// final wallet = await acc.createWallet();
/// await acc.fundWallet(wallet);
/// final adi = await acc.setupADI(wallet, "my-adi");
/// await acc.buyCreditsForADI(wallet, adi, 1000);
/// ```
class QuickStart {
  final Accumulate client;
  final AccumulateHelper helper;

  QuickStart._(this.client) : helper = AccumulateHelper(client);

  /// Connect to local DevNet
  static QuickStart devnet({String host = "127.0.0.1", int port = 26660}) {
    final client = Accumulate.custom(
      v2Endpoint: "http://$host:$port/v2",
      v3Endpoint: "http://$host:$port/v3",
    );
    return QuickStart._(client);
  }

  /// Connect to TestNet
  static QuickStart testnet() {
    final client = Accumulate.network(NetworkEndpoint.testnet);
    return QuickStart._(client);
  }

  /// Connect to MainNet
  static QuickStart mainnet() {
    final client = Accumulate.network(NetworkEndpoint.mainnet);
    return QuickStart._(client);
  }

  /// Connect with custom endpoints
  static QuickStart custom({required String v2Endpoint, required String v3Endpoint}) {
    final client = Accumulate.custom(v2Endpoint: v2Endpoint, v3Endpoint: v3Endpoint);
    return QuickStart._(client);
  }

  /// Close the client connection
  void close() => client.close();

  // ============================================================
  // WALLET MANAGEMENT
  // ============================================================

  /// Create a new wallet (keypair with derived lite account URLs)
  ///
  /// Returns a Wallet object containing the keypair and URLs.
  Future<Wallet> createWallet() async {
    final keypair = await Ed25519KeyPair.generate();
    final liteIdentity = await keypair.deriveLiteIdentityUrl();
    final liteTokenAccount = await keypair.deriveLiteTokenAccountUrl();

    return Wallet(
      keypair: keypair,
      liteIdentity: liteIdentity,
      liteTokenAccount: liteTokenAccount,
    );
  }

  /// Fund a wallet from the faucet (DevNet only)
  ///
  /// Requests tokens from faucet multiple times and waits for processing.
  Future<void> fundWallet(Wallet wallet, {int times = 5, Duration waitTime = const Duration(seconds: 15)}) async {
    await helper.faucet(wallet.liteTokenAccount.toString(), times: times);
    await Future.delayed(waitTime);
  }

  /// Get wallet balance
  Future<BigInt> getBalance(Wallet wallet) async {
    return helper.getBalance(wallet.liteTokenAccount.toString());
  }

  /// Get wallet credits
  Future<int> getCredits(Wallet wallet) async {
    return helper.getCreditBalance(wallet.liteIdentity.toString());
  }

  // ============================================================
  // ADI SETUP (One-Call Solutions)
  // ============================================================

  /// Create a complete ADI setup with a single call
  ///
  /// Creates an ADI with a key book and key page, returns an ADISetup object.
  /// You still need to add credits to the key page before using the ADI.
  ///
  /// Example:
  /// ```dart
  /// final adi = await acc.setupADI(wallet, "my-adi");
  /// await acc.buyCreditsForADI(wallet, adi, 500);
  /// ```
  Future<ADISetup> setupADI(Wallet fundingWallet, String name, {Ed25519KeyPair? adiKeypair}) async {
    // Generate ADI keypair if not provided
    final adiKp = adiKeypair ?? await Ed25519KeyPair.generate();

    // First, ensure the lite identity has credits
    final credits = await helper.getCreditBalance(fundingWallet.liteIdentity.toString());
    if (credits < 100) {
      // Need at least 100 credits
      await helper.buyCredits(
        from: fundingWallet.liteTokenAccount.toString(),
        to: fundingWallet.liteIdentity.toString(),
        credits: 500,
        signer: fundingWallet.keypair,
      );
      await Future.delayed(Duration(seconds: 10));
    }

    // Create the ADI
    await helper.createADI(
      name: name,
      fundingAccount: fundingWallet.liteTokenAccount.toString(),
      fundingSigner: fundingWallet.keypair,
      adiSigner: adiKp,
    );

    await Future.delayed(Duration(seconds: 10));

    return ADISetup(
      name: name,
      url: "acc://$name.acme",
      keyBookUrl: "acc://$name.acme/book",
      keyPageUrl: "acc://$name.acme/book/1",
      keypair: adiKp,
    );
  }

  /// Complete one-call setup: Fund wallet, create ADI, add credits to key page
  ///
  /// This is the ultimate convenience method that does everything from scratch:
  /// 1. Funds the wallet from faucet (DevNet only)
  /// 2. Buys credits for the lite identity
  /// 3. Creates the ADI with key book and key page
  /// 4. Buys credits for the ADI's key page
  ///
  /// Example:
  /// ```dart
  /// final acc = QuickStart.devnet();
  /// final wallet = await acc.createWallet();
  /// final result = await acc.setupCompleteADI(
  ///   wallet: wallet,
  ///   adiName: "my-adi",
  /// );
  /// // Ready to use: result.adi.keyPageUrl has credits
  /// ```
  ///
  /// Parameters:
  /// - [wallet]: The wallet to fund and use for setup
  /// - [adiName]: Name for the ADI (without .acme suffix)
  /// - [faucetCalls]: Number of faucet requests (DevNet only)
  /// - [creditsForLiteIdentity]: Credits to buy for the lite identity
  /// - [creditsForKeyPage]: Credits to buy for the ADI key page
  /// - [adiKeypair]: Optional keypair for ADI (generated if not provided)
  /// - [processingDelay]: Delay between operations for settlement
  Future<CompleteADISetup> setupCompleteADI({
    required Wallet wallet,
    required String adiName,
    int faucetCalls = 5,
    int creditsForLiteIdentity = 500,
    int creditsForKeyPage = 500,
    Ed25519KeyPair? adiKeypair,
    Duration processingDelay = const Duration(seconds: 15),
  }) async {
    // Step 1: Fund wallet from faucet
    await fundWallet(wallet, times: faucetCalls, waitTime: processingDelay);

    // Step 2: Buy credits for lite identity
    await helper.buyCredits(
      from: wallet.liteTokenAccount.toString(),
      to: wallet.liteIdentity.toString(),
      credits: creditsForLiteIdentity,
      signer: wallet.keypair,
    );
    await Future.delayed(processingDelay);

    // Step 3: Create ADI
    final adiKp = adiKeypair ?? await Ed25519KeyPair.generate();
    await helper.createADI(
      name: adiName,
      fundingAccount: wallet.liteTokenAccount.toString(),
      fundingSigner: wallet.keypair,
      adiSigner: adiKp,
    );
    await Future.delayed(processingDelay);

    // Step 4: Buy credits for key page
    final keyPageUrl = "acc://$adiName.acme/book/1";
    await helper.buyCredits(
      from: wallet.liteTokenAccount.toString(),
      to: keyPageUrl,
      credits: creditsForKeyPage,
      signer: wallet.keypair,
    );
    await Future.delayed(processingDelay);

    final adi = ADISetup(
      name: adiName,
      url: "acc://$adiName.acme",
      keyBookUrl: "acc://$adiName.acme/book",
      keyPageUrl: keyPageUrl,
      keypair: adiKp,
    );

    return CompleteADISetup(
      fundingWallet: wallet,
      adi: adi,
    );
  }

  /// Buy credits for an ADI's key page
  ///
  /// Uses the funding wallet to purchase credits for the ADI's key page.
  Future<String?> buyCreditsForADI(Wallet fundingWallet, ADISetup adi, int credits) async {
    return helper.buyCredits(
      from: fundingWallet.liteTokenAccount.toString(),
      to: adi.keyPageUrl,
      credits: credits,
      signer: fundingWallet.keypair,
    );
  }

  // ============================================================
  // TOKEN OPERATIONS (Simplified)
  // ============================================================

  /// Send ACME tokens from a lite account
  Future<String?> sendFromLite(Wallet wallet, String toAccount, String amount) async {
    return helper.sendTokens(
      from: wallet.liteTokenAccount.toString(),
      to: toAccount,
      amount: amount,
      signer: wallet.keypair,
    );
  }

  /// Send tokens from an ADI token account
  Future<String?> sendFromADI(ADISetup adi, String fromAccountName, String toAccount, String amount) async {
    return helper.sendTokens(
      from: "${adi.url}/$fromAccountName",
      to: toAccount,
      amount: amount,
      signer: adi.keypair,
      signerUrl: adi.keyPageUrl,
    );
  }

  /// Create a token account under an ADI
  Future<String?> createTokenAccount(ADISetup adi, String accountName, {String tokenUrl = "acc://ACME"}) async {
    return helper.createTokenAccount(
      adiUrl: adi.url,
      accountName: accountName,
      signer: adi.keypair,
      keyPageUrl: adi.keyPageUrl,
      tokenUrl: tokenUrl,
    );
  }

  // ============================================================
  // DATA OPERATIONS (Simplified)
  // ============================================================

  /// Create a data account under an ADI
  Future<String?> createDataAccount(ADISetup adi, String accountName) async {
    return helper.createDataAccount(
      adiUrl: adi.url,
      accountName: accountName,
      signer: adi.keypair,
      keyPageUrl: adi.keyPageUrl,
    );
  }

  /// Write string data to a data account
  Future<String?> writeData(ADISetup adi, String accountName, List<String> data) async {
    return helper.writeData(
      dataAccountUrl: "${adi.url}/$accountName",
      data: data,
      signer: adi.keypair,
      keyPageUrl: adi.keyPageUrl,
    );
  }

  // ============================================================
  // KEY MANAGEMENT (Simplified)
  // ============================================================

  /// Add a new key to an ADI's key page
  Future<String?> addKeyToADI(ADISetup adi, Ed25519KeyPair newKey) async {
    return helper.addKey(
      keyPageUrl: adi.keyPageUrl,
      newKey: newKey,
      signer: adi.keypair,
    );
  }

  /// Set multi-sig threshold for an ADI
  Future<String?> setMultiSigThreshold(ADISetup adi, int threshold) async {
    return helper.setThreshold(
      keyPageUrl: adi.keyPageUrl,
      threshold: threshold,
      signer: adi.keypair,
    );
  }

  // ============================================================
  // CUSTOM TOKEN OPERATIONS (Simplified)
  // ============================================================

  /// Create a custom token issuer under an ADI
  Future<CustomToken> createCustomToken(
    ADISetup adi,
    String tokenName,
    String symbol,
    int precision,
  ) async {
    await helper.createToken(
      adiUrl: adi.url,
      tokenName: tokenName,
      symbol: symbol,
      precision: precision,
      signer: adi.keypair,
      keyPageUrl: adi.keyPageUrl,
    );

    return CustomToken(
      url: "${adi.url}/$tokenName",
      symbol: symbol,
      precision: precision,
      adi: adi,
    );
  }

  /// Issue custom tokens to an account
  Future<String?> issueCustomTokens(CustomToken token, String toAccount, String amount) async {
    return helper.issueTokens(
      tokenUrl: token.url,
      toAccount: toAccount,
      amount: amount,
      signer: token.adi.keypair,
      keyPageUrl: token.adi.keyPageUrl,
    );
  }

  // ============================================================
  // QUERY HELPERS
  // ============================================================

  /// Get account information
  Future<Map<String, dynamic>?> getAccount(String url) async {
    return helper.getAccount(url);
  }

  /// Get key page information
  Future<KeyPageInfo?> getKeyPageInfo(String keyPageUrl) async {
    return helper.getKeyPageInfo(keyPageUrl);
  }

  /// Wait for a transaction to be confirmed
  Future<bool> waitForTx(String txId, {Duration timeout = const Duration(seconds: 30)}) async {
    return helper.waitForTx(txId, timeout: timeout);
  }
}

/// Wallet containing a keypair and derived lite account URLs
class Wallet {
  final Ed25519KeyPair keypair;
  final AccUrl liteIdentity;
  final AccUrl liteTokenAccount;

  Wallet({
    required this.keypair,
    required this.liteIdentity,
    required this.liteTokenAccount,
  });

  @override
  String toString() => 'Wallet(liteIdentity: $liteIdentity, liteTokenAccount: $liteTokenAccount)';
}

/// ADI setup containing all URLs and the controlling keypair
class ADISetup {
  final String name;
  final String url;
  final String keyBookUrl;
  final String keyPageUrl;
  final Ed25519KeyPair keypair;

  ADISetup({
    required this.name,
    required this.url,
    required this.keyBookUrl,
    required this.keyPageUrl,
    required this.keypair,
  });

  @override
  String toString() => 'ADISetup(name: $name, url: $url)';
}

/// Custom token issuer information
class CustomToken {
  final String url;
  final String symbol;
  final int precision;
  final ADISetup adi;

  CustomToken({
    required this.url,
    required this.symbol,
    required this.precision,
    required this.adi,
  });

  @override
  String toString() => 'CustomToken(url: $url, symbol: $symbol)';
}

/// Result of setupCompleteADI - contains both funding wallet and ADI setup
///
/// This provides everything needed to start using an ADI immediately:
/// - The funding wallet (for sending more tokens/credits)
/// - The ADI setup (for creating accounts, signing transactions)
class CompleteADISetup {
  /// The wallet used to fund the ADI (still has tokens for more operations)
  final Wallet fundingWallet;

  /// The fully set up ADI with credits on key page
  final ADISetup adi;

  CompleteADISetup({
    required this.fundingWallet,
    required this.adi,
  });

  @override
  String toString() => 'CompleteADISetup(wallet: $fundingWallet, adi: $adi)';
}
