import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class UpdateKey extends TransactionBody {
  final Uint8List NewKeyHash;

  const UpdateKey({
    required this.NewKeyHash,
  });

  @override
  String get $type => 'updatekey';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'updatekey',
    'NewKeyHash': ByteUtils.bytesToJson(NewKeyHash),
  };

  static UpdateKey fromJson(Map<String, dynamic> j) {
    return UpdateKey(
      NewKeyHash: ByteUtils.bytesFromJson(j['NewKeyHash'] as String),
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(NewKeyHash, 'NewKeyHash');
      return true;
    } catch (e) {
      return false;
    }
  }
}
