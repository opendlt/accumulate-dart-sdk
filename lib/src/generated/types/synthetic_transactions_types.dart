// GENERATED — Do not edit.
// Protocol types from synthetic_transactions.yml

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


