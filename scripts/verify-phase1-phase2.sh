#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "FAIL: не найдено '$1'" >&2
    return 1
  fi
  return 0
}

fail=0

echo "== Базовые команды =="
for cmd in python3 node; do
  if ! need "$cmd"; then
    fail=1
  else
    "$cmd" --version || true
  fi
done

echo "== Фаза 1 =="
if need codebase-memory-mcp; then
  codebase-memory-mcp --version || true
else
  fail=1
fi

if need mcp-language-server; then
  mcp-language-server --help >/dev/null || true
else
  fail=1
fi

if need typescript-language-server; then
  typescript-language-server --version || true
else
  fail=1
fi

echo "== Фаза 2 =="
if python3 - <<'PY'
import importlib
for name in ("fastmcp", "yaml"):
    importlib.import_module(name)
print("Python зависимости summary/context MCP в порядке.")
PY
then
  true
else
  fail=1
fi

echo "== Конфиг =="
if [[ -f "$repo_root/.qwen/settings.json" ]]; then
  echo "OK: найден $repo_root/.qwen/settings.json"
else
  echo "WARN: не найден $repo_root/.qwen/settings.json"
  echo "      скопируй templates/qwen-settings.phase1-phase2.json"
fi

if [[ "$fail" -ne 0 ]]; then
  echo "Проверка завершилась с ошибками."
  exit 1
fi

echo "Проверка фаз 1+2 прошла успешно."

