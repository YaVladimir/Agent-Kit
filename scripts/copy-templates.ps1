param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryPath
)

$ErrorActionPreference = "Stop"

$kitRoot = Split-Path -Parent $PSScriptRoot
$target = Resolve-Path -LiteralPath $RepositoryPath

Copy-Item -LiteralPath (Join-Path $kitRoot "templates\AGENTS.md") -Destination (Join-Path $target "AGENTS.md") -Force
Copy-Item -LiteralPath (Join-Path $kitRoot "templates\QWEN.md") -Destination (Join-Path $target "QWEN.md") -Force
Copy-Item -LiteralPath (Join-Path $kitRoot "templates\.lsp.json") -Destination (Join-Path $target ".lsp.json") -Force
Copy-Item -LiteralPath (Join-Path $kitRoot "templates\.gigacode.yaml") -Destination (Join-Path $target ".gigacode.yaml") -Force
Copy-Item -LiteralPath (Join-Path $kitRoot "templates\adapter-compatibility.yaml") -Destination (Join-Path $target ".gigacode-adapter.yaml") -Force
Copy-Item -LiteralPath (Join-Path $kitRoot "templates\tool-manifest.json") -Destination (Join-Path $target ".gigacode-tools.json") -Force

$contextTarget = Join-Path $target ".context"
New-Item -ItemType Directory -Force -Path $contextTarget | Out-Null
Copy-Item -Path (Join-Path $kitRoot "templates\context\*") -Destination $contextTarget -Recurse -Force

Write-Host "Шаблоны GigaCode скопированы в $target"
