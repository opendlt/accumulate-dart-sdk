# Accumulate SDK V3 Examples for Dart

This directory provides a suite of examples for using the Dart SDK with the Accumulate network V3 API. These examples are refactored from the original V1 examples to demonstrate the capabilities and functionalities of the Accumulate protocol using the new V3 API, offering developers a hands-on experience to better understand how to interact with the network effectively.

The V3 Example Suite consists of 10 example files:

## 📁 Example Files Overview

### 1. **Lite Identities and Accounts (V3)**
**File**: `SDK_Examples_file_1_lite_identities_v3.dart`

Demonstrates lite identities using the V3 API. Lite identities serve as the entry point into the Accumulate network, offering a traditional blockchain address format. Shows creation, management, and token transfers between lite accounts.

**Highlights**:
- Creation and management of Lite Identities and Accounts using V3 API
- Acquiring and transferring ACME tokens with V3 `submit()` method
- Adding credits to Lite Token Accounts using V3 transaction builders

**To run**:
```bash
dart run SDK_Examples_file_1_lite_identities_v3.dart
```

### 2. **ADI Identity (V3)**
**File**: `SDK_Examples_file_2_Accumulate_Identities_v3.dart`

Demonstrates Accumulate Digital Identifiers (ADIs) using V3 API. ADIs are versatile and dynamic, allowing comprehensive management and authorization functionalities.

**Focuses on**:
- Creation of ADI identities using V3 transaction builders
- Management of key books and key pages with V3 API
- Adding credits to key pages using V3 `submit()` method

**To run**:
```bash
dart run SDK_Examples_file_2_Accumulate_Identities_v3.dart
```

### 3. **ADI Token Accounts (V3)**
**File**: `SDK_Examples_file_3_ADI_Token_Accounts_v3.dart`

Shows ADI Token Accounts using V3 API. These are human-readable and controlled by an ADI's key book, facilitating ACME token transactions.

**Teaches**:
- Creation and management of ADI Token Accounts with V3 API
- Transactions between ADI Token Accounts and Lite Token Accounts using V3 `submit()`
- Advanced token account management patterns

**To run**:
```bash
dart run SDK_Examples_file_3_ADI_Token_Accounts_v3.dart
```

### 4. **ADI Data Accounts (V3)**
**File**: `SDK_Examples_file_4_Data_Accounts_and_Entries_v3.dart`

Demonstrates Accumulate's data account features using V3 API. Shows easy data entry into the blockchain with both legacy Factom Protocol support and new scratch data entries.

**Covers**:
- Creation of ADI Data Accounts using V3 transaction builders
- Data entry management within Data Accounts via V3 API
- Working with lite data accounts using V3 `submit()`

**To run**:
```bash
dart run SDK_Examples_file_4_Data_Accounts_and_Entries_v3.dart
```

### 5. **Send ACME ADI to ADI (V3)**
**File**: `SDK_Examples_file_4_Send_ACME_ADI_to_ADI_v3.dart`

Advanced token transfer example using V3 API, showing transfers between ADI accounts with signature metadata support.

**Demonstrates**:
- Advanced token transfers between ADI accounts using V3 API
- Signature metadata and memo support in V3 transactions
- Error handling and retry logic with V3 `submit()`

**To run**:
```bash
dart run SDK_Examples_file_4_Send_ACME_ADI_to_ADI_v3.dart
```

### 6. **Custom Tokens (V3)**
**File**: `SDK_Examples_file_5_Custom_Tokens_v3.dart`

Shows creating, issuing, and transferring custom tokens using V3 API. Demonstrates the simplified approach of Accumulate for custom tokens without smart contracts.

**Explores**:
- Custom token creation under an ADI using V3 transaction builders
- Account management and token issuance via V3 `submit()`
- Token transfers between custom token accounts using V3 API

**To run**:
```bash
dart run SDK_Examples_file_5_Custom_Tokens_v3.dart
```

