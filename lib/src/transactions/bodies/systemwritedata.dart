import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class SystemWriteData extends TransactionBody {
  final dynamic Entry;
  final bool? WriteToState;

  const SystemWriteData({
    required this.Entry,
    this.WriteToState,
  });

  @override
  String get $type => 'systemwritedata';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'systemwritedata',
    'Entry': Entry,
    if (WriteToState != null) 'WriteToState': WriteToState,
  };

  static SystemWriteData fromJson(Map<String, dynamic> j) {
    return SystemWriteData(
      Entry: j['Entry'] as dynamic,
      WriteToState: j['WriteToState'] as bool?,
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
