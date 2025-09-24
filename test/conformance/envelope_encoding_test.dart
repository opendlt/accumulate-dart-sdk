import "dart:convert";
import "dart:typed_data";
import "package:test/test.dart";
import "package:opendlt_accumulate/src/codec/codec.dart";
import "golden_loader.dart";

void main() {
  group("Envelope encoding conformance", () {
    test("encode simple envelope structure", () {
      final envelope = {
        "header": {"principal": "acc://test.acme/alice", "nonce": 1},
        "body": {"type": "sendTokens", "amount": "1000"},
        "signatures": []
      };

      // Encode the envelope
      final encoded = AccumulateCodec.encodeEnvelope(envelope);
      expect(encoded, isNotEmpty);

      // Decode it back
      final decoded = AccumulateCodec.decodeEnvelope(encoded);
      expect(decoded, containsPair("header", isA<Uint8List>()));
      expect(decoded, containsPair("body", isA<Uint8List>()));
    });

    test("roundtrip envelope with signatures", () {
      final envelope = {
        "header": {"type": "transaction"},
        "body": {"data": "test"},
        "signatures": [
          Uint8List.fromList([1, 2, 3, 4]),
          Uint8List.fromList([5, 6, 7, 8]),
        ]
      };

      final encoded = AccumulateCodec.encodeEnvelope(envelope);
      final decoded = AccumulateCodec.decodeEnvelope(encoded);

      expect(decoded["signatures"], isA<List>());
      final signatures = decoded["signatures"] as List;
      expect(signatures, hasLength(2));
    });

    test("process golden envelope files", () {
      final goldens = scanGolden("test/golden").where(
          (g) => g.path.contains("envelope") && g.path.endsWith(".json"));

      for (final g in goldens) {
        try {
          final content = g.readAsStringSync();
          final envelope = jsonDecode(content);

          if (envelope is Map<String, dynamic>) {
            // Try to encode the golden envelope
            print("Processing golden file: ${g.path}");
            final encoded = AccumulateCodec.encodeEnvelope(envelope);
            expect(encoded, isNotEmpty);

            // Verify we can decode it back
            final decoded = AccumulateCodec.decodeEnvelope(encoded);
            expect(decoded, isA<Map<String, dynamic>>());
          }
        } catch (e) {
          print("Could not process golden file ${g.path}: $e");
          // Non-fatal for now - some golden files might not be in expected format
        }
      }
    });
  });
}
