import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class SendTokens extends TransactionBody {
  final dynamic? Hash;
  final dynamic? Meta;
  final dynamic To;

  const SendTokens({
    this.Hash,
    this.Meta,
    required this.To,
  });

  @override
  String get $type => 'sendtokens';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'sendtokens',
    if (Hash != null) 'Hash': Hash,
    if (Meta != null) 'Meta': Meta,
    'To': To,
  };

  static SendTokens fromJson(Map<String, dynamic> j) {
    return SendTokens(
      Hash: j['Hash'] as dynamic?,
      Meta: j['Meta'] as dynamic?,
      To: j['To'] as dynamic,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(To, 'To');
      if (To is String && !To.startsWith('acc://')) return false;
      return true;
    } catch (e) {
      return false;
    }
  }
}
