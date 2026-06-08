param()

$ErrorActionPreference = "Stop"

function Test-CommandExists {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Write-Check {
    param([string]$Name)
    if (Test-CommandExists $Name) {
        Write-Host "OK   $Name"
        return $true
    }

    Write-Host "MISS $Name"
    return $false
}

function Write-AnyCheck {
    param(
        [string]$Label,
        [string[]]$Commands
    )

    foreach ($cmd in $Commands) {
        if (Test-CommandExists $cmd) {
            Write-Host "OK   $Label ($cmd)"
            return $true
        }
    }

    Write-Host "MISS $Label"
    return $false
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$hasMissing = $false

Write-Host "== Phase 1+2 preflight: Windows =="
Write-Host "This script does not download or install third-party software."
Write-Host ""

$pythonOk = Write-AnyCheck -Label "python" -Commands @("python", "py")
if (-not $pythonOk) {
    $hasMissing = $true
}

$checks = @(
    "git",
    "node",
    "npm",
    "go",
    "java",
    "jdtls",
    "codebase-memory-mcp",
    "mcp-language-server",
    "typescript-language-server"
)

foreach ($cmd in $checks) {
    $ok = Write-Check -Name $cmd
    if (-not $ok) {
        $hasMissing = $true
    }
}

Write-Host ""
Write-Host "Manual installation instructions:"
Write-Host "  $repoRoot\docs\phase1-phase2-deployment.md"
Write-Host ""
Write-Host "After approved tools are installed, run:"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\scripts\verify-phase1-phase2-windows.ps1"

if ($hasMissing) {
    exit 1
}
