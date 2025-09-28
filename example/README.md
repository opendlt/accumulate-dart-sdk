# Examples

This directory contains runnable examples demonstrating the Accumulate Dart SDK functionality.

## Quick Start

### Environment Setup
```bash
# Select network (optional, defaults to testnet)
$env:ACC_NET = "testnet"   # Options: mainnet, devnet, testnet
```

### Key Generation & Lite URLs
```bash
# Generate Ed25519 keys and derive Lite Identity/Token Account URLs
dart run example/flows/100_keygen_lite_urls.dart
```

### Testnet Faucet
```bash
# First generate or set your Lite Token Account URL
$env:ACC_LTA_URL = "acc://<your-lite-hash>/ACME"
dart run example/flows/110_testnet_faucet.dart
```

### Transaction Examples
```bash
# Create ADI (Accumulate Digital Identifier)
dart run example/flows/200_create_identity_v3.dart

# Send tokens between accounts
$env:ACC_FROM_URL = "acc://sender.acme/tokens"
$env:ACC_TO_URL = "acc://receiver.acme/tokens"
$env:ACC_AMOUNT = "1000"
dart run example/flows/230_send_tokens_v3.dart

# Create and write to data account
dart run example/flows/240_create_data_account_v3.dart
dart run example/flows/250_write_data_v3.dart
```

## CLI Tool

The SDK includes a command-line tool for common operations:

```bash
# Generate keys and addresses
dart run bin/accumulate.dart keygen

# Query account information
dart run bin/accumulate.dart query acc://accumulatenetwork.acme

# Submit pre-built transaction envelope
dart run bin/accumulate.dart submit example/tx/envelope.json
```

## Example Outputs

### Key Generation
```json
{
  "publicKeyHex": "b781235c8f3995f07d81724d2b25976448f0f9f770fc4a5d82e04e0983e63699",
  "lid": "acc://2c27fb67db121b5d2043e68d664b1624d470d891b1f68736",
  "lta": "acc://2c27fb67db121b5d2043e68d664b1624d470d891b1f68736/ACME"
}
```

### Transaction Submission
```json
{
  "envelope": {
    "signatures": [{
      "type": "ed25519",
      "publicKey": "b781235c8f3995f07d81724d2b25976448f0f9f770fc4a5d82e04e0983e63699",
      "signature": "base64-encoded-signature",
      "timestamp": 1234567890123
    }],
    "transaction": {
      "header": {
        "principal": "acc://sender.acme/tokens",
        "timestamp": 1234567890123
      },
      "body": {
        "type": "send-tokens",
        "to": [{"url": "acc://receiver.acme/tokens", "amount": "1000"}]
      }
    }
  }
}
```

## Network Endpoints

The SDK supports all Accumulate networks:

- **Mainnet**: Production network
- **Testnet**: Test network with faucet available
- **DevNet**: Development network for testing

Environment variables:
- `ACC_NET`: Network selection (mainnet/testnet/devnet)
- `ACC_LTA_URL`: Your Lite Token Account URL
- `ACC_FROM_URL`: Source account for transactions
- `ACC_TO_URL`: Destination account for transactions
- `ACC_AMOUNT`: Token amount to send

## Key Features Demonstrated

- **Ed25519 Cryptography**: Pure Dart implementation with bit-for-bit compatibility
- **LID/LTA Derivation**: Exact key-to-URL mapping matching Go/TypeScript
- **Transaction Building**: Type-safe builders for all v3 operations
- **Envelope Signing**: Verified signing preimage construction
- **Network Integration**: Unified v2+v3 JSON-RPC client with retries
- **Error Handling**: Comprehensive error reporting and retry logic