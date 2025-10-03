// GENERATED — Do not edit.
// Protocol types from system.yml

import 'dart:typed_data';
import '../enums.dart';
import '../runtime/canon_helpers.dart';
import '../runtime/validators.dart';

/// Protocol type: AnchorLedger
final class AnchorLedger {
  final String url;
  final int minorBlockSequenceNumber;
  final int majorBlockIndex;
  final DateTime majorBlockTime;
  final String pendingMajorBlockAnchors;
  final dynamic sequence;

  const AnchorLedger({required this.url, required this.minorBlockSequenceNumber, required this.majorBlockIndex, required this.majorBlockTime, required this.pendingMajorBlockAnchors, required this.sequence});

  /// Create from JSON map
  factory AnchorLedger.fromJson(Map<String, dynamic> json) {
    return AnchorLedger(
    url: json['Url'] as String,
    minorBlockSequenceNumber: json['MinorBlockSequenceNumber'] as int,
    majorBlockIndex: json['MajorBlockIndex'] as int,
    majorBlockTime: DateTime.fromMillisecondsSinceEpoch(json['MajorBlockTime'] as int),
    pendingMajorBlockAnchors: json['PendingMajorBlockAnchors'] as String,
    sequence: json['Sequence'] as dynamic,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'MajorBlockIndex': majorBlockIndex,
    'MajorBlockTime': majorBlockTime.millisecondsSinceEpoch,
    'MinorBlockSequenceNumber': minorBlockSequenceNumber,
    'PendingMajorBlockAnchors': pendingMajorBlockAnchors,
    'Sequence': sequence,
    'Url': url,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(url, 'url');
    Validators.validateUrl(pendingMajorBlockAnchors, 'pendingMajorBlockAnchors');
  }
}

/// Protocol type: BlockLedger
final class BlockLedger {
  final String url;
  final int index;
  final DateTime time;
  final dynamic entries;

  const BlockLedger({required this.url, required this.index, required this.time, required this.entries});

  /// Create from JSON map
  factory BlockLedger.fromJson(Map<String, dynamic> json) {
    return BlockLedger(
    url: json['Url'] as String,
    index: json['Index'] as int,
    time: DateTime.fromMillisecondsSinceEpoch(json['Time'] as int),
    entries: json['Entries'] as dynamic,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Entries': entries,
    'Index': index,
    'Time': time.millisecondsSinceEpoch,
    'Url': url,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(url, 'url');
  }
}

/// Protocol type: BlockValidatorAnchor
final class BlockValidatorAnchor {
  final BigInt acmeBurnt;

  const BlockValidatorAnchor({required this.acmeBurnt});

  /// Create from JSON map
  factory BlockValidatorAnchor.fromJson(Map<String, dynamic> json) {
    return BlockValidatorAnchor(
    acmeBurnt: BigInt.parse(json['AcmeBurnt'] as String),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'AcmeBurnt': acmeBurnt.toString(),
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateBigInt(acmeBurnt, 'acmeBurnt');
  }
}

/// Protocol type: DirectoryAnchor
final class DirectoryAnchor {
  final dynamic updates;
  final dynamic receipts;
  final int makeMajorBlock;
  final DateTime makeMajorBlockTime;

  const DirectoryAnchor({required this.updates, required this.receipts, required this.makeMajorBlock, required this.makeMajorBlockTime});

  /// Create from JSON map
  factory DirectoryAnchor.fromJson(Map<String, dynamic> json) {
    return DirectoryAnchor(
    updates: json['Updates'] as dynamic,
    receipts: json['Receipts'] as dynamic,
    makeMajorBlock: json['MakeMajorBlock'] as int,
    makeMajorBlockTime: DateTime.fromMillisecondsSinceEpoch(json['MakeMajorBlockTime'] as int),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'MakeMajorBlock': makeMajorBlock,
    'MakeMajorBlockTime': makeMajorBlockTime.millisecondsSinceEpoch,
    'Receipts': receipts,
    'Updates': updates,
    };
  }

  /// Validate the object
  void validate() {

  }
}

/// Protocol type: NetworkAccountUpdate
final class NetworkAccountUpdate {
  final String name;
  final dynamic body;

  const NetworkAccountUpdate({required this.name, required this.body});

  /// Create from JSON map
  factory NetworkAccountUpdate.fromJson(Map<String, dynamic> json) {
    return NetworkAccountUpdate(
    name: json['Name'] as String,
    body: json['Body'] as dynamic,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Body': body,
    'Name': name,
    };
  }

  /// Validate the object
  void validate() {

  }
}

/// Protocol type: PartitionAnchor
final class PartitionAnchor {
  final String source;
  final int majorBlockIndex;
  final int minorBlockIndex;
  final int rootChainIndex;
  final Uint8List rootChainAnchor;
  final Uint8List stateTreeAnchor;

  const PartitionAnchor({required this.source, required this.majorBlockIndex, required this.minorBlockIndex, required this.rootChainIndex, required this.rootChainAnchor, required this.stateTreeAnchor});

