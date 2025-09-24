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
class SignatureDoc {
  final String type;
  final String publicKey;
  final String signature;
  final int timestamp;
  final String? signer;

  const SignatureDoc({
    required this.type,
    required this.publicKey,
    required this.signature,
    required this.timestamp,
    this.signer,
  });

  Map<String, dynamic> toJson() => {
        "type": type,
        "publicKey": publicKey,
        "signature": signature,
        "timestamp": timestamp,
        if (signer != null) "signer": signer,
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
          "signatures":
              signatures.map((s) => s.toJson()).toList(growable: false),
          "transaction": transaction,
        },
      };
}
