/// Accumulate Signing Helpers
///
/// This library provides developer-friendly abstractions for signing
/// transactions with any supported key type. It handles:
///
/// - Automatic signature algorithm selection based on key type
/// - Automatic signer version querying and caching
/// - Unified interface for all key types (Ed25519, RCD1, BTC, ETH, RSA, ECDSA)
/// - Key page management helpers
///
/// Main Classes:
///
/// - [SignatureAlgorithm] - Enum of all supported signature algorithms
/// - [UnifiedKeyPair] - Wraps any key type with a unified signing interface
/// - [SmartSigner] - Auto-queries signer version, provides sign() and signAndSubmit()
/// - [KeyManager] - Manages keys on a key page (add, remove, query)
///
/// Example Usage:
///
/// ```dart
/// import 'package:opendlt_accumulate/opendlt_accumulate.dart';
///
/// // Create client
/// final client = Accumulate.devNet();
///
/// // Create a unified key pair (from any key type)
/// final ed25519Key = await Ed25519KeyPair.generate();
/// final key = UnifiedKeyPair.fromEd25519(ed25519Key);
///
/// // Create a smart signer - no more manual version tracking!
/// final signer = SmartSigner(
///   client: client.v3,
///   keypair: key,
///   signerUrl: "acc://myadi.acme/book/1",
/// );
///
/// // Sign and submit in one call
/// final result = await signer.signAndSubmit(
///   principal: "acc://myadi.acme/tokens",
///   body: TxBody.sendTokensSingle(
///     toUrl: "acc://recipient.acme/tokens",
///     amount: "1000000",
///   ),
/// );
///
/// // Or sign, submit, and wait for delivery
/// final result = await signer.signSubmitAndWait(
///   principal: "acc://myadi.acme/data",
///   body: TxBody.writeData(entriesHex: ["48656c6c6f"]),
/// );
///
/// if (result.success) {
///   print("Transaction delivered: ${result.txid}");
/// } else {
///   print("Transaction failed: ${result.error}");
/// }
/// ```
///
/// Using Different Key Types:
///
/// ```dart
/// // ETH key (for networks with Baikonur upgrade)
/// final ethRawKey = Secp256k1KeyPair.generate();
/// final ethKey = UnifiedKeyPair.fromETH(ethRawKey);
///
/// // RSA key (for networks with Vandenberg upgrade)
/// final rsaRawKey = RsaKeyPair.generate(bitLength: 2048);
/// final rsaKey = UnifiedKeyPair.fromRSA(rsaRawKey);
///
/// // ECDSA key (for networks with Vandenberg upgrade)
/// final ecdsaRawKey = EcdsaKeyPair.generate(curve: "secp256r1");
/// final ecdsaKey = UnifiedKeyPair.fromECDSA(ecdsaRawKey);
///
/// // All use the same SmartSigner interface!
/// final signer = SmartSigner(
///   client: client.v3,
///   keypair: ethKey, // or rsaKey, or ecdsaKey
///   signerUrl: "acc://myadi.acme/book/1",
/// );
/// ```
///
/// Key Management:
///
/// ```dart
/// // Create a key manager
/// final manager = KeyManager(
///   client: client.v3,
///   keyPageUrl: "acc://myadi.acme/book/1",
/// );
///
/// // Query key page state
/// final info = await manager.getKeyPageInfo();
/// print("Version: ${info.version}");
/// print("Credits: ${info.creditBalance}");
/// print("Keys: ${info.keys.length}");
///
/// // Add a new key
/// final newKey = UnifiedKeyPair.fromEd25519(await Ed25519KeyPair.generate());
/// await manager.addKey(existingKey, newKey);
///
/// // Check if a key is on the page
/// if (await manager.hasKey(someKey)) {
///   print("Key is on page");
/// }
/// ```
library signing;

export "algorithm.dart";
export "unified_keypair.dart";
export "smart_signer.dart";
export "key_manager.dart";
