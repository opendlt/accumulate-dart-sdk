part of 'signatures.dart';
final class RemoteSignature extends Signature {
  final String Destination;
  final BaseSignature Signature;
  final Uint8List Cause;

  const RemoteSignature({
    required this.Destination,
    required this.Signature,
    required this.Cause,
  });

  @override
  String get $type => 'remote';

  @override
  Map<String, dynamic> toJson() => {
      'type': $type,
      'Destination': Destination,
      'Signature': Signature.toJson(),
      'Cause': ByteUtils.bytesToJson(Cause),
    };

  static RemoteSignature fromJson(Map<String, dynamic> j, [int depth = 0]) {
    final parsedSignature = BaseSignature.fromJson(j['Signature'] as Map<String, dynamic>, depth + 1);
    final instance = RemoteSignature(
      Destination: j['Destination'] as String,
      Signature: parsedSignature,
      Cause: (() { final bytes = ByteUtils.bytesFromJson(j['Cause'] as String); ByteUtils.validateLength(bytes, 32, 'Cause'); return bytes; })(),
    );
    return instance;
  }

}
