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


def relative_path(path: Path) -> str:
    return path.relative_to(Path.cwd()).as_posix()


def as_text(value: Any) -> str:
    return str(value or "")


def matches_query(value: Any, query: str) -> bool:
    needle = query.strip().casefold()
    if not needle:
        return True
    return needle in as_text(value).casefold()


def process_files() -> list[Path]:
    root = context_root() / "processes"
    if not root.exists():
        return []
    return sorted(root.glob("*.yaml"))


def rule_files() -> list[Path]:
    root = context_root() / "rules"
    if not root.exists():
        return []
    return sorted(root.glob("*.yaml"))


def load_processes() -> list[dict[str, Any]]:
    processes: list[dict[str, Any]] = []
    for path in process_files():
        data = read_yaml(path)
        if isinstance(data, dict):
            processes.append({"file": relative_path(path), "data": data})
    return processes


def load_rules() -> list[dict[str, Any]]:
    rules: list[dict[str, Any]] = []
    for path in rule_files():
        data = read_yaml(path)
        for rule in (data or {}).get("rules") or []:
            if isinstance(rule, dict):
                rules.append({"file": relative_path(path), "data": rule})
    return rules


def compact_process(item: dict[str, Any]) -> dict[str, Any]:
    data = item["data"]
    return {
        "file": item["file"],
        "id": data.get("id", ""),
        "title": data.get("title", ""),
        "description": data.get("description", ""),
        "entrypoints": data.get("entrypoints", []),
        "services": data.get("services", []),
        "rules": data.get("rules", []),
        "tests": data.get("tests", []),
    }


def compact_rule(item: dict[str, Any]) -> dict[str, Any]:
    data = item["data"]
    return {
        "file": item["file"],
        "id": data.get("id", ""),
        "title": data.get("title", ""),
        "description": data.get("description", ""),
        "applies_to": data.get("applies_to", {}),
        "code": data.get("code", {}),
        "tests": data.get("tests", []),
    }


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

    for item in load_processes():
        if matches_query(item, needle):
            matches["processes"].append(item)

    for item in load_rules():
        if matches_query(item, needle):
            matches["rules"].append(item)

    return matches


@mcp.tool()
def list_processes() -> dict[str, Any]:
    """Вернуть список известных бизнес-процессов из .context/processes."""
    return {"processes": [compact_process(item) for item in load_processes()]}


@mcp.tool()
def list_rules() -> dict[str, Any]:
    """Вернуть список известных бизнес-правил из .context/rules."""
    return {"rules": [compact_rule(item) for item in load_rules()]}


@mcp.tool()
def find_rule(query: str) -> dict[str, Any]:
    """Найти бизнес-правила по id, названию, описанию или связанным сущностям."""
    return {
        "query": query,
        "rules": [
            compact_rule(item)
            for item in load_rules()
            if matches_query(item, query)
        ],
    }


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


@mcp.tool()
def translate_task(task: str) -> dict[str, Any]:
    """Перевести бизнес-задачу в доменный контекст и первичный план изменения."""
    domain = lookup_domain(task)
    change_points = find_change_points(task)
    rule_ids = {
        rule["data"].get("id")
        for rule in domain["rules"]
        if isinstance(rule.get("data"), dict) and rule["data"].get("id")
    }

    for term in domain["terms"]:
        for rule_id in term.get("rules") or []:
            rule_ids.add(rule_id)
    for process in domain["processes"]:
        for rule_id in process["data"].get("rules") or []:
            rule_ids.add(rule_id)

    related_rules = [
        compact_rule(item)
        for item in load_rules()
        if item["data"].get("id") in rule_ids or matches_query(item, task)
    ]

    steps = [
        "Проверить найденные доменные термины и бизнес-правила.",
        "Изучить candidate classes, services, entrypoints и связанные тесты.",
        "Через LSP/MCP прочитать определения и usages перед изменением кода.",
        "Внести минимальное изменение по существующему паттерну проекта.",
        "Запустить релевантные unit/integration проверки.",
    ]

    return {
        "task": task,
        "terms": domain["terms"],
        "processes": [compact_process(item) for item in domain["processes"]],
        "rules": related_rules,
        "change_points": change_points["candidates"],
        "recommended_steps": steps,
        "notes": [
            "Это первичная трансляция бизнес-задачи; агент обязан подтвердить точки изменения через code/LSP tools.",
            "Если совпадений мало, нужно уточнить .context/glossary.yaml, processes или rules.",
        ],
    }


def main() -> None:
    mcp.run()


if __name__ == "__main__":
    main()
