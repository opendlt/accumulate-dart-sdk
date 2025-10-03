import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class BlockValidatorAnchor extends TransactionBody {
  final BigInt AcmeBurnt;

  const BlockValidatorAnchor({
    required this.AcmeBurnt,
  });

  @override
  String get $type => 'blockvalidatoranchor';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'blockvalidatoranchor',
    'AcmeBurnt': AcmeBurnt,
  };

  static BlockValidatorAnchor fromJson(Map<String, dynamic> j) {
    return BlockValidatorAnchor(
      AcmeBurnt: j['AcmeBurnt'] as BigInt,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(AcmeBurnt, 'AcmeBurnt');
      return true;
    } catch (e) {
      return false;
    }
  }
}
