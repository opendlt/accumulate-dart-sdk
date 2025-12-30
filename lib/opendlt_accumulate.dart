library opendlt_accumulate;

// Facade - Main public API
export 'src/facade/accumulate.dart' show Accumulate, AccumulateV2, AccumulateV3;
export 'src/core/options.dart' show AccumulateOptions;

// Runtime utilities
export 'src/runtime/bytes.dart';
export 'src/runtime/url.dart';
export 'src/runtime/validate.dart';
export 'src/util/acc_url.dart';
export 'src/util/bytes.dart' show toHex, hexTo, fromHex, bytesToBigInt, bigIntToBytes, deriveLiteIdentityFromKeyHash;
export 'src/util/validation.dart' show ValidationException;
export 'src/util/response_parser.dart';

// Enums (from Stage 1) - hide types that are redefined in operations files
export 'src/enums.dart'
    hide KeyPageOperationType, AccountAuthOperationType, VoteType, NetworkMaintenanceOperationType;

// Core types
export 'src/core/endpoints.dart';

// Cryptography - All signature types supported by Accumulate
export 'src/crypto/ed25519.dart';
export 'src/crypto/rcd1.dart';
export 'src/crypto/secp256k1.dart';
export 'src/crypto/rsa.dart';
export 'src/crypto/ecdsa.dart';

// Transaction building - hide types that conflict with generated
export 'src/build/builders.dart' hide CreditRecipient, TokenRecipient;
export 'src/build/context.dart' hide ExpireOptions, HoldUntilOptions;
export 'src/build/tx_types.dart';

// Operations (for UpdateKeyPage, UpdateAccountAuth, etc.)
export 'src/operations/key_page_operations.dart';
export 'src/operations/account_auth_operations.dart';

// Signatures
export 'src/signatures/signatures.dart';

// Protocol types (envelope, etc.)
export 'src/protocol/envelope.dart';

// Transactions (Phase 2)
export 'src/transactions/transaction_header.dart';
export 'src/transactions/transaction.dart';
export 'src/api/client.dart';

export 'src/generated/runtime/canon_helpers.dart';
export 'src/generated/runtime/validators.dart';
export 'src/generated/types/accounts_types.dart';
export 'src/generated/types/general_types.dart';
export 'src/generated/types/synthetic_transactions_types.dart';
export 'src/generated/types/system_types.dart';
export 'src/generated/types/transaction_types.dart' hide Transaction, TransactionHeader;
export 'src/generated/types/user_transactions_types.dart';

// High-level helpers for simplified SDK usage
export 'src/helpers/accumulate_helper.dart';
export 'src/helpers/quick_start.dart';

// Smart signing helpers - unified interface for all signature types
export 'src/signing/algorithm.dart';
export 'src/signing/unified_keypair.dart';
export 'src/signing/smart_signer.dart';
export 'src/signing/key_manager.dart';