### 7. **Custom Tokens Copy (V3)**
**File**: `SDK_Examples_file_5_Custom_Tokens_copy_v3.dart`

Alternative custom token example with variations in implementation using V3 API.

**To run**:
```bash
dart run SDK_Examples_file_5_Custom_Tokens_copy_v3.dart
```

### 8. **Query Transactions, Signatures, Memo & Data (V3)**
**File**: `SDK_Examples_file_5_Query_Tx_Signatures_Memo_Data_v3.dart`

Comprehensive querying example using V3 API, showing how to retrieve transaction information, signatures, and metadata.

**Demonstrates**:
- Querying transactions by ID using V3 `query()` method
- Retrieving signature information and metadata via V3 API
- Account and key page information queries using V3 endpoints

**To run**:
```bash
dart run SDK_Examples_file_5_Query_Tx_Signatures_Memo_Data_v3.dart
```

### 9. **Key Management (V3)**
**File**: `SDK_Examples_file_6_Key_Management_v3.dart`

Advanced key management example using V3 API, demonstrating security and identity management within the Accumulate network.

**Explores**:
- Creation and management of Key Books and Key Pages using V3 transaction builders
- Addition and updating of keys for enhanced security via V3 `submit()`
- Advanced key management operations with V3 API

**To run**:
```bash
dart run SDK_Examples_file_6_Key_Management_v3.dart
```

### 10. **Update Key Page Threshold (V3)**
**File**: `SDK_UpdateKeyPageThreshold_v3.dart`

Demonstrates updating key page thresholds using V3 API for multi-signature requirements.

**Shows**:
- Updating key page thresholds using V3 transaction builders
- Multi-signature configuration management via V3 API
- Threshold validation and security best practices

**To run**:
```bash
dart run SDK_UpdateKeyPageThreshold_v3.dart
```

## 🚀 Getting Started

### Prerequisites

- **Dart SDK**: Required to run the examples. If you haven't already, [install Dart](https://dart.dev/get-dart).
- **Local Accumulate DevNet**: The examples are configured for a local Accumulate devnet environment.

### Configuration

Each example file has a configurable endpoint constant at the top:

```dart
// Configurable endpoint constant - set to your local devnet
const String endPoint = "http://127.0.0.1:26660/v3";
```

**Important**: These examples are configured to work with your local Accumulate devnet running at `http://127.0.0.1:26660/v3`. The faucet account for your devnet is:
```
acc://a21555da824d14f3f066214657a44e6a1a347dad3052a23a/ACME
```

### Key Differences from V1 Examples

The V3 examples include several important improvements over the V1 versions:

1. **V3 API Usage**: All examples use the new V3 API with `AccumulateV3.custom()` client
2. **New Transaction Builders**: Uses `TxBody` builders and `TxSigner.buildAndSign()` for transaction creation
3. **Simplified Signing**: Streamlined signing process with `Ed25519KeyPair`
4. **Enhanced Error Handling**: Better error reporting and transaction status checking
5. **Modern Dart Patterns**: Updated to use modern Dart async/await patterns
6. **Local DevNet Support**: Configured to work with local development networks

### Running Examples

1. Ensure your local Accumulate devnet is running
2. Navigate to the v3 examples directory
3. Run any example file with Dart:

```bash
cd C:\Accumulate_Stuff\opendlt-dart-v2v3-sdk\unified\example\v3
dart run SDK_Examples_file_1_lite_identities_v3.dart
```

### Development Notes

- Each example is self-contained and can be run independently
- Examples generate new key pairs on each run for demonstration purposes
- In production, you should persist and securely manage key pairs
- The examples include proper error handling and transaction verification
- All endpoints are configurable via the constant at the top of each file

## 🤝 Support

For support or further clarification, consult the [Accumulate official documentation](https://docs.accumulatenetwork.io/) or join the Accumulate community on [Discord](https://discord.gg/2kBcaxrB).

## 📄 License

These examples follow the same license as the parent SDK project.