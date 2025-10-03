import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

void main() {
  group('Delegation and Depth Tests', () {
    group('DelegatedSignature Depth', () {
      test('should calculate depth for single level delegation', () {
        final baseSig = ED25519Signature(
          PublicKey: Uint8List.fromList([1, 2, 3, 4]),
          Signature: Uint8List.fromList([5, 6, 7, 8]),
          Signer: 'acc://base',
          SignerVersion: 1,
        );

        final delegated = DelegatedSignature(
          Signature: baseSig,
          Delegator: 'acc://delegator1',
        );

        expect(delegated.depth, equals(1));
      });

      test('should calculate depth for multi-level delegation', () {
        final baseSig = ED25519Signature(
          PublicKey: Uint8List.fromList([1, 2, 3, 4]),
          Signature: Uint8List.fromList([5, 6, 7, 8]),
          Signer: 'acc://base',
          SignerVersion: 1,
        );

        final delegated1 = DelegatedSignature(
          Signature: baseSig,
          Delegator: 'acc://delegator1',
        );

        final delegated2 = DelegatedSignature(
          Signature: delegated1,
          Delegator: 'acc://delegator2',
        );

        final delegated3 = DelegatedSignature(
          Signature: delegated2,
          Delegator: 'acc://delegator3',
        );

        expect(delegated1.depth, equals(1));
        expect(delegated2.depth, equals(2));
        expect(delegated3.depth, equals(3));
      });

      test('should prevent excessive delegation depth', () {
        final baseSig = ED25519Signature(
          PublicKey: Uint8List.fromList([1, 2, 3, 4]),
          Signature: Uint8List.fromList([5, 6, 7, 8]),
          Signer: 'acc://base',
          SignerVersion: 1,
        );

        // Create a deeply nested delegation JSON that should be rejected
        final deepDelegationJson = {
          'type': 'delegated',
          'Delegator': 'acc://delegator6',
          'Signature': {
            'type': 'delegated',
            'Delegator': 'acc://delegator5',
            'Signature': {
              'type': 'delegated',
              'Delegator': 'acc://delegator4',
              'Signature': {
                'type': 'delegated',
                'Delegator': 'acc://delegator3',
                'Signature': {
                  'type': 'delegated',
                  'Delegator': 'acc://delegator2',
                  'Signature': {
                    'type': 'delegated',
                    'Delegator': 'acc://delegator1',
                    'Signature': {
                      'type': 'ed25519',
                      'PublicKey': 'dGVzdA==',
                      'Signature': 'dGVzdA==',
                      'Signer': 'acc://base',
                      'SignerVersion': 1
                    }
                  }
                }
              }
            }
          }
        };

        // Should throw when depth limit is exceeded (depth limit of 5)
        expect(() => BaseSignature.fromJson(deepDelegationJson), throwsArgumentError);
      });
    });

    group('DelegatedSignature Chain Operations', () {
      test('should unwrap delegation chain correctly', () {
        final baseSig = ED25519Signature(
          PublicKey: Uint8List.fromList([1, 2, 3, 4]),
          Signature: Uint8List.fromList([5, 6, 7, 8]),
          Signer: 'acc://base',
          SignerVersion: 1,
        );

        final delegated1 = DelegatedSignature(
          Signature: baseSig,
          Delegator: 'acc://delegator1',
        );

        final delegated2 = DelegatedSignature(
          Signature: delegated1,
          Delegator: 'acc://delegator2',
        );

        final chain = delegated2.unwrapChain();
        expect(chain.length, equals(3)); // delegated2, delegated1, baseSig
        expect(chain[0], equals(delegated2));
        expect(chain[1], equals(delegated1));
        expect(chain[2], equals(baseSig));
      });

      test('should flatten delegation to base signature', () {
        final baseSig = ED25519Signature(
          PublicKey: Uint8List.fromList([1, 2, 3, 4]),
          Signature: Uint8List.fromList([5, 6, 7, 8]),
          Signer: 'acc://base',
          SignerVersion: 1,
        );

        final delegated1 = DelegatedSignature(
          Signature: baseSig,
          Delegator: 'acc://delegator1',
        );

        final delegated2 = DelegatedSignature(
          Signature: delegated1,
          Delegator: 'acc://delegator2',
        );

        final flattened = delegated2.flatten();
        expect(flattened, equals(baseSig));
        expect(flattened, isA<ED25519Signature>());
      });

      test('should handle single level unwrap chain', () {
        final baseSig = ED25519Signature(
          PublicKey: Uint8List.fromList([1, 2, 3, 4]),
          Signature: Uint8List.fromList([5, 6, 7, 8]),
          Signer: 'acc://base',
          SignerVersion: 1,
        );

        final delegated = DelegatedSignature(
          Signature: baseSig,
          Delegator: 'acc://delegator1',
        );

        final chain = delegated.unwrapChain();
        expect(chain.length, equals(2)); // delegated, baseSig
        expect(chain[0], equals(delegated));
        expect(chain[1], equals(baseSig));
      });

      test('should handle empty delegation chain edge case', () {
        final baseSig = ED25519Signature(
          PublicKey: Uint8List.fromList([1, 2, 3, 4]),
          Signature: Uint8List.fromList([5, 6, 7, 8]),
          Signer: 'acc://base',
          SignerVersion: 1,
        );

        final delegated = DelegatedSignature(
          Signature: baseSig,
          Delegator: 'acc://delegator1',
        );

        final flattened = delegated.flatten();
        expect(flattened, isNotNull);
        expect(flattened, equals(baseSig));
      });
    });

    group('Delegation JSON Serialization', () {
      test('should preserve delegation structure in JSON round-trip', () {
        final baseSig = ED25519Signature(
          PublicKey: Uint8List.fromList([1, 2, 3, 4]),
          Signature: Uint8List.fromList([5, 6, 7, 8]),
          Signer: 'acc://base',
          SignerVersion: 1,
        );

        final delegated = DelegatedSignature(
          Signature: baseSig,
          Delegator: 'acc://delegator1',
        );

        final json = delegated.toJson();
        expect(json['type'], equals('delegated'));
        expect(json['Delegator'], equals('acc://delegator1'));
        expect(json['Signature'], isA<Map<String, dynamic>>());
        expect(json['Signature']['type'], equals('ed25519'));

        final deserialized = BaseSignature.fromJson(json) as DelegatedSignature;
        expect(deserialized.$type, equals('delegated'));
        expect(deserialized.Delegator, equals('acc://delegator1'));
        expect(deserialized.Signature, isA<ED25519Signature>());
      });

      test('should preserve multi-level delegation structure', () {
        final baseSig = ED25519Signature(
          PublicKey: Uint8List.fromList([1, 2, 3, 4]),
          Signature: Uint8List.fromList([5, 6, 7, 8]),
          Signer: 'acc://base',
          SignerVersion: 1,
        );

        final delegated1 = DelegatedSignature(
          Signature: baseSig,
          Delegator: 'acc://delegator1',
        );

        final delegated2 = DelegatedSignature(
          Signature: delegated1,
          Delegator: 'acc://delegator2',
        );

        final json = delegated2.toJson();
        final deserialized = BaseSignature.fromJson(json) as DelegatedSignature;

        expect(deserialized.depth, equals(2));
        expect(deserialized.Delegator, equals('acc://delegator2'));
        expect(deserialized.Signature, isA<DelegatedSignature>());

        final innerDelegated = deserialized.Signature as DelegatedSignature;
        expect(innerDelegated.Delegator, equals('acc://delegator1'));
        expect(innerDelegated.Signature, isA<ED25519Signature>());
      });
    });

    group('Delegation Security Features', () {
      test('should validate delegation chain integrity', () {
        final baseSig = ED25519Signature(
          PublicKey: Uint8List.fromList([1, 2, 3, 4]),
          Signature: Uint8List.fromList([5, 6, 7, 8]),
          Signer: 'acc://base',
          SignerVersion: 1,
        );

        final delegated = DelegatedSignature(
          Signature: baseSig,
          Delegator: 'acc://delegator1',
        );

        // Basic structure validation
        expect(delegated.Signature, isNotNull);
        expect(delegated.Delegator, isNotEmpty);
        expect(delegated.$type, equals('delegated'));
      });

      test('should handle delegation with different signature types', () {
        final btcSig = BTCSignature(
          PublicKey: Uint8List.fromList([1, 2, 3, 4]),
          Signature: Uint8List.fromList([5, 6, 7, 8]),
          Signer: 'acc://btc',
          SignerVersion: 1,
        );

        final delegated = DelegatedSignature(
          Signature: btcSig,
          Delegator: 'acc://delegator1',
        );

        expect(delegated.Signature, isA<BTCSignature>());
        expect(delegated.flatten(), equals(btcSig));
      });
    });
  });
}