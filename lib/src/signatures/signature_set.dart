/// SignatureSet aggregate wrapper
library;

import 'dart:typed_data';
import '../runtime/bytes.dart';
import '../runtime/url.dart';
import '../enums.dart';
import 'signatures.dart';

/// SignatureSet for forwarding multiple signatures
final class SignatureSet extends Signature {
  const SignatureSet({
    this.vote,
    required this.signer,
    this.transactionHash,
    required this.signatures,
    required this.authority,
  });

  final VoteType? vote;
  final String signer;
  final Uint8List? transactionHash;
  final List<Signature> signatures;
  final String authority;

  @override
  String get $type => 'SignatureSet';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['\$type'] = $type;
      if (vote != null) json['Vote'] = vote!.toJson();
    json['Signer'] = signer;
      if (transactionHash != null) json['TransactionHash'] = ByteUtils.bytesToJson(transactionHash!);
    json['Signatures'] = signatures.map((s) => s.toJson()).toList();
    json['Authority'] = authority;
    return json;
  }

  /// Parse from JSON
  static SignatureSet? fromJson(Map<String, dynamic> json, [int depth = 0]) {
    try {
      final vote = json['Vote'] != null ? VoteType.fromJson(json['Vote']) : null;
      final signer = json['Signer'] as String;
      final transactionHash = json['TransactionHash'] != null
          ? ByteUtils.bytesFromJson(json['TransactionHash'] as String)
          : null;
      final authority = json['Authority'] as String;

      final signaturesJson = json['Signatures'] as List<dynamic>?;
      if (signaturesJson == null) return null;

      final signatures = <Signature>[];
      for (final sigJson in signaturesJson) {
        if (sigJson is Map<String, dynamic>) {
          final sig = Signature.fromJson(sigJson);
          if (sig != null) signatures.add(sig);
        }
      }

      return SignatureSet(
        vote: vote,
        signer: signer,
        transactionHash: transactionHash,
        signatures: signatures,
        authority: authority,
      );
    } catch (e) {
      return null;
    }
  }

  /// Validate signature set
  bool validate() {
    try {
      if (!AccumulateUrl.isValid(signer)) return false;
      if (!AccumulateUrl.isValid(authority)) return false;
      if (transactionHash != null && transactionHash!.isEmpty) return false;

      // Validate all contained signatures - basic check only
      for (final signature in signatures) {
        if (signature == null) return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
