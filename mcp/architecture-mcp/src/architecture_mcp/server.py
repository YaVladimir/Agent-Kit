from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml
from fastmcp import FastMCP


mcp = FastMCP("architecture-mcp")


def repo_root() -> Path:
    return Path.cwd()


def graph_path() -> Path:
    return repo_root() / ".context" / "architecture-graph.yaml"


def read_graph() -> dict[str, Any]:
    path = graph_path()
    if not path.exists():
        return {}
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle) or {}
    return data if isinstance(data, dict) else {}


def as_text(value: Any) -> str:
    return str(value or "")


def matches(value: Any, query: str) -> bool:
    needle = query.strip().casefold()
    if not needle:
        return True
    return needle in as_text(value).casefold()


def list_items(graph: dict[str, Any], key: str) -> list[dict[str, Any]]:
    value = graph.get(key) or []
    return [item for item in value if isinstance(item, dict)]


def endpoint_chain(endpoint: dict[str, Any]) -> list[dict[str, Any]]:
    chain: list[dict[str, Any]] = []
    for key, kind in (
        ("controller", "controller"),
        ("service", "service"),
        ("repository", "repository"),
    ):
        value = endpoint.get(key)
        if value:
            chain.append({"kind": kind, "name": value})
    for table in endpoint.get("tables") or []:
        chain.append({"kind": "table", "name": table})
    return chain


@mcp.tool()
def trace_endpoint_to_db(endpoint: str) -> dict[str, Any]:
    """Построить цепочку endpoint -> controller -> service -> repository -> DB."""
    graph = read_graph()
    endpoints = [
        item
        for item in list_items(graph, "endpoints")
        if matches(item.get("path", ""), endpoint) or matches(item.get("name", ""), endpoint)
    ]
    return {
        "endpoint": endpoint,
        "source": ".context/architecture-graph.yaml" if graph else "",
        "matches": [
            {
                "path": item.get("path", ""),
                "method": item.get("method", ""),
                "name": item.get("name", ""),
                "chain": endpoint_chain(item),
                "notes": item.get("notes", []),
            }
            for item in endpoints
        ],
        "fallback": "Если совпадений нет, проверь .context/architecture-graph.yaml или используй LSP/code search.",
    }


@mcp.tool()
def find_blast_radius(symbol: str) -> dict[str, Any]:
    """Найти известные зависимости, endpoint'ы, wiring и тесты вокруг символа."""
    graph = read_graph()
    dependencies = list_items(graph, "dependencies")
    endpoints = list_items(graph, "endpoints")
    beans = list_items(graph, "spring_beans")
    modules = list_items(graph, "modules")

    touched_dependencies = [
        item
        for item in dependencies
        if matches(item.get("source", ""), symbol) or matches(item.get("target", ""), symbol)
    ]
    touched_endpoints = [item for item in endpoints if matches(item, symbol)]
    touched_beans = [item for item in beans if matches(item, symbol)]
    touched_modules = [item for item in modules if matches(item, symbol)]
    tests: list[str] = []
    for item in touched_endpoints + touched_beans + touched_modules:
        for test in item.get("tests") or []:
            if test not in tests:
                tests.append(test)

    return {
        "symbol": symbol,
        "source": ".context/architecture-graph.yaml" if graph else "",
        "dependencies": touched_dependencies,
        "endpoints": touched_endpoints,
        "spring_beans": touched_beans,
        "modules": touched_modules,
        "tests": tests,
        "fallback": "Подтверди blast radius через find_references/read_definition перед изменением кода.",
    }


@mcp.tool()
def check_layer_violations(files: list[str] | None = None) -> dict[str, Any]:
    """Вернуть известные нарушения слоев из архитектурного графа."""
    graph = read_graph()
    requested = files or []
    dependencies = list_items(graph, "dependencies")
    violations = [
        item
        for item in dependencies
        if item.get("allowed") is False
        and (
            not requested
            or any(matches(item.get("source", ""), file) or matches(item.get("target", ""), file) for file in requested)
        )
    ]
    return {
        "files": requested,
        "source": ".context/architecture-graph.yaml" if graph else "",
        "violations": violations,
        "policy": graph.get("layer_policy", {}),
        "fallback": "Если граф пустой, используй ArchUnit/jdeps/jQAssistant отчёт из approved CI и обнови .context/architecture-graph.yaml.",
    }


@mcp.tool()
def find_spring_wiring(component: str) -> dict[str, Any]:
    """Найти Spring bean wiring, зависимости и тесты для компонента."""
    graph = read_graph()
    beans = [
        item
        for item in list_items(graph, "spring_beans")
        if matches(item.get("name", ""), component) or matches(item.get("class", ""), component)
    ]
    return {
        "component": component,
        "source": ".context/architecture-graph.yaml" if graph else "",
        "beans": beans,
        "fallback": "Если wiring не описан, используй LSP references, Spring configuration и тесты контекста.",
    }


def main() -> None:
    mcp.run()


if __name__ == "__main__":
    main()
