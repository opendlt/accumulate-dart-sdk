# Changelog

All notable changes to the opendlt-accumulate Dart SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.3.2] - 2026-07-28

### Fixed
- **WriteData silently dropped its payload when given `entries`.** `_marshalWriteData` accepts either `entry` (a Map) or `entries` (a List), but `_marshalDataEntry` only handled the Map form — a List fell through every branch, so the body marshalled to just the type enum and produced a WriteData carrying no data, signed and submitted as though valid.
- Test-suite correctness: WriteData conformance tests passed base64 where the documented contract is hex (`builders.writeData` takes `entriesHex`), and a builder test asserted a `timestamp` on the transaction header — the protocol puts the timestamp on the signature, not the header.
- `dart_test.yaml` now lives at the package root and uses valid string tag selectors. It previously sat at the repository root (never read by `dart test`) and used list-form selectors, which made the file invalid — so quarantined and network-dependent tests ran, and failed, on a default `dart test`.

## [2.3.1] - 2026-07-28

### Fixed
- **The umbrella library shadowed `dart:core`'s `Object`.** The Accumulate protocol defines a type named `Object` (account type/chains/pending) and the generator emits it verbatim; exporting it meant ordinary Dart such as `Object o = 'x';` failed to compile in any file that imported this package (`A value of type 'String' can't be assigned to a variable of type 'Object'`). The generated `Object` is now hidden from the umbrella and re-exported as `ProtocolObject`, so nothing is lost and `dart:core` behaves normally.

  The alias lives in the hand-maintained `lib/src/protocol_aliases.dart` rather than in `lib/src/generated/`, which the generator overwrites — a rename applied there would be silently reverted on the next regeneration.

  Checked for the same class of collision across the package: `Duration` (`core_types.dart`) and `Record` (`api.dart`) also shadow `dart:core` names but are not reachable from the umbrella export, so they do not affect consumers.

## [2.3.0] - 2026-07-28

### Added
- `Amount.token(whole, precision)` / `toToken(precision)` for **custom tokens**. Custom tokens declare their own precision at creation; the wire format is always base units. Previously `Amount` covered only ACME and credits, so issuing a custom token meant hand-computing a power of ten — and issuing `1000` against a precision-8 token mints `0.00001` tokens, not 1000, while the transaction succeeds either way.

### Changed
- Fleet version alignment: all five Accumulate SDKs now ship 2.3.0 with the same `Amount` surface.

## [2.2.2] - 2026-07-28

### Fixed
- Removed a stray `example/v3/110_testnet_faucet.dart` left behind by an earlier move to `example/flows/`. It imported a `config.dart` that only exists in `example/flows/`, so it was the sole source of two analyzer errors — which is what earned the package pub.dev's `has:error` tag and degraded static analysis for every consumer. `dart analyze` now reports 0 errors.
- Normalized `LICENSE` to LF line endings so pub.dev's license detector can match the Apache-2.0 text (previously reported as `license:unknown`).

## [2.2.1] - 2026-07-28

### Fixed
- **The package could not be imported at all.** `lib/src/build/` (`builders.dart`, `context.dart`, `tx_types.dart`) was missing from the published archive, while `lib/opendlt_accumulate.dart` re-exports all three. Every consumer of 2.2.0 got a compile error on `import 'package:opendlt_accumulate/opendlt_accumulate.dart'`, so the entire documented golden path — `Accumulate`, `TxBody`, `SmartSigner` — was unreachable.

  Root cause: `.gitignore` contained an unanchored `build/` rule intended for the repo-root build output. Unanchored patterns match at any depth, so it also excluded `lib/src/build/` — the SDK's own source. The files existed on disk but were never tracked by git and therefore never published. The rule is now anchored (`/build/`) with an explicit `!lib/src/build/` guard.

  This also explains the package's pub.dev analysis score: static analysis could not resolve the umbrella library.

## [2.2.0] - 2026-07-22

### Added
- `Amount` helper for ACME base-unit scaling (1 ACME = 1e8 base units): `Amount.acme()`, `Amount.baseUnitsOf()`, `Amount.credits()`.
- Typed error taxonomy (`AccError` and subclasses) exported from the package root.

### Changed
- RPC errors from the live API path now surface as typed `AccError` (via `Transport`), so callers can `catch (ValidationError)` / `catch (ApiError)` instead of a flat `JsonRpcException`.
- Added generated `llms.txt`, `llms-full.txt`, and `AGENTS.md` AI-agent interface files.

## [2.1.2] - 2026-07-21

### Changed
- Documented ACME base-unit scaling (1 ACME = 1e8) in the README quickstart and clarified the dependency version pin.

## [2.1.0] - 2026-02-27

### Added
- Binary encoding for BurnTokens, BurnCredits, WriteDataTo, LockAccount, UpdateKey, UpdateAccountAuth, and TransferCredits transaction types
- `fromJson` factory on AccountAuthOperation and KeyPageOperation for deserialization
- Testnet faucet example

### Changed
- Moved ad-hoc test/debug examples from `example/v3/` to `example/flows/`

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
