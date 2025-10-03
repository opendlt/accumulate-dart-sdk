// GENERATED — Do not edit.
// Protocol types from system.yml

import 'dart:typed_data';
import '../../enums.dart';
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

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Url': url,
    'MinorBlockSequenceNumber': minorBlockSequenceNumber,
    'MajorBlockIndex': majorBlockIndex,
    'MajorBlockTime': majorBlockTime.millisecondsSinceEpoch,
    'PendingMajorBlockAnchors': pendingMajorBlockAnchors,
    'Sequence': sequence,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(url, 'url');
    Validators.validateUrl(url, 'url');
    Validators.validateRequired(majorBlockTime, 'majorBlockTime');
    Validators.validateRequired(pendingMajorBlockAnchors, 'pendingMajorBlockAnchors');
    Validators.validateUrl(pendingMajorBlockAnchors, 'pendingMajorBlockAnchors');
    Validators.validateRequired(sequence, 'sequence');
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

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Url': url,
    'Index': index,
    'Time': time.millisecondsSinceEpoch,
    'Entries': entries,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(url, 'url');
    Validators.validateUrl(url, 'url');
    Validators.validateRequired(time, 'time');
    Validators.validateRequired(entries, 'entries');
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

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'AcmeBurnt': CanonHelpers.bigIntToJson(acmeBurnt),
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(acmeBurnt, 'acmeBurnt');
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

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Updates': updates,
    'Receipts': receipts,
    'MakeMajorBlock': makeMajorBlock,
    'MakeMajorBlockTime': makeMajorBlockTime.millisecondsSinceEpoch,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(updates, 'updates');
    Validators.validateRequired(receipts, 'receipts');
    Validators.validateRequired(makeMajorBlockTime, 'makeMajorBlockTime');
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

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Name': name,
    'Body': body,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(name, 'name');
    Validators.validateRequired(body, 'body');
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

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Source': source,
    'MajorBlockIndex': majorBlockIndex,
    'MinorBlockIndex': minorBlockIndex,
    'RootChainIndex': rootChainIndex,
    'RootChainAnchor': CanonHelpers.uint8ListToBase64(rootChainAnchor),
    'StateTreeAnchor': CanonHelpers.uint8ListToBase64(stateTreeAnchor),
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(source, 'source');
    Validators.validateUrl(source, 'source');
    Validators.validateRequired(rootChainAnchor, 'rootChainAnchor');
    Validators.validateHash32(rootChainAnchor, 'rootChainAnchor');
    Validators.validateRequired(stateTreeAnchor, 'stateTreeAnchor');
    Validators.validateHash32(stateTreeAnchor, 'stateTreeAnchor');
  }
}


/// Protocol type: PartitionAnchorReceipt
final class PartitionAnchorReceipt {
  final dynamic anchor;
  final dynamic rootChainReceipt;

  const PartitionAnchorReceipt({required this.anchor, required this.rootChainReceipt});

  /// Create from JSON map
  factory PartitionAnchorReceipt.fromJson(Map<String, dynamic> json) {
    return PartitionAnchorReceipt(
    anchor: json['Anchor'] as dynamic,
    rootChainReceipt: json['RootChainReceipt'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Anchor': anchor,
    'RootChainReceipt': rootChainReceipt,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(anchor, 'anchor');
    Validators.validateRequired(rootChainReceipt, 'rootChainReceipt');
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

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Partition': partition,
    'Version': version,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(partition, 'partition');
    Validators.validateRequired(version, 'version');
  }
}


/// Protocol type: PartitionSyntheticLedger
final class PartitionSyntheticLedger {
  final String url;
  final int produced;
  final int received;
  final int delivered;
  final dynamic pending;

  const PartitionSyntheticLedger({required this.url, required this.produced, required this.received, required this.delivered, required this.pending});

  /// Create from JSON map
  factory PartitionSyntheticLedger.fromJson(Map<String, dynamic> json) {
    return PartitionSyntheticLedger(
    url: json['Url'] as String,
    produced: json['Produced'] as int,
    received: json['Received'] as int,
    delivered: json['Delivered'] as int,
    pending: json['Pending'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Url': url,
    'Produced': produced,
    'Received': received,
    'Delivered': delivered,
    'Pending': pending,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(url, 'url');
    Validators.validateUrl(url, 'url');
    Validators.validateRequired(pending, 'pending');
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

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Url': url,
    'Sequence': sequence,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(url, 'url');
    Validators.validateUrl(url, 'url');
    Validators.validateRequired(sequence, 'sequence');
  }
}


/// Protocol type: SystemGenesis
final class SystemGenesis {
  const SystemGenesis();

  /// Create from JSON map
  factory SystemGenesis.fromJson(Map<String, dynamic> json) {
    return SystemGenesis();
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

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Url': url,
    'Index': index,
    'Timestamp': timestamp.millisecondsSinceEpoch,
    'AcmeBurnt': CanonHelpers.bigIntToJson(acmeBurnt),
    'PendingUpdates': pendingUpdates,
    'Anchor': anchor,
    'ExecutorVersion': executorVersion,
    'BvnExecutorVersions': bvnExecutorVersions,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(url, 'url');
    Validators.validateUrl(url, 'url');
    Validators.validateRequired(timestamp, 'timestamp');
    Validators.validateRequired(acmeBurnt, 'acmeBurnt');
    Validators.validateBigInt(acmeBurnt, 'acmeBurnt');
    Validators.validateRequired(pendingUpdates, 'pendingUpdates');
    Validators.validateRequired(anchor, 'anchor');
    Validators.validateRequired(executorVersion, 'executorVersion');
    Validators.validateRequired(bvnExecutorVersions, 'bvnExecutorVersions');
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

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Entry': entry,
    'WriteToState': writeToState,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(entry, 'entry');
  }
}


