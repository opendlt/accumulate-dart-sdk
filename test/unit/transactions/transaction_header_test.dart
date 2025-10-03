import 'package:test/test.dart';
import 'dart:typed_data';
import 'package:opendlt_accumulate/src/transactions/transaction_header.dart';

void main() {
  group('TransactionHeader Tests', () {

    test('should create TransactionHeader with all required fields', () {
      final header = TransactionHeader(
        Principal: 'acc://test.acme/identity',
        Initiator: Uint8List.fromList([1, 2, 3, 4]),
        Memo: 'test memo',
      );

      expect(header.Principal, equals('acc://test.acme/identity'));
      expect(header.Initiator, equals(Uint8List.fromList([1, 2, 3, 4])));
      expect(header.Memo, equals('test memo'));
    });

    test('should serialize to JSON correctly', () {
      final header = TransactionHeader(
        Principal: 'acc://test.acme/identity',
        Initiator: Uint8List.fromList([1, 2, 3, 4]),
        Memo: 'test memo',
      );

      final json = header.toJson();

      expect(json['Principal'], equals('acc://test.acme/identity'));
      expect(json['Initiator'], equals(Uint8List.fromList([1, 2, 3, 4])));
      expect(json['Memo'], equals('test memo'));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'Principal': 'acc://test.acme/identity',
        'Initiator': Uint8List.fromList([1, 2, 3, 4]),
        'Memo': 'test memo',
      };

      final header = TransactionHeader.fromJson(json);

      expect(header.Principal, equals('acc://test.acme/identity'));
      expect(header.Initiator, equals(Uint8List.fromList([1, 2, 3, 4])));
      expect(header.Memo, equals('test memo'));
    });

    test('should validate correctly with valid data', () {
      final header = TransactionHeader(
        Principal: 'acc://test.acme/identity',
        Initiator: Uint8List.fromList([1, 2, 3, 4]),
        Memo: 'test memo',
      );

      expect(header.validate(), isTrue);
    });

    test('should fail validation with invalid principal URL', () {
      final header = TransactionHeader(
        Principal: 'invalid://url',
        Initiator: Uint8List.fromList([1, 2, 3, 4]),
        Memo: 'test memo',
      );

      expect(header.validate(), isFalse);
    });

    test('should handle round-trip JSON serialization', () {
      final original = TransactionHeader(
        Principal: 'acc://test.acme/identity',
        Initiator: Uint8List.fromList([1, 2, 3, 4, 5]),
        Memo: 'round trip test',
      );

      final json = original.toJson();
      final reconstructed = TransactionHeader.fromJson(json);

      expect(reconstructed.Principal, equals(original.Principal));
      expect(reconstructed.Initiator, equals(original.Initiator));
      expect(reconstructed.Memo, equals(original.Memo));
      expect(reconstructed.validate(), equals(original.validate()));
    });

    test('should handle optional fields correctly', () {
      // Test with minimal required fields
      final minimalJson = {
        'Principal': 'acc://test.acme/identity',
        'Initiator': Uint8List.fromList([1, 2, 3, 4]),
      };

      final header = TransactionHeader.fromJson(minimalJson);
      expect(header.Principal, equals('acc://test.acme/identity'));

      final backToJson = header.toJson();
      expect(backToJson.containsKey('Principal'), isTrue);
    });

    test('should handle empty memo field', () {
      final header = TransactionHeader(
        Principal: 'acc://test.acme/identity',
        Initiator: Uint8List.fromList([1, 2, 3, 4]),
        Memo: '',
      );

      expect(header.validate(), isTrue);
      final json = header.toJson();
      final reconstructed = TransactionHeader.fromJson(json);
      expect(reconstructed.Memo, equals(''));
    });

    test('should handle metadata field', () {
      final metadata = Uint8List.fromList([10, 20, 30, 40]);
      final header = TransactionHeader(
        Principal: 'acc://test.acme/identity',
        Initiator: Uint8List.fromList([1, 2, 3, 4]),
        Metadata: metadata,
      );

      expect(header.Metadata, equals(metadata));
      expect(header.validate(), isTrue);
    });

    test('should handle authorities field', () {
      final header = TransactionHeader(
        Principal: 'acc://test.acme/identity',
        Initiator: Uint8List.fromList([1, 2, 3, 4]),
        Authorities: 'acc://test.acme/auth',
      );

      expect(header.Authorities, equals('acc://test.acme/auth'));
      expect(header.validate(), isTrue);
    });
  });
}