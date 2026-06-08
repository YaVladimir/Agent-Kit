$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$required = @(
    "agent-kit.manifest.json",
    "README.md",
    "skills\gigacode-java-enterprise\SKILL.md",
    "skills\gigacode-java-enterprise\references\tool-contracts.md",
    "prompts\system.md",
    "templates\AGENTS.md",
    "templates\.lsp.json",
    "templates\.gigacode.yaml",
    "templates\.gitignore.additions",
    "templates\adapter-compatibility.yaml",
    "templates\adapters\qwen-coder.yaml",
    "templates\adapters\deepseek-v4-flash.yaml",
    "templates\tool-manifest.json",
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
    "scripts\copy-templates.ps1",
    "scripts\check-kit.sh",
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
$toolManifestJson = Get-Content -Raw -LiteralPath (Join-Path $root "templates\tool-manifest.json") | ConvertFrom-Json
$kitManifestJson = Get-Content -Raw -LiteralPath (Join-Path $root "agent-kit.manifest.json") | ConvertFrom-Json

if ($kitManifestJson.deployment.allowsExternalDownloads -ne $false -or $kitManifestJson.deployment.requiresDocker -ne $false) {
    throw "agent-kit.manifest.json нарушает политики portable/no-download/no-docker"
}
if (@($kitManifestJson.modelAdapters | Where-Object { $_.modelFamily -eq "qwen-coder" }).Count -eq 0) {
    throw "agent-kit.manifest.json не содержит qwen-coder adapter"
}
if (@($kitManifestJson.modelAdapters | Where-Object { $_.modelFamily -eq "deepseek-v4-flash" }).Count -eq 0) {
    throw "agent-kit.manifest.json не содержит deepseek-v4-flash adapter"
}
foreach ($output in @(".gigacode-kit.json", ".gigacode-tools.json", ".gigacode-adapter.yaml")) {
    if (@($kitManifestJson.templateOutputs) -notcontains $output) {
        throw "agent-kit.manifest.json не содержит template output: $output"
    }
}

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
if ($adapterProfile -notmatch "tool_manifest_path:\s*\.gigacode-tools\.json") {
    throw "adapter-compatibility.yaml не указывает tool manifest"
}

$qwenAdapterProfile = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root "templates\adapters\qwen-coder.yaml")
if ($qwenAdapterProfile -notmatch "model_family:\s*qwen-coder" -or $qwenAdapterProfile -notmatch "cli_mode:\s*mcp-stdio") {
    throw "Некорректный профиль adapters/qwen-coder.yaml"
}

$deepseekAdapterProfile = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root "templates\adapters\deepseek-v4-flash.yaml")
if ($deepseekAdapterProfile -notmatch "model_family:\s*deepseek-v4-flash" -or $deepseekAdapterProfile -notmatch "cli_mode:\s*wrapper-loop") {
    throw "Некорректный профиль adapters/deepseek-v4-flash.yaml"
}

