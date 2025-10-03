// GENERATED — Do not edit.
// Protocol types from user_transactions.yml

import 'dart:typed_data';
import '../enums.dart';
import '../runtime/canon_helpers.dart';
import '../runtime/validators.dart';

/// Protocol type: AcmeFaucet
final class AcmeFaucet {
  final String url;

  const AcmeFaucet({required this.url});

  /// Create from JSON map
  factory AcmeFaucet.fromJson(Map<String, dynamic> json) {
    return AcmeFaucet(
    url: json['Url'] as String,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Url': url,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(url, 'url');
    Validators.validateUrl(url, 'url');
  }
}


/// Protocol type: ActivateProtocolVersion
final class ActivateProtocolVersion {
  final ExecutorVersion version;

  const ActivateProtocolVersion({required this.version});

  /// Create from JSON map
  factory ActivateProtocolVersion.fromJson(Map<String, dynamic> json) {
    return ActivateProtocolVersion(
    version: json['Version'] as ExecutorVersion,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Version': version,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(version, 'version');
  }
}


/// Protocol type: AddCredits
final class AddCredits {
  final String recipient;
  final BigInt amount;
  final int oracle;

  const AddCredits({required this.recipient, required this.amount, required this.oracle});

  /// Create from JSON map
  factory AddCredits.fromJson(Map<String, dynamic> json) {
    return AddCredits(
    recipient: json['Recipient'] as String,
    amount: BigInt.parse(json['Amount'] as String),
    oracle: json['Oracle'] as int,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Recipient': recipient,
    'Amount': CanonHelpers.bigIntToJson(amount),
    'Oracle': oracle,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(recipient, 'recipient');
    Validators.validateUrl(recipient, 'recipient');
    Validators.validateRequired(amount, 'amount');
    Validators.validateBigInt(amount, 'amount');
  }
}


/// Protocol type: BurnCredits
final class BurnCredits {
  final int amount;

  const BurnCredits({required this.amount});

  /// Create from JSON map
  factory BurnCredits.fromJson(Map<String, dynamic> json) {
    return BurnCredits(
    amount: json['Amount'] as int,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Amount': amount,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    // No validation required
  }
}


/// Protocol type: BurnTokens
final class BurnTokens {
  final BigInt amount;

  const BurnTokens({required this.amount});

  /// Create from JSON map
  factory BurnTokens.fromJson(Map<String, dynamic> json) {
    return BurnTokens(
    amount: BigInt.parse(json['Amount'] as String),
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Amount': CanonHelpers.bigIntToJson(amount),
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(amount, 'amount');
    Validators.validateBigInt(amount, 'amount');
  }
}


/// Protocol type: CreateDataAccount
final class CreateDataAccount {
  final String url;
  final String authorities;

  const CreateDataAccount({required this.url, required this.authorities});

  /// Create from JSON map
  factory CreateDataAccount.fromJson(Map<String, dynamic> json) {
    return CreateDataAccount(
    url: json['Url'] as String,
    authorities: json['Authorities'] as String,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Url': url,
    'Authorities': authorities,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(url, 'url');
    Validators.validateUrl(url, 'url');
    Validators.validateRequired(authorities, 'authorities');
    Validators.validateUrl(authorities, 'authorities');
  }
}


/// Protocol type: CreateIdentity
final class CreateIdentity {
  final String url;
  final Uint8List keyHash;
  final String keyBookUrl;
  final String authorities;

  const CreateIdentity({required this.url, required this.keyHash, required this.keyBookUrl, required this.authorities});

  /// Create from JSON map
  factory CreateIdentity.fromJson(Map<String, dynamic> json) {
    return CreateIdentity(
    url: json['Url'] as String,
    keyHash: CanonHelpers.base64ToUint8List(json['KeyHash'] as String),
    keyBookUrl: json['KeyBookUrl'] as String,
    authorities: json['Authorities'] as String,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Url': url,
    'KeyHash': CanonHelpers.uint8ListToBase64(keyHash),
    'KeyBookUrl': keyBookUrl,
    'Authorities': authorities,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(url, 'url');
    Validators.validateUrl(url, 'url');
    Validators.validateRequired(keyHash, 'keyHash');
    Validators.validateHash32(keyHash, 'keyHash');
    Validators.validateRequired(keyBookUrl, 'keyBookUrl');
    Validators.validateUrl(keyBookUrl, 'keyBookUrl');
    Validators.validateRequired(authorities, 'authorities');
    Validators.validateUrl(authorities, 'authorities');
  }
}


/// Protocol type: CreateKeyBook
final class CreateKeyBook {
  final String url;
  final Uint8List publicKeyHash;
  final String authorities;

  const CreateKeyBook({required this.url, required this.publicKeyHash, required this.authorities});

