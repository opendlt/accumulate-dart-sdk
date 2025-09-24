# Changelog

All notable changes to the opendlt-accumulate Dart SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Enhanced transport with retries, exponential backoff, and User-Agent headers
- CLI tool (`bin/accumulate.dart`) for keygen, query, and submit operations
- Comprehensive tooling scripts (preflight checks, docs generation, release checklist)
- Governance files (CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md)
- Coverage reporting with `coverage` package
- Examples documentation and usage instructions

### Changed
- Upgraded minimum Dart SDK to 3.3.0 for better language features
- Enhanced pubspec.yaml metadata for pub.dev readiness
- Improved error handling and retry logic for network requests

### Security
- Added User-Agent headers for better request tracing
- Implemented request timeout and retry mechanisms

## [1.0.0] - 2024-12-XX

### Added
- Initial release of production-ready Dart/Flutter SDK
- Ed25519 cryptography with bit-for-bit compatible signing
- LID/LTA derivation matching Go/TypeScript implementations
- Transaction builders for all Accumulate v3 operations
- Unified v2+v3 JSON-RPC client (generated)
- Comprehensive test suite with cross-language validation
- Golden file test harness for encoding compatibility
- Working examples for all common workflows
- Pure Dart crypto implementation (Flutter/web friendly)