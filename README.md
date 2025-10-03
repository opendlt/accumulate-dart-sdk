# OpenDLT Accumulate Dart SDK

[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Dart SDK for the Accumulate blockchain protocol. Supports both V2 and V3 API endpoints with a unified interface.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  opendlt_accumulate:
    path: ../opendlt-dart-v2v3-sdk/UNIFIED  # Local development
    # git: https://github.com/your-org/opendlt-dart-v2v3-sdk.git  # When published
```

## Quick Start

```dart
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

void main() async {
  // Connect to network
  final acc = Accumulate.network(NetworkEndpoint.testnet);

  // Query account (V3 by default)
  final account = await acc.query({
    "type": "query-account",
    "url": "acc://accumulatenetwork.acme",
  });

  print('Account: ${account}');
  acc.close();
}
```

## Examples

See [`example/`](example/) for complete usage examples:

- **Basic Operations**: Account queries, transaction submission
- **Identity Management**: Creating ADIs, lite accounts
- **Token Operations**: Sending tokens, managing credits
- **DevNet Setup**: Local development environment
- **Zero-to-Hero**: Complete workflow from setup to transactions

Run any example:
```bash
dart run example/flows/999_zero_to_hero_simple.dart
```

## API Overview

### Unified Interface
```dart
final acc = Accumulate.network(NetworkEndpoint.mainnet);

// V3 API (default)
await acc.query(queryData);
await acc.submit(transaction);

// V2 API (legacy support)
await acc.v2.executeDirect(txData);

// Raw access
await acc.v3.rawCall("query", params);
```

### Network Endpoints
- **Mainnet**: `NetworkEndpoint.mainnet`
- **Testnet**: `NetworkEndpoint.testnet`
- **DevNet**: `NetworkEndpoint.devnet` (localhost:26660)
- **Custom**: `NetworkEndpoint.custom("https://your-node.com")`

## Project Structure

```
lib/
├── src/generated/       # Generated code (DO NOT EDIT)
│   ├── api/            # API clients
│   ├── types/          # Protocol types
│   └── runtime/        # Validation & helpers
├── src/                # Hand-written SDK code
│   ├── api/           # High-level API wrappers
│   ├── codec/         # Encoding/decoding
│   ├── signatures/    # Cryptographic signatures
│   └── transactions/  # Transaction builders
example/                # Usage examples
test/                   # Test suite (organized by function)
tool/                   # Build and development tools
```

## Development

### Running Tests
```bash
# All tests
dart test

# Specific categories
dart test test/unit/
dart test test/conformance/
dart test test/integration/
```

### Code Generation
Generated files are produced by the Accumulate gen-sdk tool from the GitLab Go repository. See [`lib/src/generated/README.md`](lib/src/generated/README.md) for regeneration instructions.

### Build Tools
See [`tool/README.md`](tool/README.md) for available development tools and scripts.

## Contributing

1. Follow existing code patterns and structure
2. Add tests for new functionality in appropriate test categories
3. Run `dart analyze` and fix any issues
4. Update documentation as needed

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.