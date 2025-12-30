/// Smart Signing Demo
///
/// This example demonstrates the new developer-friendly signing API that:
/// - Automatically queries signer version before each transaction
/// - Provides a unified interface for all key types
/// - Handles all the complexity of different signature algorithms
///
/// Compare this to the manual approach where you had to:
/// 1. Query the key page version manually
/// 2. Know which buildAndSign* method to use for each key type
/// 3. Track version updates after key page changes
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  print("=== Smart Signing Demo ===\n");

  // Create client
  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: "http://127.0.0.1:26660/v3",
  );

  try {
    // =========================================================
    // PART 1: Creating Unified Key Pairs
    // =========================================================
    print("--- Part 1: Creating Unified Key Pairs ---\n");

    // Ed25519 - standard Accumulate signature
    final ed25519Raw = await Ed25519KeyPair.generate();
    final ed25519Key = UnifiedKeyPair.fromEd25519(ed25519Raw);
    print("Ed25519 algorithm: ${ed25519Key.algorithm.description}");

    // ETH - Ethereum-style secp256k1 (V2 RSV format)
    final ethRaw = Secp256k1KeyPair.generate();
    final ethKey = UnifiedKeyPair.fromETH(ethRaw);
    print("ETH algorithm: ${ethKey.algorithm.description}");

    // RSA - RSA-SHA256 (requires Vandenberg upgrade)
    print("Generating RSA key (2048-bit)...");
    final rsaRaw = RsaKeyPair.generate(bitLength: 2048);
    final rsaKey = UnifiedKeyPair.fromRSA(rsaRaw);
    print("RSA algorithm: ${rsaKey.algorithm.description}");

    // ECDSA - ECDSA-SHA256 with P-256 (requires Vandenberg upgrade)
    final ecdsaRaw = EcdsaKeyPair.generate(curve: "secp256r1");
    final ecdsaKey = UnifiedKeyPair.fromECDSA(ecdsaRaw);
    print("ECDSA algorithm: ${ecdsaKey.algorithm.description}");

    // Get public key hashes for display
    print("\nPublic Key Hashes:");
    print("  Ed25519: ${toHex(await ed25519Key.publicKeyHash)}");
    print("  ETH: ${toHex(await ethKey.publicKeyHash)}");
    print("  RSA: ${toHex(await rsaKey.publicKeyHash)}");
    print("  ECDSA: ${toHex(await ecdsaKey.publicKeyHash)}");

    // =========================================================
    // PART 2: Using SmartSigner (auto-version querying)
    // =========================================================
    print("\n--- Part 2: SmartSigner (Auto-Version) ---\n");

    // In a real app, you'd have an existing ADI with a key page
    // For demo, we'll create a lite account and show the concept

    final liteKp = await Ed25519KeyPair.generate();
    final lta = await liteKp.deriveLiteTokenAccountUrl();
    final lid = await liteKp.deriveLiteIdentityUrl();

    print("Lite Token Account: $lta");
    print("Lite Identity: $lid");

    // Fund the lite account
    print("\nFunding lite account from faucet...");
    try {
      await client.v2.faucet({'type': 'acmeFaucet', 'url': lta.toString()});
      await client.v2.faucet({'type': 'acmeFaucet', 'url': lta.toString()});
      print("Faucet requests sent");
    } catch (e) {
      print("Faucet error: $e");
    }

    print("Waiting for funds...");
    await Future.delayed(Duration(seconds: 10));

    // Create a SmartSigner for the lite identity
    // Note: For lite accounts, the signer URL is the lite identity
    final liteKey = UnifiedKeyPair.fromEd25519(liteKp);
    final signer = SmartSigner(
      client: client.v3,
      keypair: liteKey,
      signerUrl: lid.toString(),
    );

    // SmartSigner auto-queries the signer version!
    print("\nQuerying signer version automatically...");
    final version = await signer.getSignerVersion();
    print("Cached version: $version");

    // =========================================================
    // PART 3: Sign and Submit with SmartSigner
    // =========================================================
    print("\n--- Part 3: Sign and Submit ---\n");

    // For this demo, we'll just show envelope creation
    // (actual submission would require credits on the lite identity)

    // Option A: Sign only (returns envelope)
    print("Option A: Sign a transaction (envelope only)");

    // Use addCredits which is supported by the binary encoder
    final envelope = await signer.sign(
      principal: lta.toString(),
      body: TxBody.addCredits(
        recipient: lid.toString(),
        amount: "1000000",
        oracle: 500,
      ),
      memo: "Smart signing demo",
    );
    print("Envelope created with ${envelope.signatures.length} signature(s)");
    print("Signature type: ${envelope.signatures.first.type}");

    // Option B: Sign and submit (will fail without balance, but shows API)
    print("\nOption B: Sign and submit in one call");
    try {
      final response = await signer.signAndSubmit(
        principal: lta.toString(),
        body: TxBody.addCredits(
          recipient: lid.toString(),
          amount: "1000000",
          oracle: 500,
        ),
      );
      final txid = (response as List?)?.firstOrNull?["status"]?["txID"];
      print("Submit response - TxID: $txid");
    } catch (e) {
      print("Submit error (expected if no balance): $e");
    }

    // Option C: Sign, submit, and wait for delivery
    print("\nOption C: Sign, submit, and wait (with polling)");
    try {
      final result = await signer.signSubmitAndWait(
        principal: lta.toString(),
        body: TxBody.addCredits(
          recipient: lid.toString(),
          amount: "1000000",
          oracle: 500,
        ),
        maxAttempts: 3,
        pollInterval: Duration(seconds: 2),
      );
      print("Result: ${result.success ? 'SUCCESS' : 'FAILED'}");
      if (result.txid != null) print("TxID: ${result.txid}");
      if (result.error != null) print("Error: ${result.error}");
    } catch (e) {
      print("Error (expected if insufficient balance): $e");
    }

    // =========================================================
    // PART 4: Key Type Comparison
    // =========================================================
    print("\n--- Part 4: All Key Types Use Same Interface ---\n");

    // With UnifiedKeyPair, all key types use the same sign() method!
    // The SDK handles the complexity internally.

    final keyTypes = <String, UnifiedKeyPair>{
      "Ed25519": UnifiedKeyPair.fromEd25519(await Ed25519KeyPair.generate()),
      "RCD1": UnifiedKeyPair.fromRCD1(await RCD1KeyPair.generate()),
      "BTC": UnifiedKeyPair.fromBTC(Secp256k1KeyPair.generate()),
      "ETH (V2)": UnifiedKeyPair.fromETH(Secp256k1KeyPair.generate()),
      "ETH (V1)": UnifiedKeyPair.fromETHv1(Secp256k1KeyPair.generate()),
      "RSA": UnifiedKeyPair.fromRSA(RsaKeyPair.generate(bitLength: 2048)),
      "ECDSA": UnifiedKeyPair.fromECDSA(EcdsaKeyPair.generate()),
    };

    print("Key Type             | Algorithm           | Upgrade Required");
    print("-" * 65);
    for (final entry in keyTypes.entries) {
      final algo = entry.value.algorithm;
      String upgrade = "-";
      if (algo.requiresBaikonur) upgrade = "Baikonur";
      if (algo.requiresVandenberg) upgrade = "Vandenberg";
      print("${entry.key.padRight(20)} | ${algo.description.padRight(19)} | $upgrade");
    }

    // =========================================================
    // SUMMARY
    // =========================================================
    print("\n=== Summary ===");
    print("""
The new Smart Signing API provides:

1. UnifiedKeyPair - Wraps any key type with unified interface
   - fromEd25519(), fromRCD1(), fromBTC(), fromETH(), fromRSA(), fromECDSA()
   - Automatically uses correct signature algorithm
   - No need to remember which buildAndSign* method to use

2. SmartSigner - Auto-queries signer version, caches it
   - sign() - Returns envelope, auto-queries version
   - signAndSubmit() - Signs and submits in one call
   - signSubmitAndWait() - Signs, submits, polls for delivery

3. KeyManager - Manages keys on a key page
   - getKeyPageState() - Query key page with details
   - addKey() - Add new key (auto-signs, auto-invalidates cache)
   - createSigner() - Create SmartSigner for a key

No more manual version tracking!
""");

  } finally {
    client.close();
  }
}
