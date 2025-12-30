/// Purchase credits for a lite identity using tokens from LTA

import "package:opendlt_accumulate/src/crypto/ed25519.dart";
import "package:opendlt_accumulate/src/build/builders.dart";
import "package:opendlt_accumulate/src/build/context.dart";
import "config.dart";

Future<void> main() async {
  print("=== Buy Credits for Lite Identity ===");

  final config = await FlowConfig.fromDevNetDiscovery();
  final accumulate = config.make();

  try {
    // Generate key pair (in real usage, this would be persistent)
    print("Setting up demo key pair...");
    final kp = await Ed25519KeyPair.generate();
    final lid = await kp.deriveLiteIdentityUrl();
    final lta = await kp.deriveLiteTokenAccountUrl();

    print("Lite Identity (LID): $lid");
    print("Lite Token Account (LTA): $lta");

    // Check LTA balance first
    print("Checking LTA balance...");
    try {
      final ltaBalance = await accumulate.v3.query({
        'url': lta.toString(),
      });
      print("LTA balance query: $ltaBalance");
    } catch (e) {
      print("LTA not found or no balance: $e");
      print("Run 120_faucet_local_devnet.dart first to fund the LTA");
      return;
    }

    // Build AddCredits transaction
    print("Building AddCredits transaction...");

    // Create AddCredits transaction body
    final addCreditsTx = TxBody.buyCredits(
      recipientUrl: lid.toString(),
      amount: '1000000', // Amount in credits to purchase
    );

    // Create transaction context
    final ctx = BuildContext(
      principal: lta.toString(),
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000, // microseconds
    );

    // Sign and build envelope
    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: addCreditsTx,
      keypair: kp,
    );

    print("Submitting AddCredits transaction...");
    final submitResult = await accumulate.v3.submit(envelope.toJson());
    print("Submit result: $submitResult");

    // Extract transaction hash if available
    if (submitResult['txid'] != null) {
      final txHash = submitResult['txid'];
      print("[OK] Transaction submitted with hash: $txHash");

      // Wait for transaction to process
      print("Waiting for transaction to process...");
      await Future.delayed(Duration(seconds: 5));

      // Query the transaction to verify
      try {
        final txQuery = await accumulate.v3.query({
          'txid': txHash,
        });
        print("Transaction query result: $txQuery");
      } catch (e) {
        print("Transaction query failed: $e");
      }

      // Check LID credits
      print("Checking LID credits...");
      try {
        final lidQuery = await accumulate.v3.query({
          'url': lid.toString(),
        });
        print("LID query result: $lidQuery");
      } catch (e) {
        print("LID query failed: $e");
      }

      print("[OK] AddCredits transaction completed!");
    } else {
      print("[ERROR] No transaction hash returned");
    }

  } catch (e) {
    print("[ERROR] AddCredits transaction failed: $e");
    print("This might be due to:");
    print("  - Insufficient balance in LTA");
    print("  - Incorrect transaction format");
    print("  - DevNet processing issues");
  } finally {
    accumulate.close();
  }
}