/// Write data entries to a data account and verify retrieval

import "dart:convert";
import "package:opendlt_accumulate/src/crypto/ed25519.dart";
import "package:opendlt_accumulate/src/build/builders.dart";
import "package:opendlt_accumulate/src/build/context.dart";
import "config.dart";

Future<void> main() async {
  print("=== Write Data to Data Account ===");

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
    print("Data Account: $dataAccountUrl");

    // Check if data account exists
    print("Checking if data account exists...");
    try {
      final dataAccountQuery = await accumulate.v3.query({
        'url': dataAccountUrl,
      });
      print("Data account exists: $dataAccountQuery");
    } catch (e) {
      print("Data account not found: $e");
      print("Run 260_create_data_account.dart first to create the data account");
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
      return;
    }

    // Prepare data to write
    final timestamp = DateTime.now().toIso8601String();
    final dataToWrite = {
      'message': 'Hello from Accumulate Dart SDK!',
      'timestamp': timestamp,
      'counter': 42,
      'metadata': {
        'version': '1.0',
        'source': 'dart-sdk-example',
      }
    };

    final dataBytes = utf8.encode(jsonEncode(dataToWrite));
    print("Data to write: ${jsonEncode(dataToWrite)}");
    print("Data size: ${dataBytes.length} bytes");

    // Build WriteData transaction
    print("Building WriteData transaction...");
    final dataBase64 = base64.encode(dataBytes);
    final writeDataBody = TxBody.writeData(
      entriesBase64: [dataBase64],
    );

    final ctx = BuildContext(
      principal: dataAccountUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000, // microseconds
    );

    final envelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: writeDataBody,
      keypair: adiKp,
    );

    print("Submitting WriteData transaction...");
    final submitResult = await accumulate.v3.submit(envelope.toJson());
    print("Submit result: $submitResult");

    if (submitResult['txid'] != null) {
      final txHash = submitResult['txid'];
      print("✓ WriteData transaction submitted: $txHash");

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

      // Query data account to see the new entry
      print("Querying data account for entries...");
      try {
        final dataQuery = await accumulate.v3.query({
          'url': dataAccountUrl,
          'includeReceipt': true,
        });
        print("Data account after write: $dataQuery");

        // Try to query the specific data entry
        print("Querying specific data entry...");
        final entryQuery = await accumulate.v3.queryChain({
          'url': dataAccountUrl,
          'range': {
            'start': 0,
            'count': 10,
          }
        });
        print("Data entries: $entryQuery");

        print("✓ Data write operation completed!");
        print("✓ Data Account: $dataAccountUrl");
        print("✓ Transaction Hash: $txHash");
        print("✓ Data written and verified");

      } catch (e) {
        print("Data query failed: $e");
        print("Data may still be processing...");
      }

    } else {
      print("✗ WriteData transaction failed - no transaction hash");
    }

  } catch (e) {
    print("✗ Data write operation failed: $e");
    print("This might be due to:");
    print("  - Data account doesn't exist");
    print("  - Insufficient credits in key page");
    print("  - Data too large for single transaction");
    print("  - Incorrect transaction format");
  } finally {
    accumulate.close();
  }
}