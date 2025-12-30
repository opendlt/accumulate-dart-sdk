// examples\v3\SDK_Examples_file_10_UpdateKeyPageThreshold_v3.dart
// Demonstrates updating key page threshold - requires multiple keys for multi-sig
import 'dart:async';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

// Configurable endpoint constant - set to your local devnet
const String endPoint = "http://127.0.0.1:26660/v3";
int delayBeforePrintSeconds = 15;

Future<void> main() async {
  print("V3 API Endpoint: $endPoint");
  print("Example 10: Update Key Page Threshold (Multi-Sig)");
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
    // Generate key pairs
    final liteKp = await Ed25519KeyPair.generate();
    final adiKp = await Ed25519KeyPair.generate();
    final secondKey = await Ed25519KeyPair.generate();

    // Derive lite identity and token account URLs
    final lid = await liteKp.deriveLiteIdentityUrl();
    final lta = await liteKp.deriveLiteTokenAccountUrl();

    await printKeypairDetails(liteKp);

    // Fund the lite account with faucet
    print("Lite account URL: $lta\n");
    await addFundsToAccount(client, lta, times: 5);

    // Wait for faucet to process
    print("Waiting for faucet transactions to process...");
    await Future.delayed(Duration(seconds: 15));

    // Add credits to the lite identity
    await addCredits(client, lid, lta, 500, liteKp);

    // Wait for addCredits to settle
    print("Waiting for addCredits to settle...");
    await Future.delayed(Duration(seconds: 15));

    // Create an ADI
    String adiName = "threshold-${DateTime.now().millisecondsSinceEpoch}";
    await createAdi(client, lid, lta, adiKp, adiName, liteKp);

    // Wait for ADI creation to settle
    print("Waiting for ADI creation to settle...");
    await Future.delayed(Duration(seconds: 15));

    // Add credits to ADI key page
    String keyPageUrl = "acc://$adiName.acme/book/1";
    String keyBookUrl = "acc://$adiName.acme/book";
    print("Key Page URL: $keyPageUrl");
    print("Key Book URL: $keyBookUrl");
    await addCreditsToAdiKeyPage(client, lid, lta, keyPageUrl, 500, liteKp);

    // Pause to allow the addCredits transaction to settle
    print("Pausing to allow addCredits transaction to settle...");
    await Future.delayed(Duration(seconds: 20));

    // ========================================
    // THRESHOLD UPDATE OPERATIONS
    // ========================================

    // First, query the current key page state
    print("\n=== Querying Initial Key Page State ===");
    await queryKeyPageState(client, keyPageUrl);

    // Add a second key to the key page so we can set threshold to 2
    print("\n=== Adding Second Key to Key Page ===");
    final secondKeyBytes = await secondKey.publicKeyBytes();
    final secondKeyHash = sha256.convert(secondKeyBytes).bytes;
    await updateKeyPageAddKey(client, keyPageUrl, Uint8List.fromList(secondKeyHash), adiKp, keyPageUrl);

    // Wait for key addition to settle
    print("Waiting for key addition to settle...");
    await Future.delayed(Duration(seconds: 20));

    // Query key page again to see the new key
    print("\n=== Querying Key Page After Adding Second Key ===");
    await queryKeyPageState(client, keyPageUrl);

    // Now update the threshold to 2 (require both keys to sign)
    print("\n=== Updating Key Page Threshold to 2 ===");
    await updateKeyPageThreshold(client, keyPageUrl, 2, adiKp, keyPageUrl);

    // Wait for threshold update to settle
    print("Waiting for threshold update to settle...");
    await Future.delayed(Duration(seconds: 20));

    // Query key page again to verify threshold change
    print("\n=== Querying Key Page After Threshold Update ===");
    await queryKeyPageState(client, keyPageUrl);

    // Demonstrate setting threshold back to 1
    print("\n=== Setting Threshold Back to 1 ===");
    await updateKeyPageThreshold(client, keyPageUrl, 1, adiKp, keyPageUrl);

    // Wait for threshold update to settle
    print("Waiting for threshold update to settle...");
    await Future.delayed(Duration(seconds: 20));

    // Final query
    print("\n=== Final Key Page State ===");
    await queryKeyPageState(client, keyPageUrl);

    print("\n=== Example 10 Completed Successfully! ===");
    print("Created ADI: acc://$adiName.acme");
    print("Key Book URL: $keyBookUrl");
    print("Key Page URL: $keyPageUrl");
    print("Added second key to key page");
    print("Demonstrated threshold updates (1 -> 2 -> 1)");
  } finally {
    client.close();
  }
}

