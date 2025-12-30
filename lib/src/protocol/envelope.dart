import "dart:typed_data";
import "../util/bytes.dart";

/// Vote type enum matching Go's VoteType
///
/// From Go: protocol/enums.yml
enum VoteType {
  /// Vote yea (accept)
  accept(0),

  /// Vote nay (reject)
  reject(1),

  /// Chose not to vote
  abstain(2),

  /// Put forth proposal
  suggest(3);

  const VoteType(this.value);

  final int value;

  String toJson() => "0x${value.toRadixString(16)}";

  static VoteType? fromValue(int value) {
    switch (value) {
      case 0:
        return VoteType.accept;
      case 1:
        return VoteType.reject;
      case 2:
        return VoteType.abstain;
      case 3:
        return VoteType.suggest;
      default:
        return null;
    }
  }
}

/// Transaction header structure for Accumulate v3
class TxHeader {
  final String principal;
  final int timestamp;
  final String? memo;

  const TxHeader({
    required this.principal,
    required this.timestamp,
    this.memo,
  });

  Map<String, dynamic> toJson() => {
        "principal": principal,
        "timestamp": timestamp,
        if (memo != null) "memo": memo,
      };
}

/// Signature document structure
///
/// Matches Go: protocol/signature.yml ED25519Signature
/// Fields:
/// - type: Signature type (ed25519)
/// - publicKey: Public key in hex
/// - signature: Signature in hex
/// - signer: Signer URL
/// - signerVersion: Signer version
/// - timestamp: Timestamp
/// - transactionHash: Hash of the transaction being signed (required!)
/// - vote: Optional vote (for governance)
/// - memo: Optional signature-level memo
/// - data: Optional signature-level metadata
class SignatureDoc {
  final String type;
  final String publicKey;
  final String signature;
  final int timestamp;
  final String? signer;
  final int? signerVersion;
  final String transactionHash;
  final VoteType? vote;
  final String? memo;
  final Uint8List? data;

  const SignatureDoc({
    required this.type,
    required this.publicKey,
    required this.signature,
    required this.timestamp,
    required this.transactionHash,
    this.signer,
    this.signerVersion,
    this.vote,
    this.memo,
    this.data,
  });

  Map<String, dynamic> toJson() => {
        "type": type,
        "publicKey": publicKey,
        "signature": signature,
        "signer": signer,
        if (signerVersion != null) "signerVersion": signerVersion,
        "timestamp": timestamp,
        "transactionHash": transactionHash,
        if (vote != null) "vote": vote!.toJson(),
        if (memo != null && memo!.isNotEmpty) "memo": memo,
        if (data != null && data!.isNotEmpty) "data": toHex(data!),
      };
}

/// Complete envelope structure for submission
class Envelope {
  final List<SignatureDoc> signatures;
  final Map<String, dynamic> transaction;

  const Envelope({
    required this.signatures,
    required this.transaction,
  });

  Map<String, dynamic> toJson() => {
        "envelope": {
          "signatures": signatures.map((s) => s.toJson()).toList(growable: false),
          "transaction": [transaction],
        },
      };
}
