/// Create a data account under an ADI for storing arbitrary data

import "package:opendlt_accumulate/src/crypto/ed25519.dart";
import "package:opendlt_accumulate/src/build/builders.dart";
import "package:opendlt_accumulate/src/build/context.dart";
import "config.dart";

Future<void> main() async {
  print("=== Create ADI Data Account ===");

  final config = await FlowConfig.fromDevNetDiscovery();
  final accumulate = config.make();

  try {
    // Demo key pairs (would be persistent in real usage)
    print("Setting up demo key pairs...");
    final adiKp = await Ed25519KeyPair.generate();

    // Demo ADI URLs (would match those from previous steps)
    final adiSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final adiUrl = "acc://demo-adi-$adiSuffix.acme";
    final keyPageUrl = "$adiUrl/book/1";
    final dataAccountUrl = "$adiUrl/data";

    print("ADI: $adiUrl");
    print("Key Page: $keyPageUrl");
    print("Data Account: $dataAccountUrl");

    // Check if ADI exists
    print("Checking if ADI exists...");
    try {
      final adiQuery = await accumulate.v3.query({
        'url': adiUrl,
      });
      print("ADI exists: $adiQuery");
    } catch (e) {
      print("ADI not found: $e");
      print("Run 220_create_adi_v3.dart first to create the ADI");
      return;
    }

    // Check if key page has credits
    print("Checking key page credits...");
    try {
      final keyPageQuery = await accumulate.v3.query({
        'url': keyPageUrl,
      });
      print("Key page status: $keyPageQuery");
    } catch (e) {
      print("Key page not found: $e");
      print("Ensure key page exists and has credits");
      return;
    }

    // Build CreateDataAccount transaction
    print("Building CreateDataAccount transaction...");
    final createDataAccountBody = TxBody.createDataAccount(
      url: dataAccountUrl,
    );

    final ctx = BuildContext(
      principal: adiUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000, // microseconds
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: createDataAccountBody,
      keypair: adiKp,
    );

    print("Submitting CreateDataAccount transaction...");
    final submitResult = await accumulate.v3.submit(envelope.toJson());
    print("Submit result: $submitResult");

    if (submitResult['txid'] != null) {
      final txHash = submitResult['txid'];
      print("✓ CreateDataAccount transaction submitted: $txHash");

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

      // Check if data account was created
      print("Verifying data account creation...");
      try {
        final dataAccountQuery = await accumulate.v3.query({
          'url': dataAccountUrl,
        });
        print("Data account query: $dataAccountQuery");

        print("✓ Data account created successfully!");
        print("✓ Data Account URL: $dataAccountUrl");
        print("✓ Transaction Hash: $txHash");
        print("✓ Ready for data storage operations");

      } catch (e) {
        print("Data account query failed: $e");
        print("Account may still be processing...");
      }

    } else {
      print("✗ CreateDataAccount transaction failed - no transaction hash");
    }

  } catch (e) {
    print("✗ Data account creation failed: $e");
    print("This might be due to:");
    print("  - ADI doesn't exist");
    print("  - Insufficient credits in key page");
    print("  - Data account URL already exists");
    print("  - Incorrect transaction format");
  } finally {
    accumulate.close();
  }
}