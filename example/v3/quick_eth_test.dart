// Quick ETH test using existing ADI from earlier tests
import 'dart:convert';
import 'dart:typed_data';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  print("=== Quick ETH Test ===\n");

  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: "http://127.0.0.1:26660/v3",
  );

  try {
    // Use existing ADI from previous tests
    final keyPageUrl = "acc://multi-sig-1767087064768.acme/book/1";
    final dataAccountUrl = "acc://multi-sig-1767087064768.acme/test-data";

    // Query key page to see current state
    print("Querying key page: $keyPageUrl");
    final kpResult = await client.v3.rawCall("query", {
      "scope": keyPageUrl,
      "query": {"queryType": "default"}
    });

    final account = kpResult["account"];
    final version = account?["version"] ?? 1;
    final keys = account?["keys"] as List?;
    print("Key Page Version: $version");
    print("Keys on page:");
    if (keys != null) {
      for (var i = 0; i < keys.length; i++) {
        final hash = keys[i]['publicKeyHash'] ?? "?";
        print("  $i: $hash");
      }
    }

    // Generate a fresh ETH key
    final ethKey = Secp256k1KeyPair.generate();
    final ethKeyHash = ethKey.ethPublicKeyHash;
    print("\nNew ETH Key Hash: ${toHex(ethKeyHash)}");
    print("Check if this hash matches any key on the page above...");

    // Try to write data with ETH signature using fresh key
    // This SHOULD fail with "key does not belong to signer"
    print("\n--- Attempting WriteData with fresh ETH key (should fail) ---");

    final timestamp = DateTime.now().millisecondsSinceEpoch * 1000;
    final hexData = toHex(Uint8List.fromList("ETH test".codeUnits));
    final body = TxBody.writeData(entriesHex: [hexData]);

    final ctx = BuildContext(
      principal: dataAccountUrl,
      timestamp: timestamp,
      memo: "ETH Quick Test",
    );

    // Use V1 (DER format) for DevNet which doesn't have Baikonur enabled
    final envelope = await TxSigner.buildAndSignETHv1(
      ctx: ctx,
      body: body,
      keypair: ethKey,
      signerUrl: keyPageUrl,
      signerVersion: version,
    );

    // Print envelope JSON
    print("\nEnvelope JSON:");
    print(JsonEncoder.withIndent('  ').convert(envelope.toJson()));

    // Submit and get full response
    print("\n--- Submitting ---");
    final response = await client.v3.rawCall("submit", envelope.toJson());
    print("\n*** FULL RESPONSE ***");
    print(JsonEncoder.withIndent('  ').convert(response));

  } catch (e, stack) {
    print("Error: $e");
    print(stack);
  } finally {
    client.close();
  }
}