$toolNames = @($toolManifestJson.tools | ForEach-Object { $_.name })
$requiredToolNames = @(
    "context.repo_overview",
    "context.lookup_domain",
    "context.find_change_points",
    "domain.translate_task",
    "domain.find_rule",
    "domain.list_processes",
    "domain.list_rules",
    "summary.get_summary",
    "summary.find_module",
    "code.search_symbols",
    "code.read_definition",
    "code.find_references"
)
foreach ($toolName in $requiredToolNames) {
    if ($toolNames -notcontains $toolName) {
        throw "tool-manifest.json не содержит обязательный tool: $toolName"
    }
}
if ($toolManifestJson.policy.allowExternalDownloads -ne $false) {
    throw "tool-manifest.json должен запрещать внешние загрузки"
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
if ($copyPs1 -notmatch "\.gigacode-tools\.json" -or $copySh -notmatch "\.gigacode-tools\.json") {
    throw "copy-templates скрипты не копируют tool manifest"
}
if ($copyPs1 -notmatch "\.gigacode-kit\.json" -or $copySh -notmatch "\.gigacode-kit\.json") {
    throw "copy-templates скрипты не копируют kit manifest"
}
if ($copyPs1 -notmatch "\.gigacode-adapters" -or $copySh -notmatch "\.gigacode-adapters") {
    throw "copy-templates скрипты не копируют профили адаптеров"
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

$smokeRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("gigacode-agent-kit-smoke-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $smokeRoot | Out-Null
try {
    & (Join-Path $root "scripts\copy-templates.ps1") -RepositoryPath $smokeRoot | Out-Null

    $deployedRequired = @(
        "AGENTS.md",
        "QWEN.md",
        ".lsp.json",
        ".gigacode.yaml",
        ".gigacode-adapter.yaml",
        ".gigacode-tools.json",
        ".gigacode-kit.json",
        ".gigacode-adapters\qwen-coder.yaml",
        ".gigacode-adapters\deepseek-v4-flash.yaml",
        ".context\index.md",
        ".context\architecture.md",
        ".context\glossary.yaml",
        ".context\processes\example-process.yaml",
        ".context\rules\example-rules.yaml"
    )
    foreach ($relative in $deployedRequired) {
        $path = Join-Path $smokeRoot $relative
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Smoke-test развёртывания не нашёл файл: $relative"
        }
    }

    Get-Content -Raw -LiteralPath (Join-Path $smokeRoot ".lsp.json") | ConvertFrom-Json | Out-Null
    Get-Content -Raw -LiteralPath (Join-Path $smokeRoot ".gigacode-tools.json") | ConvertFrom-Json | Out-Null
    $deployedKitManifest = Get-Content -Raw -LiteralPath (Join-Path $smokeRoot ".gigacode-kit.json") | ConvertFrom-Json | Out-Null

    $deployedProjectConfig = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $smokeRoot ".gigacode.yaml")
    if ($deployedProjectConfig -notmatch "allow_network_tools:\s*false" -or $deployedProjectConfig -notmatch "require_plan_before_edit:\s*true") {
        throw "Smoke-test развёртывания нашёл некорректную .gigacode.yaml"
    }

    $deployedAdapterConfig = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $smokeRoot ".gigacode-adapter.yaml")
    if ($deployedAdapterConfig -notmatch "model_family" -or $deployedAdapterConfig -notmatch "allow_external_downloads:\s*false") {
        throw "Smoke-test развёртывания нашёл некорректную .gigacode-adapter.yaml"
    }

    $deployedDeepseekProfile = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $smokeRoot ".gigacode-adapters\deepseek-v4-flash.yaml")
    if ($deployedDeepseekProfile -notmatch "deepseek-v4-flash" -or $deployedDeepseekProfile -notmatch "wrapper-loop") {
        throw "Smoke-test развёртывания нашёл некорректный deepseek-v4-flash profile"
    }

    $deployedToolManifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $smokeRoot ".gigacode-tools.json")
    if ($deployedToolManifest -notmatch "context.find_change_points" -or $deployedToolManifest -notmatch "domain.translate_task" -or $deployedToolManifest -notmatch "code.search_symbols") {
        throw "Smoke-test развёртывания нашёл некорректную .gigacode-tools.json"
    }

    $deployedKitManifestText = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $smokeRoot ".gigacode-kit.json")
    if ($deployedKitManifestText -notmatch "deepseek-v4-flash" -or $deployedKitManifestText -notmatch '"allowsExternalDownloads": false') {
        throw "Smoke-test развёртывания нашёл некорректную .gigacode-kit.json"
    }
} finally {
    if (Test-Path -LiteralPath $smokeRoot) {
        Remove-Item -LiteralPath $smokeRoot -Recurse -Force
    }
}

Write-Host "Структура GigaCode Agent Kit выглядит корректно."
