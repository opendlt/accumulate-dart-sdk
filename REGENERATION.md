# Code Regeneration Guide

This guide demonstrates how to safely regenerate the generated code files and verify that the SDK continues to function correctly.

## Generated Files Location

All generated files are consolidated in:
```
lib/src/generated/
├── api/        # API clients (2 files)
├── types/      # Protocol types (6 files)
└── runtime/    # Validation helpers (3 files)
```

Total: **12 Dart files** that are auto-generated from the Accumulate GitLab Go repository.

## Backup Process

### 1. Create Timestamped Backup
```bash
cd /path/to/opendlt-dart-v2v3-sdk/UNIFIED
mkdir -p _backup_generated_$(date +%Y%m%d_%H%M%S)
cp -r lib/src/generated/* _backup_generated_*/
```

### 2. Verify Backup Integrity
```bash
# Count original files
find lib/src/generated/ -name "*.dart" | wc -l

# Count backup files
find _backup_generated_*/ -name "*.dart" | wc -l

# Should be identical (12 files)
```

## Regeneration Process

### 1. Clean Generated Files
```bash
# Remove only the generated code directories
rm -rf lib/src/generated/api
rm -rf lib/src/generated/types
rm -rf lib/src/generated/runtime

# Keep README.md and pubspec.yaml
ls lib/src/generated/  # Should show only README.md and pubspec.yaml
```

### 2. Verify Impact
```bash
# This should show import errors (expected)
dart analyze lib/ 2>&1 | head -10
```

Expected output:
```
error - Target of URI doesn't exist: 'src/generated/runtime/canon_helpers.dart'
error - Target of URI doesn't exist: 'src/generated/types/accounts_types.dart'
...
```

### 3. Regenerate Files
Run your code generation tool to recreate the files:
```bash
# Your generation command here - this is project-specific
# accumulate-gen-sdk --target=dart --output=lib/src/generated/
```

### 4. Restore Structure
Ensure the regenerated files follow the expected structure:
```
lib/src/generated/
├── api/
│   ├── client.dart
│   └── json_rpc_client.dart
├── types/
│   ├── accounts_types.dart
│   ├── core_types.dart
│   ├── general_types.dart
│   ├── synthetic_transactions_types.dart
│   ├── system_types.dart
│   ├── transaction_types.dart
│   └── user_transactions_types.dart
└── runtime/
    ├── canon_helpers.dart
    ├── errors.dart
    └── validators.dart
```

## Validation Process

### 1. Check File Count
```bash
find lib/src/generated/ -name "*.dart" | wc -l
# Should return: 12
```

### 2. Verify Analysis
```bash
dart analyze lib/
# Should show only warnings, no errors
```

### 3. Run Test Suite
```bash
# Test error handling (quick verification)
dart test test/unit/errors/error_handling_test.dart

# Run all unit tests
dart test test/unit/ --timeout=30s

# Run full test suite (if time permits)
dart test
```

Expected results:
- ✅ **18/18** error handling tests pass
- ✅ **200+** unit tests pass
- ✅ No import errors
- ✅ All functionality intact

## Rollback Process

If regeneration fails or tests don't pass:

### 1. Restore from Backup
```bash
# Remove broken generated files
rm -rf lib/src/generated/api lib/src/generated/types lib/src/generated/runtime

# Restore from backup
cp -r _backup_generated_20241003_175955/* lib/src/generated/

# Verify restoration
find lib/src/generated/ -name "*.dart" | wc -l  # Should be 12
```

### 2. Verify Restoration
```bash
dart analyze lib/  # Should show only warnings
dart test test/unit/errors/error_handling_test.dart  # Should pass 18/18
```

## Important Notes

1. **Never edit generated files manually** - they will be overwritten
2. **Always backup before regeneration** - provides safety net
3. **Test thoroughly after regeneration** - ensures functionality is preserved
4. **Update imports if structure changes** - generated files may have different paths
5. **Keep README.md and pubspec.yaml** - these are not regenerated

## Environment Variables

The regeneration process may use these environment variables:
- `SDK_TEST_OUTPUT` - Custom test output directory
- `ACC_RUN_LIVE` - Enable live network tests
- `ACC_DEVNET_DIR` - DevNet directory location

## Success Indicators

After successful regeneration:
- ✅ 12 Dart files in `lib/src/generated/`
- ✅ `dart analyze lib/` shows only warnings
- ✅ All tests pass
- ✅ No missing import errors
- ✅ SDK functionality unchanged