// GENERATED - Do not edit.
// Test path helpers for Dart SDK reorganized test tree

import 'dart:io';

/// Get the repository root directory
String repoRoot() {
  // Try to find repo root by looking for pubspec.yaml
  Directory current = Directory.current;

  while (current.path != current.parent.path) {
    final pubspec = File('${current.path}${Platform.pathSeparator}pubspec.yaml');
    if (pubspec.existsSync()) {
      return current.path;
    }

    // Also check UNIFIED subdirectory
    final unifiedPubspec = File('${current.path}${Platform.pathSeparator}UNIFIED${Platform.pathSeparator}pubspec.yaml');
    if (unifiedPubspec.existsSync()) {
      return current.path;
    }

    current = current.parent;
  }

  // Fallback: assume run from repo root
  return Directory.current.path;
}

/// Get the test root directory
String testRoot() {
  return pathJoin([repoRoot(), 'UNIFIED', 'test']);
}

/// Get the golden vectors directory
String goldenDir() {
  return pathJoin([testRoot(), 'golden']);
}

/// Get the source root directory
String sourceRoot() {
  return pathJoin([repoRoot(), 'UNIFIED', 'lib']);
}

/// Join path components using platform-specific separator
String pathJoin(List<String> parts) {
  return parts.join(Platform.pathSeparator);
}

/// Normalize path separators for current platform
String normalizePath(String path) {
  if (Platform.isWindows) {
    return path.replaceAll('/', '\\');
  } else {
    return path.replaceAll('\\', '/');
  }
}

/// Check if a file exists relative to test root
bool testFileExists(String relativePath) {
  final fullPath = pathJoin([testRoot(), relativePath]);
  return File(fullPath).existsSync();
}

/// Check if a directory exists relative to test root
bool testDirExists(String relativePath) {
  final fullPath = pathJoin([testRoot(), relativePath]);
  return Directory(fullPath).existsSync();
}

/// Get absolute path from test-relative path
String absoluteTestPath(String relativePath) {
  return pathJoin([testRoot(), relativePath]);
}

/// Get path relative to test root from absolute path
String relativeTestPath(String absolutePath) {
  final testRootPath = testRoot();
  if (absolutePath.startsWith(testRootPath)) {
    return absolutePath.substring(testRootPath.length + 1);
  }
  return absolutePath;
}

/// List all .dart files in a test subdirectory
List<String> listTestFiles(String subdir, {bool recursive = false}) {
  final dirPath = pathJoin([testRoot(), subdir]);
  final dir = Directory(dirPath);

  if (!dir.existsSync()) {
    return [];
  }

  final files = <String>[];
  final pattern = RegExp(r'\.dart$');

  if (recursive) {
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && pattern.hasMatch(entity.path)) {
        files.add(relativeTestPath(entity.path));
      }
    }
  } else {
    for (final entity in dir.listSync()) {
      if (entity is File && pattern.hasMatch(entity.path)) {
        files.add(relativeTestPath(entity.path));
      }
    }
  }

  return files..sort();
}

/// Test environment helpers
class TestEnvironment {
  static bool get isCI => Platform.environment['CI'] == 'true';
  static bool get isWindows => Platform.isWindows;
  static bool get isDebug => bool.fromEnvironment('dart.vm.product') == false;

  static String get platform {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}

/// Golden file path helpers
class GoldenPaths {
  static String vectors(String filename) => pathJoin([goldenDir(), filename]);
  static String conformance(String filename) => pathJoin([goldenDir(), 'conformance', filename]);
  static String integration(String filename) => pathJoin([goldenDir(), 'integration', filename]);
  static String errors(String filename) => pathJoin([goldenDir(), 'errors', filename]);
}