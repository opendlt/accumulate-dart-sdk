import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class SyntheticWriteData extends TransactionBody {
  final dynamic Entry;

  const SyntheticWriteData({
    required this.Entry,
  });

  @override
  String get $type => 'syntheticwritedata';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'syntheticwritedata',
    'Entry': Entry,
  };

  static SyntheticWriteData fromJson(Map<String, dynamic> j) {
    return SyntheticWriteData(
      Entry: j['Entry'] as dynamic,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Entry, 'Entry');
      return true;
    } catch (e) {
      return false;
    }
  }
}
