/// Send ACME tokens from Lite Token Account to ADI Token Account

import "package:opendlt_accumulate/src/crypto/ed25519.dart";
import "package:opendlt_accumulate/src/build/builders.dart";
import "package:opendlt_accumulate/src/build/context.dart";
import "config.dart";

Future<void> main() async {
  print("=== Send Tokens: LTA → ADI Token Account ===");

  final config = await FlowConfig.fromDevNetDiscovery();
  final accumulate = config.make();

  try {
    // Demo key pairs (would be persistent in real usage)
    print("Setting up demo key pairs...");
    final liteKp = await Ed25519KeyPair.generate();
    final adiKp = await Ed25519KeyPair.generate();

    final lta = await liteKp.deriveLiteTokenAccountUrl();

    // Demo ADI URLs (would match those from previous steps)
    final adiSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final adiUrl = "acc://demo-adi-$adiSuffix.acme";
    final adiTokenAccountUrl = "$adiUrl/tokens";

    print("Source LTA: $lta");
    print("Target ADI Token Account: $adiTokenAccountUrl");

    // Check LTA balance
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

    // Check if ADI token account exists
    print("Checking ADI token account...");
    try {
      final adiTokenQuery = await accumulate.v3.query({
        'url': adiTokenAccountUrl,
      });
      print("ADI token account exists: $adiTokenQuery");
    } catch (e) {
      print("ADI token account not found: $e");
      print("Run 250_create_token_account.dart first to create the token account");
      return;
    }

    // Build SendTokens transaction
    print("Building SendTokens transaction...");
    final sendTokensBody = TxBody.sendTokens(
      toUrl: adiTokenAccountUrl,
      amount: '50000000', // 0.5 ACME (in credits, 10^8 = 1 ACME)
    );

    final ctx = BuildContext(
      principal: lta.toString(),
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000, // microseconds
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: sendTokensBody,
      keypair: liteKp,
    );

    print("Submitting SendTokens transaction...");
    final submitResult = await accumulate.v3.submit(envelope.toJson());
    print("Submit result: $submitResult");

    if (submitResult['txid'] != null) {
      final txHash = submitResult['txid'];
      print("✓ SendTokens transaction submitted: $txHash");

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

      // Check balances after transfer
      print("Checking balances after transfer...");

      try {
        print("LTA balance after send:");
        final ltaAfterQuery = await accumulate.v3.query({
          'url': lta.toString(),
        });
        print("  $ltaAfterQuery");

        print("ADI token account balance after receive:");
        final adiTokenAfterQuery = await accumulate.v3.query({
          'url': adiTokenAccountUrl,
        });
        print("  $adiTokenAfterQuery");

        print("✓ Token transfer completed successfully!");
        print("✓ Source: $lta");
        print("✓ Destination: $adiTokenAccountUrl");
        print("✓ Transaction Hash: $txHash");
        print("✓ Amount: 0.5 ACME");

      } catch (e) {
        print("Balance check failed: $e");
        print("Transfer may still be processing...");
      }

    } else {
      print("✗ SendTokens transaction failed - no transaction hash");
    }

  } catch (e) {
    print("✗ Token transfer failed: $e");
    print("This might be due to:");
    print("  - Insufficient balance in LTA");
    print("  - ADI token account doesn't exist");
    print("  - Network processing issues");
    print("  - Incorrect transaction format");
  } finally {
    accumulate.close();
  }
}