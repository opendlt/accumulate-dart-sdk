# OpenDLT Accumulate Dart SDK

[![Dart](https://img.shields.io/badge/Dart-3.3+-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Production-ready Dart SDK for the Accumulate blockchain protocol. Supports all signature types, V2/V3 API endpoints, and provides a high-level signing API with automatic version tracking.

## Features

- **Multi-Signature Support**: Ed25519, RCD1, BTC, ETH, RSA-SHA256, ECDSA-SHA256
- **Smart Signing**: Automatic signer version tracking with `SmartSigner`
- **Complete Protocol**: All transaction types and account operations
- **Cross-Platform**: Pure Dart implementation (Flutter/web compatible)
- **Network Ready**: Mainnet, Testnet (Kermit), and local DevNet support

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  opendlt_accumulate: ^2.0.0
```

## Quick Start

```dart
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

void main() async {
  // Connect to Kermit testnet
  final client = Accumulate.network(NetworkEndpoint.testnet);

  // Generate key pair and derive lite account URLs
  final kp = await Ed25519KeyPair.generate();
  final lid = await kp.deriveLiteIdentityUrl();
  final lta = await kp.deriveLiteTokenAccountUrl();

  print('Lite Identity: $lid');
  print('Lite Token Account: $lta');

  // Query account
  final account = await client.v3.rawCall("query", {
    "scope": lta.toString(),
    "query": {"queryType": "default"}
  });
  print('Account: $account');

  client.close();
}
```

## Smart Signing API

The `SmartSigner` class handles version tracking automatically:

```dart
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

void main() async {
  final client = Accumulate.network(NetworkEndpoint.testnet);
  final kp = await Ed25519KeyPair.generate();
  final lid = await kp.deriveLiteIdentityUrl();
  final lta = await kp.deriveLiteTokenAccountUrl();

  // Create SmartSigner - automatically queries and tracks signer version
  final signer = SmartSigner(
    client: client.v3,
    keypair: UnifiedKeyPair.fromEd25519(kp),
    signerUrl: lid.toString(),
  );

  // Sign, submit, and wait for delivery in one call
  final result = await signer.signSubmitAndWait(
    principal: lta.toString(),
    body: TxBody.sendTokensSingle(
      toUrl: "acc://recipient.acme/tokens",
      amount: "100000000", // 1 ACME
    ),
    memo: "Payment",
  );

  if (result.success) {
    print('Transaction delivered: ${result.txid}');
  }

  client.close();
}
```

## Supported Signature Types

| Type | Key Pair Class | Use Case |
|------|---------------|----------|
| Ed25519 | `Ed25519KeyPair` | Default, recommended |
| RCD1 | `RCD1KeyPair` | Factom compatibility |
| BTC | `Secp256k1KeyPair` | Bitcoin ecosystem |
| ETH | `Secp256k1KeyPair` | Ethereum ecosystem |
| RSA-SHA256 | `RsaKeyPair` | Enterprise/legacy systems |
| ECDSA-SHA256 | `EcdsaKeyPair` | P-256 curve operations |

## Transaction Builders

Build transactions using the `TxBody` class:

```dart
// Send tokens
TxBody.sendTokensSingle(toUrl: "acc://...", amount: "100000000");

// Add credits
TxBody.addCredits(recipient: "acc://...", amount: "1000000", oracle: oraclePrice);

// Create ADI
TxBody.createIdentity(url: "acc://my-adi.acme", keyBookUrl: "acc://my-adi.acme/book", publicKeyHash: keyHash);

// Create token account
TxBody.createTokenAccount(url: "acc://my-adi.acme/tokens", tokenUrl: "acc://ACME");

// Create custom token
TxBody.createToken(url: "acc://my-adi.acme/mytoken", symbol: "MTK", precision: 8);

// Write data
TxBody.writeData(entriesHex: [dataHex]);
```

## Network Endpoints

```dart
// Public networks
Accumulate.network(NetworkEndpoint.mainnet);  // Production
Accumulate.network(NetworkEndpoint.testnet);  // Kermit testnet

// Local development
Accumulate.network(NetworkEndpoint.devnet);   // localhost:26660

// Custom endpoint
Accumulate.custom(
  v2Endpoint: "https://your-node.com/v2",
  v3Endpoint: "https://your-node.com/v3",
);
```

## Examples

See [`example/v3/`](example/v3/) for complete working examples:

| Example | Description |
|---------|-------------|
| `SDK_Examples_file_1_lite_identities_v3.dart` | Lite identity and token account operations |
| `SDK_Examples_file_2_Accumulate_Identities_v3.dart` | ADI creation |
| `SDK_Examples_file_3_ADI_Token_Accounts_v3.dart` | ADI token account management |
| `SDK_Examples_file_4_Data_Accounts_and_Entries_v3.dart` | Data account operations |
| `SDK_Examples_file_5_Send_ACME_ADI_to_ADI_v3.dart` | ADI-to-ADI transfers |
| `SDK_Examples_file_6_Custom_Tokens_copy_v3.dart` | Custom token creation |
| `SDK_Examples_file_9_Key_Management_v3.dart` | Key page and key book management |

Run any example:
```bash
dart run example/v3/SDK_Examples_file_1_lite_identities_v3.dart
```

## Project Structure

```
lib/
├── src/
│   ├── api/           # Client wrappers
│   ├── build/         # Transaction builders (TxBody, TxSigner)
│   ├── codec/         # Binary encoding
│   ├── crypto/        # Key pair implementations
│   ├── signing/       # SmartSigner, KeyManager
│   └── signatures/    # Signature type classes
example/
├── v3/                # V3 API examples with SmartSigner
└── flows/             # Step-by-step workflow examples
test/
├── unit/              # Unit tests
├── integration/       # Network integration tests
└── conformance/       # Cross-implementation compatibility
```

## Development

### Running Tests
```bash
dart test                    # All tests
dart test test/unit/         # Unit tests only
dart test test/integration/  # Integration tests (requires network)
```

### Code Quality
```bash
dart analyze lib/ test/
dart format lib/ test/ example/
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Links

- [Accumulate Protocol](https://accumulatenetwork.io/)
- [API Documentation](https://docs.accumulatenetwork.io/)
- [Kermit Testnet Explorer](https://kermit.explorer.accumulatenetwork.io/)
