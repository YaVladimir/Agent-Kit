#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required=(
  "README.md"
  "skills/gigacode-java-enterprise/SKILL.md"
  "skills/gigacode-java-enterprise/references/tool-contracts.md"
  "prompts/system.md"
  "templates/AGENTS.md"
  "templates/.lsp.json"
  "templates/.gigacode.yaml"
  "templates/.gitignore.additions"
  "templates/adapter-compatibility.yaml"
  "templates/adapters/qwen-coder.yaml"
  "templates/adapters/deepseek-v4-flash.yaml"
  "templates/tool-manifest.json"
  "templates/qwen-settings.json"
  "templates/qwen-settings.phase1-phase2.json"
  "docs/cli-integration-notes.md"
  "docs/gigacode-cli-integration.md"
  "docs/cli-user-guide.md"
  "docs/phase1-phase2-deployment.md"
  "docs/model-agnostic-agent-test.md"
  "docs/model-adapter-contract.md"
  "docs/manifest-alignment.md"
  "docs/no-docker-architecture.md"
  "examples/todoserver-context/index.md"
  "examples/todoserver-context/glossary.yaml"
  "examples/todoserver-context/processes/todo-crud.yaml"
  "examples/todoserver-context/rules/todo-rules.yaml"
  "mcp/summary-mcp/src/summary_mcp/server.py"
  "scripts/setup-phase1-phase2-macos.sh"
  "scripts/setup-phase1-phase2-linux.sh"
  "scripts/verify-phase1-phase2.sh"
  "scripts/setup-phase1-phase2-windows.ps1"
  "scripts/verify-phase1-phase2-windows.ps1"
  "scripts/copy-templates.sh"
  "scripts/copy-templates.ps1"
  "scripts/check-kit.ps1"
  "mcp/gigacode-context/src/gigacode_context/server.py"
)

for relative in "${required[@]}"; do
  if [[ ! -e "$root/$relative" ]]; then
    echo "Missing required file: $relative" >&2
    exit 1
  fi
done

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required for JSON validation." >&2
  exit 1
fi

python3 -m json.tool "$root/templates/.lsp.json" >/dev/null
python3 -m json.tool "$root/templates/qwen-settings.json" >/dev/null
python3 -m json.tool "$root/templates/qwen-settings.phase1-phase2.json" >/dev/null
python3 -m json.tool "$root/templates/tool-manifest.json" >/dev/null

if ! grep -Eq '^---[[:space:]]*$' "$root/skills/gigacode-java-enterprise/SKILL.md"; then
  echo "Skill frontmatter is missing." >&2
  exit 1
fi

if ! grep -q 'рус' "$root/prompts/system.md"; then
  echo "System prompt does not mention Russian-language communication." >&2
  exit 1
fi

if ! grep -q 'model_family' "$root/templates/adapter-compatibility.yaml"; then
  echo "adapter-compatibility.yaml does not describe model_family." >&2
  exit 1
fi

if ! grep -Eq 'allow_external_downloads:[[:space:]]*false' "$root/templates/adapter-compatibility.yaml"; then
  echo "adapter-compatibility.yaml must forbid external downloads." >&2
  exit 1
fi

if ! grep -Eq 'tool_manifest_path:[[:space:]]*.gigacode-tools.json' "$root/templates/adapter-compatibility.yaml"; then
  echo "adapter-compatibility.yaml does not point to tool manifest." >&2
  exit 1
fi

if ! grep -Eq 'model_family:[[:space:]]*qwen-coder' "$root/templates/adapters/qwen-coder.yaml"; then
  echo "qwen-coder adapter profile is invalid." >&2
  exit 1
fi

if ! grep -Eq 'cli_mode:[[:space:]]*mcp-stdio' "$root/templates/adapters/qwen-coder.yaml"; then
  echo "qwen-coder adapter profile must use mcp-stdio." >&2
  exit 1
fi

if ! grep -Eq 'model_family:[[:space:]]*deepseek-v4-flash' "$root/templates/adapters/deepseek-v4-flash.yaml"; then
  echo "deepseek-v4-flash adapter profile is invalid." >&2
  exit 1
fi

if ! grep -Eq 'cli_mode:[[:space:]]*wrapper-loop' "$root/templates/adapters/deepseek-v4-flash.yaml"; then
  echo "deepseek-v4-flash adapter profile must use wrapper-loop." >&2
  exit 1
fi

required_tool_names=(
  "context.repo_overview"
  "context.lookup_domain"
  "context.find_change_points"
  "summary.get_summary"
  "summary.find_module"
  "code.search_symbols"
  "code.read_definition"
  "code.find_references"
)
for tool_name in "${required_tool_names[@]}"; do
  if ! grep -q "\"name\": \"$tool_name\"" "$root/templates/tool-manifest.json"; then
    echo "tool-manifest.json does not contain required tool: $tool_name" >&2
    exit 1
  fi
done

if ! grep -q '"allowExternalDownloads": false' "$root/templates/tool-manifest.json"; then
  echo "tool-manifest.json must forbid external downloads." >&2
  exit 1
