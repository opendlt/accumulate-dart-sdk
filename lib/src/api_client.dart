import 'dart:convert';
import 'dart:io';

class JsonRpcRequest {
  const JsonRpcRequest({
    required this.id,
    required this.method,
    this.params,
  });

  final String id;
  final String method;
  final Map<String, dynamic>? params;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
    };
    if (params != null) json['params'] = params;
    return json;
  }
}

class JsonRpcResponse {
  const JsonRpcResponse({
    required this.id,
    this.result,
    this.error,
  });

  final String id;
  final dynamic result;
  final Map<String, dynamic>? error;

  bool get isSuccess => error == null;

  static JsonRpcResponse fromJson(Map<String, dynamic> json) {
    return JsonRpcResponse(
      id: json['id'] as String,
      result: json['result'],
      error: json['error'] as Map<String, dynamic>?,
    );
  }
}

class AccumulateClient {
  AccumulateClient({
    required this.endpoint,
    this.timeout = const Duration(seconds: 30),
  });

  final String endpoint;
  final Duration timeout;

  int _requestId = 0;

  String _nextId() => (_requestId++).toString();

  Future<JsonRpcResponse> call(String method, [Map<String, dynamic>? params]) async {
    final request = JsonRpcRequest(
      id: _nextId(),
      method: method,
      params: params,
    );

    final httpClient = HttpClient();
    httpClient.connectionTimeout = timeout;

    try {
      final uri = Uri.parse(endpoint);
      final httpRequest = await httpClient.postUrl(uri);
      httpRequest.headers.contentType = ContentType.json;

      final requestBody = jsonEncode(request.toJson());
      httpRequest.write(requestBody);

      final httpResponse = await httpRequest.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      final responseJson = jsonDecode(responseBody) as Map<String, dynamic>;
      return JsonRpcResponse.fromJson(responseJson);
    } finally {
      httpClient.close();
    }
  }

  // 35 API methods from truth IR

  /// queries the status of the node
  Future<JsonRpcResponse> status([Map<String, dynamic>? params]) async {
    return call('status', params);
  }

  /// queries the software version of the node
  Future<JsonRpcResponse> version([Map<String, dynamic>? params]) async {
    return call('version', params);
  }

  /// queries the basic configuration of the node
  Future<JsonRpcResponse> describe([Map<String, dynamic>? params]) async {
    return call('describe', params);
  }

  /// queries network metrics, such as transactions per second
  Future<JsonRpcResponse> metrics([Map<String, dynamic>? params]) async {
    return call('metrics', params);
  }

  /// requests tokens from the ACME faucet
  Future<JsonRpcResponse> faucet([Map<String, dynamic>? params]) async {
    return call('faucet', params);
  }

  /// queries an account or account chain by URL
  Future<JsonRpcResponse> query([Map<String, dynamic>? params]) async {
    return call('query', params);
  }

  /// queries the directory entries of an account
  Future<JsonRpcResponse> queryDirectory([Map<String, dynamic>? params]) async {
    return call('query-directory', params);
  }

  /// queries a transaction by ID
  Future<JsonRpcResponse> queryTx([Map<String, dynamic>? params]) async {
    return call('query-tx', params);
  }

  /// queries a transaction by ID
  Future<JsonRpcResponse> queryTxLocal([Map<String, dynamic>? params]) async {
    return call('query-tx-local', params);
  }

  /// queries an account's transaction history
  Future<JsonRpcResponse> queryTxHistory([Map<String, dynamic>? params]) async {
    return call('query-tx-history', params);
  }

  /// queries an entry on an account's data chain
  Future<JsonRpcResponse> queryData([Map<String, dynamic>? params]) async {
    return call('query-data', params);
  }

  /// queries a range of entries on an account's data chain
  Future<JsonRpcResponse> queryDataSet([Map<String, dynamic>? params]) async {
    return call('query-data-set', params);
  }

  /// queries the location of a key within an account's key book(s)
  Future<JsonRpcResponse> queryKeyPageIndex([Map<String, dynamic>? params]) async {
    return call('query-key-index', params);
  }

