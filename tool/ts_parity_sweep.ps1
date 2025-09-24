param(
  [Parameter(Mandatory=$true)][string]$TsRoot,
  [Parameter(Mandatory=$true)][string]$OutFile
)
$ErrorActionPreference = "Stop"

function Grep {
  param([string]$pat, [string]$root)
  $rg = (Get-Command rg -ErrorAction SilentlyContinue)
  if ($rg) {
    rg -n --hidden --no-ignore -S $pat $root
  } else {
    Push-Location $root
    git grep -n -- $pat
    Pop-Location
  }
}

# Heuristic: look for client classes, exported methods, and api v2/v3 namespaces
$lines = @()
$lines += Grep "export class .*Client" $TsRoot
$lines += Grep "export function|export async function|export const .* =" $TsRoot
$lines += Grep "api_v2|api-v2|v2" $TsRoot
$lines += Grep "api_v3|api-v3|v3" $TsRoot
$lines | Set-Content -Encoding UTF8 $OutFile