fi

if ! grep -q 'Qwen' "$root/docs/model-adapter-contract.md" || ! grep -q 'DeepSeek' "$root/docs/model-adapter-contract.md"; then
  echo "Model adapter contract must describe Qwen and DeepSeek-like models." >&2
  exit 1
fi

if ! grep -q 'Матрица соответствия' "$root/docs/manifest-alignment.md" || ! grep -q 'DeepSeek' "$root/docs/manifest-alignment.md"; then
  echo "Manifest alignment document is incomplete." >&2
  exit 1
fi

if ! grep -q '.gigacode-adapter.yaml' "$root/scripts/copy-templates.ps1" || ! grep -q '.gigacode-adapter.yaml' "$root/scripts/copy-templates.sh"; then
  echo "copy-templates scripts do not copy adapter profile." >&2
  exit 1
fi

if ! grep -q '.gigacode-tools.json' "$root/scripts/copy-templates.ps1" || ! grep -q '.gigacode-tools.json' "$root/scripts/copy-templates.sh"; then
  echo "copy-templates scripts do not copy tool manifest." >&2
  exit 1
fi

if ! grep -q '.gigacode-adapters' "$root/scripts/copy-templates.ps1" || ! grep -q '.gigacode-adapters' "$root/scripts/copy-templates.sh"; then
  echo "copy-templates scripts do not copy adapter profiles." >&2
  exit 1
fi

setup_scripts=(
  "scripts/setup-phase1-phase2-macos.sh"
  "scripts/setup-phase1-phase2-linux.sh"
  "scripts/setup-phase1-phase2-windows.ps1"
)
forbidden_installers=(
  "curl"
  "Invoke-WebRequest"
  "Invoke-RestMethod"
  "go install"
  "npm install"
  "pip install"
  "winget"
  "choco"
  "brew install"
  "apt install"
)

for relative in "${setup_scripts[@]}"; do
  for pattern in "${forbidden_installers[@]}"; do
    if grep -Fq "$pattern" "$root/$relative"; then
      echo "Setup script contains forbidden installer '$pattern': $relative" >&2
      exit 1
    fi
  done
done

smoke_root="$(mktemp -d "${TMPDIR:-/tmp}/gigacode-agent-kit-smoke.XXXXXX")"
cleanup() {
  rm -rf "$smoke_root"
}
trap cleanup EXIT

"$root/scripts/copy-templates.sh" "$smoke_root" >/dev/null

deployed_required=(
  "AGENTS.md"
  "QWEN.md"
  ".lsp.json"
  ".gigacode.yaml"
  ".gigacode-adapter.yaml"
  ".gigacode-tools.json"
  ".gigacode-adapters/qwen-coder.yaml"
  ".gigacode-adapters/deepseek-v4-flash.yaml"
  ".context/index.md"
  ".context/architecture.md"
  ".context/glossary.yaml"
  ".context/processes/example-process.yaml"
  ".context/rules/example-rules.yaml"
)

for relative in "${deployed_required[@]}"; do
  if [[ ! -e "$smoke_root/$relative" ]]; then
    echo "Smoke deployment did not create: $relative" >&2
    exit 1
  fi
done

python3 -m json.tool "$smoke_root/.lsp.json" >/dev/null
python3 -m json.tool "$smoke_root/.gigacode-tools.json" >/dev/null

if ! grep -Eq 'allow_network_tools:[[:space:]]*false' "$smoke_root/.gigacode.yaml"; then
  echo "Deployed .gigacode.yaml must forbid network tools." >&2
  exit 1
fi

if ! grep -Eq 'require_plan_before_edit:[[:space:]]*true' "$smoke_root/.gigacode.yaml"; then
  echo "Deployed .gigacode.yaml must require plan before edit." >&2
  exit 1
fi

if ! grep -q 'model_family' "$smoke_root/.gigacode-adapter.yaml"; then
  echo "Deployed .gigacode-adapter.yaml does not describe model_family." >&2
  exit 1
fi

if ! grep -Eq 'allow_external_downloads:[[:space:]]*false' "$smoke_root/.gigacode-adapter.yaml"; then
  echo "Deployed .gigacode-adapter.yaml must forbid external downloads." >&2
  exit 1
fi

if ! grep -q 'deepseek-v4-flash' "$smoke_root/.gigacode-adapters/deepseek-v4-flash.yaml" || ! grep -q 'wrapper-loop' "$smoke_root/.gigacode-adapters/deepseek-v4-flash.yaml"; then
  echo "Deployed deepseek-v4-flash adapter profile is invalid." >&2
  exit 1
fi

if ! grep -q '"name": "context.find_change_points"' "$smoke_root/.gigacode-tools.json" || ! grep -q '"name": "code.search_symbols"' "$smoke_root/.gigacode-tools.json"; then
  echo "Deployed .gigacode-tools.json is incomplete." >&2
  exit 1
fi

echo "GigaCode Agent Kit structure looks valid."
