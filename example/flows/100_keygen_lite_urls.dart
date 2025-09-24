import "package:opendlt_accumulate/src/crypto/ed25519.dart";

Future<void> main() async {
  print("=== Accumulate Key Generation & Lite URL Derivation ===");

  // Generate new Ed25519 key pair
  print("Generating Ed25519 key pair...");
  final kp = await Ed25519KeyPair.generate();

  // Get public key
  final publicKey = await kp.publicKeyBytes();
  final publicKeyHex =
      publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  print("Public Key: $publicKeyHex");

  // Derive Lite Identity URL
  final lid = await kp.deriveLiteIdentityUrl();
  print("Lite Identity (LID): $lid");

  // Derive Lite Token Account URL for ACME
  final lta = await kp.deriveLiteTokenAccountUrl();
  print("Lite Token Account (LTA): $lta");

  print("\nThese URLs can be used to:");
  print("- LID: Identity for signing transactions");
  print("- LTA: Receive ACME tokens from faucet or transfers");
}
