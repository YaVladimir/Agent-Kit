param(
    [switch]$NoInstall,
    [string]$PythonExe = ""
)

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

function Refresh-PathFromRegistry {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $parts = @()
    if ($userPath) { $parts += $userPath }
    if ($machinePath) { $parts += $machinePath }
    if ($env:PATH) { $parts += $env:PATH }
    $env:PATH = ($parts -join ";")
}

function Add-RepoToolsToPath {
    param([string]$ToolsRoot)

    Add-ToPathIfExists (Join-Path $ToolsRoot "go\current\bin")
    Add-ToPathIfExists (Join-Path $ToolsRoot "gopath\bin")
    Add-ToPathIfExists (Join-Path $ToolsRoot "jdk\current\bin")
    Add-ToPathIfExists (Join-Path $ToolsRoot "jdtls\current\bin")
    Add-ToPathIfExists (Join-Path $ToolsRoot "codebase-memory\current")
}

function Add-WellKnownJavaPaths {
    $roots = @(
        "C:\Program Files\Eclipse Adoptium",
        "C:\Program Files\Java"
    )
    foreach ($root in $roots) {
        if (-not (Test-Path -LiteralPath $root)) {
            continue
        }
        $dirs = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
        foreach ($dir in $dirs) {
            Add-ToPathIfExists (Join-Path $dir.FullName "bin")
        }
    }
}

function New-CleanDirectory {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
    New-Item -ItemType Directory -Path $Path | Out-Null
}

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Download-File {
    param(
        [string]$Url,
        [string]$Destination
    )
    Write-Host "Downloading: $Url"
    Invoke-WebRequest -Uri $Url -OutFile $Destination
}

