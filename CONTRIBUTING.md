# Contributing to opendlt-accumulate

Thank you for your interest in contributing to the Accumulate Dart SDK!

## Development Setup

1. Ensure you have Dart SDK 3.3.0+ installed
2. Clone the repository
3. Run `dart pub get` to install dependencies
4. Run `.\tool\preflight.ps1` to validate your setup

## Code Guidelines

### Do NOT Edit Generated Files
- `lib/accumulate_client.dart` - Generated unified v2+v3 client
- `lib/types.dart` - Generated type definitions
- `lib/src/json_rpc_client.dart` - Generated JSON-RPC client

These files are regenerated from the Go repository using `gen-sdk`. If changes are needed, update the generator templates instead.

### Code Standards
- Run `dart format .` before committing
- Ensure `dart analyze` passes with no issues
- Write tests for new functionality
- Follow existing code patterns and naming conventions
- Add inline documentation for public APIs

### Testing
- All tests must pass: `dart test`
- Add golden file tests for encoding/signing compatibility
- Include both unit tests and integration tests
- Test examples to ensure they work end-to-end

## Submitting Changes

1. **Run Preflight Checks**
   ```bash
   .\tool\preflight.ps1
   ```

2. **Commit Standards**
   - Use clear, descriptive commit messages
   - Reference issues when applicable
   - Keep commits focused and atomic

3. **Pull Request Process**
   - Ensure all tests pass
   - Update documentation if needed
   - Add entry to CHANGELOG.md
   - Request review from maintainers

## Cross-Language Compatibility

This SDK maintains bit-for-bit compatibility with Go and TypeScript implementations:

- **Signing**: Must match preimage construction exactly
- **Encoding**: Binary codecs must produce identical bytes
- **LID/LTA**: Key derivation must match character-for-character
- **Golden Tests**: Use shared test vectors when possible

Any changes to cryptographic or encoding logic must be verified against reference implementations.

## Release Process

See `.\tool\release_checklist.ps1` for the complete release workflow.

## Questions?

- Open an issue for bugs or feature requests
- Check existing issues before creating new ones
- Be respectful and constructive in all interactions