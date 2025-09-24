// Protocol types for generated client compatibility

class AcmeFaucet {
  final Map<String, dynamic> data;
  const AcmeFaucet(this.data);
  factory AcmeFaucet.fromJson(Map<String, dynamic> json) => AcmeFaucet(json);
  Map<String, dynamic> toJson() => data;
}
