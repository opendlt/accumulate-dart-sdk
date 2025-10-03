import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class AccumulateApiClient {
  final String baseUrl;
  final Duration timeout;
  final HttpClient _httpClient;
  int _nextId = 1;

  AccumulateApiClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
  }) : _httpClient = HttpClient();

  void dispose() {
    _httpClient.close();
  }

  Future<T> _call<T>(String method, Map<String, dynamic> params) async {
    final id = _nextId++;

    final request = {
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
      'id': id,
    };

    try {
      final uri = Uri.parse('$baseUrl/v2');
      final httpRequest = await _httpClient.postUrl(uri);
      httpRequest.headers.contentType = ContentType.json;

      final requestBody = utf8.encode(json.encode(request));
      httpRequest.add(requestBody);

      final httpResponse = await httpRequest.close().timeout(timeout);
      final responseBody = await utf8.decodeStream(httpResponse);
      final response = json.decode(responseBody) as Map<String, dynamic>;

      if (response.containsKey('error')) {
        final error = response['error'] as Map<String, dynamic>;
        throw AccumulateApiException(
          code: error['code'] as int,
          message: error['message'] as String,
          data: error['data'],
        );
      }

      return response['result'] as T;
    } catch (e) {
      if (e is AccumulateApiException) rethrow;
      throw AccumulateApiException(
        code: -1,
        message: 'Network error: $e',
        data: null,
      );
    }
  }

  Future<Map<String, dynamic>> Status() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('status', params);
  }
  Future<Map<String, dynamic>> Version() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('version', params);
  }
  Future<Map<String, dynamic>> Describe() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('describe', params);
  }
  Future<Map<String, dynamic>> Metrics() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('metrics', params);
  }
  Future<Map<String, dynamic>> Faucet() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('faucet', params);
  }
  Future<Map<String, dynamic>> Query() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('query', params);
  }
  Future<Map<String, dynamic>> QueryDirectory() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('query-directory', params);
  }
  Future<Map<String, dynamic>> QueryTx() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('query-tx', params);
  }
  Future<Map<String, dynamic>> QueryTxLocal() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('query-tx-local', params);
  }
  Future<Map<String, dynamic>> QueryTxHistory() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('query-tx-history', params);
  }
  Future<Map<String, dynamic>> QueryData() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('query-data', params);
  }
  Future<Map<String, dynamic>> QueryDataSet() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('query-data-set', params);
  }
  Future<Map<String, dynamic>> QueryKeyPageIndex() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('query-key-page-index', params);
  }
  Future<Map<String, dynamic>> QueryMinorBlocks() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('query-minor-blocks', params);
  }
  Future<Map<String, dynamic>> QueryMajorBlocks() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('query-major-blocks', params);
  }
  Future<Map<String, dynamic>> QuerySynth() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('query-synth', params);
  }
  Future<Map<String, dynamic>> Execute() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('execute', params);
  }
  Future<Map<String, dynamic>> ExecuteDirect() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('execute-direct', params);
  }
  Future<Map<String, dynamic>> ExecuteLocal() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('execute-local', params);
  }
  Future<Map<String, dynamic>> ExecuteCreateAdi() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('execute-create-adi', params);
  }
  Future<Map<String, dynamic>> ExecuteCreateIdentity() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('execute-create-identity', params);
  }
  Future<Map<String, dynamic>> ExecuteCreateDataAccount() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('execute-create-data-account', params);
  }
  Future<Map<String, dynamic>> ExecuteCreateKeyBook() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('execute-create-key-book', params);
  }
  Future<Map<String, dynamic>> ExecuteCreateKeyPage() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('execute-create-key-page', params);
  }
  Future<Map<String, dynamic>> ExecuteCreateToken() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('execute-create-token', params);
  }
  Future<Map<String, dynamic>> ExecuteCreateTokenAccount() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('execute-create-token-account', params);
  }
  Future<Map<String, dynamic>> ExecuteSendTokens() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('execute-send-tokens', params);
  }
  Future<Map<String, dynamic>> ExecuteAddCredits() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('execute-add-credits', params);
  }
  Future<Map<String, dynamic>> ExecuteUpdateKeyPage() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('execute-update-key-page', params);
  }
  Future<Map<String, dynamic>> ExecuteUpdateKey() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('execute-update-key', params);
  }
  Future<Map<String, dynamic>> ExecuteWriteData() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('execute-write-data', params);
  }
  Future<Map<String, dynamic>> ExecuteIssueTokens() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('execute-issue-tokens', params);
  }
  Future<Map<String, dynamic>> ExecuteWriteDataTo() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('execute-write-data-to', params);
  }
  Future<Map<String, dynamic>> ExecuteBurnTokens() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('execute-burn-tokens', params);
  }
  Future<Map<String, dynamic>> ExecuteUpdateAccountAuth() async {
    final params = <String, dynamic>{

    };

    return await _call<Map<String, dynamic>>('execute-update-account-auth', params);
  }
}

class AccumulateApiException implements Exception {
  final int code;
  final String message;
  final dynamic data;

  const AccumulateApiException({
    required this.code,
    required this.message,
    this.data,
  });

  @override
  String toString() => 'AccumulateApiException($code): $message';
}