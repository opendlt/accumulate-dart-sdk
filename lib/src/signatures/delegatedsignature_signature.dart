part of 'signatures.dart';
final class DelegatedSignature extends Signature {
  final BaseSignature Signature;
  final String Delegator;

  const DelegatedSignature({
    required this.Signature,
    required this.Delegator,
  });

  @override
  String get $type => 'delegated';

  @override
  Map<String, dynamic> toJson() => {
      'type': $type,
      'Signature': Signature.toJson(),
      'Delegator': Delegator,
    };

  static DelegatedSignature fromJson(Map<String, dynamic> j, [int depth = 0]) {
    Validate.signatureDepth(depth, 5);
    final parsedSignature = BaseSignature.fromJson(j['Signature'] as Map<String, dynamic>, depth + 1);
    final instance = DelegatedSignature(
      Signature: parsedSignature,
      Delegator: j['Delegator'] as String,
    );
    return instance;
  }
  /// Get the nesting depth of this delegated signature
  int get depth => _calculateDepth(this, 0);

  /// Unwrap the delegation chain
  List<BaseSignature> unwrapChain() {
    final chain = <BaseSignature>[];
    BaseSignature current = this;
    while (current is DelegatedSignature) {
      chain.add(current);
      if (current.Signature == null) break;
      current = current.Signature!;
    }
    if (current is! DelegatedSignature) {
      chain.add(current);
    }
    return chain;
  }

  /// Flatten delegated signature to base signature
  BaseSignature? flatten() {
    BaseSignature? current = Signature;
    while (current is DelegatedSignature) {
      current = current.Signature;
    }
    return current;
  }

  static int _calculateDepth(DelegatedSignature sig, int current) {
    if (sig.Signature is DelegatedSignature) {
      return _calculateDepth(sig.Signature as DelegatedSignature, current + 1);
    }
    return current + 1;
  }


}
