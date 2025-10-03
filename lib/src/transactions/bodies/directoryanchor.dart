import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class DirectoryAnchor extends TransactionBody {
  final dynamic Updates;
  final dynamic Receipts;
  final int MakeMajorBlock;
  final int MakeMajorBlockTime;

  const DirectoryAnchor({
    required this.Updates,
    required this.Receipts,
    required this.MakeMajorBlock,
    required this.MakeMajorBlockTime,
  });

  @override
  String get $type => 'directoryanchor';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'directoryanchor',
    'Updates': Updates,
    'Receipts': Receipts,
    'MakeMajorBlock': MakeMajorBlock,
    'MakeMajorBlockTime': MakeMajorBlockTime,
  };

  static DirectoryAnchor fromJson(Map<String, dynamic> j) {
    return DirectoryAnchor(
      Updates: j['Updates'] as dynamic,
      Receipts: j['Receipts'] as dynamic,
      MakeMajorBlock: j['MakeMajorBlock'] as int,
      MakeMajorBlockTime: j['MakeMajorBlockTime'] as int,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Updates, 'Updates');
      Validate.required(Receipts, 'Receipts');
      Validate.required(MakeMajorBlock, 'MakeMajorBlock');
      Validate.required(MakeMajorBlockTime, 'MakeMajorBlockTime');
      return true;
    } catch (e) {
      return false;
    }
  }
}
