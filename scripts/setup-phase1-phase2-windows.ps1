param(
    [switch]$NoInstall,
    [string]$PythonExe = ""
)

$ErrorActionPreference = "Stop"

function Test-CommandExists {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Resolve-PythonCommand {
    param([string]$UserPythonExe)
    if ($UserPythonExe -and (Test-Path -LiteralPath $UserPythonExe)) {
        return @($UserPythonExe)
    }
    if (Test-CommandExists "python") {
        return @("python")
    }
    if (Test-CommandExists "py") {
        return @("py", "-3")
    }
    return @()
}

function Invoke-Python {
    param(
        [string[]]$PythonCmd,
        [string[]]$Args
    )
    if ($PythonCmd.Count -eq 1) {
        & $PythonCmd[0] @Args
        return
    }
    & $PythonCmd[0] $PythonCmd[1] @Args
}

function Install-WithWinget {
    param([string]$Id)
    & winget install --id $Id -e --accept-package-agreements --accept-source-agreements
}

function Install-WithChoco {
    param([string]$Package)
    & choco install $Package -y
}

function Ensure-Tool {
    param(
        [string]$Name,
        [string]$WingetId,
        [string]$ChocoPackage
    )
    if (Test-CommandExists $Name) {
        Write-Host "OK: найдено $Name"
        return
    }
    if ($NoInstall) {
        throw "Не найдено $Name (режим NoInstall)."
    }

    if (Test-CommandExists "winget") {
        Write-Host "Ставлю $Name через winget ($WingetId)..."
        Install-WithWinget $WingetId
    } elseif (Test-CommandExists "choco") {
        Write-Host "Ставлю $Name через choco ($ChocoPackage)..."
        Install-WithChoco $ChocoPackage
    } else {
        throw "Не найдено $Name и нет winget/choco для установки."
    }

    if (-not (Test-CommandExists $Name)) {
        throw "$Name не появился в PATH после установки. Перезапусти терминал и повтори."
    }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Write-Host "== Фазы 1+2: Windows setup =="

Ensure-Tool -Name "node" -WingetId "OpenJS.NodeJS" -ChocoPackage "nodejs"

if (-not (Test-CommandExists "npm")) {
    throw "npm не найден. Проверь установку Node.js."
}

Ensure-Tool -Name "go" -WingetId "GoLang.Go" -ChocoPackage "golang"
Ensure-Tool -Name "java" -WingetId "EclipseAdoptium.Temurin.17.JDK" -ChocoPackage "temurin17jdk"

$pythonCmd = Resolve-PythonCommand -UserPythonExe $PythonExe
if ($pythonCmd.Count -eq 0) {
    if ($NoInstall) {
        throw "Python не найден (режим NoInstall)."
    }
    if (Test-CommandExists "winget") {
        Write-Host "Ставлю Python через winget..."
        Install-WithWinget "Python.Python.3.12"
    } elseif (Test-CommandExists "choco") {
        Write-Host "Ставлю Python через choco..."
        Install-WithChoco "python"
    } else {
        throw "Python не найден и нет winget/choco для установки."
    }
    $pythonCmd = Resolve-PythonCommand -UserPythonExe $PythonExe
    if ($pythonCmd.Count -eq 0) {
        throw "Python не найден после установки. Перезапусти терминал и повтори."
    }
}
Write-Host "OK: Python команда: $($pythonCmd -join ' ')"

if (-not (Test-CommandExists "jdtls")) {
    if ($NoInstall) {
        throw "jdtls не найден (режим NoInstall). Установи jdtls и добавь его в PATH."
    }
    throw @"
jdtls не найден в PATH.
Автоустановка jdtls на Windows часто нестабильна через пакетные менеджеры.
Рекомендованный путь:
1) Скачать jdtls milestone архив с https://download.eclipse.org/jdtls/milestones/
2) Распаковать в папку, например C:\tools\jdtls
3) Добавить C:\tools\jdtls\bin в PATH
4) Проверить: jdtls --version
"@
}
Write-Host "OK: найден jdtls"

if (-not (Test-CommandExists "codebase-memory-mcp")) {
    if ($NoInstall) {
        throw "codebase-memory-mcp не найден (режим NoInstall)."
    }
    throw @"
codebase-memory-mcp не найден в PATH.
Установи бинарник codebase-memory-mcp для Windows из релизов проекта и добавь его в PATH.
"@
}
Write-Host "OK: найден codebase-memory-mcp"

Write-Host "== mcp-language-server =="
& go install github.com/isaacphi/mcp-language-server@latest
$goBin = (& go env GOPATH).Trim() + "\bin"
if (Test-Path -LiteralPath $goBin) {
    $env:PATH = "$goBin;$env:PATH"
}

if (-not (Test-CommandExists "mcp-language-server")) {
    throw "mcp-language-server не найден после go install."
}
Write-Host "OK: найден mcp-language-server"

Write-Host "== TypeScript LSP =="
& cmd /c npm install -g typescript typescript-language-server

Write-Host "== Python зависимости MCP =="
Invoke-Python -PythonCmd $pythonCmd -Args @("-m", "pip", "install", "--upgrade", "pip")
Invoke-Python -PythonCmd $pythonCmd -Args @("-m", "pip", "install", "fastmcp", "pyyaml")

Write-Host "== Конфиг MCP =="
$qwenDir = Join-Path $repoRoot ".qwen"
if (-not (Test-Path -LiteralPath $qwenDir)) {
    New-Item -ItemType Directory -Path $qwenDir | Out-Null
}
Copy-Item -LiteralPath (Join-Path $repoRoot "templates\qwen-settings.phase1-phase2.json") -Destination (Join-Path $qwenDir "settings.json") -Force
Write-Host "Скопирован: $qwenDir\settings.json"

Write-Host "Готово. Запусти проверку:"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\scripts\verify-phase1-phase2-windows.ps1"

