$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$required = @(
    "README.md",
    "skills\gigacode-java-enterprise\SKILL.md",
    "skills\gigacode-java-enterprise\references\tool-contracts.md",
    "prompts\system.md",
    "templates\AGENTS.md",
    "templates\.lsp.json",
    "templates\.gigacode.yaml",
    "templates\.gitignore.additions",
    "templates\adapter-compatibility.yaml",
    "templates\qwen-settings.json",
    "docs\cli-integration-notes.md",
    "docs\gigacode-cli-integration.md",
    "docs\cli-user-guide.md",
    "docs\phase1-phase2-deployment.md",
    "docs\model-agnostic-agent-test.md",
    "docs\model-adapter-contract.md",
    "docs\manifest-alignment.md",
    "docs\no-docker-architecture.md",
    "examples\todoserver-context\index.md",
    "examples\todoserver-context\glossary.yaml",
    "examples\todoserver-context\processes\todo-crud.yaml",
    "examples\todoserver-context\rules\todo-rules.yaml",
    "mcp\summary-mcp\src\summary_mcp\server.py",
    "templates\qwen-settings.phase1-phase2.json",
    "scripts\setup-phase1-phase2-macos.sh",
    "scripts\setup-phase1-phase2-linux.sh",
    "scripts\verify-phase1-phase2.sh",
    "scripts\setup-phase1-phase2-windows.ps1",
    "scripts\verify-phase1-phase2-windows.ps1",
    "scripts\copy-templates.sh",
    "mcp\gigacode-context\src\gigacode_context\server.py"
)

foreach ($relative in $required) {
    $path = Join-Path $root $relative
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Не найден обязательный файл: $relative"
    }
}

Get-Content -Raw -LiteralPath (Join-Path $root "templates\.lsp.json") | ConvertFrom-Json | Out-Null
Get-Content -Raw -LiteralPath (Join-Path $root "templates\qwen-settings.json") | ConvertFrom-Json | Out-Null
Get-Content -Raw -LiteralPath (Join-Path $root "templates\qwen-settings.phase1-phase2.json") | ConvertFrom-Json | Out-Null

$skill = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root "skills\gigacode-java-enterprise\SKILL.md")
if ($skill -notmatch '(?s)^---\s+name:\s+gigacode-java-enterprise\s+description:\s+.+?\s+---') {
    throw "Некорректный frontmatter skill"
}

$systemPrompt = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root "prompts\system.md")
if ($systemPrompt -notmatch "рус") {
    throw "В системном промпте нет правила общения на русском языке"
}

$adapterProfile = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root "templates\adapter-compatibility.yaml")
if ($adapterProfile -notmatch "model_family" -or $adapterProfile -notmatch "allow_external_downloads:\s*false") {
    throw "Некорректный шаблон adapter-compatibility.yaml"
}

$adapterContract = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root "docs\model-adapter-contract.md")
if ($adapterContract -notmatch "Qwen" -or $adapterContract -notmatch "DeepSeek") {
    throw "Контракт адаптера не описывает Qwen/DeepSeek-like модели"
}

$manifestAlignment = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root "docs\manifest-alignment.md")
if ($manifestAlignment -notmatch "Матрица соответствия" -or $manifestAlignment -notmatch "Фаза 1" -or $manifestAlignment -notmatch "DeepSeek") {
    throw "Матрица соответствия манифесту неполная"
}

$copyPs1 = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root "scripts\copy-templates.ps1")
$copySh = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root "scripts\copy-templates.sh")
if ($copyPs1 -notmatch "\.gigacode-adapter\.yaml" -or $copySh -notmatch "\.gigacode-adapter\.yaml") {
    throw "copy-templates скрипты не копируют профиль адаптера"
}

$setupScripts = @(
    "scripts\setup-phase1-phase2-macos.sh",
    "scripts\setup-phase1-phase2-linux.sh",
    "scripts\setup-phase1-phase2-windows.ps1"
)
$forbiddenInstallers = @(
    "curl",
    "Invoke-WebRequest",
    "Invoke-RestMethod",
    "go install",
    "npm install",
    "pip install",
    "winget",
    "choco",
    "brew install",
    "apt install"
)
foreach ($relative in $setupScripts) {
    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root $relative)
    foreach ($pattern in $forbiddenInstallers) {
        if ($content -match [regex]::Escape($pattern)) {
            throw "Setup-скрипт содержит запрещённую автоустановку '$pattern': $relative"
        }
    }
}

Write-Host "Структура GigaCode Agent Kit выглядит корректно."
