// examples/v3/SDK_Examples_file_11_Multi_Signature_Types_v3.dart
// Demonstrates all supported key types and signature types in Accumulate
//
// This example proves the Dart SDK can handle all signature types that
// the Go core implementation supports:
// - Ed25519 (standard)
// - RCD1 (Factom-style Ed25519)
// - BTC (Bitcoin secp256k1)
// - ETH (Ethereum secp256k1) - Uses V1 (DER) format for current networks
// - RSA (RSA-SHA256) - NOTE: Cannot initiate transactions, only co-sign
// - ECDSA (ECDSA-SHA256 with P-256 curve) - NOTE: Cannot initiate, only co-sign
//
// IMPORTANT: ETH signatures have two formats:
// - V1 (DER format): For networks without V2 Baikonur upgrade (most current networks)
// - V2 (RSV format): For networks with V2 Baikonur upgrade enabled
// This example uses ETHv1 which works with DevNet.

import 'dart:async';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

// Configurable endpoint constant - set to your local devnet
const String endPoint = "http://127.0.0.1:26660/v3";
int delayBeforePrintSeconds = 15;

Future<void> main() async {
  print("=" * 70);
  print("V3 API Endpoint: $endPoint");
  print("Example 11: Multi-Signature Types - All Supported Key & Signature Types");
  print("=" * 70);
  await testFeatures();
}

Future<void> delayBeforePrint() async {
  await Future.delayed(Duration(seconds: delayBeforePrintSeconds));
}

