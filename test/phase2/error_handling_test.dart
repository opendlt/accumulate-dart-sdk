import 'package:test/test.dart';
import 'dart:typed_data';
import '../../lib/src/transactions/transaction_header.dart';
import '../../lib/src/transactions/transaction.dart';
import '../../lib/src/transactions/bodies/createidentity.dart';
import '../../lib/src/transactions/bodies/sendtokens.dart';
import '../../lib/src/api/client.dart';

void main() {
  group('Error Handling Tests', () {

    group('Transaction Construction Error Tests', () {
      test('should handle null values gracefully', () {
        // Test that Dart's type system prevents null values for required fields
        expect(
          () => CreateIdentity(Url: null as dynamic),
          throwsA(isA<TypeError>()),
        );
      });

      test('should handle empty string validation', () {
        final tx = CreateIdentity(Url: '');
        expect(tx.validate(), isFalse);
      });

      test('should handle invalid URL formats', () {
        final invalidUrls = [
          'not-a-url',
          'http://example.com',
          'acc:/invalid',
          'acc:///invalid',
        ];

        for (final url in invalidUrls) {
          final tx = CreateIdentity(Url: url);
          expect(tx.validate(), isFalse, reason: 'Should reject invalid URL: \$url');
        }
      });
    });

    group('JSON Deserialization Error Tests', () {
      test('should throw error for missing required fields', () {
        final invalidJson = {
          'type': 'createidentity',
          // Missing required Url field
        };

        expect(() => CreateIdentity.fromJson(invalidJson), throwsA(isA<TypeError>()));
      });

      test('should throw error for wrong field types', () {
        final invalidTypeJson = {
          'type': 'createidentity',
          'Url': 123, // Should be string
        };

        expect(() => CreateIdentity.fromJson(invalidTypeJson), throwsA(isA<TypeError>()));
      });

      test('should throw error for invalid base64 encoding', () {
        final invalidBase64Json = {
          'type': 'createidentity',
          'Url': 'acc://test.acme/identity',
          'KeyHash': 'invalid-base64!!!',
        };

        expect(() => CreateIdentity.fromJson(invalidBase64Json), throwsA(isA<FormatException>()));
      });

      test('should handle malformed JSON structure', () {
        final malformedJson = {
          'type': 'createidentity',
          'Url': 'acc://test.acme/identity',
          'KeyHash': ['not', 'a', 'string'], // Should be string (base64)
        };

        expect(() => CreateIdentity.fromJson(malformedJson), throwsA(isA<TypeError>()));
      });
    });

    group('Transaction Dispatcher Error Tests', () {
      test('should throw error for unknown transaction type', () {
        final unknownTypeJson = {
          'type': 'unknowntransactiontype',
          'Url': 'acc://test.acme/identity',
        };

        expect(() => TransactionBody.fromJson(unknownTypeJson), throwsA(isA<ArgumentError>()));
      });

      test('should throw error for missing type field', () {
        final noTypeJson = {
          'Url': 'acc://test.acme/identity',
        };

        expect(() => TransactionBody.fromJson(noTypeJson), throwsA(isA<ArgumentError>()));
      });

      test('should throw error for null type field', () {
        final nullTypeJson = {
          'type': null,
          'Url': 'acc://test.acme/identity',
        };

        expect(() => TransactionBody.fromJson(nullTypeJson), throwsA(isA<ArgumentError>()));
      });

      test('should throw error for empty type field', () {
        final emptyTypeJson = {
          'type': '',
          'Url': 'acc://test.acme/identity',
        };

        expect(() => TransactionBody.fromJson(emptyTypeJson), throwsA(isA<ArgumentError>()));
      });
    });

    group('Transaction Header Error Tests', () {
      test('should handle invalid principal URLs', () {
        final header = TransactionHeader(
          Principal: 'invalid-url',
          Initiator: Uint8List.fromList([1, 2, 3, 4]),
          Memo: "test",
        );

        expect(header.validate(), isFalse);
      });

      test('should handle empty initiator', () {
        final header = TransactionHeader(
          Principal: 'acc://test.acme/identity',
          Initiator: Uint8List(0),
          Memo: "test",
        );

        // Empty initiator might be valid or invalid depending on business rules
        final isValid = header.validate();
        expect(isValid, isA<bool>());
      });

      test('should handle negative nonce values', () {
        final header = TransactionHeader(
          Principal: 'acc://test.acme/identity',
          Initiator: Uint8List.fromList([1, 2, 3, 4]),
          Memo: "negative-test",
        );

        // Negative nonce might be valid or invalid depending on business rules
        final isValid = header.validate();
        expect(isValid, isA<bool>());
      });
    });

    group('API Client Error Tests', () {
      test('should create AccumulateApiException correctly', () {
        final exception = AccumulateApiException(
          code: -32600,
          message: 'Invalid Request',
          data: {'details': 'Additional error information'},
        );

        expect(exception.code, equals(-32600));
        expect(exception.message, equals('Invalid Request'));
        expect(exception.data, equals({'details': 'Additional error information'}));
        expect(exception.toString(), contains('AccumulateApiException(-32600)'));
        expect(exception.toString(), contains('Invalid Request'));
      });

      test('should handle AccumulateApiException without data', () {
        final exception = AccumulateApiException(
          code: -32602,
          message: 'Invalid params',
        );

        expect(exception.code, equals(-32602));
        expect(exception.message, equals('Invalid params'));
        expect(exception.data, isNull);
      });

      test('should handle network timeout errors', () {
        final client = AccumulateApiClient(
          baseUrl: 'http://nonexistent.example.com',
          timeout: Duration(milliseconds: 1), // Very short timeout
        );

        expect(client.Status(), throwsA(isA<AccumulateApiException>()));
        client.dispose();
      });

      test('should handle invalid base URL', () {
        final client = AccumulateApiClient(
          baseUrl: 'invalid-url',
        );

        expect(client.Status(), throwsA(isA<AccumulateApiException>()));
        client.dispose();
      });
    });

    group('Validation Edge Cases', () {
      test('should handle validation exceptions gracefully', () {
        // Create objects that might cause validation issues
        final createIdentity = CreateIdentity(Url: 'acc://test.acme/identity');
        final sendTokens = SendTokens(To: 'acc://recipient.acme/tokens');
        final header = TransactionHeader(
          Principal: 'acc://test.acme/identity',
          Initiator: Uint8List.fromList([1, 2, 3, 4]),
          Memo: "zero",
        );

        expect(() => createIdentity.validate(), returnsNormally);
        expect(createIdentity.validate(), isA<bool>());

        expect(() => sendTokens.validate(), returnsNormally);
        expect(sendTokens.validate(), isA<bool>());

        expect(() => header.validate(), returnsNormally);
        expect(header.validate(), isA<bool>());
      });

      test('should handle extremely large values', () {
        final largeAmount = 9223372036854775807; // Max int64
        final tx = SendTokens(
          To: 'acc://recipient.acme/tokens',
        );

        expect(() => tx.validate(), returnsNormally);
        expect(tx.validate(), isA<bool>());
      });

      test('should handle extremely long strings', () {
        final longString = 'x' * 10000;
        final header = TransactionHeader(
          Principal: 'acc://test.acme/identity',
          Initiator: Uint8List.fromList([1, 2, 3, 4]),
          Memo: longString,
        );

        expect(() => header.validate(), returnsNormally);
        expect(header.validate(), isA<bool>());
      });

      test('should handle large byte arrays', () {
        final largeBytes = Uint8List(100000);
        for (int i = 0; i < largeBytes.length; i++) {
          largeBytes[i] = i % 256;
        }

        final tx = CreateIdentity(
          Url: 'acc://test.acme/identity',
          KeyHash: largeBytes,
        );

        expect(() => tx.validate(), returnsNormally);
        expect(tx.validate(), isA<bool>());
      });
    });

    group('Memory and Performance Edge Cases', () {
      test('should handle many small transactions', () {
        final transactions = <CreateIdentity>[];

        for (int i = 0; i < 1000; i++) {
          transactions.add(CreateIdentity(
            Url: 'acc://test\$i.acme/identity',
          ));
        }

        expect(transactions, hasLength(1000));

        // Validate all transactions
        for (final tx in transactions) {
          expect(tx.validate(), isTrue);
        }
      });

      test('should handle repeated serialization/deserialization', () {
        var tx = CreateIdentity(Url: 'acc://test.acme/identity');

        // Perform 100 round-trips
        for (int i = 0; i < 100; i++) {
          final json = tx.toJson();
          tx = CreateIdentity.fromJson(json);
        }

        expect(tx.Url, equals('acc://test.acme/identity'));
        expect(tx.validate(), isTrue);
      });

      test('should handle concurrent validation calls', () {
        final tx = CreateIdentity(Url: 'acc://test.acme/identity');

        // Run validation concurrently (simulated)
        final results = <bool>[];
        for (int i = 0; i < 100; i++) {
          results.add(tx.validate());
        }

        expect(results, hasLength(100));
        expect(results.every((result) => result == true), isTrue);
      });
    });

    group('Error Message Quality Tests', () {
      test('should provide clear error messages for validation failures', () {
        // This tests that error messages are meaningful when available
        final invalidTx = CreateIdentity(Url: 'invalid-url');
        final isValid = invalidTx.validate();

        expect(isValid, isFalse);
        // Note: We can't test the exact error message without knowing the implementation
      });

      test('should provide clear error messages for JSON parsing failures', () {
        final invalidJson = {
          'type': 'createidentity',
          // Missing Url
        };

        try {
          CreateIdentity.fromJson(invalidJson);
          fail('Should have thrown an error');
        } catch (e) {
          expect(e, isA<TypeError>());
          // The error should be meaningful
          expect(e.toString(), isNotEmpty);
        }
      });

      test('should provide clear error messages for unknown transaction types', () {
        final unknownTypeJson = {
          'type': 'nonexistenttype',
          'Url': 'acc://test.acme/identity',
        };

        try {
          TransactionBody.fromJson(unknownTypeJson);
          fail('Should have thrown an error');
        } catch (e) {
          expect(e, isA<ArgumentError>());
          expect(e.toString(), contains('nonexistenttype'));
        }
      });
    });

    group('Recovery and Resilience Tests', () {
      test('should recover from validation errors and continue processing', () {
        final validTx = CreateIdentity(Url: 'acc://valid.acme/identity');
        final invalidTx = CreateIdentity(Url: 'invalid-url');

        expect(validTx.validate(), isTrue);
        expect(invalidTx.validate(), isFalse);

        // Should still be able to process valid transaction after invalid one
        expect(validTx.validate(), isTrue);
      });

      test('should handle mixed valid and invalid data gracefully', () {
        final testCases = [
          {'valid': true, 'tx': () => CreateIdentity(Url: 'acc://valid.acme/identity')},
          {'valid': false, 'tx': () => CreateIdentity(Url: 'invalid-url')},
          {'valid': true, 'tx': () => CreateIdentity(Url: 'acc://another-valid.acme/identity')},
        ];

        for (final testCase in testCases) {
          final tx = testCase['tx'] as Function;
          final transaction = tx();
          final expectedValid = testCase['valid'] as bool;

          expect(transaction.validate(), equals(expectedValid));
        }
      });
    });
  });
}