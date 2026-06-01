$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$required = @(
    "README.md",
    "skills\gigacode-java-enterprise\SKILL.md",
    "skills\gigacode-java-enterprise\references\tool-contracts.md",
    "prompts\system.md",
    "templates\AGENTS.md",
    "templates\.lsp.json",
    "templates\qwen-settings.json",
    "docs\cli-integration-notes.md",
    "docs\gigacode-cli-integration.md",
    "docs\cli-user-guide.md",
    "docs\phase1-phase2-deployment.md",
    "docs\model-agnostic-agent-test.md",
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

$skill = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root "skills\gigacode-java-enterprise\SKILL.md")
if ($skill -notmatch '(?s)^---\s+name:\s+gigacode-java-enterprise\s+description:\s+.+?\s+---') {
    throw "Некорректный frontmatter skill"
}

$systemPrompt = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root "prompts\system.md")
if ($systemPrompt -notmatch "рус") {
    throw "В системном промпте нет правила общения на русском языке"
}

Write-Host "Структура GigaCode Agent Kit выглядит корректно."
