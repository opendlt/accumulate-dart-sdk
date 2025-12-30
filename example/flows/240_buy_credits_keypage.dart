/// Purchase credits for an ADI key page

import "package:opendlt_accumulate/src/crypto/ed25519.dart";
import "package:opendlt_accumulate/src/build/builders.dart";
import "package:opendlt_accumulate/src/build/context.dart";
import "config.dart";

Future<void> main() async {
  print("=== Buy Credits for ADI Key Page ===");

  final config = await FlowConfig.fromDevNetDiscovery();
  final accumulate = config.make();

  try {
    // For demo purposes, generate key pairs
    // In real usage, these would be persistent and match the ADI created earlier
    print("Setting up demo key pairs...");
    final liteKp = await Ed25519KeyPair.generate();

    final lta = await liteKp.deriveLiteTokenAccountUrl();

    // Demo ADI URLs (would match those from 220_create_adi_v3.dart)
    final adiSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final adiUrl = "acc://demo-adi-$adiSuffix.acme";
    final keyBookUrl = "$adiUrl/book";
    final keyPageUrl = "$keyBookUrl/1";

    print("LTA (token source): $lta");
    print("Target Key Page: $keyPageUrl");

    // Check LTA has sufficient balance
    print("Checking LTA balance...");
    try {
      final ltaQuery = await accumulate.v3.query({
        'url': lta.toString(),
      });
      print("LTA balance: $ltaQuery");
    } catch (e) {
      print("LTA not found or no balance: $e");
      print("Ensure LTA is funded via faucet first");
      return;
    }

    // Check if key page exists
    print("Checking if key page exists...");
    try {
      final keyPageQuery = await accumulate.v3.query({
        'url': keyPageUrl,
      });
      print("Key page exists: $keyPageQuery");
    } catch (e) {
      print("Key page not found: $e");
      print("Run 220_create_adi_v3.dart first to create the ADI structure");
      return;
    }

    // Build AddCredits transaction for the key page
    print("Building AddCredits transaction for key page...");
    final addCreditsBody = TxBody.buyCredits(
      recipientUrl: keyPageUrl,
      amount: '500000', // Amount in credits to purchase
    );

    final ctx = BuildContext(
      principal: lta.toString(),
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000, // microseconds
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: addCreditsBody,
      keypair: liteKp,
    );

    print("Submitting AddCredits transaction...");
    final submitResult = await accumulate.v3.submit(envelope.toJson());
    print("Submit result: $submitResult");

    if (submitResult['txid'] != null) {
      final txHash = submitResult['txid'];
      print("[OK] AddCredits transaction submitted: $txHash");

      // Wait for processing
      print("Waiting for transaction to process...");
      await Future.delayed(Duration(seconds: 5));

      // Verify transaction
      try {
        final txQuery = await accumulate.v3.query({
          'txid': txHash,
        });
        print("Transaction status: $txQuery");
      } catch (e) {
        print("Transaction query failed: $e");
      }

      // Check key page credits
      print("Checking key page credits...");
      try {
        final keyPageQuery = await accumulate.v3.query({
          'url': keyPageUrl,
        });
        print("Key page after credits: $keyPageQuery");

        print("[OK] Credits successfully added to key page!");
        print("[OK] Key Page: $keyPageUrl");
        print("[OK] Transaction: $txHash");

      } catch (e) {
        print("Key page query failed: $e");
      }

    } else {
      print("[ERROR] AddCredits transaction failed - no transaction hash");
    }

  } catch (e) {
    print("[ERROR] AddCredits for key page failed: $e");
    print("This might be due to:");
    print("  - Insufficient balance in LTA");
    print("  - Key page doesn't exist");
    print("  - Incorrect transaction format");
  } finally {
    accumulate.close();
  }
}