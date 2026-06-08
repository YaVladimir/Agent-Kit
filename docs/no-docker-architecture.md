# Архитектура без Docker

Используй эту схему, если корпоративная политика запрещает Docker или локальные
демоны.

## Рекомендуемый MVP

```text
GigaCode CLI
  -> локальный дочерний stdio MCP-процесс
  -> .context/*.md и *.yaml
  -> опционально .gigacode/index.sqlite
  -> LSP-сервер, запущенный CLI или машиной разработчика
```

Сетевой сервер не нужен.

## Чем заменить Neo4j

Для пилота используй один из вариантов вместо Neo4j:

- SQLite-таблицы: `nodes(id, type, name, path)` и `edges(src, dst, type)`.
- Файловый граф `.context/architecture-graph.yaml`, который читает локальный
  `architecture-mcp`.
- CI-артефакт: `context.sqlite`, который разработчики получают из внутреннего
  артефактного хранилища.
- Существующий корпоративный PostgreSQL, если нужно центральное хранилище.
- ArchUnit, jdeps, отчёты зависимостей Maven/Gradle для проверки слоёв.

## Минимальный phase 3 без Docker

Для первого запуска не поднимай Neo4j. Заполни
`.context/architecture-graph.yaml` вручную или из approved CI-отчёта и подключи
`mcp/architecture-mcp` как stdio MCP-сервер.

Минимальный набор tools:

- `trace_endpoint_to_db(endpoint)` — цепочка endpoint → controller → service →
  repository → таблицы.
- `find_blast_radius(symbol)` — известные зависимости, endpoint'ы, Spring beans
  и тесты вокруг класса или модуля.
- `check_layer_violations(files)` — известные нарушения слоёв из графа.
- `find_spring_wiring(component)` — Spring bean wiring и связанные тесты.

Позже backend можно заменить на Neo4j/jQAssistant, сохранив те же имена tools и
схемы входа/выхода.

## Когда добавлять настоящий сервер

HTTP/SSE MCP-сервер нужен только когда появляются:

- централизованный контроль доступа и аудит;
- общие индексы для многих репозиториев;
- интеграция с Jira, Confluence или внутренними системами;
- тяжёлые графовые запросы, которые слишком медленны локально.
