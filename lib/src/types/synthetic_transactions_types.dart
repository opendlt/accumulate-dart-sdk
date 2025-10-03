// GENERATED — Do not edit.
// Protocol types from synthetic_transactions.yml

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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Amount': amount.toString(),
    'IsRefund': isRefund,
    };
  }

  /// Validate the object
  void validate() {
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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Accounts': accounts,
    };
  }

  /// Validate the object
  void validate() {

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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'AcmeRefundAmount': acmeRefundAmount.toString(),
    'Amount': amount,
    'IsRefund': isRefund,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateBigInt(acmeRefundAmount, 'acmeRefundAmount');
  }
}

/// Protocol type: SyntheticDepositTokens
final class SyntheticDepositTokens {
  final String token;
  final BigInt amount;
  final bool isIssuer;
  final bool isRefund;

  const SyntheticDepositTokens({required this.token, required this.amount, required this.isIssuer, required this.isRefund});

  /// Create from JSON map
  factory SyntheticDepositTokens.fromJson(Map<String, dynamic> json) {
    return SyntheticDepositTokens(
    token: json['Token'] as String,
    amount: BigInt.parse(json['Amount'] as String),
    isIssuer: json['IsIssuer'] as bool,
    isRefund: json['IsRefund'] as bool,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Amount': amount.toString(),
    'IsIssuer': isIssuer,
    'IsRefund': isRefund,
    'Token': token,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(token, 'token');
    Validators.validateBigInt(amount, 'amount');
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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Signatures': signatures,
    'Transaction': transaction,
    };
  }

  /// Validate the object
  void validate() {

  }
}

/// Protocol type: SyntheticOrigin
final class SyntheticOrigin {
  final String cause;
  final String source;
  final String initiator;
  final int feeRefund;
  final int index;

  const SyntheticOrigin({required this.cause, required this.source, required this.initiator, required this.feeRefund, required this.index});

  /// Create from JSON map
  factory SyntheticOrigin.fromJson(Map<String, dynamic> json) {
    return SyntheticOrigin(
    cause: json['Cause'] as String,
    source: json['Source'] as String,
    initiator: json['Initiator'] as String,
    feeRefund: json['FeeRefund'] as int,
    index: json['Index'] as int,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Cause': cause,
    'FeeRefund': feeRefund,
    'Index': index,
    'Initiator': initiator,
    'Source': source,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(source, 'source');
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

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Entry': entry,
    };
  }

  /// Validate the object
  void validate() {

  }
}