Future<void> updateKeyPageThreshold(
    dynamic client,
    String keyPageUrl,
    int newThreshold,
    Ed25519KeyPair signer,
    String signerKeyPageUrl) async {
  print("Updating key page threshold: $keyPageUrl to $newThreshold");

  try {
    // Query current key page version for signing
    int signerVersion = 1;
    try {
      final keyPageQuery = await client.v3.query({
        "scope": signerKeyPageUrl,
        "query": {"@type": "DefaultQuery"}
      });
      if (keyPageQuery["account"] != null) {
        signerVersion = keyPageQuery["account"]["version"] ?? 1;
        print("Current key page version: $signerVersion");
      }
    } catch (e) {
      print("Warning: Could not query key page version, using default: $e");
    }

    // Build update key page transaction using SetThresholdKeyPageOperation
    final updateKeyPageBody = TxBody.updateKeyPage(
      operations: [SetThresholdKeyPageOperation(threshold: newThreshold)],
    );

    // Create transaction context
    final ctx = BuildContext(
      principal: keyPageUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      memo: "Update key page threshold to $newThreshold",
    );

    // Sign and build envelope with correct version
    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: updateKeyPageBody,
      keypair: signer,
      signerUrl: signerKeyPageUrl,
      signerVersion: signerVersion,
    );

    final response = await client.v3.submit(envelope.toJson());
    print("Update threshold response: $response");

    // Extract transaction ID from response
    String? txId;
    if (response is List && response.isNotEmpty) {
      final firstResult = response[0];
      if (firstResult is Map && firstResult["status"] != null) {
        txId = firstResult["status"]["txID"]?.toString();
      }
    }
    if (txId != null) {
      print("UpdateKeyPage (threshold) Transaction ID: $txId");
    }
  } catch (e) {
    print("Error updating key page threshold: $e");
  }
}

Future<void> updateKeyPageAddKey(
    dynamic client,
    String keyPageUrl,
    Uint8List keyHash,
    Ed25519KeyPair signer,
    String signerKeyPageUrl) async {
  print("Adding key to key page: $keyPageUrl");

  try {
    // Query current key page version for signing
    int signerVersion = 1;
    try {
      final keyPageQuery = await client.v3.query({
        "scope": signerKeyPageUrl,
        "query": {"@type": "DefaultQuery"}
      });
      if (keyPageQuery["account"] != null) {
        signerVersion = keyPageQuery["account"]["version"] ?? 1;
        print("Current key page version: $signerVersion");
      }
    } catch (e) {
      print("Warning: Could not query key page version, using default: $e");
    }

    // Build update key page transaction using AddKeyOperation
    final keySpec = KeySpecParams(keyHash: keyHash);
    final updateKeyPageBody = TxBody.updateKeyPage(
      operations: [AddKeyOperation(entry: keySpec)],
    );

    // Create transaction context
    final ctx = BuildContext(
      principal: keyPageUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      memo: "Add new key to key page",
    );

    // Sign and build envelope with correct version
    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: updateKeyPageBody,
      keypair: signer,
      signerUrl: signerKeyPageUrl,
      signerVersion: signerVersion,
    );

    final response = await client.v3.submit(envelope.toJson());
    print("Add key response: $response");

    // Extract transaction ID from response
    String? txId;
    if (response is List && response.isNotEmpty) {
      final firstResult = response[0];
      if (firstResult is Map && firstResult["status"] != null) {
        txId = firstResult["status"]["txID"]?.toString();
      }
    }
    if (txId != null) {
      print("UpdateKeyPage (add key) Transaction ID: $txId");
    }
  } catch (e) {
    print("Error adding key to key page: $e");
  }
}

Future<void> queryKeyPageState(dynamic client, String keyPageUrl) async {
  try {
    print("Querying key page: $keyPageUrl");

    final keyPageQuery = await client.v3.query({
      "scope": keyPageUrl,
      "query": {
        "@type": "DefaultQuery"
      }
    });

    print("Key page query result:");

    // Display key page information
    if (keyPageQuery["account"] != null) {
      final data = keyPageQuery["account"];
      print("  Type: ${data['type'] ?? 'Unknown'}");
      print("  URL: ${data['url'] ?? keyPageUrl}");
      print("  Version: ${data['version'] ?? 'Unknown'}");
      print("  Accept Threshold: ${data['acceptThreshold'] ?? data['threshold'] ?? 'Not set'}");
      print("  Credits: ${data['creditBalance'] ?? data['credits'] ?? 'Unknown'}");

      if (data['keys'] != null) {
        final keys = data['keys'] as List;
        print("  Keys (${keys.length}):");
        for (int i = 0; i < keys.length; i++) {
          final key = keys[i];
          if (key is Map) {
            final pubKeyHash = key['publicKeyHash'] ?? key['publicKey'] ?? 'N/A';
            print("    Key ${i + 1}: $pubKeyHash");
          } else {
            print("    Key ${i + 1}: $key");
          }
        }
      }
    } else if (keyPageQuery["data"] != null) {
      final data = keyPageQuery["data"];
      print("  Type: ${data['type'] ?? 'Unknown'}");
      print("  URL: ${data['url'] ?? keyPageUrl}");
      print("  Threshold: ${data['threshold'] ?? 'Not set'}");
    } else {
      print("  Raw response: $keyPageQuery");
    }
  } catch (e) {
    print("Error querying key page state: $e");
  }
}

