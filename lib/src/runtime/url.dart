library url;

class AccumulateUrl {
  /// Validate Accumulate URL format
  static bool isValid(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('acc://') && url.length > 6;
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