  /// queries an account's minor blocks
  Future<JsonRpcResponse> queryMinorBlocks([Map<String, dynamic>? params]) async {
    return call('query-minor-blocks', params);
  }

  /// queries an account's major blocks
  Future<JsonRpcResponse> queryMajorBlocks([Map<String, dynamic>? params]) async {
    return call('query-major-blocks', params);
  }

  /// 
  Future<JsonRpcResponse> querySynth([Map<String, dynamic>? params]) async {
    return call('query-synth', params);
  }

  /// submits a transaction
  Future<JsonRpcResponse> execute([Map<String, dynamic>? params]) async {
    return call('execute', params);
  }

  /// submits a transaction
  Future<JsonRpcResponse> executeDirect([Map<String, dynamic>? params]) async {
    return call('execute-direct', params);
  }

  /// submits a transaction without routing it. INTENDED FOR INTERNAL USE ONLY
  Future<JsonRpcResponse> executeLocal([Map<String, dynamic>? params]) async {
    return call('execute-local', params);
  }

  /// submits a CreateIdentity transaction
  Future<JsonRpcResponse> executeCreateAdi([Map<String, dynamic>? params]) async {
    return call('create-adi', params);
  }

  /// submits a CreateIdentity transaction
  Future<JsonRpcResponse> executeCreateIdentity([Map<String, dynamic>? params]) async {
    return call('create-identity', params);
  }

  /// submits a CreateDataAccount transaction
  Future<JsonRpcResponse> executeCreateDataAccount([Map<String, dynamic>? params]) async {
    return call('create-data-account', params);
  }

  /// submits a CreateKeyBook transaction
  Future<JsonRpcResponse> executeCreateKeyBook([Map<String, dynamic>? params]) async {
    return call('create-key-book', params);
  }

  /// submits a CreateKeyPage transaction
  Future<JsonRpcResponse> executeCreateKeyPage([Map<String, dynamic>? params]) async {
    return call('create-key-page', params);
  }

  /// submits a CreateToken transaction
  Future<JsonRpcResponse> executeCreateToken([Map<String, dynamic>? params]) async {
    return call('create-token', params);
  }

  /// submits a CreateTokenAccount transaction
  Future<JsonRpcResponse> executeCreateTokenAccount([Map<String, dynamic>? params]) async {
    return call('create-token-account', params);
  }

  /// submits a SendTokens transaction
  Future<JsonRpcResponse> executeSendTokens([Map<String, dynamic>? params]) async {
    return call('send-tokens', params);
  }

  /// submits an AddCredits transaction
  Future<JsonRpcResponse> executeAddCredits([Map<String, dynamic>? params]) async {
    return call('add-credits', params);
  }

  /// submits an UpdateKeyPage transaction
  Future<JsonRpcResponse> executeUpdateKeyPage([Map<String, dynamic>? params]) async {
    return call('update-key-page', params);
  }

  /// submits an UpdateKey transaction
  Future<JsonRpcResponse> executeUpdateKey([Map<String, dynamic>? params]) async {
    return call('update-key', params);
  }

  /// submits a WriteData transaction
  Future<JsonRpcResponse> executeWriteData([Map<String, dynamic>? params]) async {
    return call('write-data', params);
  }

  /// submits an IssueTokens transaction
  Future<JsonRpcResponse> executeIssueTokens([Map<String, dynamic>? params]) async {
    return call('issue-tokens', params);
  }

  /// submits a WriteDataTo transaction
  Future<JsonRpcResponse> executeWriteDataTo([Map<String, dynamic>? params]) async {
    return call('write-data-to', params);
  }

  /// submits a BurnTokens transaction
  Future<JsonRpcResponse> executeBurnTokens([Map<String, dynamic>? params]) async {
    return call('burn-tokens', params);
  }

  /// submits an UpdateAccountAuth transaction
  Future<JsonRpcResponse> executeUpdateAccountAuth([Map<String, dynamic>? params]) async {
    return call('update-account-auth', params);
  }

}