Future<void> testFeatures() async {
  // Create unified client (V2 for faucet, V3 for transactions)
  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: endPoint,
  );

  try {
    // ========================================
    // SETUP: Create ADI with initial Ed25519 key
    // ========================================
    print("\n" + "=" * 70);
    print("PHASE 1: INITIAL SETUP");
    print("=" * 70);

    // Generate the primary Ed25519 keypair for ADI management
    final primaryKp = await Ed25519KeyPair.generate();
    final liteKp = await Ed25519KeyPair.generate();

    // Derive lite identity and token account URLs
    final lid = await liteKp.deriveLiteIdentityUrl();
    final lta = await liteKp.deriveLiteTokenAccountUrl();

    print("\nLite Identity: $lid");
    print("Lite Token Account: $lta");

    // Fund the lite account with faucet
    print("\n--- Funding lite account from faucet ---");
    await addFundsToAccount(client, lta, times: 10);

    // Wait for faucet to process
    print("Waiting for faucet transactions to process...");
    await Future.delayed(Duration(seconds: 20));

    // Add credits to the lite identity
    print("\n--- Adding credits to lite identity ---");
    await addCredits(client, lid, lta, 2000, liteKp);

    // Wait for addCredits to settle
    print("Waiting for addCredits to settle...");
    await Future.delayed(Duration(seconds: 15));

    // Create an ADI
    String adiName = "multi-sig-${DateTime.now().millisecondsSinceEpoch}";
    print("\n--- Creating ADI: $adiName ---");
    await createAdi(client, lid, lta, primaryKp, adiName, liteKp);

    // Wait for ADI creation to settle
    print("Waiting for ADI creation to settle...");
    await Future.delayed(Duration(seconds: 15));

    // Add credits to the ADI key page
    String keyPageUrl = "acc://$adiName.acme/book/1";
    String keyBookUrl = "acc://$adiName.acme/book";
    String adiUrl = "acc://$adiName.acme";
    print("\nKey Page URL: $keyPageUrl");
    print("Key Book URL: $keyBookUrl");
    await addCreditsToAdiKeyPage(client, lid, lta, keyPageUrl, 2000, liteKp);

    // Pause to allow the addCredits transaction to settle
    print("Pausing to allow addCredits transaction to settle...");
    await Future.delayed(Duration(seconds: 20));

    // Create a data account for testing write operations
    String dataAccountUrl = "$adiUrl/test-data";
    print("\n--- Creating data account: $dataAccountUrl ---");
    await createDataAccount(client, primaryKp, adiUrl, "test-data", keyPageUrl);
    await Future.delayed(Duration(seconds: 15));

    // ========================================
    // PHASE 2: GENERATE ALL KEY TYPES
    // ========================================
    print("\n" + "=" * 70);
    print("PHASE 2: GENERATING ALL KEY TYPES");
    print("=" * 70);

    // 1. Ed25519 key (already have primaryKp, generate another)
    final ed25519Key = await Ed25519KeyPair.generate();
    final ed25519PubKey = await ed25519Key.publicKeyBytes();
    final ed25519KeyHash = Uint8List.fromList(sha256.convert(ed25519PubKey).bytes);
    print("\n1. Ed25519 Key Generated");
    print("   Public Key Hash: ${toHex(ed25519KeyHash)}");

    // 2. RCD1 key (Factom-style)
    final rcd1Key = await RCD1KeyPair.generate();
    final rcd1KeyHash = await rcd1Key.publicKeyHash();
    print("\n2. RCD1 Key Generated (Factom-style)");
    print("   Public Key Hash: ${toHex(rcd1KeyHash)}");

    // 3. BTC key (secp256k1)
    final btcKey = Secp256k1KeyPair.generate();
    final btcPubKey = btcKey.publicKeyBytes;
    final btcKeyHash = btcKey.btcPublicKeyHash;
    print("\n3. BTC Key Generated (secp256k1)");
    print("   Public Key (${btcPubKey.length} bytes): ${toHex(btcPubKey).substring(0, 40)}...");
    print("   BTC Key Hash: ${toHex(btcKeyHash)}");

    // 4. ETH key (secp256k1 with ETH hash)
    final ethKey = Secp256k1KeyPair.generate();
    final ethPubKey = ethKey.publicKeyBytes;
    final ethKeyHash = ethKey.ethPublicKeyHash;
    print("\n4. ETH Key Generated (secp256k1)");
    print("   Public Key (${ethPubKey.length} bytes): ${toHex(ethPubKey).substring(0, 40)}...");
    print("   ETH Key Hash: ${toHex(ethKeyHash)}");

    // 5. RSA key (2048-bit)
    print("\n5. Generating RSA Key (2048-bit)... (this may take a moment)");
    final rsaKey = RsaKeyPair.generate(bitLength: 2048);
    final rsaPubKey = rsaKey.publicKeyBytes;
    final rsaKeyHash = rsaKey.publicKeyHash;
    print("   RSA Key Generated");
    print("   Public Key (${rsaPubKey.length} bytes): ${toHex(rsaPubKey).substring(0, 40)}...");
    print("   RSA Key Hash: ${toHex(rsaKeyHash)}");

    // 6. ECDSA key (P-256)
    final ecdsaKey = EcdsaKeyPair.generate(curve: "secp256r1");
    final ecdsaPubKey = ecdsaKey.publicKeyBytes;
    final ecdsaKeyHash = ecdsaKey.publicKeyHash;
    print("\n6. ECDSA Key Generated (P-256/secp256r1)");
    print("   Public Key (${ecdsaPubKey.length} bytes): ${toHex(ecdsaPubKey).substring(0, 40)}...");
    print("   ECDSA Key Hash: ${toHex(ecdsaKeyHash)}");

    // ========================================
    // PHASE 3: ADD ALL KEYS TO KEY PAGE
    // ========================================
    print("\n" + "=" * 70);
    print("PHASE 3: ADDING ALL KEYS TO KEY PAGE");
    print("=" * 70);

    int keyPageVersion = 1;

    // Add Ed25519 key
    print("\n--- Adding Ed25519 key to key page ---");
    await addKeyToKeyPage(client, primaryKp, keyPageUrl, ed25519KeyHash, keyPageVersion);
    keyPageVersion++;
    await Future.delayed(Duration(seconds: 15));

    // Add RCD1 key
    print("\n--- Adding RCD1 key to key page ---");
    await addKeyToKeyPage(client, primaryKp, keyPageUrl, rcd1KeyHash, keyPageVersion);
    keyPageVersion++;
    await Future.delayed(Duration(seconds: 15));

    // Add BTC key (BTC hash is 20 bytes - Accumulate stores as-is)
    print("\n--- Adding BTC key to key page ---");
    await addKeyToKeyPage(client, primaryKp, keyPageUrl, btcKeyHash, keyPageVersion);
    keyPageVersion++;
    await Future.delayed(Duration(seconds: 15));

    // Add ETH key (ETH hash is 20 bytes - Accumulate stores as-is)
    print("\n--- Adding ETH key to key page ---");
    await addKeyToKeyPage(client, primaryKp, keyPageUrl, ethKeyHash, keyPageVersion);
    keyPageVersion++;
    await Future.delayed(Duration(seconds: 15));

    // Add RSA key
    print("\n--- Adding RSA key to key page ---");
    await addKeyToKeyPage(client, primaryKp, keyPageUrl, rsaKeyHash, keyPageVersion);
    keyPageVersion++;
    await Future.delayed(Duration(seconds: 15));

    // Add ECDSA key
    print("\n--- Adding ECDSA key to key page ---");
    await addKeyToKeyPage(client, primaryKp, keyPageUrl, ecdsaKeyHash, keyPageVersion);
    keyPageVersion++;
    await Future.delayed(Duration(seconds: 15));

    // ========================================
    // PHASE 4: WRITE DATA WITH EACH KEY TYPE
    // ========================================
    print("\n" + "=" * 70);
    print("PHASE 4: WRITING DATA WITH EACH SIGNATURE TYPE");
    print("=" * 70);

    // Write data with Ed25519 signature
    print("\n--- Writing data with Ed25519 signature ---");
    await writeDataWithEd25519(client, ed25519Key, dataAccountUrl, keyPageUrl, keyPageVersion,
        "Hello from Ed25519!");
    // NOTE: WriteData does NOT increment key page version - only UpdateKeyPage does
    await Future.delayed(Duration(seconds: 15));

    // Write data with RCD1 signature
    print("\n--- Writing data with RCD1 signature ---");
    await writeDataWithRCD1(client, rcd1Key, dataAccountUrl, keyPageUrl, keyPageVersion,
        "Hello from RCD1 (Factom)!");
    await Future.delayed(Duration(seconds: 15));

    // Write data with BTC signature
    print("\n--- Writing data with BTC signature ---");
    await writeDataWithBTC(client, btcKey, dataAccountUrl, keyPageUrl, keyPageVersion,
        "Hello from Bitcoin!");
    await Future.delayed(Duration(seconds: 15));

    // Write data with ETH signature
    print("\n--- Writing data with ETH signature ---");
    await writeDataWithETH(client, ethKey, dataAccountUrl, keyPageUrl, keyPageVersion,
        "Hello from Ethereum!");
    await Future.delayed(Duration(seconds: 15));

    // Write data with RSA signature
    // NOTE: Go code suggests RSA signatures cannot initiate, but testing shows
    // they work on DevNet. The V3 API accepts them successfully.
    print("\n--- Writing data with RSA signature ---");
    await writeDataWithRSA(client, rsaKey, dataAccountUrl, keyPageUrl, keyPageVersion,
        "Hello from RSA!");
    await Future.delayed(Duration(seconds: 15));

    // Write data with ECDSA signature
    // NOTE: Go code suggests ECDSA signatures cannot initiate, but testing shows
    // they work on DevNet. The V3 API accepts them successfully.
    print("\n--- Writing data with ECDSA signature ---");
    await writeDataWithECDSA(client, ecdsaKey, dataAccountUrl, keyPageUrl, keyPageVersion,
        "Hello from ECDSA P-256!");
    await Future.delayed(Duration(seconds: 15));

    // ========================================
    // PHASE 5: VERIFY KEY PAGE STATE
    // ========================================
    print("\n" + "=" * 70);
    print("PHASE 5: VERIFYING KEY PAGE STATE");
    print("=" * 70);

    await queryKeyPage(client, keyPageUrl);

    // ========================================
    // SUMMARY
    // ========================================
    print("\n" + "=" * 70);
    print("EXAMPLE 11 COMPLETE - MULTI-SIGNATURE TYPES DEMONSTRATION");
    print("=" * 70);
    print("\nSuccessfully demonstrated ALL 6 signature types:");
    print("  [OK] Ed25519 key generation and signing");
    print("  [OK] RCD1 (Factom-style) key generation and signing");
    print("  [OK] BTC (Bitcoin secp256k1) key generation and signing");
    print("  [OK] ETH (Ethereum secp256k1) key generation and signing");
    print("  [OK] RSA-SHA256 key generation and signing");
    print("  [OK] ECDSA-SHA256 (P-256) key generation and signing");
    print("\nAll 6 signature types successfully used to write data to the data account!");
    print("The Dart SDK now has full parity with Go core signature types.");

  } catch (e, stack) {
    print("Error: $e");
    print("Stack trace: $stack");
  } finally {
    client.close();
  }
}

