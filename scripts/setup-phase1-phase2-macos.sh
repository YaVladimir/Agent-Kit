#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Не найдено: $1" >&2
    exit 1
  fi
}

install_with_brew_if_missing() {
  local cmd="$1"
  local formula="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi
  if ! command -v brew >/dev/null 2>&1; then
    echo "Не найден Homebrew, нельзя автоматически поставить $formula." >&2
    return 1
  fi
  echo "Устанавливаю $formula через Homebrew..."
  brew install "$formula"
}

echo "== Проверка базовых зависимостей =="
need curl
need git
need python3
need node
need java

if ! command -v brew >/dev/null 2>&1; then
  cat <<'EOF'
Homebrew не найден.
Для автоматической установки Go и jdtls нужен Homebrew:
  https://brew.sh
EOF
  exit 1
fi

if ! command -v go >/dev/null 2>&1; then
  install_with_brew_if_missing go go || exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  cat <<'EOF'
npm не найден.
Проверь установку Node.js.
EOF
  exit 1
fi

if ! command -v jdtls >/dev/null 2>&1; then
  install_with_brew_if_missing jdtls jdtls || exit 1
fi

echo "== Фаза 1: codebase-memory-mcp =="
if ! command -v codebase-memory-mcp >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash -s -- --skip-config
else
  echo "codebase-memory-mcp уже установлен."
fi

echo "== Фаза 1: mcp-language-server =="
go install github.com/isaacphi/mcp-language-server@latest
GOPATH_BIN="$(go env GOPATH)/bin"
if [[ -d "$GOPATH_BIN" ]] && [[ ":$PATH:" != *":$GOPATH_BIN:"* ]]; then
  export PATH="$GOPATH_BIN:$PATH"
fi

echo "== Фаза 1: language servers =="
npm install -g typescript typescript-language-server
echo "jdtls: $(command -v jdtls)"

echo "== Фаза 2: Python MCP-серверы =="
python3 -m pip install --upgrade pip
python3 -m pip install fastmcp pyyaml

echo "== Конфиг MCP для фаз 1+2 =="
mkdir -p "$repo_root/.qwen"
cp "$repo_root/templates/qwen-settings.phase1-phase2.json" "$repo_root/.qwen/settings.json"
echo "Скопирован: $repo_root/.qwen/settings.json"

echo "Готово. Запусти проверку:"
echo "  $repo_root/scripts/verify-phase1-phase2.sh"
