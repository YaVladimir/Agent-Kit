$ErrorActionPreference = "Stop"

function Test-CommandExists {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Write-Result {
    param(
        [string]$Name,
        [bool]$Ok,
        [string]$Details = ""
    )
    if ($Ok) {
        Write-Host "OK   $Name $Details"
    } else {
        Write-Host "FAIL $Name $Details"
    }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$hasErrors = $false

Write-Host "== Проверка фаз 1+2 (Windows) =="

$checks = @(
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
    $ok = Test-CommandExists $cmd
    Write-Result -Name $cmd -Ok $ok
    if (-not $ok) {
        $hasErrors = $true
    }
}

$pythonOk = $false
if (Test-CommandExists "python") {
    try {
        & python -c "import fastmcp, yaml; print('python deps ok')" | Out-Null
        $pythonOk = $true
    } catch {
        $pythonOk = $false
    }
} elseif (Test-CommandExists "py") {
    try {
        & py -3 -c "import fastmcp, yaml; print('python deps ok')" | Out-Null
        $pythonOk = $true
    } catch {
        $pythonOk = $false
    }
}
Write-Result -Name "python + fastmcp/pyyaml" -Ok $pythonOk
if (-not $pythonOk) {
    $hasErrors = $true
}

$configPath = Join-Path $repoRoot ".qwen\settings.json"
$configOk = Test-Path -LiteralPath $configPath
Write-Result -Name ".qwen/settings.json" -Ok $configOk -Details $configPath
if (-not $configOk) {
    $hasErrors = $true
}

if ($hasErrors) {
    Write-Host "Проверка завершилась с ошибками."
    exit 1
}

Write-Host "Проверка фаз 1+2 прошла успешно."

