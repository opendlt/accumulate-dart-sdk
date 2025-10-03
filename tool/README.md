# Development Tools

Build and development tools for the Accumulate Dart SDK.

## Available Tools

### `docs.ps1`
Generates API documentation using dartdoc.

```powershell
# Generate documentation
.\tool\docs.ps1
```

Output: `.dart_tool/doc/api/index.html`

### `preflight.ps1`
Pre-commit checks for code quality and correctness.

```powershell
# Run all checks
.\tool\preflight.ps1

# Skip tests (faster for quick checks)
.\tool\preflight.ps1 -NoTests
```

Performs:
- Dart version check
- Dependency installation (`dart pub get`)
- Code analysis (`dart analyze`)
- Full test suite (unless `-NoTests` specified)

### `release_checklist.ps1`
Release preparation checklist and validation.

```powershell
# Validate release readiness
.\tool\release_checklist.ps1
```

Checks:
- All tests pass
- Documentation is up to date
- Version numbers are consistent
- No uncommitted changes

### `ts_parity_sweep.ps1`
Cross-language compatibility testing with TypeScript implementation.

```powershell
# Run parity checks
.\tool\ts_parity_sweep.ps1
```

Validates:
- Binary encoding matches TypeScript output
- Hash calculations are identical
- JSON canonicalization is consistent

### `export_random_vectors.dart`
Generates deterministic random test vectors for cross-language validation.

```bash
# Generate 100 random vectors (default)
dart run tool/export_random_vectors.dart > test/golden/random_vectors.jsonl

# Generate specific count
dart run tool/export_random_vectors.dart 1000 > test/golden/large_vectors.jsonl
```

Output format (JSON Lines):
```json
{"seed": 42, "envelope": {...}, "canonicalJson": "...", "binaryHex": "...", "hash": "..."}
{"seed": 43, "envelope": {...}, "canonicalJson": "...", "binaryHex": "...", "hash": "..."}
```

## Development Workflow

### Before Committing
```powershell
# Run preflight checks
.\tool\preflight.ps1

# If all passes, commit is ready
git add .
git commit -m "Your changes"
```

### Before Releasing
```powershell
# Full release validation
.\tool\release_checklist.ps1

# Generate fresh documentation
.\tool\docs.ps1

# Verify cross-language compatibility
.\tool\ts_parity_sweep.ps1
```

### Generating Test Vectors
```bash
# Create conformance test data
dart run tool/export_random_vectors.dart 500 > test/golden/conformance_vectors.jsonl

# Update golden files
git add test/golden/
git commit -m "Update golden test vectors"
```

## Tool Dependencies

- **PowerShell 5.0+** (for .ps1 scripts)
- **Dart SDK 3.0+**
- **Git** (for release checklist)

## Cross-Platform Notes

- PowerShell scripts work on Windows, macOS, and Linux with PowerShell Core
- Dart scripts are fully cross-platform
- Path separators are handled automatically

## Adding New Tools

When adding new tools:

1. Place scripts in `tool/` directory
2. Use `.ps1` for system/build tasks
3. Use `.dart` for SDK-specific functionality
4. Add documentation to this README
5. Include usage examples