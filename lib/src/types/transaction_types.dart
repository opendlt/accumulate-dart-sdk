// GENERATED — Do not edit.
// Protocol types from transaction.yml

import 'dart:typed_data';
import '../runtime/canon_helpers.dart';
import '../runtime/validators.dart';

/// Protocol type: ExpireOptions
final class ExpireOptions {
  final DateTime atTime;

  const ExpireOptions({required this.atTime});

  /// Create from JSON map
  factory ExpireOptions.fromJson(Map<String, dynamic> json) {
    return ExpireOptions(
    atTime: DateTime.fromMillisecondsSinceEpoch(json['AtTime'] as int),
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'AtTime': atTime.millisecondsSinceEpoch,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(atTime, 'atTime');
  }
}


/// Protocol type: HoldUntilOptions
final class HoldUntilOptions {
  final int minorBlock;

  const HoldUntilOptions({required this.minorBlock});

  /// Create from JSON map
  factory HoldUntilOptions.fromJson(Map<String, dynamic> json) {
    return HoldUntilOptions(
    minorBlock: json['MinorBlock'] as int,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'MinorBlock': minorBlock,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    // No validation required
  }
}


/// Protocol type: Transaction
final class Transaction {
  final dynamic header;
  final dynamic body;
  final Uint8List hash;
  final bool header64bytes;
  final bool body64bytes;

  const Transaction({required this.header, required this.body, required this.hash, required this.header64bytes, required this.body64bytes});

  /// Create from JSON map
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
    header: json['Header'] as dynamic,
    body: json['Body'] as dynamic,
    hash: CanonHelpers.base64ToUint8List(json['hash'] as String),
    header64bytes: json['header64bytes'] as bool,
    body64bytes: json['body64bytes'] as bool,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Header': header,
    'Body': body,
    'hash': CanonHelpers.uint8ListToBase64(hash),
    'header64bytes': header64bytes,
    'body64bytes': body64bytes,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(header, 'header');
    Validators.validateRequired(body, 'body');
    Validators.validateRequired(hash, 'hash');
    Validators.validateHash32(hash, 'hash');
  }
}


/// Protocol type: TransactionHeader
final class TransactionHeader {
  final String principal;
  final Uint8List initiator;
  final String memo;
  final Uint8List metadata;
  final dynamic expire;
  final dynamic holdUntil;
  final String authorities;

  const TransactionHeader({required this.principal, required this.initiator, required this.memo, required this.metadata, required this.expire, required this.holdUntil, required this.authorities});

  /// Create from JSON map
  factory TransactionHeader.fromJson(Map<String, dynamic> json) {
    return TransactionHeader(
    principal: json['Principal'] as String,
    initiator: CanonHelpers.base64ToUint8List(json['Initiator'] as String),
    memo: json['Memo'] as String,
    metadata: CanonHelpers.base64ToUint8List(json['Metadata'] as String),
    expire: json['Expire'] as dynamic,
    holdUntil: json['HoldUntil'] as dynamic,
    authorities: json['Authorities'] as String,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Principal': principal,
    'Initiator': CanonHelpers.uint8ListToBase64(initiator),
    'Memo': memo,
    'Metadata': CanonHelpers.uint8ListToBase64(metadata),
    'Expire': expire,
    'HoldUntil': holdUntil,
    'Authorities': authorities,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(principal, 'principal');
    Validators.validateUrl(principal, 'principal');
    Validators.validateRequired(initiator, 'initiator');
    Validators.validateHash32(initiator, 'initiator');
    Validators.validateRequired(memo, 'memo');
    Validators.validateRequired(metadata, 'metadata');
    Validators.validateRequired(expire, 'expire');
    Validators.validateRequired(holdUntil, 'holdUntil');
    Validators.validateRequired(authorities, 'authorities');
    Validators.validateUrl(authorities, 'authorities');
  }
}


/// Protocol type: TransactionStatus
final class TransactionStatus {
  final dynamic txID;
  final dynamic code;
  final bool remote;
  final bool delivered;
  final bool pending;
  final bool failed;
  final int codeNum;
  final dynamic error;
  final dynamic result;
  final int received;
  final String initiator;
  final dynamic signers;
  final String sourceNetwork;
  final String destinationNetwork;
  final int sequenceNumber;
  final bool gotDirectoryReceipt;
  final dynamic proof;
  final Uint8List anchorSigners;

  const TransactionStatus({required this.txID, required this.code, required this.remote, required this.delivered, required this.pending, required this.failed, required this.codeNum, required this.error, required this.result, required this.received, required this.initiator, required this.signers, required this.sourceNetwork, required this.destinationNetwork, required this.sequenceNumber, required this.gotDirectoryReceipt, required this.proof, required this.anchorSigners});

  /// Create from JSON map
  factory TransactionStatus.fromJson(Map<String, dynamic> json) {
    return TransactionStatus(
    txID: json['TxID'] as dynamic,
    code: json['Code'] as dynamic,
    remote: json['Remote'] as bool,
    delivered: json['Delivered'] as bool,
    pending: json['Pending'] as bool,
    failed: json['Failed'] as bool,
    codeNum: json['CodeNum'] as int,
    error: json['Error'] as dynamic,
    result: json['Result'] as dynamic,
    received: json['Received'] as int,
    initiator: json['Initiator'] as String,
    signers: json['Signers'] as dynamic,
    sourceNetwork: json['SourceNetwork'] as String,
    destinationNetwork: json['DestinationNetwork'] as String,
    sequenceNumber: json['SequenceNumber'] as int,
    gotDirectoryReceipt: json['GotDirectoryReceipt'] as bool,
    proof: json['Proof'] as dynamic,
    anchorSigners: CanonHelpers.base64ToUint8List(json['AnchorSigners'] as String),
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'TxID': txID,
    'Code': code,
    'Remote': remote,
    'Delivered': delivered,
    'Pending': pending,
    'Failed': failed,
    'CodeNum': codeNum,
    'Error': error,
    'Result': result,
    'Received': received,
    'Initiator': initiator,
    'Signers': signers,
    'SourceNetwork': sourceNetwork,
    'DestinationNetwork': destinationNetwork,
    'SequenceNumber': sequenceNumber,
    'GotDirectoryReceipt': gotDirectoryReceipt,
    'Proof': proof,
    'AnchorSigners': CanonHelpers.uint8ListToBase64(anchorSigners),
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(txID, 'txID');
    Validators.validateRequired(code, 'code');
    Validators.validateRequired(error, 'error');
    Validators.validateRequired(result, 'result');
    Validators.validateRequired(initiator, 'initiator');
    Validators.validateUrl(initiator, 'initiator');
    Validators.validateRequired(signers, 'signers');
    Validators.validateRequired(sourceNetwork, 'sourceNetwork');
    Validators.validateUrl(sourceNetwork, 'sourceNetwork');
    Validators.validateRequired(destinationNetwork, 'destinationNetwork');
    Validators.validateUrl(destinationNetwork, 'destinationNetwork');
    Validators.validateRequired(proof, 'proof');
    Validators.validateRequired(anchorSigners, 'anchorSigners');
  }
}