// Helper functions
Future<void> createAdi(dynamic client, AccUrl fromLid, AccUrl fromLta, Ed25519KeyPair adiSigner, String adiName, Ed25519KeyPair fundingSigner) async {
  final String identityUrl = "acc://$adiName.acme";
  final String bookUrl = "$identityUrl/book";

  final publicKey = await adiSigner.publicKeyBytes();
  final keyHash = sha256.convert(publicKey).bytes;
  final keyHashHex = keyHash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  print("Preparing to create identity:");
  print("ADI URL: $identityUrl");
  print("Key Book URL: $bookUrl");
  print("Key Hash: $keyHashHex");

  try {
    final createIdentityBody = TxBody.createIdentity(
      url: identityUrl,
      keyBookUrl: bookUrl,
      publicKeyHash: keyHashHex,
    );

    final ctx = BuildContext(
      principal: fromLta.toString(),
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      memo: "Create identity via Dart SDK V3",
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: createIdentityBody,
      keypair: fundingSigner,
    );

    final response = await client.v3.submit(envelope.toJson());
    print("Create identity response: $response");
  } catch (e) {
    print("Error creating ADI: $e");
  }
}

Future<void> addCreditsToAdiKeyPage(dynamic client, AccUrl fromLid, AccUrl fromLta, String keyPageUrl, int creditAmount, Ed25519KeyPair signer) async {
  print("Adding credits to ADI key page: $keyPageUrl with amount: $creditAmount");

  try {
    final networkStatus = await client.v3.rawCall("network-status", {});
    final oracle = networkStatus["oracle"]["price"] as int;
    print("Current oracle price: $oracle");

    final calculatedAmount = creditAmount * 2000000;

    final addCreditsBody = TxBody.buyCredits(
      recipientUrl: keyPageUrl,
      amount: calculatedAmount.toString(),
      oracle: oracle,
    );

    final ctx = BuildContext(
      principal: fromLta.toString(),
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      memo: "Add credits to key page",
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: addCreditsBody,
      keypair: signer,
    );

    final response = await client.v3.submit(envelope.toJson());
    print("Add credits response: $response");
  } catch (e) {
    print("Error adding credits: $e");
  }
}

Future<void> addFundsToAccount(dynamic client, AccUrl accountUrl, {int times = 10}) async {
  for (int i = 0; i < times; i++) {
    try {
      print("Adding funds attempt ${i + 1}/$times to $accountUrl");

      final faucetResponse = await client.v2.faucet({
        'type': 'acmeFaucet',
        'url': accountUrl.toString(),
      });

      print("Faucet response: $faucetResponse");

      if (faucetResponse['txid'] != null) {
        final txId = faucetResponse['txid'];
        print("Faucet transaction ID: $txId");
        await Future.delayed(Duration(seconds: 3));
      }
    } catch (e) {
      print("Faucet attempt ${i + 1} failed: $e");
      if (i < times - 1) {
        await Future.delayed(Duration(seconds: 3));
      }
    }
  }
}

Future<void> printKeypairDetails(Ed25519KeyPair kp) async {
  final publicKey = await kp.publicKeyBytes();
  final publicKeyHex = publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  print("Public Key: $publicKeyHex");
  print("Private Key: [HIDDEN - Use kp.privateKeyBytes() to access]");
  print("");
}

Future<void> addCredits(dynamic client, AccUrl recipient, AccUrl fromAccount, int creditAmount, Ed25519KeyPair signer) async {
  print("Preparing to add credits:");
  print("Recipient URL: $recipient");
  print("From Account: $fromAccount");
  print("Credit Amount: $creditAmount");

  try {
    print("Getting current oracle price from network...");
    final networkStatus = await client.v3.rawCall("network-status", {});
    final oracle = networkStatus["oracle"]["price"] as int;
    print("Current oracle price: $oracle");

    final calculatedAmount = creditAmount * 2000000;
    print("Calculated amount: $calculatedAmount");

    final addCreditsBody = TxBody.buyCredits(
      recipientUrl: recipient.toString(),
      amount: calculatedAmount.toString(),
      oracle: oracle,
    );

    final ctx = BuildContext(
      principal: fromAccount.toString(),
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      memo: "Add credits",
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: addCreditsBody,
      keypair: signer,
    );

    final response = await client.v3.submit(envelope.toJson());
    print("Add credits response: $response");
  } catch (e) {
    print("Error adding credits: $e");
  }
}
