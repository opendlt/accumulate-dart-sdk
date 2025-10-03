# Test Suite

Comprehensive test suite for the Accumulate Dart SDK, organized by functional concern.

## Test Structure

```
test/
├── unit/               # Unit tests for individual components
│   ├── api/           # API client testing
│   ├── builders/      # Transaction builder tests
│   ├── codec/         # Encoding/decoding tests
│   ├── enums/         # Enum serialization tests
│   ├── errors/        # Error handling tests
│   ├── protocol_types/ # Protocol type validation
│   ├── runtime/       # Runtime helper tests
│   ├── signatures/    # Cryptographic signature tests
│   └── transactions/  # Transaction validation tests
├── conformance/       # Protocol conformance tests
│   ├── codec/         # Binary encoding conformance
│   └── json/          # JSON canonicalization conformance
├── integration/       # End-to-end integration tests
│   └── network/       # Network connectivity tests
├── support/           # Test utilities and helpers
├── golden/            # Golden master test vectors
└── quarantine/        # Experimental or broken tests (excluded by default)
```

## Running Tests

### All Tests
```bash
dart test
```

### By Category
```bash
# Unit tests only
dart test test/unit/

# Conformance tests only
dart test test/conformance/

# Integration tests only
dart test test/integration/
```

### Specific Test Files
```bash
# Single test file
dart test test/unit/errors/error_handling_test.dart

# Pattern matching
dart test -n "JSON"  # Run tests with "JSON" in name
```

## Test Categories

### Unit Tests (`unit/`)
Fast, isolated tests for individual components:

- **API**: Client wrapper functionality and endpoint handling
- **Builders**: Transaction builder validation and construction
- **Codec**: Binary/JSON encoding and decoding logic
- **Enums**: Enum serialization and validation
- **Errors**: Error handling and validation edge cases
- **Protocol Types**: Protocol type validation and constraints
- **Runtime**: Helper functions and validation utilities
- **Signatures**: Cryptographic signature generation and validation
- **Transactions**: Transaction header and body validation

### Conformance Tests (`conformance/`)
Tests against protocol specifications:

- **Binary Encoding**: Matches TypeScript/Go implementations exactly
- **Hash Vectors**: SHA-256 hash conformance with golden files
- **JSON Canonicalization**: Deterministic JSON encoding
- **Envelope Encoding**: Transaction envelope structure validation

### Integration Tests (`integration/`)
End-to-end tests with external dependencies:

- **DevNet E2E**: Full workflow testing against local DevNet
- **Network Smoke Tests**: Basic connectivity and endpoint validation
- **Zero-to-Hero**: Complete user journey from key generation to transactions

## Test Data

### Golden Files (`golden/`)
Reference test vectors for conformance testing:
- `envelope_fixed.golden.json` - Transaction envelope examples
- `sample.golden.json` - General test data
- `sig_ed25519.golden.json` - Ed25519 signature vectors
- `tx_only.golden.json` - Transaction-only test cases

### Test Utilities (`support/`)
- `test_paths.dart` - Path resolution helpers
- `golden_loader.dart` - Golden file loading utilities

## Configuration

### Test Selection by Tags
Tests use tags for categorization:
```bash
# Run only unit tests
dart test -t unit

# Exclude integration tests
dart test -x integration

# Run conformance tests only
dart test -t conformance
```

### Environment Variables
- `ACC_DEVNET_DIR` - DevNet directory for integration tests
- `ACC_RPC_URL_V2` - V2 API endpoint override
- `ACC_RPC_URL_V3` - V3 API endpoint override
- `CI` - Enables CI-specific test behavior

## Writing Tests

### Test Placement
- **Unit tests**: Test single functions/classes in isolation
- **Conformance**: Test against external specifications or golden files
- **Integration**: Test complete workflows requiring external services

### Test Patterns
```dart
import 'package:test/test.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

void main() {
  group('Component Name', () {
    test('should do expected behavior', () {
      // Arrange
      final input = createTestData();

      // Act
      final result = functionUnderTest(input);

      // Assert
      expect(result, equals(expectedOutput));
    });
  });
}
```

### Golden File Tests
```dart
test('should match golden file', () {
  final testData = loadGoldenFile('test_case.golden.json');
  final result = processData(testData.input);
  expect(result, equals(testData.expectedOutput));
});
```

## Test Quality

- **Coverage**: Aim for high test coverage of critical paths
- **Isolation**: Unit tests should not depend on external services
- **Speed**: Unit and conformance tests should run quickly
- **Reliability**: Integration tests should be resilient to network issues
- **Clarity**: Test names should clearly describe what is being tested