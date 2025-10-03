class AccumulateUrl {
  static bool isValid(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('acc://') && url.length > 6;
  }
}
