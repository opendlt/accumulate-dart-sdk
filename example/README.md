# Examples

Complete usage examples for the Accumulate Dart SDK. All examples are runnable and demonstrate real-world integration patterns.

## Available Examples

### Setup & Key Management
- `000_boot_devnet_local.dart` - Start local DevNet for development
- `100_keygen_lite_urls.dart` - Generate Ed25519 keys and derive Lite accounts
- `110_testnet_faucet.dart` - Request testnet tokens via faucet
- `120_faucet_local_devnet.dart` - Request tokens from local DevNet

### Identity Management
- `200_create_identity_v3.dart` - Create Accumulate Digital Identifier (ADI)
- `210_buy_credits_lite.dart` - Purchase credits for Lite accounts
- `220_create_adi_v3.dart` - Advanced ADI creation with authorities

### Token Operations
- `230_send_tokens_v3.dart` - Send tokens between accounts
- `240_buy_credits_keypage.dart` - Purchase credits for ADI key pages
- `250_create_token_account.dart` - Create custom token accounts
- `280_send_tokens_lta_to_adi.dart` - Transfer from Lite to ADI accounts

### Data Management
- `260_create_data_account.dart` - Create data storage accounts
- `270_write_data.dart` - Write data to accounts

### Complete Workflows
- `999_zero_to_hero.dart` - Full workflow: keys → identity → tokens → data
- `999_zero_to_hero_simple.dart` - Simplified version with DevNet discovery

## Quick Start

### 1. Environment Setup
```bash
# Optional: Set target network (defaults to testnet)
export ACC_NET=testnet  # Options: mainnet, testnet, devnet
```

### 2. Generate Keys
```bash
dart run example/flows/100_keygen_lite_urls.dart
```
Output:
```json
{
  "privateKeyHex": "1234567890abcdef...",
  "publicKeyHex": "abcdef1234567890...",
  "liteIdentity": "acc://a1b2c3d4e5f6.../",
  "liteTokenAccount": "acc://a1b2c3d4e5f6.../ACME"
}
```

### 3. Get Testnet Tokens
```bash
# Use LTA from step 2
export ACC_LTA_URL="acc://your-lite-hash/ACME"
dart run example/flows/110_testnet_faucet.dart
```

### 4. Create Identity & Send Tokens
```bash
dart run example/flows/999_zero_to_hero_simple.dart
```

## CLI Tool

The SDK includes a command-line interface:

```bash
# Generate keys
dart run bin/accumulate.dart keygen

# Query accounts
dart run bin/accumulate.dart query acc://accumulatenetwork.acme

# Submit transactions
dart run bin/accumulate.dart submit transaction.json
```

## Environment Variables

Examples support these optional environment variables:

| Variable | Purpose | Default |
|----------|---------|---------|
| `ACC_NET` | Network (mainnet/testnet/devnet) | testnet |
| `ACC_LTA_URL` | Your Lite Token Account URL | Generated |
| `ACC_FROM_URL` | Transaction source account | Generated |
| `ACC_TO_URL` | Transaction destination account | Generated |
| `ACC_AMOUNT` | Token amount to send | 1000 |

## Network Configuration

### Testnet (Recommended for Development)
- Faucet available for free tokens
- Stable environment for testing
- Same protocol as mainnet

### DevNet (Local Development)
- Run locally for fastest iteration
- Full protocol support
- Start with `000_boot_devnet_local.dart`

### Mainnet (Production)
- Real tokens with value
- Use with caution
- Same API as testnet

## Key Features Demonstrated

- **Ed25519 Cryptography**: Pure Dart implementation
- **Protocol Compatibility**: V2 and V3 API support
- **Transaction Building**: Type-safe builders for all operations
- **Error Handling**: Comprehensive retry logic and error reporting
- **Network Integration**: Unified JSON-RPC client with automatic endpoint discovery