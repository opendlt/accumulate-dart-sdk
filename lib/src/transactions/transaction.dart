import 'dart:typed_data';
import 'transaction_header.dart';
import 'bodies/createidentity.dart';
import 'bodies/createtokenaccount.dart';
import 'bodies/sendtokens.dart';
import 'bodies/createdataaccount.dart';
import 'bodies/writedata.dart';
import 'bodies/writedatato.dart';
import 'bodies/acmefaucet.dart';
import 'bodies/createtoken.dart';
import 'bodies/issuetokens.dart';
import 'bodies/burntokens.dart';
import 'bodies/createlitetokenaccount.dart';
import 'bodies/createkeypage.dart';
import 'bodies/createkeybook.dart';
import 'bodies/addcredits.dart';
import 'bodies/updatekeypage.dart';
import 'bodies/lockaccount.dart';
import 'bodies/burncredits.dart';
import 'bodies/transfercredits.dart';
import 'bodies/updateaccountauth.dart';
import 'bodies/updatekey.dart';
import 'bodies/networkmaintenance.dart';
import 'bodies/activateprotocolversion.dart';
import 'bodies/remotetransaction.dart';
import 'bodies/syntheticcreateidentity.dart';
import 'bodies/syntheticwritedata.dart';
import 'bodies/syntheticdeposittokens.dart';
import 'bodies/syntheticdepositcredits.dart';
import 'bodies/syntheticburntokens.dart';
import 'bodies/syntheticforwardtransaction.dart';
import 'bodies/systemgenesis.dart';
import 'bodies/directoryanchor.dart';
import 'bodies/blockvalidatoranchor.dart';
import 'bodies/systemwritedata.dart';

abstract class TransactionBody {
  const TransactionBody();

  String get $type;
  Map<String, dynamic> toJson();
  bool validate();

  static TransactionBody fromJson(Map<String, dynamic> j) {
    final type = j['type'] as String?;
    if (type == null) {
      throw ArgumentError('Transaction body missing type discriminant');
    }

    switch (type) {
      case 'createidentity': return CreateIdentity.fromJson(j);
      case 'createtokenaccount': return CreateTokenAccount.fromJson(j);
      case 'sendtokens': return SendTokens.fromJson(j);
      case 'createdataaccount': return CreateDataAccount.fromJson(j);
      case 'writedata': return WriteData.fromJson(j);
      case 'writedatato': return WriteDataTo.fromJson(j);
      case 'acmefaucet': return AcmeFaucet.fromJson(j);
      case 'createtoken': return CreateToken.fromJson(j);
      case 'issuetokens': return IssueTokens.fromJson(j);
      case 'burntokens': return BurnTokens.fromJson(j);
      case 'createlitetokenaccount': return CreateLiteTokenAccount.fromJson(j);
      case 'createkeypage': return CreateKeyPage.fromJson(j);
      case 'createkeybook': return CreateKeyBook.fromJson(j);
      case 'addcredits': return AddCredits.fromJson(j);
      case 'updatekeypage': return UpdateKeyPage.fromJson(j);
      case 'lockaccount': return LockAccount.fromJson(j);
      case 'burncredits': return BurnCredits.fromJson(j);
      case 'transfercredits': return TransferCredits.fromJson(j);
      case 'updateaccountauth': return UpdateAccountAuth.fromJson(j);
      case 'updatekey': return UpdateKey.fromJson(j);
      case 'networkmaintenance': return NetworkMaintenance.fromJson(j);
      case 'activateprotocolversion': return ActivateProtocolVersion.fromJson(j);
      case 'remotetransaction': return RemoteTransaction.fromJson(j);
      case 'syntheticcreateidentity': return SyntheticCreateIdentity.fromJson(j);
      case 'syntheticwritedata': return SyntheticWriteData.fromJson(j);
      case 'syntheticdeposittokens': return SyntheticDepositTokens.fromJson(j);
      case 'syntheticdepositcredits': return SyntheticDepositCredits.fromJson(j);
      case 'syntheticburntokens': return SyntheticBurnTokens.fromJson(j);
      case 'syntheticforwardtransaction': return SyntheticForwardTransaction.fromJson(j);
      case 'systemgenesis': return SystemGenesis.fromJson(j);
      case 'directoryanchor': return DirectoryAnchor.fromJson(j);
      case 'blockvalidatoranchor': return BlockValidatorAnchor.fromJson(j);
      case 'systemwritedata': return SystemWriteData.fromJson(j);
      default:
        throw ArgumentError('Unknown transaction type: $type');
    }
  }
}

class Transaction {
  final TransactionHeader header;
  final TransactionBody body;

  const Transaction({
    required this.header,
    required this.body,
  });

  Map<String, dynamic> toJson() => {
    ...header.toJson(),
    'body': body.toJson(),
  };

  static Transaction fromJson(Map<String, dynamic> j) {
    final bodyJson = j['body'] as Map<String, dynamic>?;
    if (bodyJson == null) {
      throw ArgumentError('Transaction missing body');
    }

    return Transaction(
      header: TransactionHeader.fromJson(j),
      body: TransactionBody.fromJson(bodyJson),
    );
  }

  bool validate() {
    return header.validate() && body.validate();
  }
}
