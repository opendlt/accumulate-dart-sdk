/// Accumulate Cryptographic Key Pairs
///
/// This library provides key generation, signing, and verification for all
/// signature types supported by the Accumulate protocol.
///
/// Matches Go: protocol/signature.go
library crypto;

// Ed25519 key pair (standard Accumulate signature type)
export "ed25519.dart";

// RCD1 key pair (Factom-style Ed25519 with RCD1 hash)
export "rcd1.dart";

// Secp256k1 key pair (BTC and ETH signatures)
export "secp256k1.dart";

// RSA key pair (RSA-SHA256 signatures)
export "rsa.dart";

// ECDSA key pair (ECDSA-SHA256 with P-256/P-384/P-521 curves)
export "ecdsa.dart";