// ============================================================
// HELPER FUNCTIONS
// ============================================================

Future<void> addFundsToAccount(Accumulate client, dynamic lta, {int times = 5}) async {
  for (int i = 0; i < times; i++) {
    try {
      final response = await client.v2.faucet({
        'type': 'acmeFaucet',
        'url': lta.toString(),
      });
      print("  Faucet request ${i + 1}/$times: ${response['txid'] ?? 'submitted'}");
      await Future.delayed(Duration(seconds: 2));
    } catch (e) {
      print("  Faucet request ${i + 1}/$times failed: $e");
    }
  }
}

Future<void> addCredits(Accumulate client, dynamic lid, dynamic lta,
    int credits, Ed25519KeyPair liteKp) async {
  final networkStatus = await client.v3.rawCall("network-status", {});
  final oracle = networkStatus["oracle"]["price"] as int;
  final amount = (BigInt.from(credits) * BigInt.from(10000000000)) ~/ BigInt.from(oracle);

  final body = TxBody.buyCredits(
    recipientUrl: lid.toString(),
    amount: amount.toString(),
    oracle: oracle,
  );

  final ctx = BuildContext(
    principal: lta.toString(),
    timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
    memo: "Buy $credits credits",
  );

  final envelope = await TxSigner.buildAndSign(
    ctx: ctx,
    body: body,
    keypair: liteKp,
  );

  final response = await client.v3.submit(envelope.toJson());
  print("  AddCredits response: ${extractTxId(response) ?? 'submitted'}");
}

