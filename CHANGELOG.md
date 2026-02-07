# Changelog

All notable changes to the opendlt-accumulate Dart SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.2] - 2026-02-07

### Fixed
- Fixed and verified all v3 examples against Kermit public testnet
- Modernized Multi-Signature Types example with SmartSigner and UnifiedKeyPair
- Updated QuickStart and AccumulateHelper examples for Kermit endpoints
- Removed duplicate custom tokens example

## [2.0.0] - 2025-12-30

### Added

#### Multi-Signature Support
- RCD1 (Factom-style) signature support with proper public key hash computation
- BTC (Bitcoin secp256k1) signature support with compressed public keys
- BTCLegacy signature support for legacy Bitcoin compatibility
- ETH (Ethereum secp256k1) signature support with Keccak-256 hashing
- RSA-SHA256 signature support (2048-4096 bit keys)
- ECDSA-SHA256 (P-256/secp256r1) signature support
- TypedData (EIP-712) signature support for Ethereum typed data

#### Cryptographic Key Pairs
- `Secp256k1KeyPair` for BTC/ETH operations with compressed/uncompressed support
- `RsaKeyPair` with PKCS#1 DER encoding/decoding
- `EcdsaKeyPair` for P-256 curve operations
- `RCD1KeyPair` for Factom-compatible signing
- `UnifiedKeyPair` wrapper for polymorphic key handling

#### Smart Signing API
- `SmartSigner` class for automatic signer version tracking
- `signSubmitAndWait()` method for complete transaction lifecycle
- `addKey()` helper for key page operations
- Automatic retry logic for transient network errors

#### Key Management
- `KeyManager` class for key page state queries
- `KeyPageState` model with keys, thresholds, and credit balance
- Support for UpdateKeyPage operations (add/remove/update keys)

#### Transaction Builders (TxBody)
- `createToken()` for custom token issuer creation
- `createKeyPage()` for key page creation
- `createKeyBook()` for key book creation
- `issueTokens()` / `issueTokensSingle()` for token issuance
- `sendTokensSingle()` convenience method for single-recipient transfers
- `addCredits()` for credit purchase operations

#### Protocol Types
- Complete signature type hierarchy matching Go core
- Vote, Memo, and Data fields on all signature types
- TransactionHeader with Metadata, Expire, HoldUntil, and Authorities fields
- Proper enum values for all 16 signature types

### Changed
- Signature type enum values now match Go protocol exactly
- Binary encoding for signatures uses correct field ordering
- Transaction hash computation matches Go core implementation
- Public key hash computation varies by signature type (as per protocol)

### Fixed
- ETH signature public key hash uses Keccak-256 (not SHA-256)
- RSA signatures include full public key in hash (not truncated)
- RCD1 signatures use double-SHA256 for public key hash
- Transaction ID extraction from multi-response arrays
- Status parsing handles both string and map formats

### Security
- No hardcoded keys or secrets in library code
- Test vectors use well-known public test data only
- Removed debug files that printed sensitive data

## [1.0.0] - 2025-09-01

### Added
- Initial release of production-ready Dart/Flutter SDK
- Ed25519 cryptography with bit-for-bit compatible signing
- LID/LTA derivation matching Go/TypeScript implementations
- Transaction builders for common Accumulate v3 operations
- Unified v2+v3 JSON-RPC client
- Comprehensive test suite with cross-language validation
- Golden file test harness for encoding compatibility
- Working examples for all common workflows
- Pure Dart crypto implementation (Flutter/web friendly)
- Enhanced transport with retries, exponential backoff
- CLI tool for keygen, query, and submit operations
