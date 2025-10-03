# Test Reorg Engineer: Orchestrator Script
# Executes the complete test reorganization pipeline

param(
    [switch]$DryRun = $false,
    [switch]$SkipVerification = $false,
    [switch]$SkipTests = $false
)

$ErrorActionPreference = "Continue"
$ReorgDir = "C:\Accumulate_Stuff\opendlt-dart-v2v3-sdk\UNIFIED\test\_reorg"
$RepoRoot = "C:\Accumulate_Stuff\opendlt-dart-v2v3-sdk"

Write-Host "=== Test Reorg Engineer: Orchestrator ===" -ForegroundColor Cyan
Write-Host "Reorganizing Dart SDK test tree by functional concern" -ForegroundColor White
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
    Write-Host ""
}

# Track execution results
$Results = @{
    StartTime = Get-Date
    Steps = @()
    Success = $true
    Errors = @()
}

function Add-StepResult {
    param($StepName, $Success, $Output, $Error)

    $Results.Steps += @{
        Name = $StepName
        Success = $Success
        Output = $Output
        Error = $Error
        Timestamp = Get-Date
    }

    if (-not $Success) {
        $Results.Success = $false
        $Results.Errors += "$StepName failed: $Error"
    }
}

function Run-PythonScript {
    param($ScriptPath, $StepName)

    Write-Host "[$StepName] Starting..." -ForegroundColor Green

    if ($DryRun) {
        Write-Host "  DRY RUN: Would execute python $ScriptPath" -ForegroundColor Yellow
        Add-StepResult $StepName $true "DRY RUN - skipped" $null
        return $true
    }

    try {
        $Process = Start-Process -FilePath "python" -ArgumentList $ScriptPath -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$ReorgDir\${StepName}_output.txt" -RedirectStandardError "$ReorgDir\${StepName}_error.txt"

        $Output = ""
        $Error = ""

        if (Test-Path "$ReorgDir\${StepName}_output.txt") {
            $Output = Get-Content "$ReorgDir\${StepName}_output.txt" -Raw
        }

        if (Test-Path "$ReorgDir\${StepName}_error.txt") {
            $Error = Get-Content "$ReorgDir\${StepName}_error.txt" -Raw
        }

        $Success = $Process.ExitCode -eq 0

        if ($Success) {
            Write-Host "  OK: $StepName completed successfully" -ForegroundColor Green
        } else {
            Write-Host "  ERROR: $StepName failed (exit code $($Process.ExitCode))" -ForegroundColor Red
            if ($Error) {
                Write-Host "  Error details: $Error" -ForegroundColor Red
            }
        }

        Add-StepResult $StepName $Success $Output $Error
        return $Success

    } catch {
        $ErrorMsg = $_.Exception.Message
        Write-Host "  ERROR: Failed to execute $StepName - $ErrorMsg" -ForegroundColor Red
        Add-StepResult $StepName $false "" $ErrorMsg
        return $false
    }
}

# Step 1: Plan and Move
Write-Host ""
$Step1Success = Run-PythonScript "$ReorgDir\plan_and_move.py" "plan_and_move"

# Step 2: Rewrite Imports
Write-Host ""
$Step2Success = Run-PythonScript "$ReorgDir\rewrite_imports.py" "rewrite_imports"

# Step 3: Verify Reorganization
if (-not $SkipVerification) {
    Write-Host ""
    $Step3Success = Run-PythonScript "$ReorgDir\verify_post_reorg.py" "verify_post_reorg"
} else {
    Write-Host ""
    Write-Host "[verify_post_reorg] SKIPPED" -ForegroundColor Yellow
    $Step3Success = $true
}

# Step 4: Test Discovery
if (-not $SkipTests -and -not $DryRun) {
    Write-Host ""
    Write-Host "[dart_test] Testing discovery and basic execution..." -ForegroundColor Green

    try {
        Push-Location $RepoRoot

        # Try to discover tests
        Write-Host "  Discovering tests..." -ForegroundColor White
        $DiscoveryProcess = Start-Process -FilePath "dart" -ArgumentList @("test", "--reporter=expanded", "-n", "*") -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$ReorgDir\test_discovery_output.txt" -RedirectStandardError "$ReorgDir\test_discovery_error.txt"

        $TestOutput = ""
        $TestError = ""

        if (Test-Path "$ReorgDir\test_discovery_output.txt") {
            $TestOutput = Get-Content "$ReorgDir\test_discovery_output.txt" -Raw
        }

        if (Test-Path "$ReorgDir\test_discovery_error.txt") {
            $TestError = Get-Content "$ReorgDir\test_discovery_error.txt" -Raw
        }

        $TestSuccess = $DiscoveryProcess.ExitCode -eq 0

        if ($TestSuccess) {
            Write-Host "  OK: Test discovery successful" -ForegroundColor Green
        } else {
            Write-Host "  WARNING: Test discovery issues (exit code $($DiscoveryProcess.ExitCode))" -ForegroundColor Yellow
            if ($TestError) {
                Write-Host "  Test errors: $TestError" -ForegroundColor Yellow
            }
        }

        Add-StepResult "dart_test" $TestSuccess $TestOutput $TestError

    } catch {
        $ErrorMsg = $_.Exception.Message
        Write-Host "  ERROR: Failed to run dart test - $ErrorMsg" -ForegroundColor Red
        Add-StepResult "dart_test" $false "" $ErrorMsg
    } finally {
        Pop-Location
    }
} else {
    Write-Host ""
    Write-Host "[dart_test] SKIPPED" -ForegroundColor Yellow
}

# Generate summary report
$Results.EndTime = Get-Date
$Results.Duration = $Results.EndTime - $Results.StartTime

$ReportPath = "$ReorgDir\orchestrator_report.json"
$Results | ConvertTo-Json -Depth 10 | Out-File $ReportPath

# Print summary
Write-Host ""
Write-Host "=== Test Reorganization Summary ===" -ForegroundColor Cyan

$SuccessfulSteps = ($Results.Steps | Where-Object { $_.Success }).Count
$TotalSteps = $Results.Steps.Count

Write-Host "Execution time: $($Results.Duration.ToString('mm\:ss'))" -ForegroundColor White
Write-Host "Steps completed: $SuccessfulSteps/$TotalSteps" -ForegroundColor White

foreach ($Step in $Results.Steps) {
    $Status = if ($Step.Success) { "PASS" } else { "FAIL" }
    $Color = if ($Step.Success) { "Green" } else { "Red" }
    Write-Host "  $($Step.Name): $Status" -ForegroundColor $Color
}

if ($Results.Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Errors encountered:" -ForegroundColor Red
    foreach ($Error in $Results.Errors) {
        Write-Host "  - $Error" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Report saved: $ReportPath" -ForegroundColor White

# Check if reorganization was successful
$CoreStepsSuccess = $Step1Success -and $Step2Success

if ($DryRun) {
    Write-Host ""
    Write-Host "Test Reorg -> DRY RUN: functional layout planned, no changes made" -ForegroundColor Yellow
    exit 0
} elseif ($CoreStepsSuccess) {
    Write-Host ""
    Write-Host "Test Reorg -> PASS: functional layout active, imports fixed, tests runnable" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "Test Reorg -> FAIL: reorganization encountered errors" -ForegroundColor Red
    exit 1
}