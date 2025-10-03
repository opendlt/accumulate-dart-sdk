import 'package:test/test.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  group('Runtime Helpers Tests', () {

    group('Validators Class Tests', () {
      test('validateRequired should reject null values', () {
        expect(() => Validators.validateRequired(null, 'testField'),
               throwsA(isA<ArgumentError>()));

        expect(() => Validators.validateRequired('', 'testField'),
               returnsNormally);

        expect(() => Validators.validateRequired('value', 'testField'),
               returnsNormally);

        expect(() => Validators.validateRequired(0, 'testField'),
               returnsNormally);
      });

      test('validateUrl should validate Accumulate URLs', () {
        final validUrls = [
          'acc://test.acme',
          'acc://test.acme/identity',
          'acc://test.acme/tokens/ACME',
          'acc://bvn-test.acme/data',
          'acc://dn.acme',
        ];

        for (final url in validUrls) {
          expect(() => Validators.validateUrl(url, 'testUrl'),
                 returnsNormally,
                 reason: 'URL should be valid: \$url');
        }
      });

      test('validateUrl should reject invalid URLs', () {
        final invalidUrls = [
          'http://example.com',
          'https://example.com',
          'ftp://example.com',
          'invalid-url',
          'acc:invalid', // Missing //
        ];

        for (final url in invalidUrls) {
          expect(() => Validators.validateUrl(url, 'testUrl'),
                 throwsA(isA<ArgumentError>()),
                 reason: 'URL should be invalid: \$url');
        }
      });

      test('validateUrl should handle null values', () {
        // null should not throw (for optional fields)
        expect(() => Validators.validateUrl(null, 'testUrl'),
               returnsNormally);
      });

      test('validateBigInt should validate BigInt values', () {
        final validBigInts = [
          BigInt.zero,
          BigInt.one,
          BigInt.from(1000),
          BigInt.parse('12345678901234567890'),
          BigInt.from(-1), // Negative values are allowed
        ];

        for (final bigInt in validBigInts) {
          expect(() => Validators.validateBigInt(bigInt, 'testBigInt'),
                 returnsNormally,
                 reason: 'BigInt should be valid: \$bigInt');
        }
      });

      test('validateBigInt should reject null values', () {
        expect(() => Validators.validateBigInt(null, 'testBigInt'),
               throwsA(isA<ArgumentError>()));
      });

      test('validateHash32 should validate 32-byte hashes', () {
        final validHash = Uint8List.fromList(List.generate(32, (i) => i));
        expect(() => Validators.validateHash32(validHash, 'testHash'),
               returnsNormally);

        final invalidHashes = [
          Uint8List(0),
          Uint8List.fromList([1, 2, 3]),
          Uint8List.fromList(List.generate(31, (i) => i)),
          Uint8List.fromList(List.generate(33, (i) => i)),
        ];

        for (final hash in invalidHashes) {
          expect(() => Validators.validateHash32(hash, 'testHash'),
                 throwsA(isA<ArgumentError>()),
                 reason: 'Hash should be invalid: \${hash.length} bytes');
        }
      });
    });

    group('CanonHelpers Class Tests', () {
      test('uint8ListToBase64 should encode correctly', () {
        final testData = [
          Uint8List.fromList([]),
          Uint8List.fromList([0]),
          Uint8List.fromList([1, 2, 3, 4, 5]),
          Uint8List.fromList(List.generate(32, (i) => i)),
          Uint8List.fromList(List.generate(256, (i) => i % 256)),
        ];

        for (final data in testData) {
          final encoded = CanonHelpers.uint8ListToBase64(data);
          final expected = base64Encode(data);
          expect(encoded, equals(expected),
                 reason: 'Encoding should match standard base64 for \${data.length} bytes');
        }
      });

      test('base64ToUint8List should decode correctly', () {
        final testStrings = [
          '',
          'AA==',
          'AQIDBAU=',
          base64Encode(List.generate(32, (i) => i)),
          base64Encode(List.generate(100, (i) => (i * 7) % 256)),
        ];

        for (final str in testStrings) {
          final decoded = CanonHelpers.base64ToUint8List(str);
          final expected = base64Decode(str);
          expect(decoded, equals(expected),
                 reason: 'Decoding should match standard base64 for: \$str');
        }
      });

      test('base64 round-trip should preserve data', () {
        final testData = [
          Uint8List.fromList([]),
          Uint8List.fromList([255]),
          Uint8List.fromList(List.generate(32, (i) => i)),
          Uint8List.fromList(List.generate(1000, (i) => (i * 13) % 256)),
        ];

        for (final original in testData) {
          final encoded = CanonHelpers.uint8ListToBase64(original);
          final decoded = CanonHelpers.base64ToUint8List(encoded);
          expect(decoded, equals(original),
                 reason: 'Round-trip should preserve data for \${original.length} bytes');
        }
      });

      test('bigIntToJson should convert to string', () {
        final testValues = [
          BigInt.zero,
          BigInt.one,
          BigInt.from(-1),
          BigInt.from(1234567890),
          BigInt.parse('12345678901234567890123456789012345678901234567890'),
        ];

        for (final bigInt in testValues) {
          final jsonString = CanonHelpers.bigIntToJson(bigInt);
          expect(jsonString, equals(bigInt.toString()),
                 reason: 'JSON string should match toString for: \$bigInt');
        }
      });

      test('bigIntFromJson should parse from string', () {
        final testStrings = [
          '0',
          '1',
          '-1',
          '1234567890',
          '12345678901234567890123456789012345678901234567890',
        ];

        for (final str in testStrings) {
          final bigInt = CanonHelpers.bigIntFromJson(str);
          final expected = BigInt.parse(str);
          expect(bigInt, equals(expected),
                 reason: 'Parsing should match BigInt.parse for: \$str');
        }
      });

      test('BigInt round-trip should preserve value', () {
        final testValues = [
          BigInt.zero,
          BigInt.from(-999999999),
          BigInt.parse('999999999999999999999999999999999999999999'),
          BigInt.parse('-123456789012345678901234567890'),
        ];

        for (final original in testValues) {
          final jsonString = CanonHelpers.bigIntToJson(original);
          final parsed = CanonHelpers.bigIntFromJson(jsonString);
          expect(parsed, equals(original),
                 reason: 'Round-trip should preserve value for: \$original');
        }
      });
    });

    group('CanonicalJson Class Tests', () {
      test('sortMap should sort keys alphabetically', () {
        final input = <String, dynamic>{
          'zebra': 26,
          'apple': 1,
          'banana': 2,
          'cherry': 3,
        };

        final sorted = CanonicalJson.sortMap(input);
        final keys = sorted.keys.toList();

        expect(keys, equals(['apple', 'banana', 'cherry', 'zebra']));
      });

      test('sortMap should handle nested maps recursively', () {
        final input = <String, dynamic>{
          'outer': {
            'z': 26,
            'a': 1,
            'nested': {
              'gamma': 3,
              'alpha': 1,
              'beta': 2,
            }
          },
          'simple': 'value',
        };

        final sorted = CanonicalJson.sortMap(input);
        final outerKeys = sorted.keys.toList();
        final nestedOuterKeys = (sorted['outer'] as Map<String, dynamic>).keys.toList();
        final deepNestedKeys = ((sorted['outer'] as Map<String, dynamic>)['nested'] as Map<String, dynamic>).keys.toList();

        expect(outerKeys, equals(['outer', 'simple']));
        expect(nestedOuterKeys, equals(['a', 'nested', 'z']));
        expect(deepNestedKeys, equals(['alpha', 'beta', 'gamma']));
      });

      test('sortMap should convert BigInt to string', () {
        final input = <String, dynamic>{
          'bigNumber': BigInt.parse('12345678901234567890'),
          'normalNumber': 42,
        };

        final sorted = CanonicalJson.sortMap(input);
        expect(sorted['bigNumber'], equals('12345678901234567890'));
        expect(sorted['normalNumber'], equals(42));
      });

      test('sortMap should convert Uint8List to base64', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final input = <String, dynamic>{
          'bytes': data,
          'text': 'hello',
        };

        final sorted = CanonicalJson.sortMap(input);
        expect(sorted['bytes'], equals(base64Encode(data)));
        expect(sorted['text'], equals('hello'));
      });

      test('encode should produce deterministic JSON strings', () {
        final input = {
          'b': 2,
          'a': 1,
          'nested': {
            'y': 'yes',
            'x': 'no',
          }
        };

        final json1 = CanonicalJson.encode(input);
        final json2 = CanonicalJson.encode(input);

        expect(json1, equals(json2));
        expect(json1, contains('"a":1'));
        expect(json1, contains('"b":2'));
        expect(json1.indexOf('"a"'), lessThan(json1.indexOf('"b"')));
      });

      test('should handle edge cases', () {
        final edgeCases = [
          <String, dynamic>{},
          <String, dynamic>{'single': 'value'},
          <String, dynamic>{'null_value': null},
          <String, dynamic>{'empty_string': ''},
          <String, dynamic>{'zero': 0},
          <String, dynamic>{'false': false},
        ];

        for (final testCase in edgeCases) {
          expect(() => CanonicalJson.sortMap(testCase), returnsNormally);
          expect(() => CanonicalJson.encode(testCase), returnsNormally);
        }
      });
    });

    group('Integration Tests', () {
      test('validators and helpers work together in protocol types', () {
        final hash = Uint8List.fromList(List.generate(32, (i) => i));
        final tx = CreateIdentity(
          url: 'acc://test.acme/identity',
          keyHash: hash,
          keyBookUrl: 'acc://test.acme/book',
          authorities: 'acc://test.acme/authorities'
        );

        // Validation should pass
        expect(() => tx.validate(), returnsNormally);

        // JSON serialization should work
        final json = tx.toJson();
        expect(json['KeyHash'], equals(base64Encode(hash)));

        // Round-trip should preserve data
        final reconstructed = CreateIdentity.fromJson(json);
        expect(reconstructed.keyHash, equals(hash));
        expect(() => reconstructed.validate(), returnsNormally);
      });

      test('error handling provides meaningful messages', () {
        final invalidHash = Uint8List.fromList([1, 2, 3]);

        try {
          final tx = CreateIdentity(
            url: 'invalid-url',
            keyHash: invalidHash,
            keyBookUrl: 'invalid-book-url',
            authorities: 'invalid-authorities-url'
          );
          tx.validate();
          fail('Expected validation to throw');
        } catch (e) {
          expect(e, isA<ArgumentError>());
          // Should contain field name in error message
          expect(e.toString(), isNotEmpty);
        }
      });
    });
  });
}