/// Create ADI (Accumulate Digital Identifier) with key book and key page using V3

import "package:opendlt_accumulate/opendlt_accumulate.dart";
import "package:opendlt_accumulate/src/crypto/ed25519.dart";
import "package:opendlt_accumulate/src/build/builders.dart";
import "package:opendlt_accumulate/src/build/context.dart";
import "config.dart";

Future<void> main() async {
  print("=== Create ADI + Key Book + Key Page (V3) ===");

  final config = await FlowConfig.fromDevNetDiscovery();
  final accumulate = config.make();

  try {
    // Generate key pairs for lite identity (sponsor) and ADI management
    print("Setting up key pairs...");
    final sponsorKp = await Ed25519KeyPair.generate();
    final adiMgmtKp = await Ed25519KeyPair.generate();

    final sponsorLid = await sponsorKp.deriveLiteIdentityUrl();
    final sponsorLta = await sponsorKp.deriveLiteTokenAccountUrl();
    final adiMgmtPubKey = await adiMgmtKp.publicKeyBytes();

    print("Sponsor LID: $sponsorLid");
    print("Sponsor LTA: $sponsorLta");

    // Generate ADI URL (use a random suffix for demo)
    final adiSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final adiUrl = "acc://demo-adi-$adiSuffix.acme";
    final keyBookUrl = "$adiUrl/book";
    final keyPageUrl = "$keyBookUrl/1";

    print("ADI URL: $adiUrl");
    print("Key Book URL: $keyBookUrl");
    print("Key Page URL: $keyPageUrl");

    // Check sponsor has credits
    print("Checking sponsor credits...");
    try {
      final sponsorQuery = await accumulate.v3.query({
        'url': sponsorLid.toString(),
      });
      print("Sponsor query: $sponsorQuery");
    } catch (e) {
      print("Sponsor not found: $e");
      print("Run 210_buy_credits_lite.dart first to get credits");
      return;
    }

    // Step 1: Create ADI
    print("Creating ADI...");
    final createAdiBody = TxBody.createIdentity(
      url: adiUrl,
      keyBookName: "book",
      publicKeyHash: adiMgmtPubKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    );

    final adiCtx = BuildContext(
      principal: sponsorLid.toString(),
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000, // microseconds
    );

    final adiEnvelope = await TxSigner.buildAndSign(
      ctx: adiCtx,
      body: createAdiBody,
      keypair: sponsorKp,
    );

    final adiResult = await accumulate.v3.submit(adiEnvelope.toJson());
    print("ADI creation result: $adiResult");

    if (adiResult['txid'] != null) {
      print("✓ ADI created with tx: ${adiResult['txid']}");

      // Wait for processing
      await Future.delayed(Duration(seconds: 3));

      // Step 2: Create Key Book (not needed - automatically created with ADI)
      print("Key Book automatically created with ADI...");
      print("Key Book creation result: automatically handled");

      // Wait for processing
      await Future.delayed(Duration(seconds: 3));

      // Verify ADI structure
      print("Verifying ADI structure...");
      try {
        final adiQuery = await accumulate.v3.query({'url': adiUrl});
        print("ADI query: $adiQuery");

        final keyBookQuery = await accumulate.v3.query({'url': keyBookUrl});
        print("Key Book query: $keyBookQuery");

        final keyPageQuery = await accumulate.v3.query({'url': keyPageUrl});
        print("Key Page query: $keyPageQuery");

        print("✓ ADI creation completed successfully!");
        print("✓ ADI: $adiUrl");
        print("✓ Key Book: $keyBookUrl");
        print("✓ Key Page: $keyPageUrl");

      } catch (e) {
        print("Verification failed: $e");
      }
    } else {
      print("✗ ADI creation failed");
    }

  } catch (e) {
    print("✗ ADI creation sequence failed: $e");
    print("This might be due to:");
    print("  - Insufficient credits in sponsor account");
    print("  - ADI URL already exists");
    print("  - DevNet processing issues");
  } finally {
    accumulate.close();
  }
}