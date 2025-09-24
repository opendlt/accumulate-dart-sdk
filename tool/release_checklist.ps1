$ErrorActionPreference = "Stop"
Write-Host @"
📋 Release Checklist for opendlt-accumulate
==========================================

Pre-Release:
□ 1. Update CHANGELOG.md with new version and features
□ 2. Bump version in pubspec.yaml (e.g., 1.0.0 -> 1.0.1)
□ 3. Run preflight checks: .\tool\preflight.ps1
□ 4. Commit all changes: git add -A && git commit -m "Release vX.Y.Z"
□ 5. Tag release: git tag vX.Y.Z && git push --tags

Publishing:
□ 6. Remove or comment out 'publish_to: none' in pubspec.yaml
□ 7. Final dry-run: dart pub publish --dry-run
□ 8. Publish to pub.dev: dart pub publish

Post-Release:
□ 9. Re-add 'publish_to: none' for development
□ 10. Update README.md with new installation instructions
□ 11. Create GitHub release with changelog notes

🚀 SDK Features to Highlight:
- Bit-for-bit compatible signing with Go/TypeScript
- Ed25519 crypto with LID/LTA derivation
- Transaction builders for all v3 operations
- Unified v2+v3 JSON-RPC client
- Comprehensive test coverage with golden files
- CLI tools and runnable examples
- Flutter/web friendly (pure Dart crypto)
"@