  /// Create from JSON map
  factory PartitionAnchor.fromJson(Map<String, dynamic> json) {
    return PartitionAnchor(
    source: json['Source'] as String,
    majorBlockIndex: json['MajorBlockIndex'] as int,
    minorBlockIndex: json['MinorBlockIndex'] as int,
    rootChainIndex: json['RootChainIndex'] as int,
    rootChainAnchor: CanonHelpers.base64ToUint8List(json['RootChainAnchor'] as String),
    stateTreeAnchor: CanonHelpers.base64ToUint8List(json['StateTreeAnchor'] as String),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'MajorBlockIndex': majorBlockIndex,
    'MinorBlockIndex': minorBlockIndex,
    'RootChainAnchor': CanonHelpers.uint8ListToBase64(rootChainAnchor),
    'RootChainIndex': rootChainIndex,
    'Source': source,
    'StateTreeAnchor': CanonHelpers.uint8ListToBase64(stateTreeAnchor),
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(source, 'source');
    Validators.validateHash32(rootChainAnchor, 'rootChainAnchor');
    Validators.validateHash32(stateTreeAnchor, 'stateTreeAnchor');
  }
}

/// Protocol type: PartitionAnchorReceipt
final class PartitionAnchorReceipt {
  final PartitionAnchor anchor;
  final dynamic rootChainReceipt;

  const PartitionAnchorReceipt({required this.anchor, required this.rootChainReceipt});

  /// Create from JSON map
  factory PartitionAnchorReceipt.fromJson(Map<String, dynamic> json) {
    return PartitionAnchorReceipt(
    anchor: json['Anchor'] as PartitionAnchor,
    rootChainReceipt: json['RootChainReceipt'] as dynamic,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Anchor': anchor,
    'RootChainReceipt': rootChainReceipt,
    };
  }

  /// Validate the object
  void validate() {

  }
}

/// Protocol type: PartitionExecutorVersion
final class PartitionExecutorVersion {
  final String partition;
  final ExecutorVersion version;

  const PartitionExecutorVersion({required this.partition, required this.version});

  /// Create from JSON map
  factory PartitionExecutorVersion.fromJson(Map<String, dynamic> json) {
    return PartitionExecutorVersion(
    partition: json['Partition'] as String,
    version: json['Version'] as ExecutorVersion,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Partition': partition,
    'Version': version,
    };
  }

  /// Validate the object
  void validate() {

  }
}

/// Protocol type: PartitionSyntheticLedger
final class PartitionSyntheticLedger {
  final String url;
  final int produced;
  final int received;
  final int delivered;
  final String pending;

  const PartitionSyntheticLedger({required this.url, required this.produced, required this.received, required this.delivered, required this.pending});

  /// Create from JSON map
  factory PartitionSyntheticLedger.fromJson(Map<String, dynamic> json) {
    return PartitionSyntheticLedger(
    url: json['Url'] as String,
    produced: json['Produced'] as int,
    received: json['Received'] as int,
    delivered: json['Delivered'] as int,
    pending: json['Pending'] as String,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Delivered': delivered,
    'Pending': pending,
    'Produced': produced,
    'Received': received,
    'Url': url,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(url, 'url');
  }
}

/// Protocol type: SyntheticLedger
final class SyntheticLedger {
  final String url;
  final dynamic sequence;

  const SyntheticLedger({required this.url, required this.sequence});

  /// Create from JSON map
  factory SyntheticLedger.fromJson(Map<String, dynamic> json) {
    return SyntheticLedger(
    url: json['Url'] as String,
    sequence: json['Sequence'] as dynamic,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Sequence': sequence,
    'Url': url,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(url, 'url');
  }
}

/// Protocol type: SystemGenesis
final class SystemGenesis {


  const SystemGenesis();

  /// Create from JSON map
  factory SystemGenesis.fromJson(Map<String, dynamic> json) {
    return SystemGenesis(

    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {

    };
  }

  /// Validate the object
  void validate() {

  }
}

/// Protocol type: SystemLedger
final class SystemLedger {
  final String url;
  final int index;
  final DateTime timestamp;
  final BigInt acmeBurnt;
  final dynamic pendingUpdates;
  final dynamic anchor;
  final ExecutorVersion executorVersion;
  final dynamic bvnExecutorVersions;

  const SystemLedger({required this.url, required this.index, required this.timestamp, required this.acmeBurnt, required this.pendingUpdates, required this.anchor, required this.executorVersion, required this.bvnExecutorVersions});

  /// Create from JSON map
  factory SystemLedger.fromJson(Map<String, dynamic> json) {
    return SystemLedger(
    url: json['Url'] as String,
    index: json['Index'] as int,
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['Timestamp'] as int),
    acmeBurnt: BigInt.parse(json['AcmeBurnt'] as String),
    pendingUpdates: json['PendingUpdates'] as dynamic,
    anchor: json['Anchor'] as dynamic,
    executorVersion: json['ExecutorVersion'] as ExecutorVersion,
    bvnExecutorVersions: json['BvnExecutorVersions'] as dynamic,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'AcmeBurnt': acmeBurnt.toString(),
    'Anchor': anchor,
    'BvnExecutorVersions': bvnExecutorVersions,
    'ExecutorVersion': executorVersion,
    'Index': index,
    'PendingUpdates': pendingUpdates,
    'Timestamp': timestamp.millisecondsSinceEpoch,
    'Url': url,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(url, 'url');
    Validators.validateBigInt(acmeBurnt, 'acmeBurnt');
  }
}

/// Protocol type: SystemWriteData
final class SystemWriteData {
  final dynamic entry;
  final bool writeToState;

  const SystemWriteData({required this.entry, required this.writeToState});

  /// Create from JSON map
  factory SystemWriteData.fromJson(Map<String, dynamic> json) {
    return SystemWriteData(
    entry: json['Entry'] as dynamic,
    writeToState: json['WriteToState'] as bool,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Entry': entry,
    'WriteToState': writeToState,
    };
  }

  /// Validate the object
  void validate() {

  }
}

