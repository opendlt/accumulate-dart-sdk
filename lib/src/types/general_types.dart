// GENERATED — Do not edit.
// Protocol types from general.yml

import 'dart:typed_data';
import '../runtime/canon_helpers.dart';
import '../runtime/validators.dart';

/// Protocol type: AccountAuth
final class AccountAuth {
  final AuthorityEntry authorities;

  const AccountAuth({required this.authorities});

  /// Create from JSON map
  factory AccountAuth.fromJson(Map<String, dynamic> json) {
    return AccountAuth(
    authorities: json['Authorities'] as AuthorityEntry,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Authorities': authorities,
    };
  }

  /// Validate the object
  void validate() {

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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Data': CanonHelpers.uint8ListToBase64(data),
    };
  }

  /// Validate the object
  void validate() {

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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Price': price,
    };
  }

  /// Validate the object
  void validate() {

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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Account': account,
    'Entry': CanonHelpers.uint8ListToBase64(entry),
    'Index': index,
    'SourceBlock': sourceBlock,
    'SourceIndex': sourceIndex,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(account, 'account');
  }
}

/// Protocol type: AnnotatedReceipt
final class AnnotatedReceipt {
  final dynamic receipt;
  final AnchorMetadata anchor;

  const AnnotatedReceipt({required this.receipt, required this.anchor});

  /// Create from JSON map
  factory AnnotatedReceipt.fromJson(Map<String, dynamic> json) {
    return AnnotatedReceipt(
    receipt: json['Receipt'] as dynamic,
    anchor: json['Anchor'] as AnchorMetadata,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Anchor': anchor,
    'Receipt': receipt,
    };
  }

  /// Validate the object
  void validate() {

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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Disabled': disabled,
    'Url': url,
    };
  }

  /// Validate the object
  void validate() {
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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Account': account,
    'Chain': chain,
    'Index': index,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(account, 'account');
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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Name': name,
    'Type': type,
    };
  }

  /// Validate the object
  void validate() {

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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Amount': amount,
    'Url': url,
    };
  }

  /// Validate the object
  void validate() {
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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Data': CanonHelpers.uint8ListToBase64(data),
    };
  }

  /// Validate the object
  void validate() {

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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'AccountId': CanonHelpers.uint8ListToBase64(accountId),
    'Data': CanonHelpers.uint8ListToBase64(data),
    'ExtIds': CanonHelpers.uint8ListToBase64(extIds),
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateHash32(accountId, 'accountId');
  }
}

/// Protocol type: FactomDataEntryWrapper
final class FactomDataEntryWrapper {
  final FactomDataEntry entry;

  const FactomDataEntryWrapper({required this.entry});

  /// Create from JSON map
  factory FactomDataEntryWrapper.fromJson(Map<String, dynamic> json) {
    return FactomDataEntryWrapper(
    entry: json['FactomDataEntry'] as FactomDataEntry,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'FactomDataEntry': entry,
    };
  }

  /// Validate the object
  void validate() {

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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'BareIdentityDiscount': bareIdentityDiscount,
    'CreateIdentitySliding': createIdentitySliding,
    'CreateSubIdentity': createSubIdentity,
    };
  }

  /// Validate the object
  void validate() {

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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Anchor': anchor,
    'BlockIndex': blockIndex,
    'BlockTime': blockTime.millisecondsSinceEpoch,
    'RootIndexIndex': rootIndexIndex,
    'Source': source,
    };
  }

  /// Validate the object
  void validate() {

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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Delegate': delegate,
    'LastUsedOn': lastUsedOn,
    'PublicKeyHash': CanonHelpers.uint8ListToBase64(publicKeyHash),
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(delegate, 'delegate');
  }
}

/// Protocol type: NetworkDefinition
final class NetworkDefinition {
  final String networkName;
  final int version;
  final PartitionInfo partitions;
  final ValidatorInfo validators;

  const NetworkDefinition({required this.networkName, required this.version, required this.partitions, required this.validators});

  /// Create from JSON map
  factory NetworkDefinition.fromJson(Map<String, dynamic> json) {
    return NetworkDefinition(
    networkName: json['NetworkName'] as String,
    version: json['Version'] as int,
    partitions: json['Partitions'] as PartitionInfo,
    validators: json['Validators'] as ValidatorInfo,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'NetworkName': networkName,
    'Partitions': partitions,
    'Validators': validators,
    'Version': version,
    };
  }

  /// Validate the object
  void validate() {

  }
}

/// Protocol type: NetworkGlobals
final class NetworkGlobals {
  final Rational operatorAcceptThreshold;
  final Rational validatorAcceptThreshold;
  final String majorBlockSchedule;
  final bool anchorEmptyBlocks;
  final FeeSchedule feeSchedule;
  final NetworkLimits limits;

