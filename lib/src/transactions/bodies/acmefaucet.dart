import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class AcmeFaucet extends TransactionBody {
  final String Url;

  const AcmeFaucet({
    required this.Url,
  });

  @override
  String get $type => 'acmefaucet';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'acmefaucet',
    'Url': Url,
  };

  static AcmeFaucet fromJson(Map<String, dynamic> j) {
    return AcmeFaucet(
      Url: j['Url'] as String,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Url, 'Url');
      if (!Url.startsWith('acc://')) return false;
      return true;
    } catch (e) {
      return false;
    }
  }
}
