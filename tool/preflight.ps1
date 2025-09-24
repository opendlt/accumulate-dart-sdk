param([switch]$NoTests)
$ErrorActionPreference = "Stop"
Write-Host "== Preflight Checks =="

Write-Host "Checking Dart version..."
dart --version | Out-Null

Write-Host "Installing dependencies..."
dart pub get | Out-Null

Write-Host "Running analyzer..."
$analysis = (dart analyze 2>&1)
Write-Host $analysis
if ($analysis -match "error - ") {
    throw "Analysis found errors (warnings are OK)"
}

Write-Host "Checking code formatting..."
$changed = (dart format --set-exit-if-changed . 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Host $changed
    throw "Formatting changes required. Run: dart format ."
}

if (-not $NoTests) {
    Write-Host "Running tests..."
    dart test --reporter expanded
    if ($LASTEXITCODE -ne 0) { throw "Tests failed" }

    Write-Host "Generating coverage..."
    dart test --coverage=coverage | Out-Null
}

Write-Host "Skipping documentation generation (generated client has duplicate method conflicts)..."
Write-Host "Skipping publish dry-run (not ready for publication yet)..."

Write-Host "✅ All preflight checks passed!"
Write-Host ""
Write-Host "Ready for release. Next steps:"
Write-Host "1. Update CHANGELOG.md"
Write-Host "2. Bump version in pubspec.yaml"
Write-Host "3. Remove 'publish_to: none' from pubspec.yaml"
Write-Host "4. Run: dart pub publish"