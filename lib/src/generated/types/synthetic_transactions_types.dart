// GENERATED — Do not edit.
// Protocol types from synthetic_transactions.yml

import 'dart:typed_data';

import '../../enums.dart' show HashAlgorithm;
import '../runtime/canon_helpers.dart';
import '../runtime/validators.dart';

/// Protocol type: SyntheticBurnTokens
final class SyntheticBurnTokens {
  final BigInt amount;
  final bool isRefund;

  const SyntheticBurnTokens({required this.amount, required this.isRefund});

  /// Create from JSON map
  factory SyntheticBurnTokens.fromJson(Map<String, dynamic> json) {
    return SyntheticBurnTokens(
    amount: BigInt.parse(json['Amount'] as String),
    isRefund: json['IsRefund'] as bool,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Amount': CanonHelpers.bigIntToJson(amount),
    'IsRefund': isRefund,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(amount, 'amount');
    Validators.validateBigInt(amount, 'amount');
  }
}


/// Protocol type: SyntheticCreateIdentity
final class SyntheticCreateIdentity {
  final dynamic accounts;

  const SyntheticCreateIdentity({required this.accounts});

  /// Create from JSON map
  factory SyntheticCreateIdentity.fromJson(Map<String, dynamic> json) {
    return SyntheticCreateIdentity(
    accounts: json['Accounts'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Accounts': accounts,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(accounts, 'accounts');
  }
}


/// Protocol type: SyntheticDepositCredits
final class SyntheticDepositCredits {
  final int amount;
  final BigInt acmeRefundAmount;
  final bool isRefund;

  const SyntheticDepositCredits({required this.amount, required this.acmeRefundAmount, required this.isRefund});

  /// Create from JSON map
  factory SyntheticDepositCredits.fromJson(Map<String, dynamic> json) {
    return SyntheticDepositCredits(
    amount: json['Amount'] as int,
    acmeRefundAmount: BigInt.parse(json['AcmeRefundAmount'] as String),
    isRefund: json['IsRefund'] as bool,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Amount': amount,
    'AcmeRefundAmount': CanonHelpers.bigIntToJson(acmeRefundAmount),
    'IsRefund': isRefund,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(acmeRefundAmount, 'acmeRefundAmount');
    Validators.validateBigInt(acmeRefundAmount, 'acmeRefundAmount');
  }
}


/// Protocol type: SyntheticDepositTokens
final class SyntheticDepositTokens {
  final String token;
  final BigInt amount;
  final dynamic isIssuer;
  final bool isRefund;

  const SyntheticDepositTokens({required this.token, required this.amount, required this.isIssuer, required this.isRefund});

  /// Create from JSON map
  factory SyntheticDepositTokens.fromJson(Map<String, dynamic> json) {
    return SyntheticDepositTokens(
    token: json['Token'] as String,
    amount: BigInt.parse(json['Amount'] as String),
    isIssuer: json['IsIssuer'] as dynamic,
    isRefund: json['IsRefund'] as bool,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Token': token,
    'Amount': CanonHelpers.bigIntToJson(amount),
    'IsIssuer': isIssuer,
    'IsRefund': isRefund,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(token, 'token');
    Validators.validateUrl(token, 'token');
    Validators.validateRequired(amount, 'amount');
    Validators.validateBigInt(amount, 'amount');
    Validators.validateRequired(isIssuer, 'isIssuer');
  }
}


/// Protocol type: SyntheticLockedDeposit (type 0x37, Accumulate 1.4.6.7)
/// Embeds SyntheticOrigin (cause, initiator, feeRefund, index). JSON uses hex for hash (as Go does).
final class SyntheticLockedDeposit {
  final String cause;
  final String initiator;
  final int feeRefund;
  final int index;
  final String token;
  final BigInt amount;
  final String sender;
  final HashAlgorithm hashAlgorithm;
  final Uint8List hash;
  final String? expiration;
  final bool isIssuer;

  const SyntheticLockedDeposit({required this.cause, required this.initiator, this.feeRefund = 0, this.index = 0, required this.token, required this.amount, required this.sender, required this.hashAlgorithm, required this.hash, this.expiration, this.isIssuer = false});

  /// Create from JSON map
  factory SyntheticLockedDeposit.fromJson(Map<String, dynamic> json) {
    final h = json['Hash'] ?? json['hash'];
    return SyntheticLockedDeposit(
    cause: (json['Cause'] ?? json['cause']) as String,
    initiator: (json['Initiator'] ?? json['initiator']) as String,
    feeRefund: ((json['FeeRefund'] ?? json['feeRefund']) as num?)?.toInt() ?? 0,
    index: ((json['Index'] ?? json['index']) as num?)?.toInt() ?? 0,
    token: (json['Token'] ?? json['token']) as String,
    amount: BigInt.parse((json['Amount'] ?? json['amount']).toString()),
    sender: (json['Sender'] ?? json['sender']) as String,
    hashAlgorithm: HashAlgorithm.fromJson((json['HashAlgorithm'] ?? json['hashAlgorithm']) as Object),
    hash: h is Uint8List ? h : Uint8List.fromList(List<int>.generate((h as String).length ~/ 2, (i) => int.parse(h.substring(i * 2, i * 2 + 2), radix: 16))),
    expiration: (json['Expiration'] ?? json['expiration']) as String?,
    isIssuer: ((json['IsIssuer'] ?? json['isIssuer']) as bool?) ?? false,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Cause': cause,
    'Initiator': initiator,
    if (feeRefund != 0) 'FeeRefund': feeRefund,
    if (index != 0) 'Index': index,
    'Token': token,
    'Amount': CanonHelpers.bigIntToJson(amount),
    'Sender': sender,
    'HashAlgorithm': hashAlgorithm.toJson(),
    'Hash': hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    if (expiration != null) 'Expiration': expiration,
    if (isIssuer) 'IsIssuer': isIssuer,
    };
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(cause, 'cause');
    Validators.validateRequired(token, 'token');
    Validators.validateUrl(token, 'token');
    Validators.validateRequired(amount, 'amount');
    Validators.validateBigInt(amount, 'amount');
    Validators.validateRequired(sender, 'sender');
    Validators.validateUrl(sender, 'sender');
    Validators.validateRequired(hash, 'hash');
  }
}


/// Protocol type: SyntheticForwardTransaction
final class SyntheticForwardTransaction {
  final dynamic signatures;
  final dynamic transaction;

  const SyntheticForwardTransaction({required this.signatures, required this.transaction});

  /// Create from JSON map
  factory SyntheticForwardTransaction.fromJson(Map<String, dynamic> json) {
    return SyntheticForwardTransaction(
    signatures: json['Signatures'] as dynamic,
    transaction: json['Transaction'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Signatures': signatures,
    'Transaction': transaction,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(signatures, 'signatures');
    Validators.validateRequired(transaction, 'transaction');
  }
}


/// Protocol type: SyntheticOrigin
final class SyntheticOrigin {
  final dynamic cause;
  final String source;
  final String initiator;
  final int feeRefund;
  final int index;

  const SyntheticOrigin({required this.cause, required this.source, required this.initiator, required this.feeRefund, required this.index});

  /// Create from JSON map
  factory SyntheticOrigin.fromJson(Map<String, dynamic> json) {
    return SyntheticOrigin(
    cause: json['Cause'] as dynamic,
    source: json['Source'] as String,
    initiator: json['Initiator'] as String,
    feeRefund: json['FeeRefund'] as int,
    index: json['Index'] as int,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Cause': cause,
    'Source': source,
    'Initiator': initiator,
    'FeeRefund': feeRefund,
    'Index': index,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(cause, 'cause');
    Validators.validateRequired(source, 'source');
    Validators.validateUrl(source, 'source');
    Validators.validateRequired(initiator, 'initiator');
    Validators.validateUrl(initiator, 'initiator');
  }
}


/// Protocol type: SyntheticWriteData
final class SyntheticWriteData {
  final dynamic entry;

  const SyntheticWriteData({required this.entry});

  /// Create from JSON map
  factory SyntheticWriteData.fromJson(Map<String, dynamic> json) {
    return SyntheticWriteData(
    entry: json['Entry'] as dynamic,
    );
  }

  /// Convert to canonical JSON map with sorted keys
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{    'Entry': entry,
    }; 
    return CanonicalJson.sortMap(map);
  }

  /// Validate the object
  void validate() {
    Validators.validateRequired(entry, 'entry');
  }
}


