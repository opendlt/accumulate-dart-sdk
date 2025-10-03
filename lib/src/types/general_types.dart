// GENERATED — Do not edit.
// Protocol types from general.yml

import 'dart:typed_data';
import '../runtime/canon_helpers.dart';
import '../runtime/validators.dart';

/// Protocol type: AccountAuth
final class AccountAuth {
  final dynamic authorities;

  const AccountAuth({required this.authorities});

  /// Create from JSON map
  factory AccountAuth.fromJson(Map<String, dynamic> json) {
    return AccountAuth(
    authorities: json['Authorities'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Authorities': authorities,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(authorities, 'authorities');
  }
}


/// Protocol type: AccumulateDataEntry
final class AccumulateDataEntry {
  final Uint8List data;

  const AccumulateDataEntry({required this.data});

  /// Create from JSON map
  factory AccumulateDataEntry.fromJson(Map<String, dynamic> json) {
    return AccumulateDataEntry(
    data: CanonHelpers.base64ToUint8List(json['Data'] as String),
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Data': CanonHelpers.uint8ListToBase64(data),
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(data, 'data');
  }
}


/// Protocol type: AcmeOracle
final class AcmeOracle {
  final int price;

  const AcmeOracle({required this.price});

  /// Create from JSON map
  factory AcmeOracle.fromJson(Map<String, dynamic> json) {
    return AcmeOracle(
    price: json['Price'] as int,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Price': price,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    // No validation required
  }
}


/// Protocol type: AnchorMetadata
final class AnchorMetadata {
  final String account;
  final int index;
  final int sourceIndex;
  final int sourceBlock;
  final Uint8List entry;

  const AnchorMetadata({required this.account, required this.index, required this.sourceIndex, required this.sourceBlock, required this.entry});

  /// Create from JSON map
  factory AnchorMetadata.fromJson(Map<String, dynamic> json) {
    return AnchorMetadata(
    account: json['Account'] as String,
    index: json['Index'] as int,
    sourceIndex: json['SourceIndex'] as int,
    sourceBlock: json['SourceBlock'] as int,
    entry: CanonHelpers.base64ToUint8List(json['Entry'] as String),
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Account': account,
    'Index': index,
    'SourceIndex': sourceIndex,
    'SourceBlock': sourceBlock,
    'Entry': CanonHelpers.uint8ListToBase64(entry),
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(account, 'account');
    Validators.validateUrl(account, 'account');
    Validators.validateRequired(entry, 'entry');
  }
}


/// Protocol type: AnnotatedReceipt
final class AnnotatedReceipt {
  final dynamic receipt;
  final dynamic anchor;

  const AnnotatedReceipt({required this.receipt, required this.anchor});

  /// Create from JSON map
  factory AnnotatedReceipt.fromJson(Map<String, dynamic> json) {
    return AnnotatedReceipt(
    receipt: json['Receipt'] as dynamic,
    anchor: json['Anchor'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Receipt': receipt,
    'Anchor': anchor,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(receipt, 'receipt');
    Validators.validateRequired(anchor, 'anchor');
  }
}


/// Protocol type: AuthorityEntry
final class AuthorityEntry {
  final String url;
  final bool disabled;

  const AuthorityEntry({required this.url, required this.disabled});

  /// Create from JSON map
  factory AuthorityEntry.fromJson(Map<String, dynamic> json) {
    return AuthorityEntry(
    url: json['Url'] as String,
    disabled: json['Disabled'] as bool,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Url': url,
    'Disabled': disabled,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(url, 'url');
    Validators.validateUrl(url, 'url');
  }
}


/// Protocol type: BlockEntry
final class BlockEntry {
  final String account;
  final String chain;
  final int index;

  const BlockEntry({required this.account, required this.chain, required this.index});

  /// Create from JSON map
  factory BlockEntry.fromJson(Map<String, dynamic> json) {
    return BlockEntry(
    account: json['Account'] as String,
    chain: json['Chain'] as String,
    index: json['Index'] as int,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Account': account,
    'Chain': chain,
    'Index': index,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(account, 'account');
    Validators.validateUrl(account, 'account');
    Validators.validateRequired(chain, 'chain');
  }
}


/// Protocol type: ChainMetadata
final class ChainMetadata {
  final String name;
  final dynamic type;

  const ChainMetadata({required this.name, required this.type});

  /// Create from JSON map
  factory ChainMetadata.fromJson(Map<String, dynamic> json) {
    return ChainMetadata(
    name: json['Name'] as String,
    type: json['Type'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Name': name,
    'Type': type,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(name, 'name');
    Validators.validateRequired(type, 'type');
  }
}


/// Protocol type: CreditRecipient
final class CreditRecipient {
  final String url;
  final int amount;

  const CreditRecipient({required this.url, required this.amount});

  /// Create from JSON map
  factory CreditRecipient.fromJson(Map<String, dynamic> json) {
    return CreditRecipient(
    url: json['Url'] as String,
    amount: json['Amount'] as int,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Url': url,
    'Amount': amount,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(url, 'url');
    Validators.validateUrl(url, 'url');
  }
}


/// Protocol type: DoubleHashDataEntry
final class DoubleHashDataEntry {
  final Uint8List data;

  const DoubleHashDataEntry({required this.data});

  /// Create from JSON map
  factory DoubleHashDataEntry.fromJson(Map<String, dynamic> json) {
    return DoubleHashDataEntry(
    data: CanonHelpers.base64ToUint8List(json['Data'] as String),
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Data': CanonHelpers.uint8ListToBase64(data),
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(data, 'data');
  }
}


/// Protocol type: FactomDataEntry
final class FactomDataEntry {
  final Uint8List accountId;
  final Uint8List data;
  final Uint8List extIds;

  const FactomDataEntry({required this.accountId, required this.data, required this.extIds});

  /// Create from JSON map
  factory FactomDataEntry.fromJson(Map<String, dynamic> json) {
    return FactomDataEntry(
    accountId: CanonHelpers.base64ToUint8List(json['AccountId'] as String),
    data: CanonHelpers.base64ToUint8List(json['Data'] as String),
    extIds: CanonHelpers.base64ToUint8List(json['ExtIds'] as String),
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'AccountId': CanonHelpers.uint8ListToBase64(accountId),
    'Data': CanonHelpers.uint8ListToBase64(data),
    'ExtIds': CanonHelpers.uint8ListToBase64(extIds),
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(accountId, 'accountId');
    Validators.validateHash32(accountId, 'accountId');
    Validators.validateRequired(data, 'data');
    Validators.validateRequired(extIds, 'extIds');
  }
}


/// Protocol type: FactomDataEntryWrapper
final class FactomDataEntryWrapper {
  final dynamic entry;

  const FactomDataEntryWrapper({required this.entry});

  /// Create from JSON map
  factory FactomDataEntryWrapper.fromJson(Map<String, dynamic> json) {
    return FactomDataEntryWrapper(
    entry: json['FactomDataEntry'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'FactomDataEntry': entry,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(entry, 'entry');
  }
}


/// Protocol type: FeeSchedule
final class FeeSchedule {
  final dynamic createIdentitySliding;
  final dynamic createSubIdentity;
  final dynamic bareIdentityDiscount;

  const FeeSchedule({required this.createIdentitySliding, required this.createSubIdentity, required this.bareIdentityDiscount});

  /// Create from JSON map
  factory FeeSchedule.fromJson(Map<String, dynamic> json) {
    return FeeSchedule(
    createIdentitySliding: json['CreateIdentitySliding'] as dynamic,
    createSubIdentity: json['CreateSubIdentity'] as dynamic,
    bareIdentityDiscount: json['BareIdentityDiscount'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'CreateIdentitySliding': createIdentitySliding,
    'CreateSubIdentity': createSubIdentity,
    'BareIdentityDiscount': bareIdentityDiscount,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(createIdentitySliding, 'createIdentitySliding');
    Validators.validateRequired(createSubIdentity, 'createSubIdentity');
    Validators.validateRequired(bareIdentityDiscount, 'bareIdentityDiscount');
  }
}


/// Protocol type: IndexEntry
final class IndexEntry {
  final int source;
  final int anchor;
  final int blockIndex;
  final DateTime blockTime;
  final int rootIndexIndex;

  const IndexEntry({required this.source, required this.anchor, required this.blockIndex, required this.blockTime, required this.rootIndexIndex});

  /// Create from JSON map
  factory IndexEntry.fromJson(Map<String, dynamic> json) {
    return IndexEntry(
    source: json['Source'] as int,
    anchor: json['Anchor'] as int,
    blockIndex: json['BlockIndex'] as int,
    blockTime: DateTime.fromMillisecondsSinceEpoch(json['BlockTime'] as int),
    rootIndexIndex: json['RootIndexIndex'] as int,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Source': source,
    'Anchor': anchor,
    'BlockIndex': blockIndex,
    'BlockTime': blockTime.millisecondsSinceEpoch,
    'RootIndexIndex': rootIndexIndex,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(blockTime, 'blockTime');
  }
}


/// Protocol type: KeySpec
final class KeySpec {
  final Uint8List publicKeyHash;
  final int lastUsedOn;
  final String delegate;

  const KeySpec({required this.publicKeyHash, required this.lastUsedOn, required this.delegate});

  /// Create from JSON map
  factory KeySpec.fromJson(Map<String, dynamic> json) {
    return KeySpec(
    publicKeyHash: CanonHelpers.base64ToUint8List(json['PublicKeyHash'] as String),
    lastUsedOn: json['LastUsedOn'] as int,
    delegate: json['Delegate'] as String,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'PublicKeyHash': CanonHelpers.uint8ListToBase64(publicKeyHash),
    'LastUsedOn': lastUsedOn,
    'Delegate': delegate,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(publicKeyHash, 'publicKeyHash');
    Validators.validateHash32(publicKeyHash, 'publicKeyHash');
    Validators.validateRequired(delegate, 'delegate');
    Validators.validateUrl(delegate, 'delegate');
  }
}


/// Protocol type: NetworkDefinition
final class NetworkDefinition {
  final String networkName;
  final int version;
  final dynamic partitions;
  final dynamic validators;

  const NetworkDefinition({required this.networkName, required this.version, required this.partitions, required this.validators});

  /// Create from JSON map
  factory NetworkDefinition.fromJson(Map<String, dynamic> json) {
    return NetworkDefinition(
    networkName: json['NetworkName'] as String,
    version: json['Version'] as int,
    partitions: json['Partitions'] as dynamic,
    validators: json['Validators'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'NetworkName': networkName,
    'Version': version,
    'Partitions': partitions,
    'Validators': validators,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(networkName, 'networkName');
    Validators.validateRequired(partitions, 'partitions');
    Validators.validateRequired(validators, 'validators');
  }
}


/// Protocol type: NetworkGlobals
final class NetworkGlobals {
  final dynamic operatorAcceptThreshold;
  final dynamic validatorAcceptThreshold;
  final String majorBlockSchedule;
  final bool anchorEmptyBlocks;
  final dynamic feeSchedule;
  final dynamic limits;

  const NetworkGlobals({required this.operatorAcceptThreshold, required this.validatorAcceptThreshold, required this.majorBlockSchedule, required this.anchorEmptyBlocks, required this.feeSchedule, required this.limits});

  /// Create from JSON map
  factory NetworkGlobals.fromJson(Map<String, dynamic> json) {
    return NetworkGlobals(
    operatorAcceptThreshold: json['OperatorAcceptThreshold'] as dynamic,
    validatorAcceptThreshold: json['ValidatorAcceptThreshold'] as dynamic,
    majorBlockSchedule: json['MajorBlockSchedule'] as String,
    anchorEmptyBlocks: json['AnchorEmptyBlocks'] as bool,
    feeSchedule: json['FeeSchedule'] as dynamic,
    limits: json['Limits'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'OperatorAcceptThreshold': operatorAcceptThreshold,
    'ValidatorAcceptThreshold': validatorAcceptThreshold,
    'MajorBlockSchedule': majorBlockSchedule,
    'AnchorEmptyBlocks': anchorEmptyBlocks,
    'FeeSchedule': feeSchedule,
    'Limits': limits,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(operatorAcceptThreshold, 'operatorAcceptThreshold');
    Validators.validateRequired(validatorAcceptThreshold, 'validatorAcceptThreshold');
    Validators.validateRequired(majorBlockSchedule, 'majorBlockSchedule');
    Validators.validateRequired(feeSchedule, 'feeSchedule');
    Validators.validateRequired(limits, 'limits');
  }
}


/// Protocol type: NetworkLimits
final class NetworkLimits {
  final int dataEntryParts;
  final int accountAuthorities;
  final int bookPages;
  final int pageEntries;
  final int identityAccounts;
  final int pendingMajorBlocks;
  final int eventsPerBlock;

  const NetworkLimits({required this.dataEntryParts, required this.accountAuthorities, required this.bookPages, required this.pageEntries, required this.identityAccounts, required this.pendingMajorBlocks, required this.eventsPerBlock});

  /// Create from JSON map
  factory NetworkLimits.fromJson(Map<String, dynamic> json) {
    return NetworkLimits(
    dataEntryParts: json['DataEntryParts'] as int,
    accountAuthorities: json['AccountAuthorities'] as int,
    bookPages: json['BookPages'] as int,
    pageEntries: json['PageEntries'] as int,
    identityAccounts: json['IdentityAccounts'] as int,
    pendingMajorBlocks: json['PendingMajorBlocks'] as int,
    eventsPerBlock: json['EventsPerBlock'] as int,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'DataEntryParts': dataEntryParts,
    'AccountAuthorities': accountAuthorities,
    'BookPages': bookPages,
    'PageEntries': pageEntries,
    'IdentityAccounts': identityAccounts,
    'PendingMajorBlocks': pendingMajorBlocks,
    'EventsPerBlock': eventsPerBlock,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    // No validation required
  }
}


/// Protocol type: Object
final class Object {
  final dynamic type;
  final dynamic chains;
  final dynamic pending;

  const Object({required this.type, required this.chains, required this.pending});

  /// Create from JSON map
  factory Object.fromJson(Map<String, dynamic> json) {
    return Object(
    type: json['Type'] as dynamic,
    chains: json['Chains'] as dynamic,
    pending: json['Pending'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Type': type,
    'Chains': chains,
    'Pending': pending,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(type, 'type');
    Validators.validateRequired(chains, 'chains');
    Validators.validateRequired(pending, 'pending');
  }
}


/// Protocol type: PartitionInfo
final class PartitionInfo {
  final String iD;
  final dynamic type;

  const PartitionInfo({required this.iD, required this.type});

  /// Create from JSON map
  factory PartitionInfo.fromJson(Map<String, dynamic> json) {
    return PartitionInfo(
    iD: json['ID'] as String,
    type: json['Type'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'ID': iD,
    'Type': type,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(iD, 'iD');
    Validators.validateRequired(type, 'type');
  }
}


/// Protocol type: Rational
final class Rational {
  final int numerator;
  final int denominator;

  const Rational({required this.numerator, required this.denominator});

  /// Create from JSON map
  factory Rational.fromJson(Map<String, dynamic> json) {
    return Rational(
    numerator: json['Numerator'] as int,
    denominator: json['Denominator'] as int,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Numerator': numerator,
    'Denominator': denominator,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    // No validation required
  }
}


/// Protocol type: Route
final class Route {
  final int length;
  final int value;
  final String partition;

  const Route({required this.length, required this.value, required this.partition});

  /// Create from JSON map
  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
    length: json['Length'] as int,
    value: json['Value'] as int,
    partition: json['Partition'] as String,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Length': length,
    'Value': value,
    'Partition': partition,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(partition, 'partition');
  }
}


/// Protocol type: RouteOverride
final class RouteOverride {
  final String account;
  final String partition;

  const RouteOverride({required this.account, required this.partition});

  /// Create from JSON map
  factory RouteOverride.fromJson(Map<String, dynamic> json) {
    return RouteOverride(
    account: json['Account'] as String,
    partition: json['Partition'] as String,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Account': account,
    'Partition': partition,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(account, 'account');
    Validators.validateUrl(account, 'account');
    Validators.validateRequired(partition, 'partition');
  }
}


/// Protocol type: RoutingTable
final class RoutingTable {
  final dynamic overrides;
  final dynamic routes;

  const RoutingTable({required this.overrides, required this.routes});

  /// Create from JSON map
  factory RoutingTable.fromJson(Map<String, dynamic> json) {
    return RoutingTable(
    overrides: json['Overrides'] as dynamic,
    routes: json['Routes'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Overrides': overrides,
    'Routes': routes,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(overrides, 'overrides');
    Validators.validateRequired(routes, 'routes');
  }
}


/// Protocol type: TokenIssuerProof
final class TokenIssuerProof {
  final dynamic transaction;
  final dynamic receipt;

  const TokenIssuerProof({required this.transaction, required this.receipt});

  /// Create from JSON map
  factory TokenIssuerProof.fromJson(Map<String, dynamic> json) {
    return TokenIssuerProof(
    transaction: json['Transaction'] as dynamic,
    receipt: json['Receipt'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Transaction': transaction,
    'Receipt': receipt,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(transaction, 'transaction');
    Validators.validateRequired(receipt, 'receipt');
  }
}


/// Protocol type: TokenRecipient
final class TokenRecipient {
  final String url;
  final BigInt amount;

  const TokenRecipient({required this.url, required this.amount});

  /// Create from JSON map
  factory TokenRecipient.fromJson(Map<String, dynamic> json) {
    return TokenRecipient(
    url: json['Url'] as String,
    amount: BigInt.parse(json['Amount'] as String),
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Url': url,
    'Amount': CanonHelpers.bigIntToJson(amount),
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(url, 'url');
    Validators.validateUrl(url, 'url');
    Validators.validateRequired(amount, 'amount');
    Validators.validateBigInt(amount, 'amount');
  }
}


/// Protocol type: TxIdSet
final class TxIdSet {
  final dynamic entries;

  const TxIdSet({required this.entries});

  /// Create from JSON map
  factory TxIdSet.fromJson(Map<String, dynamic> json) {
    return TxIdSet(
    entries: json['Entries'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Entries': entries,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(entries, 'entries');
  }
}


/// Protocol type: ValidatorInfo
final class ValidatorInfo {
  final Uint8List publicKey;
  final Uint8List publicKeyHash;
  final String operator;
  final dynamic partitions;

  const ValidatorInfo({required this.publicKey, required this.publicKeyHash, required this.operator, required this.partitions});

  /// Create from JSON map
  factory ValidatorInfo.fromJson(Map<String, dynamic> json) {
    return ValidatorInfo(
    publicKey: CanonHelpers.base64ToUint8List(json['PublicKey'] as String),
    publicKeyHash: CanonHelpers.base64ToUint8List(json['PublicKeyHash'] as String),
    operator: json['Operator'] as String,
    partitions: json['Partitions'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'PublicKey': CanonHelpers.uint8ListToBase64(publicKey),
    'PublicKeyHash': CanonHelpers.uint8ListToBase64(publicKeyHash),
    'Operator': operator,
    'Partitions': partitions,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(publicKey, 'publicKey');
    Validators.validateRequired(publicKeyHash, 'publicKeyHash');
    Validators.validateHash32(publicKeyHash, 'publicKeyHash');
    Validators.validateRequired(operator, 'operator');
    Validators.validateUrl(operator, 'operator');
    Validators.validateRequired(partitions, 'partitions');
  }
}


/// Protocol type: ValidatorPartitionInfo
final class ValidatorPartitionInfo {
  final String iD;
  final bool active;

  const ValidatorPartitionInfo({required this.iD, required this.active});

  /// Create from JSON map
  factory ValidatorPartitionInfo.fromJson(Map<String, dynamic> json) {
    return ValidatorPartitionInfo(
    iD: json['ID'] as String,
    active: json['Active'] as bool,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'ID': iD,
    'Active': active,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(iD, 'iD');
  }
}


