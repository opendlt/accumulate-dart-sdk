import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class WriteDataTo extends TransactionBody {
  final String Recipient;
  final dynamic Entry;

  const WriteDataTo({
    required this.Recipient,
    required this.Entry,
  });

  @override
  String get $type => 'writedatato';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'writedatato',
    'Recipient': Recipient,
    'Entry': Entry,
  };

  static WriteDataTo fromJson(Map<String, dynamic> j) {
    return WriteDataTo(
      Recipient: j['Recipient'] as String,
      Entry: j['Entry'] as dynamic,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Recipient, 'Recipient');
      if (!Recipient.startsWith('acc://')) return false;
      Validate.required(Entry, 'Entry');
      return true;
    } catch (e) {
      return false;
    }
  }
}
