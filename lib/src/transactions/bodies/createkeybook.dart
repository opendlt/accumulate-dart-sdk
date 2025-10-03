import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class CreateKeyBook extends TransactionBody {
  final String Url;
  final Uint8List PublicKeyHash;
  final String? Authorities;

  const CreateKeyBook({
    required this.Url,
    required this.PublicKeyHash,
    this.Authorities,
  });

  @override
  String get $type => 'createkeybook';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'createkeybook',
    'Url': Url,
    'PublicKeyHash': ByteUtils.bytesToJson(PublicKeyHash),
    if (Authorities != null) 'Authorities': Authorities,
  };

  static CreateKeyBook fromJson(Map<String, dynamic> j) {
    return CreateKeyBook(
      Url: j['Url'] as String,
      PublicKeyHash: ByteUtils.bytesFromJson(j['PublicKeyHash'] as String),
      Authorities: j['Authorities'] as String?,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Url, 'Url');
      if (!Url.startsWith('acc://')) return false;
      Validate.required(PublicKeyHash, 'PublicKeyHash');
      if (Authorities != null && !Authorities!.startsWith('acc://')) return false;
      return true;
    } catch (e) {
      return false;
    }
  }
}
