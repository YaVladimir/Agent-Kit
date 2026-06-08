#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
missing=0

check() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "OK   $cmd"
  else
    echo "MISS $cmd"
    missing=1
  fi
}

echo "== Phase 1+2 preflight: macOS =="
echo "This script does not download or install third-party software."
echo

check git
check python3
check node
check npm
check go
check java
check jdtls
check codebase-memory-mcp
check mcp-language-server
check typescript-language-server

echo
echo "Manual installation instructions:"
echo "  $repo_root/docs/phase1-phase2-deployment.md"
echo
echo "After approved tools are installed, run:"
echo "  $repo_root/scripts/verify-phase1-phase2.sh"

exit "$missing"
