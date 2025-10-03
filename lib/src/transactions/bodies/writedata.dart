import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class WriteData extends TransactionBody {
  final dynamic Entry;
  final bool? Scratch;
  final bool? WriteToState;

  const WriteData({
    required this.Entry,
    this.Scratch,
    this.WriteToState,
  });

  @override
  String get $type => 'writedata';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'writedata',
    'Entry': Entry,
    if (Scratch != null) 'Scratch': Scratch,
    if (WriteToState != null) 'WriteToState': WriteToState,
  };

  static WriteData fromJson(Map<String, dynamic> j) {
    return WriteData(
      Entry: j['Entry'] as dynamic,
      Scratch: j['Scratch'] as bool?,
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
