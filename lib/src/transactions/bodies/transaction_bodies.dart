/// Base transaction body classes and JSON dispatcher
library;

import 'dart:convert';
import 'dart:typed_data';
import '../runtime/canonical_json.dart';
import '../runtime/bytes.dart';
import '../runtime/url.dart';
import '../enums.dart';

/// Base sealed class for all transaction bodies
sealed class TransactionBody {
  const TransactionBody();

  /// Transaction type discriminant
  String get $type;

  /// Convert to JSON representation
  Map<String, dynamic> toJson();

  /// Parse transaction body from JSON with type discrimination
  static TransactionBody? fromJson(Map<String, dynamic> json) {
    final type = json['\$type'] as String?;
    if (type == null) return null;

    switch (type) {
      case 'CreateIdentity': return CreateIdentity.fromJson(json);
      case 'CreateTokenAccount': return CreateTokenAccount.fromJson(json);
      case 'SendTokens': return SendTokens.fromJson(json);
      case 'CreateDataAccount': return CreateDataAccount.fromJson(json);
      case 'WriteData': return WriteData.fromJson(json);
      case 'WriteDataTo': return WriteDataTo.fromJson(json);
      case 'AcmeFaucet': return AcmeFaucet.fromJson(json);
      case 'CreateToken': return CreateToken.fromJson(json);
      case 'IssueTokens': return IssueTokens.fromJson(json);
      case 'BurnTokens': return BurnTokens.fromJson(json);
      case 'CreateLiteTokenAccount': return CreateLiteTokenAccount.fromJson(json);
      case 'CreateKeyPage': return CreateKeyPage.fromJson(json);
      case 'CreateKeyBook': return CreateKeyBook.fromJson(json);
      case 'AddCredits': return AddCredits.fromJson(json);
      case 'BurnCredits': return BurnCredits.fromJson(json);
      case 'TransferCredits': return TransferCredits.fromJson(json);
      case 'UpdateKeyPage': return UpdateKeyPage.fromJson(json);
      case 'LockAccount': return LockAccount.fromJson(json);
      case 'UpdateAccountAuth': return UpdateAccountAuth.fromJson(json);
      case 'UpdateKey': return UpdateKey.fromJson(json);
      case 'NetworkMaintenance': return NetworkMaintenance.fromJson(json);
      case 'ActivateProtocolVersion': return ActivateProtocolVersion.fromJson(json);
      case 'RemoteTransaction': return RemoteTransaction.fromJson(json);
      case 'SyntheticCreateIdentity': return SyntheticCreateIdentity.fromJson(json);
      case 'SyntheticWriteData': return SyntheticWriteData.fromJson(json);
      case 'SyntheticDepositTokens': return SyntheticDepositTokens.fromJson(json);
      case 'SyntheticDepositCredits': return SyntheticDepositCredits.fromJson(json);
      case 'SyntheticBurnTokens': return SyntheticBurnTokens.fromJson(json);
      case 'SyntheticForwardTransaction': return SyntheticForwardTransaction.fromJson(json);
      case 'SystemGenesis': return SystemGenesis.fromJson(json);
      case 'BlockValidatorAnchor': return BlockValidatorAnchor.fromJson(json);
      case 'DirectoryAnchor': return DirectoryAnchor.fromJson(json);
      case 'SystemWriteData': return SystemWriteData.fromJson(json);
      default: return null;
    }
  }
}
