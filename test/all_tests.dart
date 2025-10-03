// GENERATED - Do not edit.
// Master test suite for reorganized Dart SDK tests
//
// This file imports all test files and provides entry points for
// running tests by functional category.

library all_tests;

import 'dart:io';

// Support utilities
import 'support/test_paths.dart';
import 'support/golden_loader.dart';

// Unit tests
import 'unit/enums/enum_serialization_test.dart' as enum_serialization;
import 'unit/runtime/basic_test.dart' as basic_runtime;
import 'unit/runtime/runtime_helpers_test.dart' as runtime_helpers;
import 'unit/codec/json_serialization_test.dart' as json_serialization;
import 'unit/signatures/delegation_depth_test.dart' as delegation_depth;
import 'unit/signatures/signature_structure_test.dart' as signature_structure;
import 'unit/transactions/field_validation_test.dart' as field_validation;
import 'unit/transactions/transaction_bodies_test.dart' as transaction_bodies;
import 'unit/transactions/transaction_dispatcher_test.dart' as transaction_dispatcher;
import 'unit/transactions/transaction_header_test.dart' as transaction_header;
import 'unit/protocol_types/hash_validation_test.dart' as hash_validation;
import 'unit/protocol_types/protocol_types_validation_test.dart' as protocol_types_validation;
import 'unit/protocol_types/type_serialization_test.dart' as type_serialization;
import 'unit/errors/error_handling_test.dart' as error_handling;
import 'unit/api/api_client_test.dart' as api_client;
import 'unit/builders/builder_signing_test.dart' as builder_signing;

// Conformance tests
import 'conformance/codec/binary_encoding_test.dart' as binary_encoding;
import 'conformance/codec/binary_roundtrip_test.dart' as binary_roundtrip;
import 'conformance/codec/envelope_encoding_test.dart' as envelope_encoding;
import 'conformance/codec/hash_vectors_test.dart' as hash_vectors;
import 'conformance/json/canonical_json_test.dart' as canonical_json;
import 'conformance/json/canonical_json_conformance_test.dart' as canonical_json_conformance;

// Integration tests
import 'integration/network/devnet_e2e_test.dart' as devnet_e2e;
import 'integration/network/smoke_endpoints_test.dart' as smoke_endpoints;
import 'integration/network/zero_to_hero_devnet_test.dart' as zero_to_hero;

/// Main entry point - imports all tests for side effects
/// Individual test files define their own main() functions
void main() {
  // This main() function serves as an aggregator.
  // The actual test execution happens in individual test files.
  //
  // To run specific categories:
  // - Unit tests: dart test UNIFIED/test/unit/
  // - Conformance: dart test UNIFIED/test/conformance/
  // - Integration: dart test UNIFIED/test/integration/
  // - All tests: dart test UNIFIED/test/

  print('Dart SDK Test Suite - Reorganized by Functional Concern');
  print('');
  print('Available test categories:');
  print('  unit/        - Unit tests for individual components');
  print('  conformance/ - Conformance tests against specifications');
  print('  integration/ - Integration tests with external services');
  print('  quarantine/  - Experimental or broken tests (excluded by default)');
  print('');
  print('Run with: dart test [category_path]');
  print('Example: dart test UNIFIED/test/unit/');
}

/// Test discovery helpers
class TestDiscovery {
  /// Get all unit test files
  static List<String> get unitTests => [
    'unit/enums/enum_serialization_test.dart',
    'unit/runtime/basic_test.dart',
    'unit/runtime/runtime_helpers_test.dart',
    'unit/codec/json_serialization_test.dart',
    'unit/signatures/delegation_depth_test.dart',
    'unit/signatures/signature_structure_test.dart',
    'unit/transactions/field_validation_test.dart',
    'unit/transactions/transaction_bodies_test.dart',
    'unit/transactions/transaction_dispatcher_test.dart',
    'unit/transactions/transaction_header_test.dart',
    'unit/protocol_types/hash_validation_test.dart',
    'unit/protocol_types/protocol_types_validation_test.dart',
    'unit/protocol_types/type_serialization_test.dart',
    'unit/errors/error_handling_test.dart',
    'unit/api/api_client_test.dart',
    'unit/builders/builder_signing_test.dart',
  ];

  /// Get all conformance test files
  static List<String> get conformanceTests => [
    'conformance/codec/binary_encoding_test.dart',
    'conformance/codec/binary_roundtrip_test.dart',
    'conformance/codec/envelope_encoding_test.dart',
    'conformance/codec/hash_vectors_test.dart',
    'conformance/json/canonical_json_test.dart',
    'conformance/json/canonical_json_conformance_test.dart',
  ];

  /// Get all integration test files
  static List<String> get integrationTests => [
    'integration/network/devnet_e2e_test.dart',
    'integration/network/smoke_endpoints_test.dart',
    'integration/network/zero_to_hero_devnet_test.dart',
  ];

  /// Get all test files (excluding quarantine)
  static List<String> get allTests => [
    ...unitTests,
    ...conformanceTests,
    ...integrationTests,
  ];

  /// Check if reorganization is complete
  static bool get isReorganized {
    return testDirExists('unit') &&
           testDirExists('conformance') &&
           testDirExists('integration') &&
           testDirExists('support');
  }

  /// Get reorganization status
  static Map<String, dynamic> get status {
    return {
      'reorganized': isReorganized,
      'unit_tests': unitTests.length,
      'conformance_tests': conformanceTests.length,
      'integration_tests': integrationTests.length,
      'total_tests': allTests.length,
      'golden_files_available': Directory(goldenDir()).existsSync(),
    };
  }
}