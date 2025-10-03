/// Transaction body dispatcher and utilities
library;

// Import all transaction body classes
import 'createidentity.dart';
import 'createtokenaccount.dart';
import 'sendtokens.dart';
import 'createdataaccount.dart';
import 'writedata.dart';
import 'writedatato.dart';
import 'acmefaucet.dart';
import 'createtoken.dart';
import 'issuetokens.dart';
import 'burntokens.dart';
import 'createlitetokenaccount.dart';
import 'createkeypage.dart';
import 'createkeybook.dart';
import 'addcredits.dart';
import 'burncredits.dart';
import 'transfercredits.dart';
import 'updatekeypage.dart';
import 'lockaccount.dart';
import 'updateaccountauth.dart';
import 'updatekey.dart';
import 'networkmaintenance.dart';
import 'activateprotocolversion.dart';
import 'remotetransaction.dart';
import 'syntheticcreateidentity.dart';
import 'syntheticwritedata.dart';
import 'syntheticdeposittokens.dart';
import 'syntheticdepositcredits.dart';
import 'syntheticburntokens.dart';
import 'syntheticforwardtransaction.dart';
import 'systemgenesis.dart';
import 'blockvalidatoranchor.dart';
import 'directoryanchor.dart';
import 'systemwritedata.dart';

// Import the TransactionBody from transaction.dart
import '../transaction.dart' show TransactionBody;

/// Transaction body dispatcher utility class
class TransactionBodyDispatcher {
  /// Parse transaction body from JSON with type discrimination
  static TransactionBody? fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) return null;

    switch (type) {
      case 'createidentity': return CreateIdentity.fromJson(json);
      case 'createtokenaccount': return CreateTokenAccount.fromJson(json);
      case 'sendtokens': return SendTokens.fromJson(json);
      case 'createdataaccount': return CreateDataAccount.fromJson(json);
      case 'writedata': return WriteData.fromJson(json);
      case 'writedatato': return WriteDataTo.fromJson(json);
      case 'acmefaucet': return AcmeFaucet.fromJson(json);
      case 'createtoken': return CreateToken.fromJson(json);
      case 'issuetokens': return IssueTokens.fromJson(json);
      case 'burntokens': return BurnTokens.fromJson(json);
      case 'createlitetokenaccount': return CreateLiteTokenAccount.fromJson(json);
      case 'createkeypage': return CreateKeyPage.fromJson(json);
      case 'createkeybook': return CreateKeyBook.fromJson(json);
      case 'addcredits': return AddCredits.fromJson(json);
      case 'burncredits': return BurnCredits.fromJson(json);
      case 'transfercredits': return TransferCredits.fromJson(json);
      case 'updatekeypage': return UpdateKeyPage.fromJson(json);
      case 'lockaccount': return LockAccount.fromJson(json);
      case 'updateaccountauth': return UpdateAccountAuth.fromJson(json);
      case 'updatekey': return UpdateKey.fromJson(json);
      case 'networkmaintenance': return NetworkMaintenance.fromJson(json);
      case 'activateprotocolversion': return ActivateProtocolVersion.fromJson(json);
      case 'remotetransaction': return RemoteTransaction.fromJson(json);
      case 'syntheticcreateidentity': return SyntheticCreateIdentity.fromJson(json);
      case 'syntheticwritedata': return SyntheticWriteData.fromJson(json);
      case 'syntheticdeposittokens': return SyntheticDepositTokens.fromJson(json);
      case 'syntheticdepositcredits': return SyntheticDepositCredits.fromJson(json);
      case 'syntheticburntokens': return SyntheticBurnTokens.fromJson(json);
      case 'syntheticforwardtransaction': return SyntheticForwardTransaction.fromJson(json);
      case 'systemgenesis': return SystemGenesis.fromJson(json);
      case 'blockvalidatoranchor': return BlockValidatorAnchor.fromJson(json);
      case 'directoryanchor': return DirectoryAnchor.fromJson(json);
      case 'systemwritedata': return SystemWriteData.fromJson(json);
      default: return null;
    }
  }
}