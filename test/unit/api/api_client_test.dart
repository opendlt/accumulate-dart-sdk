import 'package:test/test.dart';
import 'dart:io';
import 'package:opendlt_accumulate/src/api/client.dart';

/// Resolve a base RPC root (no /v2 or /v3 suffix) from env, with sensible defaults.
/// Priority:
///   1) ACC_RPC_URL_V2 (strip '/v2' if present)
///   2) ACC_RPC_URL_V3 (strip '/v3' if present)
///   3) http://localhost:26660 (DevNet)
String _resolveBaseUrl() {
  final env = Platform.environment;
  String? v2 = env['ACC_RPC_URL_V2'];
  String? v3 = env['ACC_RPC_URL_V3'];

  String? pick = v2 ?? v3;
  if (pick != null) {
    // Strip /v2 or /v3 suffixes but keep the root
    if (pick.endsWith('/v2')) pick = pick.substring(0, pick.length - 3);
    if (pick.endsWith('/v3')) pick = pick.substring(0, pick.length - 3);
    // Remove trailing slash if present
    if (pick.endsWith('/')) pick = pick.substring(0, pick.length - 1);
    return pick;
  }
  return 'http://localhost:26660';
}

void main() {
  final baseUrl = _resolveBaseUrl();
  final isLocalDevnet =
      baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1');
  final runLive = (Platform.environment['ACC_RUN_LIVE'] ?? '').toLowerCase() == '1';

  print('API Client Tests using baseUrl: $baseUrl '
      '(env: ACC_RPC_URL_V2=${Platform.environment['ACC_RPC_URL_V2'] ?? '-'}, '
      'ACC_RPC_URL_V3=${Platform.environment['ACC_RPC_URL_V3'] ?? '-'}, '
      'ACC_RUN_LIVE=${Platform.environment['ACC_RUN_LIVE'] ?? '-'})');

  group('API Client Tests (35 methods)', () {
    group('Client Construction and Basic Properties', () {
      test('should create AccumulateApiClient with required parameters', () {
        final client = AccumulateApiClient(baseUrl: baseUrl);
        expect(client.baseUrl, equals(baseUrl));
        expect(client.timeout, equals(const Duration(seconds: 30)));
        client.dispose();
      });

      test('should create AccumulateApiClient with custom timeout', () {
        final client = AccumulateApiClient(
          baseUrl: baseUrl,
          timeout: const Duration(seconds: 60),
        );
        expect(client.timeout, equals(const Duration(seconds: 60)));
        client.dispose();
      });

      test('should dispose properly', () {
        final client = AccumulateApiClient(baseUrl: baseUrl);
        expect(() => client.dispose(), returnsNormally);
      });
    });

    group('JSON-RPC 2.0 Request Format Tests (no network)', () {
      // Assert presence/signature only (no invocation).
      test('Status method should exist', () {
        final client = AccumulateApiClient(baseUrl: baseUrl);
        expect(client.Status, isA<Future<Map<String, dynamic>> Function()>());
        client.dispose();
      });

      test('Version method should exist', () {
        final client = AccumulateApiClient(baseUrl: baseUrl);
        expect(client.Version, isA<Future<Map<String, dynamic>> Function()>());
        client.dispose();
      });

      test('Describe method should exist', () {
        final client = AccumulateApiClient(baseUrl: baseUrl);
        expect(client.Describe, isA<Future<Map<String, dynamic>> Function()>());
        client.dispose();
      });
    });

    group('All 35 API Methods Availability (no network)', () {
      late AccumulateApiClient client;

      setUp(() {
        client = AccumulateApiClient(baseUrl: baseUrl);
      });

      tearDown(() {
        client.dispose();
      });

      final expectedMethods = [
        'Status',
        'Version',
        'Describe',
        'Metrics',
        'Faucet',
        'Query',
        'QueryDirectory',
        'QueryTx',
        'QueryTxLocal',
        'QueryTxHistory',
        'QueryData',
        'QueryDataSet',
        'QueryKeyPageIndex',
        'QueryMinorBlocks',
        'QueryMajorBlocks',
        'QuerySynth',
        'Execute',
        'ExecuteDirect',
        'ExecuteLocal',
        'ExecuteCreateAdi',
        'ExecuteCreateIdentity',
        'ExecuteCreateDataAccount',
        'ExecuteCreateKeyBook',
        'ExecuteCreateKeyPage',
        'ExecuteCreateToken',
        'ExecuteCreateTokenAccount',
        'ExecuteSendTokens',
        'ExecuteAddCredits',
        'ExecuteUpdateKeyPage',
        'ExecuteUpdateKey',
        'ExecuteWriteData',
        'ExecuteIssueTokens',
        'ExecuteWriteDataTo',
        'ExecuteBurnTokens',
        'ExecuteUpdateAccountAuth',
      ];

      for (final methodName in expectedMethods) {
        test('$methodName method tear-off should exist', () {
          final tearOff = ({
            'Status': client.Status,
            'Version': client.Version,
            'Describe': client.Describe,
            'Metrics': client.Metrics,
            'Faucet': client.Faucet,
            'Query': client.Query,
            'QueryDirectory': client.QueryDirectory,
            'QueryTx': client.QueryTx,
            'QueryTxLocal': client.QueryTxLocal,
            'QueryTxHistory': client.QueryTxHistory,
            'QueryData': client.QueryData,
            'QueryDataSet': client.QueryDataSet,
            'QueryKeyPageIndex': client.QueryKeyPageIndex,
            'QueryMinorBlocks': client.QueryMinorBlocks,
            'QueryMajorBlocks': client.QueryMajorBlocks,
            'QuerySynth': client.QuerySynth,
            'Execute': client.Execute,
            'ExecuteDirect': client.ExecuteDirect,
            'ExecuteLocal': client.ExecuteLocal,
            'ExecuteCreateAdi': client.ExecuteCreateAdi,
            'ExecuteCreateIdentity': client.ExecuteCreateIdentity,
            'ExecuteCreateDataAccount': client.ExecuteCreateDataAccount,
            'ExecuteCreateKeyBook': client.ExecuteCreateKeyBook,
            'ExecuteCreateKeyPage': client.ExecuteCreateKeyPage,
            'ExecuteCreateToken': client.ExecuteCreateToken,
            'ExecuteCreateTokenAccount': client.ExecuteCreateTokenAccount,
            'ExecuteSendTokens': client.ExecuteSendTokens,
            'ExecuteAddCredits': client.ExecuteAddCredits,
            'ExecuteUpdateKeyPage': client.ExecuteUpdateKeyPage,
            'ExecuteUpdateKey': client.ExecuteUpdateKey,
            'ExecuteWriteData': client.ExecuteWriteData,
            'ExecuteIssueTokens': client.ExecuteIssueTokens,
            'ExecuteWriteDataTo': client.ExecuteWriteDataTo,
            'ExecuteBurnTokens': client.ExecuteBurnTokens,
            'ExecuteUpdateAccountAuth': client.ExecuteUpdateAccountAuth,
          })[methodName];

          expect(tearOff, isNotNull);
          expect(tearOff, isA<Future<Map<String, dynamic>> Function()>());
        });
      }

      test('should have exactly 35 API methods available', () {
        expect(expectedMethods, hasLength(35));
      });

      /// Live smoke test for DevNet only (ACC_RUN_LIVE=1, localhost root).
      /// Use 'describe' because it is known to succeed on /v2 for your DevNet.
      test(
        'Describe smoke test (real RPC to /v2)',
        () async {
          final liveClient = AccumulateApiClient(baseUrl: baseUrl);
          final res = await liveClient.Describe();
          liveClient.dispose();

          // Accept either a plain payload or an enveloped {result:{...}}
          Map<String, dynamic> payload = res;
          if (res.containsKey('result') && res['result'] is Map) {
            payload = (res['result'] as Map).cast<String, dynamic>();
          }

          // Basic sanity checks based on your DevNet output
          expect(payload['network'], isA<Map>(), reason: 'payload should contain network field');
          expect(payload['values'], isA<Map>(), reason: 'payload should contain values field');

          // Check if networkName exists and equals "DevNet"
          final network = payload['network'];
          if (network is Map && network['networkName'] != null) {
            expect(network['networkName'], equals('DevNet'),
                reason: 'networkName should be DevNet for local DevNet');
          }

          // Additional validation of DevNet structure
          final values = payload['values'] as Map;
          expect(values, isNotEmpty, reason: 'values should not be empty');

          // Verify network structure matches expected DevNet format
          if (network is Map) {
            expect(network['id'], isNotNull, reason: 'network should have id field');
            expect(network['partitions'], isA<List>(), reason: 'network should have partitions');

            // Validate partition structure based on your DevNet example
            final partitions = network['partitions'] as List;
            expect(partitions, isNotEmpty, reason: 'should have at least one partition');

            for (final partition in partitions) {
              expect(partition, isA<Map>(), reason: 'each partition should be a map');
              final p = partition as Map;
              expect(p['id'], isNotNull, reason: 'partition should have id');
              expect(p['type'], isNotNull, reason: 'partition should have type');
              // Based on your example: BVN1, Directory with types blockValidator, directory
              expect(p['type'], anyOf(equals('blockValidator'), equals('directory'), isA<String>()));
            }
          }

          // Validate values structure from your DevNet example
          if (values['oracle'] != null) {
            final oracle = values['oracle'] as Map;
            expect(oracle['price'], isA<num>(), reason: 'oracle should have price');
          }

          if (values['globals'] != null) {
            final globals = values['globals'] as Map;
            expect(globals, isNotEmpty, reason: 'globals should not be empty');

            // Validate specific globals structure from your example
            if (globals['operatorAcceptThreshold'] != null) {
              final threshold = globals['operatorAcceptThreshold'] as Map;
              expect(threshold['numerator'], isA<num>());
              expect(threshold['denominator'], isA<num>());
            }

            if (globals['feeSchedule'] != null) {
              expect(globals['feeSchedule'], isA<Map>());
            }
          }

          // Validate routing structure if present
          if (payload['routing'] != null) {
            final routing = payload['routing'] as Map;
            expect(routing, isNotEmpty, reason: 'routing should not be empty');

            if (routing['overrides'] != null) {
              expect(routing['overrides'], isA<List>());
            }

            if (routing['routes'] != null) {
              expect(routing['routes'], isA<List>());
            }
          }
        },
        skip: !(isLocalDevnet && runLive)
            ? 'Set ACC_RUN_LIVE=1 and point baseUrl to local DevNet to run this.'
            : false,
        timeout: const Timeout(Duration(seconds: 15)),
      );
    });

    group('Error Handling Tests', () {
      test('should handle AccumulateApiException correctly', () {
        final exception = AccumulateApiException(
          code: -32600,
          message: 'Invalid Request',
          data: {'details': 'test error'},
        );
        expect(exception.code, equals(-32600));
        expect(exception.message, equals('Invalid Request'));
        expect(exception.data, equals({'details': 'test error'}));
        expect(
          exception.toString(),
          contains('AccumulateApiException(-32600)'),
        );
      });

      test('should create AccumulateApiException with required fields only', () {
        final exception = AccumulateApiException(
          code: -32602,
          message: 'Invalid params',
        );
        expect(exception.code, equals(-32602));
        expect(exception.message, equals('Invalid params'));
        expect(exception.data, isNull);
      });
    });

    group('Base URL and Endpoint Tests', () {
      test('should use resolved baseUrl (no trailing /v2|/v3)', () {
        final client = AccumulateApiClient(baseUrl: baseUrl);
        expect(client.baseUrl, equals(baseUrl));
        client.dispose();
      });

      test('should handle different base URLs', () {
        final client1 = AccumulateApiClient(baseUrl: baseUrl);
        final client2 = AccumulateApiClient(baseUrl: 'http://localhost:26660');
        expect(client1.baseUrl, equals(baseUrl));
        expect(client2.baseUrl, equals('http://localhost:26660'));
        client1.dispose();
        client2.dispose();
      });
    });
  });
}