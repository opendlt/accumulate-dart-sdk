import 'dart:convert';
import 'dart:typed_data';
import 'bytes.dart';
import 'url.dart';
import 'enums.dart';

sealed class Signature {
  const Signature();

  String get type;
  Map<String, dynamic> toJson();

  static Signature? fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    // Add signature type dispatch here
    return null;
  }
}

final class ED25519Signature extends Signature {
  const ED25519Signature({
    required this.publicKey,
    required this.signature,
    required this.signer,
    required this.signerVersion,
  });

  final Uint8List publicKey;
  final Uint8List signature;
  final String signer;
  final int signerVersion;

  @override
  String get type => 'ED25519Signature';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'PublicKey': ByteUtils.bytesToJson(publicKey),
      'Signature': ByteUtils.bytesToJson(signature),
      'Signer': signer,
      'SignerVersion': signerVersion,
    };
  }

  static ED25519Signature? fromJson(Map<String, dynamic> json) {
    try {
      return ED25519Signature(
        publicKey: ByteUtils.bytesFromJson(json['PublicKey'] as String),
        signature: ByteUtils.bytesFromJson(json['Signature'] as String),
        signer: json['Signer'] as String,
        signerVersion: json['SignerVersion'] as int,
      );
    } catch (e) {
      return null;
    }
  }
}
