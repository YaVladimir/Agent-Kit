#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Использование: $0 /path/to/repository" >&2
  exit 1
fi

repo_path="$1"
kit_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -d "$repo_path" ]]; then
  echo "Репозиторий не найден: $repo_path" >&2
  exit 1
fi

cp "$kit_root/templates/AGENTS.md" "$repo_path/AGENTS.md"
cp "$kit_root/templates/QWEN.md" "$repo_path/QWEN.md"
cp "$kit_root/templates/.lsp.json" "$repo_path/.lsp.json"
cp "$kit_root/templates/.gigacode.yaml" "$repo_path/.gigacode.yaml"
cp "$kit_root/templates/adapter-compatibility.yaml" "$repo_path/.gigacode-adapter.yaml"
cp "$kit_root/templates/tool-manifest.json" "$repo_path/.gigacode-tools.json"

mkdir -p "$repo_path/.context"
cp -R "$kit_root/templates/context/." "$repo_path/.context/"

echo "Шаблоны GigaCode скопированы в $repo_path"
