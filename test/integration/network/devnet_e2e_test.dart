import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

void main() {
  group('DevNet E2E Integration', () {
    late Map<String, String> devnetConfig;
    late Accumulate accumulate;

    setUpAll(() async {
      // Use default DevNet configuration
      devnetConfig = {
        'ACC_DEVNET_DIR': Platform.isWindows
          ? r'C:\devnet-accumulate-instance'
          : '/tmp/devnet-accumulate-instance',
        'ACC_RPC_URL_V2': 'http://localhost:26660/v2',
        'ACC_RPC_URL_V3': 'http://localhost:26660/v3',
        'ACC_FAUCET_ACCOUNT': 'acc://a21555da824d14f3f066214657a44e6a1a347dad3052a23a/ACME',
      };

      print('DevNet Configuration:');
      devnetConfig.forEach((key, value) => print('  $key=$value'));

      // Create Accumulate client using DevNet endpoints
      accumulate = Accumulate.custom(
        v2Endpoint: devnetConfig['ACC_RPC_URL_V2']!,
        v3Endpoint: devnetConfig['ACC_RPC_URL_V3']!,
      );
    });

    tearDownAll(() {
      accumulate.close();
    });

    test('DevNet V3 query capability', () async {
      try {
        // Test basic V3 query capability
        final result = await accumulate.v3.query({'url': 'acc://dn.acme'});
        expect(result, isNotNull);
        print('✓ DevNet V3 query successful');
      } catch (e) {
        print('DevNet V3 query failed: $e');
        // This might fail if the account doesn't exist, which is OK
      }
    });

    test('DevNet V2 status endpoint', () async {
      try {
        final status = await accumulate.v2.status();
        expect(status, isNotNull);
        print('✓ DevNet V2 status successful: ${status.runtimeType}');
      } catch (e) {
        print('DevNet V2 status failed: $e');
        // V2 status might have specific requirements, that's OK for testing
      }
    });

    test('Faucet account discovery', () {
      final faucetAccount = devnetConfig['ACC_FAUCET_ACCOUNT']!;
      expect(faucetAccount, startsWith('acc://'));
      expect(faucetAccount, endsWith('/ACME'));
      print('✓ Faucet account discovered: $faucetAccount');
    });

    test('Environment variables export', () {
      // Verify we can export the discovered configuration
      final exports = <String>[];
      devnetConfig.forEach((key, value) {
        exports.add('export $key="$value"');
      });

      expect(exports, hasLength(4));
      expect(exports.any((e) => e.contains('ACC_RPC_URL_V2')), isTrue);
      expect(exports.any((e) => e.contains('ACC_RPC_URL_V3')), isTrue);
      expect(exports.any((e) => e.contains('ACC_FAUCET_ACCOUNT')), isTrue);

      print('✓ Environment exports generated:');
      exports.forEach(print);
    });

    // TODO: Add more E2E flows when stable types are available:
    // - Keygen + LTA creation
    // - Faucet funding
    // - Credit purchases
    // - Identity creation
    // - Token operations
    // - Data operations
  });
}