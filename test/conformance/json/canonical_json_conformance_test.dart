import 'package:test/test.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  group('Canonical JSON Conformance Tests', () {

    group('CanonicalJson Basic Functionality', () {
      test('should sort keys deterministically', () {
        final unsortedMap = <String, dynamic>{
          'z': 26,
          'a': 1,
          'b': 2,
          'm': 13,
        };

        final sorted = CanonicalJson.sortMap(unsortedMap);
        final keys = sorted.keys.toList();

        expect(keys, equals(['a', 'b', 'm', 'z']));
        expect(sorted['a'], equals(1));
        expect(sorted['z'], equals(26));
      });

      test('should handle nested maps', () {
        final nestedMap = <String, dynamic>{
          'outer': {
            'z': 3,
            'a': 1,
            'b': 2,
          },
          'simple': 'value',
        };

        final sorted = CanonicalJson.sortMap(nestedMap);
        final outerKeys = sorted.keys.toList();
        final innerKeys = (sorted['outer'] as Map<String, dynamic>).keys.toList();

        expect(outerKeys, equals(['outer', 'simple']));
        expect(innerKeys, equals(['a', 'b', 'z']));
      });

      test('should encode BigInt to string', () {
        final bigIntMap = <String, dynamic>{
          'bigNumber': BigInt.parse('12345678901234567890'),
          'normalNumber': 42,
        };

        final sorted = CanonicalJson.sortMap(bigIntMap);
        expect(sorted['bigNumber'], equals('12345678901234567890'));
        expect(sorted['normalNumber'], equals(42));
      });

      test('should encode Uint8List to base64', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final dataMap = <String, dynamic>{
          'bytes': data,
          'text': 'hello',
        };

        final sorted = CanonicalJson.sortMap(dataMap);
        expect(sorted['bytes'], equals(base64Encode(data)));
        expect(sorted['text'], equals('hello'));
      });
    });

    group('Protocol Types JSON Serialization', () {
      test('ADI toJson produces canonical output', () {
        final adi = ADI(url: 'acc://test.acme', auth: 'some-auth');
        final json = adi.toJson();

        // Should have sorted keys
        final keys = json.keys.toList();
        expect(keys, equals(['AccountAuth', 'Url']));

        // Should be JSON-serializable
        final jsonString = jsonEncode(json);
        expect(jsonString, contains('"AccountAuth":"some-auth"'));
        expect(jsonString, contains('"Url":"acc://test.acme"'));
      });

      test('LiteTokenAccount toJson handles BigInt correctly', () {
        final account = LiteTokenAccount(
          url: 'acc://user.acme',
          tokenUrl: 'acc://test.acme/tokens',
          balance: BigInt.parse('123456789012345678901234567890'),
          lockHeight: 100
        );

        final json = account.toJson();

        // BigInt should be converted to string
        expect(json['Balance'], equals('123456789012345678901234567890'));
        expect(json['LockHeight'], equals(100));

        // Keys should be sorted
        final keys = json.keys.toList();
        expect(keys, equals(['Balance', 'LockHeight', 'TokenUrl', 'Url']));
      });

      test('CreateIdentity toJson handles Uint8List correctly', () {
        final hash = Uint8List.fromList(List.generate(32, (i) => i));
        final tx = CreateIdentity(
          url: 'acc://test.acme/identity',
          keyHash: hash,
          keyBookUrl: 'acc://test.acme/book',
          authorities: 'acc://test.acme/authorities'
        );

        final json = tx.toJson();

        // Uint8List should be base64 encoded
        expect(json['KeyHash'], equals(base64Encode(hash)));

        // Keys should be sorted
        final keys = json.keys.toList();
        expect(keys, equals(['Authorities', 'KeyBookUrl', 'KeyHash', 'Url']));
      });

      test('SystemGenesis empty type produces canonical output', () {
        final genesis = SystemGenesis();
        final json = genesis.toJson();

        // Empty object should still use canonical JSON
        expect(json, isEmpty);

        // Should be valid JSON
        final jsonString = jsonEncode(json);
        expect(jsonString, equals('{}'));
      });

      test('CreateLiteTokenAccount empty type produces canonical output', () {
        final tx = CreateLiteTokenAccount();
        final json = tx.toJson();

        // Empty object should still use canonical JSON
        expect(json, isEmpty);

        // Should be valid JSON
        final jsonString = jsonEncode(json);
        expect(jsonString, equals('{}'));
      });
    });

    group('JSON Round-trip Consistency', () {
      test('ADI round-trip maintains data integrity', () {
        final original = ADI(url: 'acc://test.acme', auth: 'test-auth');
        final json = original.toJson();
        final reconstructed = ADI.fromJson(json);

        expect(reconstructed.url, equals(original.url));
        expect(reconstructed.auth, equals(original.auth));
      });

      test('LiteTokenAccount round-trip with BigInt', () {
        final original = LiteTokenAccount(
          url: 'acc://user.acme',
          tokenUrl: 'acc://test.acme/tokens',
          balance: BigInt.parse('999999999999999999999999999999'),
          lockHeight: 12345
        );

        final json = original.toJson();
        final reconstructed = LiteTokenAccount.fromJson(json);

        expect(reconstructed.url, equals(original.url));
        expect(reconstructed.tokenUrl, equals(original.tokenUrl));
        expect(reconstructed.balance, equals(original.balance));
        expect(reconstructed.lockHeight, equals(original.lockHeight));
      });

      test('CreateIdentity round-trip with Uint8List', () {
        final hash = Uint8List.fromList(List.generate(32, (i) => i * 2));
        final original = CreateIdentity(
          url: 'acc://test.acme/identity',
          keyHash: hash,
          keyBookUrl: 'acc://test.acme/book',
          authorities: 'acc://test.acme/authorities'
        );

        final json = original.toJson();
        final reconstructed = CreateIdentity.fromJson(json);

        expect(reconstructed.url, equals(original.url));
        expect(reconstructed.keyHash, equals(original.keyHash));
        expect(reconstructed.keyBookUrl, equals(original.keyBookUrl));
        expect(reconstructed.authorities, equals(original.authorities));
      });
    });

    group('Deterministic Output', () {
      test('same object produces identical JSON every time', () {
        final adi = ADI(url: 'acc://test.acme', auth: 'auth-data');

        final json1 = jsonEncode(adi.toJson());
        final json2 = jsonEncode(adi.toJson());
        final json3 = jsonEncode(adi.toJson());

        expect(json1, equals(json2));
        expect(json2, equals(json3));
      });

      test('equivalent objects produce identical JSON', () {
        final adi1 = ADI(url: 'acc://test.acme', auth: 'auth-data');
        final adi2 = ADI(url: 'acc://test.acme', auth: 'auth-data');

        final json1 = jsonEncode(adi1.toJson());
        final json2 = jsonEncode(adi2.toJson());

        expect(json1, equals(json2));
      });

      test('objects with different field order produce identical JSON', () {
        // This test verifies that field declaration order doesn't affect JSON output
        final account1 = LiteTokenAccount(
          url: 'acc://user.acme',
          tokenUrl: 'acc://test.acme/tokens',
          balance: BigInt.from(1000),
          lockHeight: 100
        );

        final account2 = LiteTokenAccount(
          lockHeight: 100,
          balance: BigInt.from(1000),
          tokenUrl: 'acc://test.acme/tokens',
          url: 'acc://user.acme'
        );

        final json1 = jsonEncode(account1.toJson());
        final json2 = jsonEncode(account2.toJson());

        expect(json1, equals(json2));
      });
    });

    group('Complex Nested Structures', () {
      test('should handle complex nested objects', () {
        // Test with TransactionStatus which has many fields
        final status = TransactionStatus(
          txID: 'test-tx-id',
          code: 'success',
          remote: false,
          delivered: true,
          pending: false,
          failed: false,
          codeNum: 200,
          error: null,
          result: null,
          received: 1234567890,
          initiator: 'acc://test.acme/identity',
          signers: null,
          sourceNetwork: 'acc://dn.acme',
          destinationNetwork: 'acc://bvn-test.acme',
          sequenceNumber: 12345,
          gotDirectoryReceipt: true,
          proof: null,
          anchorSigners: Uint8List.fromList([1, 2, 3, 4])
        );

        final json = status.toJson();

        // Should have all fields with sorted keys
        final keys = json.keys.toList();
        expect(keys, equals(keys..sort()));

        // Should handle Uint8List encoding
        expect(json['AnchorSigners'], isA<String>());

        // Should be round-trip safe
        final reconstructed = TransactionStatus.fromJson(json);
        expect(reconstructed.txID, equals(status.txID));
        expect(reconstructed.anchorSigners, equals(status.anchorSigners));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle null values correctly', () {
        final adi = ADI(url: 'acc://test.acme', auth: null);
        final json = adi.toJson();

        // null values should be included as null in JSON
        expect(json.containsKey('AccountAuth'), isTrue);
        expect(json['AccountAuth'], isNull);
      });

      test('should handle empty strings', () {
        final adi = ADI(url: '', auth: '');
        final json = adi.toJson();

        expect(json['Url'], equals(''));
        expect(json['AccountAuth'], equals(''));
      });

      test('should handle large numbers', () {
        final largeNumber = BigInt.parse('999999999999999999999999999999999999999999');
        final account = LiteTokenAccount(
          url: 'acc://user.acme',
          tokenUrl: 'acc://test.acme/tokens',
          balance: largeNumber,
          lockHeight: 0
        );

        final json = account.toJson();
        expect(json['Balance'], equals(largeNumber.toString()));

        // Should round-trip correctly
        final reconstructed = LiteTokenAccount.fromJson(json);
        expect(reconstructed.balance, equals(largeNumber));
      });
    });
  });
}