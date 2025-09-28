import "dart:io";
import "dart:convert";
import "package:opendlt_accumulate/opendlt_accumulate.dart";

class FlowConfig {
  final String v2;
  final String v3;
  final String faucetAccount;
  final String devnetDir;

  FlowConfig._(this.v2, this.v3, this.faucetAccount, this.devnetDir);

  static Future<FlowConfig> fromDevNetDiscovery() async {
    // First check environment variables
    var v2Url = Platform.environment["ACC_RPC_URL_V2"];
    var v3Url = Platform.environment["ACC_RPC_URL_V3"];
    var faucet = Platform.environment["ACC_FAUCET_ACCOUNT"];
    var devnetDir = Platform.environment["ACC_DEVNET_DIR"] ??
        r'C:\Accumulate_Stuff\devnet-accumulate-instance';

    // If any are missing, run discovery
    if (v2Url == null || v3Url == null || faucet == null) {
      print("Missing environment variables, running DevNet discovery...");
      final config = await _discoverDevNetConfig(devnetDir);
      v2Url ??= config['ACC_RPC_URL_V2'];
      v3Url ??= config['ACC_RPC_URL_V3'];
      faucet ??= config['ACC_FAUCET_ACCOUNT'];
    }

    print("DevNet Configuration:");
    print("  V2 URL: $v2Url");
    print("  V3 URL: $v3Url");
    print("  Faucet: $faucet");
    print("  DevNet Dir: $devnetDir");

    return FlowConfig._(
      v2Url ?? 'http://localhost:26660/v2',
      v3Url ?? 'http://localhost:26660/v3',
      faucet ?? 'acc://a21555da824d14f3f066214657a44e6a1a347dad3052a23a/ACME',
      devnetDir,
    );
  }

  static Future<Map<String, String>> _discoverDevNetConfig(String devnetDir) async {
    final config = <String, String>{};

    // Set default values
    config['ACC_DEVNET_DIR'] = devnetDir;
    config['ACC_RPC_URL_V2'] = 'http://localhost:26660/v2';
    config['ACC_RPC_URL_V3'] = 'http://localhost:26660/v3';
    config['ACC_FAUCET_ACCOUNT'] = 'acc://a21555da824d14f3f066214657a44e6a1a347dad3052a23a/ACME';

    // Try to get more specific info from Docker logs
    try {
      final result = await Process.run('docker', [
        'logs',
        'devnet-accumulate-instance-accumulate-devnet-1'
      ], workingDirectory: devnetDir);

      if (result.exitCode == 0) {
        final logs = result.stdout as String;

        // Extract listening address
        final listeningRegex = RegExp(r'Listening.*"IP":"([^"]+)".*"Port":(\\d+)');
        final listeningMatch = listeningRegex.firstMatch(logs);
        if (listeningMatch != null) {
          final host = listeningMatch.group(1);
          final port = listeningMatch.group(2);
          config['ACC_RPC_URL_V2'] = 'http://$host:$port/v2';
          config['ACC_RPC_URL_V3'] = 'http://$host:$port/v3';
        }

        // Extract faucet account
        final faucetRegex = RegExp(r'Faucet.*account=(acc://[^\\s]+)');
        final faucetMatch = faucetRegex.firstMatch(logs);
        if (faucetMatch != null) {
          config['ACC_FAUCET_ACCOUNT'] = faucetMatch.group(1)!;
        }
      }
    } catch (e) {
      print('Warning: Could not parse Docker logs: $e');
    }

    return config;
  }

  Accumulate make() => Accumulate.custom(
        v2Endpoint: v2,
        v3Endpoint: v3,
        v2: const AccumulateOptions(timeoutMs: 30000),
        v3: const AccumulateOptions(timeoutMs: 30000),
      );

  /// Check if DevNet is accessible
  Future<bool> checkDevNetHealth() async {
    try {
      final accumulate = make();
      // Try a simple V3 query
      await accumulate.v3.rawCall('network-status', {});
      accumulate.close();
      return true;
    } catch (e) {
      print('DevNet health check failed: $e');
      return false;
    }
  }
}
