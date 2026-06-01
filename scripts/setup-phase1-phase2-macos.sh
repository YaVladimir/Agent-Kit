#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Не найдено: $1" >&2
    exit 1
  fi
}

echo "== Проверка базовых зависимостей =="
need curl
need git
need python3
need node

if ! command -v go >/dev/null 2>&1; then
  cat <<'EOF'
Go не найден.
Установи Go, например:
  brew install go
EOF
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  cat <<'EOF'
npm не найден.
Проверь установку Node.js.
EOF
  exit 1
fi

echo "== Фаза 1: codebase-memory-mcp =="
if ! command -v codebase-memory-mcp >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash -s -- --skip-config
else
  echo "codebase-memory-mcp уже установлен."
fi

echo "== Фаза 1: mcp-language-server =="
go install github.com/isaacphi/mcp-language-server@latest

echo "== Фаза 1: language servers =="
npm install -g typescript typescript-language-server

cat <<'EOF'
jdtls нужно установить отдельно (если еще не установлен):
  brew install jdtls
или положить корпоративный binary и добавить его в PATH.
EOF

echo "== Фаза 2: Python MCP-серверы =="
python3 -m pip install --upgrade pip
python3 -m pip install fastmcp pyyaml

echo "== Конфиг MCP для фаз 1+2 =="
mkdir -p "$repo_root/.qwen"
cp "$repo_root/templates/qwen-settings.phase1-phase2.json" "$repo_root/.qwen/settings.json"

echo "Готово. Запусти проверку:"
echo "  $repo_root/scripts/verify-phase1-phase2.sh"

