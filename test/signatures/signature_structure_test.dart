import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

void main() {
  group('Signature Structure Tests', () {
    group('BaseSignature Factory', () {
      test('should create correct signature types from discriminant', () {
        final ed25519Json = {'type': 'ed25519', 'PublicKey': 'dGVzdA==', 'Signature': 'dGVzdA==', 'Signer': 'acc://test', 'SignerVersion': 1};
        final signature = BaseSignature.fromJson(ed25519Json);
        expect(signature, isA<ED25519Signature>());
        expect(signature.runtimeType.toString(), equals('ED25519Signature'));
      });

      test('should handle delegated signatures', () {
        final delegatedJson = {
          'type': 'delegated',
          'Signature': {'type': 'ed25519', 'PublicKey': 'dGVzdA==', 'Signature': 'dGVzdA==', 'Signer': 'acc://test', 'SignerVersion': 1},
          'Delegator': 'acc://delegator'
        };
        final signature = BaseSignature.fromJson(delegatedJson);
        expect(signature, isA<DelegatedSignature>());
        expect((signature as DelegatedSignature).Delegator, equals('acc://delegator'));
      });

      test('should handle remote signatures', () {
        final remoteJson = {
          'type': 'remote',
          'Destination': 'acc://destination',
          'Signature': {'type': 'ed25519', 'PublicKey': 'dGVzdA==', 'Signature': 'dGVzdA==', 'Signer': 'acc://test', 'SignerVersion': 1},
          'Cause': 'YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXpBQkNERUY='
        };
        final signature = BaseSignature.fromJson(remoteJson);
        expect(signature, isA<RemoteSignature>());
        expect((signature as RemoteSignature).Destination, equals('acc://destination'));
      });

      test('should handle signature sets', () {
        final setJson = {
          'type': 'Set',
          'Signer': 'acc://signer',
          'Authority': 'acc://authority',
          'Signatures': [
            {'type': 'ed25519', 'PublicKey': 'dGVzdA==', 'Signature': 'dGVzdA==', 'Signer': 'acc://test1', 'SignerVersion': 1},
            {'type': 'ed25519', 'PublicKey': 'dGVzdA==', 'Signature': 'dGVzdA==', 'Signer': 'acc://test2', 'SignerVersion': 1}
          ]
        };
        final signature = BaseSignature.fromJson(setJson);
        expect(signature, isA<SignatureSet>());
        expect((signature as SignatureSet).Signatures.length, equals(2));
      });

      test('should throw on unknown signature type', () {
        final unknownJson = {'type': 'unknown'};
        expect(() => BaseSignature.fromJson(unknownJson), throwsArgumentError);
      });

      test('should throw on missing discriminant', () {
        final noTypeJson = {'data': 'test'};
        expect(() => BaseSignature.fromJson(noTypeJson), throwsArgumentError);
      });
    });

    group('Signature Types', () {
      test('ED25519Signature should have correct type', () {
        final signature = ED25519Signature(
          PublicKey: Uint8List.fromList([1, 2, 3, 4]),
          Signature: Uint8List.fromList([5, 6, 7, 8]),
          Signer: 'acc://test',
          SignerVersion: 1,
        );
        expect(signature.$type, equals('ed25519'));
      });

      test('LegacyED25519Signature should have correct type', () {
        final signature = LegacyED25519Signature(
          Timestamp: 1234567890,
          PublicKey: Uint8List.fromList([1, 2, 3, 4]),
          Signature: Uint8List.fromList([5, 6, 7, 8]),
          Signer: 'acc://test',
          SignerVersion: 1,
        );
        expect(signature.$type, equals('legacyed25519'));
      });

      test('SignatureSet should have correct type', () {
        final signature = SignatureSet(
          Signer: 'acc://signer',
          Authority: 'acc://authority',
          Signatures: [],
        );
        expect(signature.$type, equals('Set'));
      });

      test('DelegatedSignature should have correct type', () {
        final innerSig = ED25519Signature(
          PublicKey: Uint8List.fromList([1, 2, 3, 4]),
          Signature: Uint8List.fromList([5, 6, 7, 8]),
          Signer: 'acc://test',
          SignerVersion: 1,
        );
        final signature = DelegatedSignature(
          Signature: innerSig,
          Delegator: 'acc://delegator',
        );
        expect(signature.$type, equals('delegated'));
      });

      test('RemoteSignature should have correct type', () {
        final innerSig = ED25519Signature(
          PublicKey: Uint8List.fromList([1, 2, 3, 4]),
          Signature: Uint8List.fromList([5, 6, 7, 8]),
          Signer: 'acc://test',
          SignerVersion: 1,
        );
        final signature = RemoteSignature(
          Destination: 'acc://destination',
          Signature: innerSig,
          Cause: Uint8List.fromList(List.generate(32, (i) => i)),
        );
        expect(signature.$type, equals('remote'));
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize ED25519Signature correctly', () {
        final original = ED25519Signature(
          PublicKey: Uint8List.fromList([1, 2, 3, 4]),
          Signature: Uint8List.fromList([5, 6, 7, 8]),
          Signer: 'acc://test',
          SignerVersion: 1,
          Timestamp: 1234567890,
        );

        final json = original.toJson();
        expect(json['type'], equals('ed25519'));
        expect(json['Signer'], equals('acc://test'));
        expect(json['SignerVersion'], equals(1));
        expect(json['Timestamp'], equals(1234567890));

        final deserialized = BaseSignature.fromJson(json) as ED25519Signature;
        expect(deserialized.$type, equals(original.$type));
        expect(deserialized.Signer, equals(original.Signer));
        expect(deserialized.SignerVersion, equals(original.SignerVersion));
        expect(deserialized.Timestamp, equals(original.Timestamp));
      });

      test('should serialize and deserialize SignatureSet correctly', () {
        final sig1 = ED25519Signature(
          PublicKey: Uint8List.fromList([1, 2, 3, 4]),
          Signature: Uint8List.fromList([5, 6, 7, 8]),
          Signer: 'acc://test1',
          SignerVersion: 1,
        );
        final sig2 = ED25519Signature(
          PublicKey: Uint8List.fromList([9, 10, 11, 12]),
          Signature: Uint8List.fromList([13, 14, 15, 16]),
          Signer: 'acc://test2',
          SignerVersion: 1,
        );

        final original = SignatureSet(
          Signer: 'acc://signer',
          Authority: 'acc://authority',
          Signatures: [sig1, sig2],
        );

        final json = original.toJson();
        expect(json['type'], equals('Set'));
        expect(json['Signer'], equals('acc://signer'));
        expect(json['Authority'], equals('acc://authority'));
        expect(json['Signatures'], hasLength(2));

        final deserialized = BaseSignature.fromJson(json) as SignatureSet;
        expect(deserialized.$type, equals(original.$type));
        expect(deserialized.Signer, equals(original.Signer));
        expect(deserialized.Authority, equals(original.Authority));
        expect(deserialized.Signatures.length, equals(2));
      });
    });
  });
}