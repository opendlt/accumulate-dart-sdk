import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class NetworkMaintenance extends TransactionBody {
  final dynamic Operations;

  const NetworkMaintenance({
    required this.Operations,
  });

  @override
  String get $type => 'networkmaintenance';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'networkmaintenance',
    'Operations': Operations,
  };

  static NetworkMaintenance fromJson(Map<String, dynamic> j) {
    return NetworkMaintenance(
      Operations: j['Operations'] as dynamic,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Operations, 'Operations');
      return true;
    } catch (e) {
      return false;
    }
  }
}