  /// Create from JSON map
  factory CreateKeyBook.fromJson(Map<String, dynamic> json) {
    return CreateKeyBook(
    url: json['Url'] as String,
    publicKeyHash: CanonHelpers.base64ToUint8List(json['PublicKeyHash'] as String),
    authorities: json['Authorities'] as String,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Url': url,
    'PublicKeyHash': CanonHelpers.uint8ListToBase64(publicKeyHash),
    'Authorities': authorities,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(url, 'url');
    Validators.validateUrl(url, 'url');
    Validators.validateRequired(publicKeyHash, 'publicKeyHash');
    Validators.validateHash32(publicKeyHash, 'publicKeyHash');
    Validators.validateRequired(authorities, 'authorities');
    Validators.validateUrl(authorities, 'authorities');
  }
}


/// Protocol type: CreateKeyPage
final class CreateKeyPage {
  final dynamic keys;

  const CreateKeyPage({required this.keys});

  /// Create from JSON map
  factory CreateKeyPage.fromJson(Map<String, dynamic> json) {
    return CreateKeyPage(
    keys: json['Keys'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Keys': keys,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(keys, 'keys');
  }
}


/// Protocol type: CreateLiteTokenAccount
final class CreateLiteTokenAccount {
  const CreateLiteTokenAccount();

  /// Create from JSON map
  factory CreateLiteTokenAccount.fromJson(Map<String, dynamic> json) {
    return CreateLiteTokenAccount();
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    return CanonicalJson.sortMap(<String, dynamic>{});
  }

  /// Validate the object
  void validate() {
    // No fields to validate
  }
}


/// Protocol type: CreateToken
final class CreateToken {
  final String url;
  final String symbol;
  final int precision;
  final String properties;
  final BigInt supplyLimit;
  final String authorities;

  const CreateToken({required this.url, required this.symbol, required this.precision, required this.properties, required this.supplyLimit, required this.authorities});

  /// Create from JSON map
  factory CreateToken.fromJson(Map<String, dynamic> json) {
    return CreateToken(
    url: json['Url'] as String,
    symbol: json['Symbol'] as String,
    precision: json['Precision'] as int,
    properties: json['Properties'] as String,
    supplyLimit: BigInt.parse(json['SupplyLimit'] as String),
    authorities: json['Authorities'] as String,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Url': url,
    'Symbol': symbol,
    'Precision': precision,
    'Properties': properties,
    'SupplyLimit': CanonHelpers.bigIntToJson(supplyLimit),
    'Authorities': authorities,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(url, 'url');
    Validators.validateUrl(url, 'url');
    Validators.validateRequired(symbol, 'symbol');
    Validators.validateRequired(properties, 'properties');
    Validators.validateUrl(properties, 'properties');
    Validators.validateRequired(supplyLimit, 'supplyLimit');
    Validators.validateBigInt(supplyLimit, 'supplyLimit');
    Validators.validateRequired(authorities, 'authorities');
    Validators.validateUrl(authorities, 'authorities');
  }
}


/// Protocol type: CreateTokenAccount
final class CreateTokenAccount {
  final String url;
  final String tokenUrl;
  final String authorities;
  final dynamic proof;

  const CreateTokenAccount({required this.url, required this.tokenUrl, required this.authorities, required this.proof});

  /// Create from JSON map
  factory CreateTokenAccount.fromJson(Map<String, dynamic> json) {
    return CreateTokenAccount(
    url: json['Url'] as String,
    tokenUrl: json['TokenUrl'] as String,
    authorities: json['Authorities'] as String,
    proof: json['Proof'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Url': url,
    'TokenUrl': tokenUrl,
    'Authorities': authorities,
    'Proof': proof,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(url, 'url');
    Validators.validateUrl(url, 'url');
    Validators.validateRequired(tokenUrl, 'tokenUrl');
    Validators.validateUrl(tokenUrl, 'tokenUrl');
    Validators.validateRequired(authorities, 'authorities');
    Validators.validateUrl(authorities, 'authorities');
    Validators.validateRequired(proof, 'proof');
  }
}


/// Protocol type: IssueTokens
final class IssueTokens {
  final String recipient;
  final BigInt amount;
  final dynamic to;

  const IssueTokens({required this.recipient, required this.amount, required this.to});

  /// Create from JSON map
  factory IssueTokens.fromJson(Map<String, dynamic> json) {
    return IssueTokens(
    recipient: json['Recipient'] as String,
    amount: BigInt.parse(json['Amount'] as String),
    to: json['To'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Recipient': recipient,
    'Amount': CanonHelpers.bigIntToJson(amount),
    'To': to,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(recipient, 'recipient');
    Validators.validateUrl(recipient, 'recipient');
    Validators.validateRequired(amount, 'amount');
    Validators.validateBigInt(amount, 'amount');
    Validators.validateRequired(to, 'to');
  }
}


/// Protocol type: LockAccount
final class LockAccount {
  final int height;

  const LockAccount({required this.height});

  /// Create from JSON map
  factory LockAccount.fromJson(Map<String, dynamic> json) {
    return LockAccount(
    height: json['Height'] as int,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Height': height,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    // No validation required
  }
}


/// Protocol type: NetworkMaintenance
final class NetworkMaintenance {
  final dynamic operations;

  const NetworkMaintenance({required this.operations});

  /// Create from JSON map
  factory NetworkMaintenance.fromJson(Map<String, dynamic> json) {
    return NetworkMaintenance(
    operations: json['Operations'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Operations': operations,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(operations, 'operations');
  }
}


/// Protocol type: RemoteTransaction
final class RemoteTransaction {
  final Uint8List hash;

  const RemoteTransaction({required this.hash});

  /// Create from JSON map
  factory RemoteTransaction.fromJson(Map<String, dynamic> json) {
    return RemoteTransaction(
    hash: CanonHelpers.base64ToUint8List(json['Hash'] as String),
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Hash': CanonHelpers.uint8ListToBase64(hash),
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(hash, 'hash');
    Validators.validateHash32(hash, 'hash');
  }
}


/// Protocol type: SendTokens
final class SendTokens {
  final Uint8List hash;
  final dynamic meta;
  final dynamic to;

  const SendTokens({required this.hash, required this.meta, required this.to});

  /// Create from JSON map
  factory SendTokens.fromJson(Map<String, dynamic> json) {
    return SendTokens(
    hash: CanonHelpers.base64ToUint8List(json['Hash'] as String),
    meta: json['Meta'] as dynamic,
    to: json['To'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Hash': CanonHelpers.uint8ListToBase64(hash),
    'Meta': meta,
    'To': to,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(hash, 'hash');
    Validators.validateHash32(hash, 'hash');
    Validators.validateRequired(meta, 'meta');
    Validators.validateRequired(to, 'to');
  }
}


/// Protocol type: TransferCredits
final class TransferCredits {
  final dynamic to;

  const TransferCredits({required this.to});

  /// Create from JSON map
  factory TransferCredits.fromJson(Map<String, dynamic> json) {
    return TransferCredits(
    to: json['To'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'To': to,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(to, 'to');
  }
}


/// Protocol type: UpdateAccountAuth
final class UpdateAccountAuth {
  final dynamic operations;

  const UpdateAccountAuth({required this.operations});

  /// Create from JSON map
  factory UpdateAccountAuth.fromJson(Map<String, dynamic> json) {
    return UpdateAccountAuth(
    operations: json['Operations'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Operations': operations,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(operations, 'operations');
  }
}


/// Protocol type: UpdateKey
final class UpdateKey {
  final Uint8List newKeyHash;

  const UpdateKey({required this.newKeyHash});

  /// Create from JSON map
  factory UpdateKey.fromJson(Map<String, dynamic> json) {
    return UpdateKey(
    newKeyHash: CanonHelpers.base64ToUint8List(json['NewKeyHash'] as String),
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'NewKeyHash': CanonHelpers.uint8ListToBase64(newKeyHash),
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(newKeyHash, 'newKeyHash');
    Validators.validateHash32(newKeyHash, 'newKeyHash');
  }
}


/// Protocol type: UpdateKeyPage
final class UpdateKeyPage {
  final dynamic operation;

  const UpdateKeyPage({required this.operation});

  /// Create from JSON map
  factory UpdateKeyPage.fromJson(Map<String, dynamic> json) {
    return UpdateKeyPage(
    operation: json['Operation'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Operation': operation,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(operation, 'operation');
  }
}


/// Protocol type: WriteData
final class WriteData {
  final dynamic entry;
  final bool scratch;
  final bool writeToState;

  const WriteData({required this.entry, required this.scratch, required this.writeToState});

  /// Create from JSON map
  factory WriteData.fromJson(Map<String, dynamic> json) {
    return WriteData(
    entry: json['Entry'] as dynamic,
    scratch: json['Scratch'] as bool,
    writeToState: json['WriteToState'] as bool,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Entry': entry,
    'Scratch': scratch,
    'WriteToState': writeToState,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(entry, 'entry');
  }
}


/// Protocol type: WriteDataTo
final class WriteDataTo {
  final String recipient;
  final dynamic entry;

  const WriteDataTo({required this.recipient, required this.entry});

  /// Create from JSON map
  factory WriteDataTo.fromJson(Map<String, dynamic> json) {
    return WriteDataTo(
    recipient: json['Recipient'] as String,
    entry: json['Entry'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Recipient': recipient,
    'Entry': entry,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(recipient, 'recipient');
    Validators.validateUrl(recipient, 'recipient');
    Validators.validateRequired(entry, 'entry');
  }
}