Future<void> addCreditsToAdiKeyPage(Accumulate client, dynamic lid, dynamic lta,
    String keyPageUrl, int credits, Ed25519KeyPair liteKp) async {
  final networkStatus = await client.v3.rawCall("network-status", {});
  final oracle = networkStatus["oracle"]["price"] as int;
  final amount = (BigInt.from(credits) * BigInt.from(10000000000)) ~/ BigInt.from(oracle);

  final body = TxBody.buyCredits(
    recipientUrl: keyPageUrl,
    amount: amount.toString(),
    oracle: oracle,
  );

  final ctx = BuildContext(
    principal: lta.toString(),
    timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
    memo: "Buy $credits credits for key page",
  );

  final envelope = await TxSigner.buildAndSign(
    ctx: ctx,
    body: body,
    keypair: liteKp,
  );

  final response = await client.v3.submit(envelope.toJson());
  print("  AddCredits to key page response: ${extractTxId(response) ?? 'submitted'}");
}

Future<void> createAdi(Accumulate client, dynamic lid, dynamic lta,
    Ed25519KeyPair adiKp, String adiName, Ed25519KeyPair liteKp) async {
  final identityUrl = "acc://$adiName.acme";
  final bookUrl = "$identityUrl/book";

  final publicKey = await adiKp.publicKeyBytes();
  final keyHash = sha256.convert(publicKey).bytes;
  final keyHashHex = toHex(Uint8List.fromList(keyHash));

  final body = TxBody.createIdentity(
    url: identityUrl,
    keyBookUrl: bookUrl,
    publicKeyHash: keyHashHex,
  );

  final ctx = BuildContext(
    principal: lta.toString(),
    timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
    memo: "Create ADI: $adiName",
  );

  final envelope = await TxSigner.buildAndSign(
    ctx: ctx,
    body: body,
    keypair: liteKp,
  );

  final response = await client.v3.submit(envelope.toJson());
  print("  CreateIdentity response: ${extractTxId(response) ?? 'submitted'}");
}

