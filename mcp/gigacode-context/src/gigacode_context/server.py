from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml
from fastmcp import FastMCP


mcp = FastMCP("gigacode-context")


def context_root() -> Path:
    return Path.cwd() / ".context"


def read_text(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8")


def read_yaml(path: Path) -> Any:
    if not path.exists():
        return None
    with path.open("r", encoding="utf-8") as handle:
        return yaml.safe_load(handle)


@mcp.tool()
def repo_overview() -> dict[str, str]:
    """Вернуть summary репозитория и архитектуры из .context."""
    root = context_root()
    return {
        "index": read_text(root / "index.md"),
        "architecture": read_text(root / "architecture.md"),
    }


@mcp.tool()
def lookup_domain(query: str) -> dict[str, Any]:
    """Найти доменные термины, процессы и правила, связанные с запросом."""
    root = context_root()
    needle = query.casefold()
    matches: dict[str, Any] = {"terms": [], "processes": [], "rules": []}

    glossary = read_yaml(root / "glossary.yaml") or {}
    for key, value in (glossary.get("terms") or {}).items():
        haystack = f"{key} {value}".casefold()
        if needle in haystack:
            matches["terms"].append({"id": key, **value})

    for path in (root / "processes").glob("*.yaml"):
        data = read_yaml(path)
        if data and needle in f"{path.name} {data}".casefold():
            matches["processes"].append({"file": str(path), "data": data})

    for path in (root / "rules").glob("*.yaml"):
        data = read_yaml(path)
        if data and needle in f"{path.name} {data}".casefold():
            matches["rules"].append({"file": str(path), "data": data})

    return matches


@mcp.tool()
def get_module_summary(module: str) -> dict[str, str]:
    """Вернуть summary модуля из module/.context/index.md, если файл есть."""
    path = Path.cwd() / module / ".context" / "index.md"
    return {"module": module, "summary": read_text(path)}


@mcp.tool()
def find_change_points(task: str) -> dict[str, Any]:
    """Вернуть кандидатные точки изменения, найденные через доменный контекст."""
    domain = lookup_domain(task)
    candidates: list[dict[str, Any]] = []

    for term in domain["terms"]:
        code = term.get("code") or {}
        candidates.append(
            {
                "source": f"term:{term.get('id')}",
                "classes": code.get("classes", []),
                "methods": code.get("methods", []),
                "reason": "Совпадение с термином бизнес-глоссария.",
            }
        )

    for process in domain["processes"]:
        data = process["data"]
        candidates.append(
            {
                "source": f"process:{data.get('id', process['file'])}",
                "classes": data.get("services", []) + data.get("entrypoints", []),
                "methods": [],
                "tests": data.get("tests", []),
                "reason": "Совпадение с бизнес-процессом.",
            }
        )

    return {"task": task, "candidates": candidates}


def main() -> None:
    mcp.run()


if __name__ == "__main__":
    main()
