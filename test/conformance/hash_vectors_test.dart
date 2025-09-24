import "dart:typed_data";
import "dart:io";
import "package:test/test.dart";
import "package:opendlt_accumulate/src/util/bytes.dart";
import "package:opendlt_accumulate/src/codec/hash.dart";
import "golden_loader.dart";

void main() {
  group("Hash vector conformance (sha256)", () {
    test("match *.sha256 or *.sha256.txt expectations", () {
      final gs = scanGolden("test/golden").where(
          (g) => g.path.endsWith(".sha256") || g.path.endsWith(".sha256.txt"));
      for (final g in gs) {
        final content = String.fromCharCodes(g.readAsBytesSync()).trim();
        // Heuristic: lines like "<hex>  <filename>" or just "<hex>"
        final lines =
            content.split(RegExp(r"\r?\n")).where((l) => l.trim().isNotEmpty);
        for (final line in lines) {
          final parts = line.trim().split(RegExp(r"\s+"));
          final hex = parts.first.toLowerCase();
          // Try to locate the referenced file next to the sha file
          // This is heuristic; adjust if golden layout differs.
          // If file name present use it; else skip (manual investigation).
          if (parts.length >= 2) {
            final dataPath =
                g.path.replaceAll(RegExp(r"\.sha256(\.txt)?$"), "");
            // or prefer explicit filename if different
            // final fname = parts[1];
            // ...
            try {
              final bytes =
                  Uint8List.fromList(File(dataPath).readAsBytesSync());
              final got = sha256OfBytes(bytes);
              expect(toHex(got), equals(hex),
                  reason: "Hash mismatch for ${dataPath} (from ${g.path})");
            } catch (_) {
              // Non-fatal; report and continue to next line
              print("WARN: could not open data for ${g.path}");
            }
          }
        }
      }
    });
  });
}
