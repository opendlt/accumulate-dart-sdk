$ErrorActionPreference = "Stop"
Write-Host "== Documentation Generation =="

Write-Host "Generating API documentation..."
dart doc

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Documentation generated successfully!"
    Write-Host "View at: .dart_tool/doc/api/index.html"
} else {
    throw "Documentation generation failed"
}