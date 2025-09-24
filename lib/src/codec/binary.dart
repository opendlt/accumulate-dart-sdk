import "dart:typed_data";

/// NOTE: This is a placeholder. Implement to exactly match Go's canonical encoding
/// used by Accumulate for transactions, signatures, and types (pkg/types & pkg/build).
/// Add unit tests that compare bytes & hashes to golden vectors under test/golden/.
class AccumulateBinaryCodec {
  /// Encode a structured value (map/record) into canonical bytes.
  /// TODO: Implement to match Go encoder semantics and field ordering.
  static Uint8List encode(dynamic value) {
    // Implement per Accumulate canonical binary (NOT JSON) if applicable.
    // For now, fail loudly so missing implementation is visible in tests.
    throw UnimplementedError("AccumulateBinaryCodec.encode not implemented");
  }

  /// Decode canonical bytes back into a structured value.
  /// TODO: Implement to match Go decoder semantics.
  static dynamic decode(Uint8List bytes) {
    throw UnimplementedError("AccumulateBinaryCodec.decode not implemented");
  }
}
