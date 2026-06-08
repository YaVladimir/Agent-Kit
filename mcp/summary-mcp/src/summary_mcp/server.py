from __future__ import annotations

from pathlib import Path
from typing import Any

from fastmcp import FastMCP


mcp = FastMCP("summary-mcp")


def repo_root() -> Path:
    return Path.cwd()


def context_root() -> Path:
    return repo_root() / ".context"


def read_text(path: Path) -> str:
    if not path.exists() or not path.is_file():
        return ""
    return path.read_text(encoding="utf-8")


def module_index_files() -> list[Path]:
    root = repo_root()
    files: list[Path] = []
    for path in root.glob("*/.context/index.md"):
        files.append(path)
    return sorted(files)


def first_line(text: str) -> str:
    for line in text.splitlines():
        value = line.strip()
        if value:
            return value
    return ""


def build_module_items() -> list[dict[str, str]]:
    items: list[dict[str, str]] = []
    for index_file in module_index_files():
        module_dir = index_file.parent.parent
        rel = module_dir.relative_to(repo_root()).as_posix()
        summary = read_text(index_file)
        items.append(
            {
                "module": rel,
                "source": index_file.relative_to(repo_root()).as_posix(),
                "headline": first_line(summary),
            }
        )
    return items


def find_best_module(target: str) -> Path | None:
    needle = target.strip().casefold()
    if not needle:
        return None
    direct = repo_root() / target / ".context" / "index.md"
    if direct.exists():
        return direct
    for index_file in module_index_files():
        module_name = index_file.parent.parent.name.casefold()
        if needle == module_name or needle in module_name:
            return index_file
    return None


def list_java_packages(base: Path) -> list[str]:
    java_root = base / "src" / "main" / "java"
    if not java_root.exists():
        return []
    packages: set[str] = set()
    for java_file in java_root.rglob("*.java"):
        package_dir = java_file.parent
        rel = package_dir.relative_to(java_root).as_posix()
        if rel and rel != ".":
            packages.add(rel.replace("/", "."))
    return sorted(packages)


@mcp.tool()
def get_summary(scope: str, target: str = "") -> dict[str, Any]:
    """Вернуть summary для scope: repo, architecture, module."""
    scope_key = scope.strip().casefold()

    if scope_key == "repo":
        source = context_root() / "index.md"
        return {
            "scope": "repo",
            "target": "",
            "source": source.relative_to(repo_root()).as_posix() if source.exists() else "",
            "summary": read_text(source),
        }

    if scope_key == "architecture":
        source = context_root() / "architecture.md"
        return {
            "scope": "architecture",
            "target": "",
            "source": source.relative_to(repo_root()).as_posix() if source.exists() else "",
            "summary": read_text(source),
        }

    if scope_key == "module":
        index_file = find_best_module(target)
        if index_file is None:
            return {
                "scope": "module",
                "target": target,
                "source": "",
                "summary": "",
                "error": "module summary not found",
            }
        return {
            "scope": "module",
            "target": index_file.parent.parent.relative_to(repo_root()).as_posix(),
            "source": index_file.relative_to(repo_root()).as_posix(),
            "summary": read_text(index_file),
        }

    return {
        "scope": scope,
        "target": target,
        "source": "",
        "summary": "",
        "error": "unsupported scope; use repo, architecture, or module",
    }


@mcp.tool()
def get_architecture_overview() -> dict[str, Any]:
    """Вернуть обзор архитектуры: repo summary, architecture summary, modules."""
    return {
        "repo_summary": read_text(context_root() / "index.md"),
        "architecture_summary": read_text(context_root() / "architecture.md"),
        "modules": build_module_items(),
    }


@mcp.tool()
def find_module(query: str) -> dict[str, Any]:
    """Найти модуль по query в именах и summary модулей."""
    needle = query.strip().casefold()
    matches: list[dict[str, str]] = []

    for index_file in module_index_files():
        module_dir = index_file.parent.parent
        rel = module_dir.relative_to(repo_root()).as_posix()
        summary = read_text(index_file)
        haystack = f"{rel}\n{summary}".casefold()
        if needle and needle in haystack:
            matches.append(
                {
                    "module": rel,
                    "source": index_file.relative_to(repo_root()).as_posix(),
                    "headline": first_line(summary),
                }
            )

    return {"query": query, "matches": matches}


@mcp.tool()
def list_packages(module: str = "") -> dict[str, Any]:
    """Вернуть Java package-имена для всего репо или конкретного модуля."""
    base = repo_root() if not module else repo_root() / module
    return {
        "module": module,
        "packages": list_java_packages(base),
    }


def main() -> None:
    mcp.run()


if __name__ == "__main__":
    main()

