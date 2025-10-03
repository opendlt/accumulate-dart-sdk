import 'package:test/test.dart';
import 'dart:typed_data';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

void main() {
  group('Error Handling Tests', () {

    group('Transaction Construction Error Tests', () {
      test('should handle invalid URL formats', () {
        final invalidUrls = [
          'not-a-url',
          'http://example.com',
          'acc:/invalid',
          '', // Empty string should be rejected
        ];

        for (final url in invalidUrls) {
          final tx = CreateIdentity(
            url: url,
            keyHash: Uint8List(32),
            keyBookUrl: 'acc://test.acme/book',
            authorities: 'acc://test.acme/book',
          );
          expect(() => tx.validate(), throwsA(isA<ArgumentError>()), reason: 'Should reject invalid URL: $url');
        }
      });

      test('should handle invalid keyBookUrl formats', () {
        final tx = CreateIdentity(
          url: 'acc://test.acme/identity',
          keyHash: Uint8List(32),
          keyBookUrl: 'invalid-url',
          authorities: 'acc://test.acme/book',
        );
        expect(() => tx.validate(), throwsA(isA<ArgumentError>()));
      });

      test('should handle invalid authorities formats', () {
        final tx = CreateIdentity(
          url: 'acc://test.acme/identity',
          keyHash: Uint8List(32),
          keyBookUrl: 'acc://test.acme/book',
          authorities: 'invalid-url',
        );
        expect(() => tx.validate(), throwsA(isA<ArgumentError>()));
      });
    });

    group('JSON Deserialization Error Tests', () {
      test('should throw error for missing required fields', () {
        final invalidJson = <String, dynamic>{
          // Missing required fields
        };

        expect(() => CreateIdentity.fromJson(invalidJson), throwsA(isA<TypeError>()));
      });

      test('should throw error for wrong field types', () {
        final invalidTypeJson = <String, dynamic>{
          'Url': 123, // Should be string
          'KeyHash': 'valid-base64-here',
          'KeyBookUrl': 'acc://test.acme/book',
          'Authorities': 'acc://test.acme/book',
        };

        expect(() => CreateIdentity.fromJson(invalidTypeJson), throwsA(isA<TypeError>()));
      });

      test('should throw error for invalid base64 encoding', () {
        final invalidBase64Json = <String, dynamic>{
          'Url': 'acc://test.acme/identity',
          'KeyHash': 'invalid-base64!!!',
          'KeyBookUrl': 'acc://test.acme/book',
          'Authorities': 'acc://test.acme/book',
        };

        expect(() => CreateIdentity.fromJson(invalidBase64Json), throwsA(isA<FormatException>()));
      });
    });

    group('SendTokens Validation Tests', () {
      test('should handle invalid hash size', () {
        final tx = SendTokens(
          hash: Uint8List(16), // Should be 32 bytes
          meta: {},
          to: {},
        );
        expect(() => tx.validate(), throwsA(isA<ArgumentError>()));
      });

      test('should accept valid hash size', () {
        final tx = SendTokens(
          hash: Uint8List(32), // Correct size
          meta: {},
          to: {},
        );
        expect(() => tx.validate(), returnsNormally);
      });
    });

    group('BurnTokens Validation Tests', () {
      test('should validate BigInt amounts', () {
        final tx = BurnTokens(amount: BigInt.from(1000));
        expect(() => tx.validate(), returnsNormally);
      });
    });

    group('URL Validation Edge Cases', () {
      test('should reject empty URLs', () {
        final tx = CreateTokenAccount(
          url: '',
          tokenUrl: 'acc://token.acme/ACME',
          authorities: 'acc://auth.acme/book',
          proof: {},
        );
        expect(() => tx.validate(), throwsA(isA<ArgumentError>()));
      });

      test('should reject malformed acc:// URLs', () {
        final invalidUrls = [
          'acc:/',
          'not-acc://test.acme/token',
        ];

        for (final url in invalidUrls) {
          final tx = CreateTokenAccount(
            url: url,
            tokenUrl: 'acc://token.acme/ACME',
            authorities: 'acc://auth.acme/book',
            proof: {},
          );
          expect(() => tx.validate(), throwsA(isA<ArgumentError>()), reason: 'Should reject URL: $url');
        }
      });

      test('should accept valid acc:// URLs', () {
        final validUrls = [
          'acc://test.acme/token',
          'acc://sub.domain.acme/account',
          'acc://a.b.c.d.acme/xyz',
        ];

        for (final url in validUrls) {
          final tx = CreateTokenAccount(
            url: url,
            tokenUrl: 'acc://token.acme/ACME',
            authorities: 'acc://auth.acme/book',
            proof: {},
          );
          expect(() => tx.validate(), returnsNormally, reason: 'Should accept URL: $url');
        }
      });
    });

    group('Type Safety Tests', () {
      test('should handle dynamic field validation', () {
        // Test classes with dynamic fields don't crash
        final origin = SyntheticOrigin(
          cause: 'acc://cause.acme/tx',
          source: 'acc://source.acme/partition',
          initiator: 'acc://init.acme/identity',
          feeRefund: 0,
          index: 1,
        );
        expect(() => origin.validate(), returnsNormally);
      });

      test('should handle empty dynamic objects', () {
        final tx = SyntheticCreateIdentity(accounts: {});
        expect(() => tx.validate(), returnsNormally);
      });
    });

    group('BigInt Validation Tests', () {
      test('should validate required BigInt fields', () {
        final tx = SyntheticBurnTokens(
          amount: BigInt.from(1000),
          isRefund: false,
        );
        expect(() => tx.validate(), returnsNormally);
      });

      test('should validate BigInt in DepositCredits', () {
        final tx = SyntheticDepositCredits(
          amount: 100,
          acmeRefundAmount: BigInt.from(50),
          isRefund: false,
        );
        expect(() => tx.validate(), returnsNormally);
      });
    });

    group('Serialization Round-trip Tests', () {
      test('should handle CreateIdentity round-trip', () {
        final original = CreateIdentity(
          url: 'acc://test.acme/identity',
          keyHash: Uint8List.fromList(List.generate(32, (i) => i)),
          keyBookUrl: 'acc://test.acme/book',
          authorities: 'acc://test.acme/auth',
        );

        final json = original.toJson();
        final restored = CreateIdentity.fromJson(json);

        expect(restored.url, equals(original.url));
        expect(restored.keyBookUrl, equals(original.keyBookUrl));
        expect(restored.authorities, equals(original.authorities));
        expect(restored.keyHash, equals(original.keyHash));
      });

      test('should handle SendTokens round-trip', () {
        final original = SendTokens(
          hash: Uint8List.fromList(List.generate(32, (i) => i)),
          meta: {'test': 'data'},
          to: {'recipient': 'acc://target.acme/tokens'},
        );

        final json = original.toJson();
        final restored = SendTokens.fromJson(json);

        expect(restored.hash, equals(original.hash));
        expect(restored.meta, equals(original.meta));
        expect(restored.to, equals(original.to));
      });
    });
  });
}