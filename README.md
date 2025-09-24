# OpenDLT Accumulate Dart SDK (V2 + V3)

**Status:** scaffolding complete. Generated core files are left intact; this layer adds a clean, idiomatic API.

## Install (local path)

```yaml
# pubspec.yaml (consumer)
dependencies:
  opendlt_accumulate:
    path: ../opendlt-dart-v2v3-sdk/unified
```

## Quickstart

```dart
import "package:opendlt_accumulate/opendlt_accumulate.dart";

void main() async {
  final acc = Accumulate.network(NetworkEndpoint.mainnet);

  final res = await acc.query({
    "type": "query-account",
    "url": "acc://accumulatenetwork.acme",
  });

  print(res);
  acc.close();
}
```

## API Design

- **Unified facade**: `Accumulate` exposes `.v2` and `.v3`
- **Defaults**: `submit()` and `query()` point to V3
- **Legacy**: `v2.executeDirect()` is available when needed
- **Escape hatches**: `rawCall()` on both versions

## Endpoints

- **Mainnet**: https://mainnet.accumulatenetwork.io
- **Testnet**: https://testnet.accumulatenetwork.io
- **Devnet**: http://localhost:26660 (adjust as needed)

## Generated Files (do not edit)

- `lib/accumulate_client.dart`
- `lib/types.dart`
- `lib/src/json_rpc_client.dart`

These are produced by the Accumulate gen-sdk tool. This package only layers additional organization on top.