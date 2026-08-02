// Marshal a corpus of transaction bodies and emit hex, for cross-SDK comparison.
import "dart:convert";
import "dart:io";
import "package:opendlt_accumulate/src/codec/binary_encoder.dart";

void main(List<String> args) {
  final cases = jsonDecode(File(args[0]).readAsStringSync()) as List;
  final out = <String, String>{};
  for (final c in cases) {
    final name = c["n"] as String;
    try {
      final bytes = TransactionBodyMarshaler.marshal(
          Map<String, dynamic>.from(c["b"] as Map));
      out[name] = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    } catch (e) {
      out[name] = "ERROR: $e";
    }
  }
  File(args[1]).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(out));
  print("dart: ${out.length} bodies marshaled");
}