  const NetworkGlobals({required this.operatorAcceptThreshold, required this.validatorAcceptThreshold, required this.majorBlockSchedule, required this.anchorEmptyBlocks, required this.feeSchedule, required this.limits});

  /// Create from JSON map
  factory NetworkGlobals.fromJson(Map<String, dynamic> json) {
    return NetworkGlobals(
    operatorAcceptThreshold: json['OperatorAcceptThreshold'] as Rational,
    validatorAcceptThreshold: json['ValidatorAcceptThreshold'] as Rational,
    majorBlockSchedule: json['MajorBlockSchedule'] as String,
    anchorEmptyBlocks: json['AnchorEmptyBlocks'] as bool,
    feeSchedule: json['FeeSchedule'] as FeeSchedule,
    limits: json['Limits'] as NetworkLimits,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'AnchorEmptyBlocks': anchorEmptyBlocks,
    'FeeSchedule': feeSchedule,
    'Limits': limits,
    'MajorBlockSchedule': majorBlockSchedule,
    'OperatorAcceptThreshold': operatorAcceptThreshold,
    'ValidatorAcceptThreshold': validatorAcceptThreshold,
    };
  }

  /// Validate the object
  void validate() {

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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'AccountAuthorities': accountAuthorities,
    'BookPages': bookPages,
    'DataEntryParts': dataEntryParts,
    'EventsPerBlock': eventsPerBlock,
    'IdentityAccounts': identityAccounts,
    'PageEntries': pageEntries,
    'PendingMajorBlocks': pendingMajorBlocks,
    };
  }

  /// Validate the object
  void validate() {

  }
}

/// Protocol type: Object
final class Object {
  final dynamic type;
  final ChainMetadata chains;
  final TxIdSet pending;

  const Object({required this.type, required this.chains, required this.pending});

  /// Create from JSON map
  factory Object.fromJson(Map<String, dynamic> json) {
    return Object(
    type: json['Type'] as dynamic,
    chains: json['Chains'] as ChainMetadata,
    pending: json['Pending'] as TxIdSet,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Chains': chains,
    'Pending': pending,
    'Type': type,
    };
  }

  /// Validate the object
  void validate() {

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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'ID': iD,
    'Type': type,
    };
  }

  /// Validate the object
  void validate() {

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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Denominator': denominator,
    'Numerator': numerator,
    };
  }

  /// Validate the object
  void validate() {

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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Length': length,
    'Partition': partition,
    'Value': value,
    };
  }

  /// Validate the object
  void validate() {

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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Account': account,
    'Partition': partition,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(account, 'account');
  }
}

/// Protocol type: RoutingTable
final class RoutingTable {
  final RouteOverride overrides;
  final Route routes;

  const RoutingTable({required this.overrides, required this.routes});

  /// Create from JSON map
  factory RoutingTable.fromJson(Map<String, dynamic> json) {
    return RoutingTable(
    overrides: json['Overrides'] as RouteOverride,
    routes: json['Routes'] as Route,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Overrides': overrides,
    'Routes': routes,
    };
  }

  /// Validate the object
  void validate() {

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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Receipt': receipt,
    'Transaction': transaction,
    };
  }

  /// Validate the object
  void validate() {

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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Amount': amount.toString(),
    'Url': url,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(url, 'url');
    Validators.validateBigInt(amount, 'amount');
  }
}

/// Protocol type: TxIdSet
final class TxIdSet {
  final String entries;

  const TxIdSet({required this.entries});

  /// Create from JSON map
  factory TxIdSet.fromJson(Map<String, dynamic> json) {
    return TxIdSet(
    entries: json['Entries'] as String,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Entries': entries,
    };
  }

  /// Validate the object
  void validate() {

  }
}

/// Protocol type: ValidatorInfo
final class ValidatorInfo {
  final Uint8List publicKey;
  final Uint8List publicKeyHash;
  final String operator;
  final ValidatorPartitionInfo partitions;

  const ValidatorInfo({required this.publicKey, required this.publicKeyHash, required this.operator, required this.partitions});

  /// Create from JSON map
  factory ValidatorInfo.fromJson(Map<String, dynamic> json) {
    return ValidatorInfo(
    publicKey: CanonHelpers.base64ToUint8List(json['PublicKey'] as String),
    publicKeyHash: CanonHelpers.base64ToUint8List(json['PublicKeyHash'] as String),
    operator: json['Operator'] as String,
    partitions: json['Partitions'] as ValidatorPartitionInfo,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Operator': operator,
    'Partitions': partitions,
    'PublicKey': CanonHelpers.uint8ListToBase64(publicKey),
    'PublicKeyHash': CanonHelpers.uint8ListToBase64(publicKeyHash),
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateHash32(publicKeyHash, 'publicKeyHash');
    Validators.validateUrl(operator, 'operator');
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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Active': active,
    'ID': iD,
    };
  }

  /// Validate the object
  void validate() {

  }
}