function Resolve-PythonCommand {
    param([string]$UserPythonExe)
    function Test-PythonCandidate {
        param([string[]]$Candidate)
        try {
            if ($Candidate.Count -eq 1) {
                & $Candidate[0] --version *> $null
            } else {
                & $Candidate[0] $Candidate[1] --version *> $null
            }
            return $LASTEXITCODE -eq 0
        } catch {
            return $false
        }
    }

    if ($UserPythonExe -and (Test-Path -LiteralPath $UserPythonExe)) {
        $candidate = @($UserPythonExe)
        if (Test-PythonCandidate -Candidate $candidate) {
            return $candidate
        }
    }
    if (Test-CommandExists "python") {
        $candidate = @("python")
        if (Test-PythonCandidate -Candidate $candidate) {
            return $candidate
        }
    }
    if (Test-CommandExists "py") {
        $candidate = @("py", "-3")
        if (Test-PythonCandidate -Candidate $candidate) {
            return $candidate
        }
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
    Refresh-PathFromRegistry
}

function Install-WithChoco {
    param([string]$Package)
    & choco install $Package -y
    Refresh-PathFromRegistry
}

function Install-GoPortable {
    param(
        [string]$ToolsRoot,
        [string]$DownloadsRoot
    )
    $goApi = "https://go.dev/dl/?mode=json"
    $releases = Invoke-RestMethod -Uri $goApi
    $selectedFile = $null
    foreach ($release in $releases) {
        foreach ($file in $release.files) {
            if ($file.os -eq "windows" -and $file.arch -eq "amd64" -and $file.kind -eq "archive" -and $file.filename -like "*.zip") {
                $selectedFile = $file.filename
                break
            }
        }
        if ($selectedFile) { break }
    }
    if (-not $selectedFile) {
        throw "Could not resolve Go archive for windows-amd64."
    }

    $zipPath = Join-Path $DownloadsRoot $selectedFile
    Download-File -Url ("https://go.dev/dl/" + $selectedFile) -Destination $zipPath

    $goRootBase = Join-Path $ToolsRoot "go"
    Ensure-Directory $goRootBase
    $extractDir = Join-Path $goRootBase ("tmp-" + [System.Guid]::NewGuid().ToString("N"))
    New-CleanDirectory $extractDir
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force

    $sourceGoDir = Join-Path $extractDir "go"
    if (-not (Test-Path -LiteralPath (Join-Path $sourceGoDir "bin\go.exe"))) {
        throw "Go archive unpacked, but go.exe was not found."
    }

    $targetGoDir = Join-Path $goRootBase "current"
    if (Test-Path -LiteralPath $targetGoDir) {
        Remove-Item -LiteralPath $targetGoDir -Recurse -Force
    }
    Move-Item -LiteralPath $sourceGoDir -Destination $targetGoDir
    Remove-Item -LiteralPath $extractDir -Recurse -Force
}

function Install-JavaPortable {
    param(
        [string]$ToolsRoot,
        [string]$DownloadsRoot
    )
    $javaUrl = "https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse"
    $zipPath = Join-Path $DownloadsRoot "temurin-jdk17-windows-x64.zip"
    Download-File -Url $javaUrl -Destination $zipPath

    $jdkRootBase = Join-Path $ToolsRoot "jdk"
    Ensure-Directory $jdkRootBase
    $extractDir = Join-Path $jdkRootBase ("tmp-" + [System.Guid]::NewGuid().ToString("N"))
    New-CleanDirectory $extractDir
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force

    $jdkCandidates = Get-ChildItem -LiteralPath $extractDir -Directory -ErrorAction SilentlyContinue
    if (-not $jdkCandidates) {
        throw "JDK archive unpacked, but no JDK directory was found."
    }

    $selected = $null
    foreach ($candidate in $jdkCandidates) {
        if (Test-Path -LiteralPath (Join-Path $candidate.FullName "bin\java.exe")) {
            $selected = $candidate.FullName
            break
        }
    }
    if (-not $selected) {
        throw "bin\\java.exe was not found after JDK unpack."
    }

    $targetJdkDir = Join-Path $jdkRootBase "current"
    if (Test-Path -LiteralPath $targetJdkDir) {
        Remove-Item -LiteralPath $targetJdkDir -Recurse -Force
    }
    Move-Item -LiteralPath $selected -Destination $targetJdkDir
    Remove-Item -LiteralPath $extractDir -Recurse -Force
}

function Install-CodebaseMemoryPortable {
    param(
        [string]$ToolsRoot,
        [string]$DownloadsRoot
    )
    $serverSpecUrl = "https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/server.json"
    $spec = Invoke-RestMethod -Uri $serverSpecUrl
    $assetUrl = $null
    foreach ($pkg in $spec.packages) {
        if ($pkg.identifier -like "*windows-amd64.zip") {
            $assetUrl = $pkg.identifier
            break
        }
    }
    if (-not $assetUrl) {
        throw "Could not find windows-amd64 package for codebase-memory-mcp in server.json."
    }

    $zipPath = Join-Path $DownloadsRoot "codebase-memory-mcp-windows-amd64.zip"
    Download-File -Url $assetUrl -Destination $zipPath

    $baseRoot = Join-Path $ToolsRoot "codebase-memory"
    Ensure-Directory $baseRoot
    $extractDir = Join-Path $baseRoot ("tmp-" + [System.Guid]::NewGuid().ToString("N"))
    New-CleanDirectory $extractDir
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force

    $exePath = Get-ChildItem -LiteralPath $extractDir -Recurse -File -Filter "codebase-memory-mcp*.exe" | Select-Object -First 1
    if (-not $exePath) {
        throw "codebase-memory-mcp .exe was not found in the archive."
    }

    $targetDir = Join-Path $baseRoot "current"
    if (Test-Path -LiteralPath $targetDir) {
        Remove-Item -LiteralPath $targetDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $targetDir | Out-Null
    Copy-Item -LiteralPath $exePath.FullName -Destination (Join-Path $targetDir "codebase-memory-mcp.exe") -Force
    Remove-Item -LiteralPath $extractDir -Recurse -Force
}

function Install-JdtlsPortable {
    param(
        [string]$ToolsRoot,
        [string]$DownloadsRoot
    )
    $url = "https://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz"
    $archivePath = Join-Path $DownloadsRoot "jdt-language-server-latest.tar.gz"
    Download-File -Url $url -Destination $archivePath

    $jdtlsRoot = Join-Path $ToolsRoot "jdtls"
    Ensure-Directory $jdtlsRoot
    $extractDir = Join-Path $jdtlsRoot ("tmp-" + [System.Guid]::NewGuid().ToString("N"))
    New-CleanDirectory $extractDir

    & tar.exe -xzf $archivePath -C $extractDir
    if ($LASTEXITCODE -ne 0) {
        throw "tar could not unpack jdtls archive."
    }

    $binScript = Get-ChildItem -LiteralPath $extractDir -Recurse -File -Filter "jdtls" | Select-Object -First 1
    if (-not $binScript) {
        throw "jdtls launcher script was not found after unpack."
    }
    $rootDir = Split-Path -Parent (Split-Path -Parent $binScript.FullName)

    $targetDir = Join-Path $jdtlsRoot "current"
    if (Test-Path -LiteralPath $targetDir) {
        Remove-Item -LiteralPath $targetDir -Recurse -Force
    }
    Move-Item -LiteralPath $rootDir -Destination $targetDir
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$toolsRoot = Join-Path $repoRoot ".tools"
$downloadsRoot = Join-Path $toolsRoot "downloads"
Ensure-Directory $toolsRoot
Ensure-Directory $downloadsRoot
Refresh-PathFromRegistry
Add-RepoToolsToPath -ToolsRoot $toolsRoot
Add-WellKnownJavaPaths

Write-Host "== Phase 1+2: Windows setup =="

if (-not (Test-CommandExists "node")) {
    if ($NoInstall) {
        throw "node not found (NoInstall mode)."
    }
    if (Test-CommandExists "winget") {
        Write-Host "Installing node via winget..."
        Install-WithWinget "OpenJS.NodeJS"
    } elseif (Test-CommandExists "choco") {
        Write-Host "Installing node via choco..."
        Install-WithChoco "nodejs"
    } else {
        throw "node not found and winget/choco unavailable."
    }
}
Write-Host "OK: node found"

if (-not (Test-CommandExists "npm")) {
    throw "npm not found. Check Node.js install."
}

if (-not (Test-CommandExists "go")) {
    if ($NoInstall) {
        throw "go not found (NoInstall mode)."
    }
    if (Test-CommandExists "winget") {
        Write-Host "Installing go via winget..."
        Install-WithWinget "GoLang.Go"
    } elseif (Test-CommandExists "choco") {
        Write-Host "Installing go via choco..."
        Install-WithChoco "golang"
    } else {
        Write-Host "winget/choco unavailable. Installing portable Go..."
        Install-GoPortable -ToolsRoot $toolsRoot -DownloadsRoot $downloadsRoot
    }
    Add-ToPathIfExists "C:\Program Files\Go\bin"
    Add-RepoToolsToPath -ToolsRoot $toolsRoot
}
Write-Host "OK: go found"

if (-not (Test-CommandExists "java")) {
    if ($NoInstall) {
        throw "java not found (NoInstall mode)."
    }
    if (Test-CommandExists "winget") {
        Write-Host "Installing Java via winget..."
        Install-WithWinget "EclipseAdoptium.Temurin.17.JDK"
    } elseif (Test-CommandExists "choco") {
        Write-Host "Installing Java via choco..."
        Install-WithChoco "temurin17jdk"
    } else {
        Write-Host "winget/choco unavailable. Installing portable JDK 17..."
        Install-JavaPortable -ToolsRoot $toolsRoot -DownloadsRoot $downloadsRoot
    }
    Add-RepoToolsToPath -ToolsRoot $toolsRoot
    Add-WellKnownJavaPaths
}
Write-Host "OK: java found"

$pythonCmd = Resolve-PythonCommand -UserPythonExe $PythonExe
if ($pythonCmd.Count -eq 0) {
    if ($NoInstall) {
        throw "python not found (NoInstall mode)."
    }
    if (Test-CommandExists "winget") {
        Write-Host "Installing Python via winget..."
        Install-WithWinget "Python.Python.3.12"
    } elseif (Test-CommandExists "choco") {
        Write-Host "Installing Python via choco..."
        Install-WithChoco "python"
    } else {
        throw "python not found and winget/choco unavailable."
    }
    $pythonCmd = Resolve-PythonCommand -UserPythonExe $PythonExe
    if ($pythonCmd.Count -eq 0) {
        throw "python still not found after install. Restart terminal and retry."
    }
}
Write-Host ("OK: python command: " + ($pythonCmd -join " "))

if (-not (Test-CommandExists "jdtls")) {
    if ($NoInstall) {
        throw "jdtls not found (NoInstall mode)."
    }
    Write-Host "Installing portable jdtls..."
    Install-JdtlsPortable -ToolsRoot $toolsRoot -DownloadsRoot $downloadsRoot
    Add-RepoToolsToPath -ToolsRoot $toolsRoot
}
if (-not (Test-CommandExists "jdtls")) {
    throw "jdtls not found after install."
}
Write-Host "OK: jdtls found"

if (-not (Test-CommandExists "codebase-memory-mcp")) {
    if ($NoInstall) {
        throw "codebase-memory-mcp not found (NoInstall mode)."
    }
    Write-Host "Installing portable codebase-memory-mcp..."
    Install-CodebaseMemoryPortable -ToolsRoot $toolsRoot -DownloadsRoot $downloadsRoot
    Add-RepoToolsToPath -ToolsRoot $toolsRoot
}
if (-not (Test-CommandExists "codebase-memory-mcp")) {
    throw "codebase-memory-mcp not found after install."
}
Write-Host "OK: codebase-memory-mcp found"

Write-Host "== mcp-language-server =="
$goRootPortable = Join-Path $toolsRoot "go\current"
if (Test-Path -LiteralPath (Join-Path $goRootPortable "bin\go.exe")) {
    $env:GOROOT = $goRootPortable
}
Add-ToPathIfExists "C:\Program Files\Go\bin"
Add-ToPathIfExists (Join-Path $goRootPortable "bin")
$env:GOPATH = Join-Path $toolsRoot "gopath"
Ensure-Directory $env:GOPATH
Add-ToPathIfExists (Join-Path $env:GOPATH "bin")
$goCmd = Get-Command go -ErrorAction SilentlyContinue
if (-not $goCmd) {
    throw "go not found in PATH before mcp-language-server install."
}
& $goCmd.Source install github.com/isaacphi/mcp-language-server@latest
Add-ToPathIfExists (Join-Path $env:GOPATH "bin")

if (-not (Test-CommandExists "mcp-language-server")) {
    throw "mcp-language-server not found after go install."
}
Write-Host "OK: mcp-language-server found"

Write-Host "== TypeScript LSP =="
& cmd /c npm install -g typescript typescript-language-server

Write-Host "== Python MCP deps =="
Invoke-Python -PythonCmd $pythonCmd -Args @("-m", "pip", "install", "--upgrade", "pip")
Invoke-Python -PythonCmd $pythonCmd -Args @("-m", "pip", "install", "fastmcp", "pyyaml")

Write-Host "== MCP config =="
$qwenDir = Join-Path $repoRoot ".qwen"
if (-not (Test-Path -LiteralPath $qwenDir)) {
    New-Item -ItemType Directory -Path $qwenDir | Out-Null
}
Copy-Item -LiteralPath (Join-Path $repoRoot "templates\qwen-settings.phase1-phase2.json") -Destination (Join-Path $qwenDir "settings.json") -Force
Write-Host "Copied: $qwenDir\settings.json"

Write-Host "== Session env =="
Write-Host "GOROOT=$env:GOROOT"
Write-Host "GOPATH=$env:GOPATH"
Write-Host "Add to persistent PATH:"
Write-Host "  $toolsRoot\go\current\bin"
Write-Host "  $toolsRoot\gopath\bin"
Write-Host "  $toolsRoot\jdk\current\bin"
Write-Host "  $toolsRoot\jdtls\current\bin"
Write-Host "  $toolsRoot\codebase-memory\current"

Write-Host "Done. Run verification:"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\scripts\verify-phase1-phase2-windows.ps1"
