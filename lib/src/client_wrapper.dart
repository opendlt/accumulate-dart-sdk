// Client wrapper that works around generated client issues

import 'package:http/http.dart' as http;
import 'generated/api/json_rpc_client.dart';

/// Simplified client wrapper that works around generated client compilation issues
class ClientWrapper {
  final JsonRpcClient _client;

  ClientWrapper(String serverUrl, {http.Client? httpClient})
      : _client = JsonRpcClient(serverUrl, httpClient: httpClient);

  /// Submit a transaction envelope
  Future<Map<String, dynamic>> submit(Map<String, dynamic> envelope) async {
    final result = await _client.call('submit', envelope);
    return result as Map<String, dynamic>;
  }

  /// Query account information
  Future<Map<String, dynamic>> query(Map<String, dynamic> queryParams) async {
    final result = await _client.call('query', queryParams);
    return result as Map<String, dynamic>;
  }

  /// Get network description
  Future<Map<String, dynamic>> describe() async {
    final result = await _client.call('describe', {});
    return result as Map<String, dynamic>;
  }

  /// Close the client
  void close() => _client.close();
}