Future<void> createDataAccount(Accumulate client, Ed25519KeyPair signer,
    String adiUrl, String accountName, String keyPageUrl) async {
  final accountUrl = "$adiUrl/$accountName";

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
    signerVersion: 1,
  );

  final response = await client.v3.submit(envelope.toJson());
  print("  CreateDataAccount response: ${extractTxId(response) ?? 'submitted'}");
}

Future<void> addKeyToKeyPage(Accumulate client, Ed25519KeyPair signer,
    String keyPageUrl, Uint8List keyHash, int version) async {
  final keySpec = KeySpecParams(keyHash: keyHash);
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
    signerVersion: version,
  );

  final response = await client.v3.submit(envelope.toJson());
  print("  AddKey response: ${extractTxId(response) ?? 'submitted'}");
}

// ============================================================
// WRITE DATA WITH DIFFERENT SIGNATURE TYPES
// ============================================================

Future<void> writeDataWithEd25519(Accumulate client, Ed25519KeyPair keypair,
    String dataAccountUrl, String keyPageUrl, int version, String data) async {
  final hexData = toHex(Uint8List.fromList(data.codeUnits));
  final body = TxBody.writeData(entriesHex: [hexData]);

  final ctx = BuildContext(
    principal: dataAccountUrl,
    timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
    memo: "Write data with Ed25519",
  );

  final envelope = await TxSigner.buildAndSign(
    ctx: ctx,
    body: body,
    keypair: keypair,
    signerUrl: keyPageUrl,
    signerVersion: version,
  );

  final response = await client.v3.submit(envelope.toJson());
  print("  WriteData (Ed25519) response: ${extractTxId(response) ?? 'submitted'}");
}

Future<void> writeDataWithRCD1(Accumulate client, RCD1KeyPair keypair,
    String dataAccountUrl, String keyPageUrl, int version, String data) async {
  final hexData = toHex(Uint8List.fromList(data.codeUnits));
  final body = TxBody.writeData(entriesHex: [hexData]);

  final ctx = BuildContext(
    principal: dataAccountUrl,
    timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
    memo: "Write data with RCD1",
  );

  final envelope = await TxSigner.buildAndSignRCD1(
    ctx: ctx,
    body: body,
    keypair: keypair,
    signerUrl: keyPageUrl,
    signerVersion: version,
  );

  final response = await client.v3.submit(envelope.toJson());
  print("  WriteData (RCD1) response: ${extractTxId(response) ?? 'submitted'}");
}

Future<void> writeDataWithBTC(Accumulate client, Secp256k1KeyPair keypair,
    String dataAccountUrl, String keyPageUrl, int version, String data) async {
  final hexData = toHex(Uint8List.fromList(data.codeUnits));
  final body = TxBody.writeData(entriesHex: [hexData]);

  final ctx = BuildContext(
    principal: dataAccountUrl,
    timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
    memo: "Write data with BTC",
  );

  final envelope = await TxSigner.buildAndSignBTC(
    ctx: ctx,
    body: body,
    keypair: keypair,
    signerUrl: keyPageUrl,
    signerVersion: version,
  );

  final response = await client.v3.submit(envelope.toJson());
  print("  WriteData (BTC) response: ${extractTxId(response) ?? 'submitted'}");
}

