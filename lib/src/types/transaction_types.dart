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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'AtTime': atTime.millisecondsSinceEpoch,
    };
  }

  /// Validate the object
  void validate() {

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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'MinorBlock': minorBlock,
    };
  }

  /// Validate the object
  void validate() {

  }
}

/// Protocol type: Transaction
final class Transaction {
  final TransactionHeader header;
  final dynamic body;
  final Uint8List hash;
  final bool header64bytes;
  final bool body64bytes;

  const Transaction({required this.header, required this.body, required this.hash, required this.header64bytes, required this.body64bytes});

  /// Create from JSON map
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
    header: json['Header'] as TransactionHeader,
    body: json['Body'] as dynamic,
    hash: CanonHelpers.base64ToUint8List(json['hash'] as String),
    header64bytes: json['header64bytes'] as bool,
    body64bytes: json['body64bytes'] as bool,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Body': body,
    'Header': header,
    'body64bytes': body64bytes,
    'hash': CanonHelpers.uint8ListToBase64(hash),
    'header64bytes': header64bytes,
    };
  }

  /// Validate the object
  void validate() {

  }
}

/// Protocol type: TransactionHeader
final class TransactionHeader {
  final String principal;
  final Uint8List initiator;
  final String memo;
  final Uint8List metadata;
  final ExpireOptions expire;
  final HoldUntilOptions holdUntil;
  final String authorities;

  const TransactionHeader({required this.principal, required this.initiator, required this.memo, required this.metadata, required this.expire, required this.holdUntil, required this.authorities});

  /// Create from JSON map
  factory TransactionHeader.fromJson(Map<String, dynamic> json) {
    return TransactionHeader(
    principal: json['Principal'] as String,
    initiator: CanonHelpers.base64ToUint8List(json['Initiator'] as String),
    memo: json['Memo'] as String,
    metadata: CanonHelpers.base64ToUint8List(json['Metadata'] as String),
    expire: json['Expire'] as ExpireOptions,
    holdUntil: json['HoldUntil'] as HoldUntilOptions,
    authorities: json['Authorities'] as String,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Authorities': authorities,
    'Expire': expire,
    'HoldUntil': holdUntil,
    'Initiator': CanonHelpers.uint8ListToBase64(initiator),
    'Memo': memo,
    'Metadata': CanonHelpers.uint8ListToBase64(metadata),
    'Principal': principal,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(principal, 'principal');
    Validators.validateHash32(initiator, 'initiator');
    Validators.validateUrl(authorities, 'authorities');
  }
}

/// Protocol type: TransactionStatus
final class TransactionStatus {
  final String txID;
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
    txID: json['TxID'] as String,
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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'AnchorSigners': CanonHelpers.uint8ListToBase64(anchorSigners),
    'Code': code,
    'CodeNum': codeNum,
    'Delivered': delivered,
    'DestinationNetwork': destinationNetwork,
    'Error': error,
    'Failed': failed,
    'GotDirectoryReceipt': gotDirectoryReceipt,
    'Initiator': initiator,
    'Pending': pending,
    'Proof': proof,
    'Received': received,
    'Remote': remote,
    'Result': result,
    'SequenceNumber': sequenceNumber,
    'Signers': signers,
    'SourceNetwork': sourceNetwork,
    'TxID': txID,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(initiator, 'initiator');
    Validators.validateUrl(sourceNetwork, 'sourceNetwork');
    Validators.validateUrl(destinationNetwork, 'destinationNetwork');
  }
}

