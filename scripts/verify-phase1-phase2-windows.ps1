$ErrorActionPreference = "Stop"

function Test-CommandExists {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Add-ToPathIfExists {
    param([string]$PathToAdd)
    if (-not (Test-Path -LiteralPath $PathToAdd)) {
        return
    }
    $needle = ";" + $PathToAdd + ";"
    $current = ";" + $env:PATH + ";"
    if ($current -notlike "*$needle*") {
        $env:PATH = "$PathToAdd;$env:PATH"
    }
}

function Add-RepoToolsToPath {
    param([string]$ToolsRoot)
    Add-ToPathIfExists "C:\Program Files\Go\bin"
    Add-ToPathIfExists (Join-Path $ToolsRoot "go\current\bin")
    Add-ToPathIfExists (Join-Path $ToolsRoot "gopath\bin")
    Add-ToPathIfExists (Join-Path $ToolsRoot "jdk\current\bin")
    Add-ToPathIfExists (Join-Path $ToolsRoot "jdtls\current\bin")
    Add-ToPathIfExists (Join-Path $ToolsRoot "codebase-memory\current")

    $javaRoots = @(
        "C:\Program Files\Eclipse Adoptium",
        "C:\Program Files\Java"
    )
    foreach ($root in $javaRoots) {
        if (-not (Test-Path -LiteralPath $root)) {
            continue
        }
        $dirs = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
        foreach ($dir in $dirs) {
            Add-ToPathIfExists (Join-Path $dir.FullName "bin")
        }
    }
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
$toolsRoot = Join-Path $repoRoot ".tools"
Add-RepoToolsToPath -ToolsRoot $toolsRoot
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
