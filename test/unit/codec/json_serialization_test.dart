import 'package:test/test.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:opendlt_accumulate/src/transactions/transaction_header.dart';
import 'package:opendlt_accumulate/src/transactions/transaction.dart';
import 'package:opendlt_accumulate/src/transactions/bodies/createidentity.dart';
import 'package:opendlt_accumulate/src/transactions/bodies/sendtokens.dart';
import 'package:opendlt_accumulate/src/transactions/bodies/writedata.dart';
import 'package:opendlt_accumulate/src/transactions/bodies/createtoken.dart';
import 'package:opendlt_accumulate/src/transactions/bodies/addcredits.dart';

void main() {
  group('JSON Serialization Tests', () {

    group('Transaction Header JSON Tests', () {
      test('should serialize header to valid JSON', () {
        final header = TransactionHeader(
          Principal: 'acc://test.acme/identity',
          Initiator: Uint8List.fromList([1, 2, 3, 4]),
          Memo: 'test memo',
        );

        final json = header.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['Principal'], equals('acc://test.acme/identity'));
        expect(json['Initiator'], isA<dynamic>()); // Should be dynamic type
        expect(json['Memo'], equals('test memo'));
      });

      test('should deserialize header from JSON correctly', () {
        final json = {
          'Principal': 'acc://test.acme/identity',
          'Initiator': 'AQIDBA==', // base64 for [1,2,3,4]
          'Memo': 'test memo',
        };

        final header = TransactionHeader.fromJson(json);

        expect(header.Principal, equals('acc://test.acme/identity'));
        expect(header.Initiator, equals('AQIDBA==')); // Initiator is stored as dynamic (base64 string)
        expect(header.Memo, equals('test memo'));
      });

      test('should handle round-trip serialization for header', () {
        final original = TransactionHeader(
          Principal: 'acc://test.acme/identity',
          Initiator: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
          Memo: 'round trip test',
        );

        final json = original.toJson();
        final reconstructed = TransactionHeader.fromJson(json);

        expect(reconstructed.Principal, equals(original.Principal));
        expect(reconstructed.Initiator, equals(original.Initiator));
        expect(reconstructed.Memo, equals(original.Memo));
      });
    });

    group('Transaction Body JSON Tests', () {
      test('should serialize CreateIdentity to valid JSON', () {
        final tx = CreateIdentity(
          Url: 'acc://test.acme/identity',
          KeyHash: Uint8List.fromList([1, 2, 3, 4]),
          KeyBookUrl: 'acc://test.acme/book',
        );

        final json = tx.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['type'], equals('createidentity'));
        expect(json['Url'], equals('acc://test.acme/identity'));
        expect(json['KeyHash'], isA<String>()); // Should be base64 encoded
        expect(json['KeyBookUrl'], equals('acc://test.acme/book'));
      });

      test('should serialize SendTokens to valid JSON', () {
        final tx = SendTokens(
          To: 'acc://recipient.acme/tokens', // Single string, not array
          Hash: Uint8List.fromList([1, 2, 3, 4]),
        );

        final json = tx.toJson();

        expect(json['type'], equals('sendtokens'));
        expect(json['To'], equals('acc://recipient.acme/tokens'));
        expect(json['Hash'], isA<dynamic>());
      });

      test('should handle optional fields in JSON serialization', () {
        final txWithOptional = CreateIdentity(
          Url: 'acc://test.acme/identity',
          KeyHash: Uint8List.fromList([1, 2, 3, 4]),
        );

        final txWithoutOptional = CreateIdentity(
          Url: 'acc://test.acme/identity',
        );

        final jsonWith = txWithOptional.toJson();
        final jsonWithout = txWithoutOptional.toJson();

        expect(jsonWith.containsKey('KeyHash'), isTrue);
        expect(jsonWithout.containsKey('KeyHash'), isFalse);
        expect(jsonWith['Url'], equals(jsonWithout['Url']));
      });
    });

    group('Complete Transaction JSON Tests', () {
      test('should serialize complete transaction to JSON', () {
        final transaction = Transaction(
          header: TransactionHeader(
            Principal: 'acc://test.acme/identity',
            Initiator: Uint8List.fromList([1, 2, 3, 4]),
            Memo: 'complete transaction test',
          ),
          body: CreateIdentity(
            Url: 'acc://test.acme/new-identity',
            KeyHash: Uint8List.fromList([5, 6, 7, 8]),
          ),
        );

        final json = transaction.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['Principal'], equals('acc://test.acme/identity'));
        expect(json['Memo'], equals('complete transaction test'));
        expect(json['body'], isA<Map<String, dynamic>>());
        expect(json['body']['type'], equals('createidentity'));
        expect(json['body']['Url'], equals('acc://test.acme/new-identity'));
      });

      test('should deserialize complete transaction from JSON', () {
        final json = {
          'Principal': 'acc://test.acme/identity',
          'Initiator': 'AQIDBA==',
          'Memo': 'deserialization test',
          'body': {
            'type': 'sendtokens',
            'To': 'acc://recipient.acme/tokens', // Single string
          },
        };

        final transaction = Transaction.fromJson(json);

        expect(transaction.header.Principal, equals('acc://test.acme/identity'));
        expect(transaction.body.$type, equals('sendtokens'));

        final sendTokens = transaction.body as SendTokens;
        expect(sendTokens.To, equals('acc://recipient.acme/tokens'));
      });
    });

    group('Base64 Encoding/Decoding Tests', () {
      test('should correctly encode byte arrays to base64', () {
        final bytes = Uint8List.fromList([1, 2, 3, 4, 255, 0, 128]);
        final tx = CreateIdentity(
          Url: 'acc://test.acme/identity',
          KeyHash: bytes,
        );

        final json = tx.toJson();
        final keyHashBase64 = json['KeyHash'] as String;

        // Verify we can decode it back
        final decoded = base64.decode(keyHashBase64);
        expect(decoded, equals(bytes));
      });

      test('should correctly decode base64 to byte arrays', () {
        final base64String = base64.encode([1, 2, 3, 4, 255, 0, 128]);
        final json = {
          'type': 'createidentity',
          'Url': 'acc://test.acme/identity',
          'KeyHash': base64String,
        };

        final tx = CreateIdentity.fromJson(json);
        expect(tx.KeyHash, equals(Uint8List.fromList([1, 2, 3, 4, 255, 0, 128])));
      });

      test('should handle empty byte arrays', () {
        final tx = CreateIdentity(
          Url: 'acc://test.acme/identity',
          KeyHash: Uint8List(0),
        );

        final json = tx.toJson();
        final reconstructed = CreateIdentity.fromJson(json);

        expect(reconstructed.KeyHash, equals(Uint8List(0)));
      });
    });

    group('Complex Data Structure JSON Tests', () {
      test('should handle simple To field correctly', () {
        final tx = SendTokens(
          To: 'acc://recipient.acme/tokens', // Single string
        );

        final json = tx.toJson();
        final reconstructed = SendTokens.fromJson(json);

        expect(reconstructed.To, equals(tx.To));
      });

      test('should handle maps and objects correctly', () {
        final tx = CreateToken(
          Url: 'acc://test.acme/token',
          Symbol: 'TEST',
          Precision: 8,
          Properties: 'acc://test.acme/properties',
        );

        final json = tx.toJson();
        final reconstructed = CreateToken.fromJson(json);

        expect(reconstructed.Symbol, equals(tx.Symbol));
        expect(reconstructed.Precision, equals(tx.Precision));
        expect(reconstructed.Properties, equals(tx.Properties));
      });
    });

    group('JSON Compliance Tests', () {
      test('should produce valid JSON strings', () {
        final transactions = [
          Transaction(
            header: TransactionHeader(
              Principal: 'acc://test.acme/identity',
              Initiator: Uint8List.fromList([1, 2, 3, 4]),
            ),
            body: CreateIdentity(Url: 'acc://test.acme/identity'),
          ),
          Transaction(
            header: TransactionHeader(
              Principal: 'acc://test.acme/identity',
              Initiator: Uint8List.fromList([1, 2, 3, 4]),
            ),
            body: SendTokens(To: 'acc://recipient.acme/tokens'),
          ),
        ];

        for (final tx in transactions) {
          final json = tx.toJson();
          final jsonString = jsonEncode(json);

          expect(jsonString, isA<String>());
          expect(jsonString.isNotEmpty, isTrue);

          // Verify we can parse it back
          final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
          expect(parsed, isA<Map<String, dynamic>>());
        }
      });

      test('should handle special characters in JSON', () {
        final specialMemos = [
          'Test with "quotes"',
          'Test with \\backslashes\\',
          'Test with\nnewlines',
          'Test with\ttabs',
          'Test with / slashes',
        ];

        for (final memo in specialMemos) {
          final header = TransactionHeader(
            Principal: 'acc://test.acme/identity',
            Initiator: Uint8List.fromList([1, 2, 3, 4]),
            Memo: memo,
          );

          final json = header.toJson();
          final jsonString = jsonEncode(json);
          final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
          final reconstructed = TransactionHeader.fromJson(parsed);

          expect(reconstructed.Memo, equals(memo));
        }
      });
    });

    group('Large Data JSON Tests', () {
      test('should handle large byte arrays', () {
        final largeBytes = Uint8List(1024);
        for (int i = 0; i < largeBytes.length; i++) {
          largeBytes[i] = i % 256;
        }

        final tx = CreateIdentity(
          Url: 'acc://test.acme/identity',
          KeyHash: largeBytes,
        );

        final json = tx.toJson();
        final reconstructed = CreateIdentity.fromJson(json);

        expect(reconstructed.KeyHash, equals(largeBytes));
      });

      test('should handle To field correctly', () {
        final tx = SendTokens(
          To: 'acc://recipient.acme/tokens', // Single string
        );

        final json = tx.toJson();
        final reconstructed = SendTokens.fromJson(json);

        expect(reconstructed.To, equals('acc://recipient.acme/tokens'));
      });
    });

    group('Error Handling in JSON Tests', () {
      test('should handle malformed JSON gracefully', () {
        final malformedJson = {
          'type': 'createidentity',
          // Missing required Url field
          'KeyHash': 'AQIDBA==',
        };

        expect(() => CreateIdentity.fromJson(malformedJson), throwsA(isA<TypeError>()));
      });

      test('should handle invalid base64 gracefully', () {
        final invalidBase64Json = {
          'type': 'createidentity',
          'Url': 'acc://test.acme/identity',
          'KeyHash': 'invalid-base64!!!',
        };

        expect(() => CreateIdentity.fromJson(invalidBase64Json), throwsA(isA<FormatException>()));
      });

      test('should handle type mismatches gracefully', () {
        final typeMismatchJson = {
          'type': 'createidentity',
          'Url': 'acc://test.acme/identity',
          'KeyHash': 12345, // Should be string (base64)
        };

        expect(() => CreateIdentity.fromJson(typeMismatchJson), throwsA(isA<TypeError>()));
      });
    });
  });
}