class AccUrl {
  final String value;
  AccUrl._(this.value);

  static AccUrl parse(String s) {
    if (!s.startsWith("acc://")) {
      throw FormatException("Invalid Accumulate URL", s);
    }
    return AccUrl._(s);
  }

  @override
  String toString() => value;
}
