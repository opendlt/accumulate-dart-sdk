// API types for generated client compatibility

class Query {
  final Map<String, dynamic> data;
  const Query(this.data);
  factory Query.fromJson(Map<String, dynamic> json) => Query(json);
  Map<String, dynamic> toJson() => data;
}

class Record {
  final Map<String, dynamic> data;
  const Record(this.data);
  factory Record.fromJson(Map<String, dynamic> json) => Record(json);
  Map<String, dynamic> toJson() => data;
}