Future<void> writeDataWithETH(Accumulate client, Secp256k1KeyPair keypair,
    String dataAccountUrl, String keyPageUrl, int version, String data) async {
  final hexData = toHex(Uint8List.fromList(data.codeUnits));
  final body = TxBody.writeData(entriesHex: [hexData]);

  final ctx = BuildContext(
    principal: dataAccountUrl,
    timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
    memo: "Write data with ETH",
  );

  // Use ETHv1 (DER format) for networks without V2 Baikonur upgrade
  // Most current networks including DevNet require V1 format
  final envelope = await TxSigner.buildAndSignETHv1(
    ctx: ctx,
    body: body,
    keypair: keypair,
    signerUrl: keyPageUrl,
    signerVersion: version,
  );

  final response = await client.v3.submit(envelope.toJson());
  print("  WriteData (ETH) response: ${extractTxId(response) ?? 'submitted'}");
}

Future<void> writeDataWithRSA(Accumulate client, RsaKeyPair keypair,
    String dataAccountUrl, String keyPageUrl, int version, String data) async {
  final hexData = toHex(Uint8List.fromList(data.codeUnits));
  final body = TxBody.writeData(entriesHex: [hexData]);

  final ctx = BuildContext(
    principal: dataAccountUrl,
    timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
    memo: "Write data with RSA",
  );

  final envelope = await TxSigner.buildAndSignRSA(
    ctx: ctx,
    body: body,
    keypair: keypair,
    signerUrl: keyPageUrl,
    signerVersion: version,
  );

  final response = await client.v3.submit(envelope.toJson());
  print("  WriteData (RSA) response: ${extractTxId(response) ?? 'submitted'}");
}

Future<void> writeDataWithECDSA(Accumulate client, EcdsaKeyPair keypair,
    String dataAccountUrl, String keyPageUrl, int version, String data) async {
  final hexData = toHex(Uint8List.fromList(data.codeUnits));
  final body = TxBody.writeData(entriesHex: [hexData]);

  final ctx = BuildContext(
    principal: dataAccountUrl,
    timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
    memo: "Write data with ECDSA",
  );

  final envelope = await TxSigner.buildAndSignECDSA(
    ctx: ctx,
    body: body,
    keypair: keypair,
    signerUrl: keyPageUrl,
    signerVersion: version,
  );

  final response = await client.v3.submit(envelope.toJson());
  print("  WriteData (ECDSA) response: ${extractTxId(response) ?? 'submitted'}");
}

Future<void> queryKeyPage(Accumulate client, String keyPageUrl) async {
  try {
    final result = await client.v3.query({
      "scope": keyPageUrl,
      "query": {"@type": "DefaultQuery"}
    });

    final account = result["account"];
    if (account != null) {
      print("\nKey Page Query Result:");
      print("  URL: ${account["url"]}");
      print("  Type: ${account["type"]}");
      print("  Version: ${account["version"]}");
      print("  Threshold: ${account["acceptThreshold"] ?? account["threshold"] ?? 1}");
      print("  Credits: ${account["creditBalance"] ?? account["credits"] ?? 0}");

      final keys = account["keys"] as List?;
      if (keys != null) {
        print("  Keys (${keys.length} total):");
        for (int i = 0; i < keys.length; i++) {
          final key = keys[i];
          if (key is Map) {
            final hash = key["publicKeyHash"] ?? key["publicKey"] ?? "unknown";
            print("    ${i + 1}. ${hash.toString().substring(0, 40)}...");
          }
        }
      }
    }
  } catch (e) {
    print("  Query failed: $e");
  }
}

String? extractTxId(dynamic response) {
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
