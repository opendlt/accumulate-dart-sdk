library url;

class AccumulateUrl {
  /// Validate Accumulate URL format
  static bool isValid(String? url) {
    if (url == null || url.isEmpty) return false;

    // Must start with 'acc://'
    if (!url.startsWith('acc://')) return false;

    // Must have content after 'acc://'
    if (url.length <= 6) return false;

    // Extract the part after 'acc://'
    final path = url.substring(6);

    // Must not be empty after 'acc://'
    if (path.isEmpty) return false;

    // Must not start with '/' (would indicate 'acc:///...')
    if (path.startsWith('/')) return false;

    // Must contain at least one character and valid URL characters
    // Basic validation for common URL characters
    final validUrlPattern = RegExp(r'^[a-zA-Z0-9._/-]+$');
    if (!validUrlPattern.hasMatch(path)) return false;

    return true;
  }

  /// Validate and require Accumulate URL
  static void validateRequired(String? url, String fieldName) {
    if (url == null || url.isEmpty) {
      throw ArgumentError('$fieldName is required');
    }
    if (!isValid(url)) {
      throw ArgumentError('$fieldName must be a valid Accumulate URL (acc://...)');
    }
  }

  /// Validate optional Accumulate URL
  static void validateOptional(String? url, String fieldName) {
    if (url != null && !isValid(url)) {
      throw ArgumentError('$fieldName must be a valid Accumulate URL (acc://...)');
    }
  }
}
