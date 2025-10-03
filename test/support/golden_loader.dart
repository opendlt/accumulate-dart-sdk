import "dart:convert";
import "dart:io";
import "package:path/path.dart" as p;

class GoldenFile {
  final File file;
  GoldenFile(this.file);

  String get path => file.path;
  String readAsStringSync() => file.readAsStringSync();
  List<int> readAsBytesSync() => file.readAsBytesSync();
}

Iterable<GoldenFile> scanGolden(String rootDir) sync* {
  final root = Directory(rootDir);
  if (!root.existsSync()) return;
  for (final f in root.listSync(recursive: true)) {
    if (f is File) {
      final name = p.basename(f.path).toLowerCase();
      if (name.endsWith(".golden.json") ||
          name.endsWith(".golden.bin") ||
          name.endsWith(".tx.json") ||
          name.endsWith(".sig.json") ||
          name.endsWith(".sha256") ||
          name.endsWith(".sha256.txt") ||
          name.endsWith(".expected.json") ||
          name.endsWith(".bin")) {
        yield GoldenFile(f);
      }
    }
  }
}
