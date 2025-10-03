import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class TransferCredits extends TransactionBody {
  final dynamic To;

  const TransferCredits({
    required this.To,
  });

  @override
  String get $type => 'transfercredits';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'transfercredits',
    'To': To,
  };

  static TransferCredits fromJson(Map<String, dynamic> j) {
    return TransferCredits(
      To: j['To'] as dynamic,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(To, 'To');
      return true;
    } catch (e) {
      return false;
    }
  }
}
