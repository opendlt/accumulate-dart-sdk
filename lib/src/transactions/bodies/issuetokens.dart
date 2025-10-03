import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class IssueTokens extends TransactionBody {
  final String Recipient;
  final BigInt Amount;
  final dynamic To;

  const IssueTokens({
    required this.Recipient,
    required this.Amount,
    required this.To,
  });

  @override
  String get $type => 'issuetokens';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'issuetokens',
    'Recipient': Recipient,
    'Amount': Amount,
    'To': To,
  };

  static IssueTokens fromJson(Map<String, dynamic> j) {
    return IssueTokens(
      Recipient: j['Recipient'] as String,
      Amount: j['Amount'] as BigInt,
      To: j['To'] as dynamic,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Recipient, 'Recipient');
      if (!Recipient.startsWith('acc://')) return false;
      Validate.required(Amount, 'Amount');
      Validate.required(To, 'To');
      return true;
    } catch (e) {
      return false;
    }
  }
}
