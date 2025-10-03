import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class CreateIdentity extends TransactionBody {
  final String Url;
  final Uint8List? KeyHash;
  final String? KeyBookUrl;
  final String? Authorities;

  const CreateIdentity({
    required this.Url,
    this.KeyHash,
    this.KeyBookUrl,
    this.Authorities,
  });

  @override
  String get $type => 'createidentity';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'createidentity',
    'Url': Url,
    if (KeyHash != null) 'KeyHash': ByteUtils.bytesToJson(KeyHash!),
    if (KeyBookUrl != null) 'KeyBookUrl': KeyBookUrl,
    if (Authorities != null) 'Authorities': Authorities,
  };

  static CreateIdentity fromJson(Map<String, dynamic> j) {
    return CreateIdentity(
      Url: j['Url'] as String,
      KeyHash: j['KeyHash'] != null ? ByteUtils.bytesFromJson(j['KeyHash'] as String) : null,
      KeyBookUrl: j['KeyBookUrl'] as String?,
      Authorities: j['Authorities'] as String?,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Url, 'Url');
      if (!Url.startsWith('acc://')) return false;
      if (KeyBookUrl != null && !KeyBookUrl!.startsWith('acc://')) return false;
      if (Authorities != null && !Authorities!.startsWith('acc://')) return false;
      return true;
    } catch (e) {
      return false;
    }
  }
}
