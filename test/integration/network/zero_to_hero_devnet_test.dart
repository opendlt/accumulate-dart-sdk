import 'package:test/test.dart';
import 'dart:io';

/// Integration test that runs the zero-to-hero flow
/// This test requires local DevNet to be running
void main() {
  group('Zero-to-Hero DevNet Integration', () {
    test('complete Accumulate lifecycle flow', () async {
      print('Running zero-to-hero flow integration test...');

      // Run the simple orchestrator script
      final result = await Process.run(
        'dart',
        ['run', 'example/flows/999_zero_to_hero_simple.dart'],
        workingDirectory: Directory.current.path,
      );

      // Print output for debugging
      print('STDOUT:');
      print(result.stdout);

      if (result.stderr != null && result.stderr.toString().isNotEmpty) {
        print('STDERR:');
        print(result.stderr);
      }

      // Check that the process completed successfully
      expect(result.exitCode, equals(0),
          reason: 'Zero-to-hero flow should complete without errors');

      // Verify key success indicators in output
      final output = result.stdout.toString();

      expect(output, contains('Simple Zero-to-Hero flow completed'),
          reason: 'Flow should complete successfully');

      expect(output, contains('DevNet discovery and basic API connectivity verified'),
          reason: 'Should verify DevNet connectivity');

      expect(output, contains('Generated Accounts:'),
          reason: 'Should generate accounts');

      expect(output, contains('Discovered Configuration:'),
          reason: 'Should discover DevNet configuration');

      expect(output, contains('Lite Identity:'),
          reason: 'Should create lite identity');

      expect(output, contains('Lite Token Account:'),
          reason: 'Should create lite token account');

      expect(output, contains('network_status: Success'),
          reason: 'Should successfully get network status');

      expect(output, contains('v2_version: Success'),
          reason: 'Should successfully get V2 version');

      print('[DONE] Zero-to-hero integration test passed!');
    });

    test('DevNet health check passes', () async {
      print('Running DevNet health check...');

      final result = await Process.run(
        'dart',
        ['run', 'example/flows/000_boot_devnet_local.dart'],
        workingDirectory: Directory.current.path,
      );

      print('Health check output:');
      print(result.stdout);

      if (result.stderr != null && result.stderr.toString().isNotEmpty) {
        print('Health check errors:');
        print(result.stderr);
      }

      expect(result.exitCode, equals(0),
          reason: 'DevNet should be healthy and accessible');

      final output = result.stdout.toString();
      expect(output, contains('DevNet is ready for examples'),
          reason: 'DevNet should be confirmed ready');

      print('[DONE] DevNet health check passed!');
    });
  });
}