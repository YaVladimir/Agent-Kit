# Фазы 1 и 2: установка и развёртывание

Документ описывает практический запуск слоя навигации (Фаза 1) и слоя
иерархических summary (Фаза 2) в model-agnostic режиме.

## Что должно получиться

После развёртывания агент получает:

1. Навигацию по коду через `codebase-memory-mcp`.
2. Семантическую навигацию через `mcp-language-server` + LSP-серверы.
3. Архитектурные summary через `summary-mcp`.
4. Доменный контекст и `find_change_points` через `gigacode-context`.

## Быстрый запуск (macOS/Linux)

Из корня `Agent-Kit`:

```bash
chmod +x scripts/setup-phase1-phase2-macos.sh
chmod +x scripts/setup-phase1-phase2-linux.sh
chmod +x scripts/verify-phase1-phase2.sh
```

Для macOS:

```bash
./scripts/setup-phase1-phase2-macos.sh
```

Для Linux:

```bash
./scripts/setup-phase1-phase2-linux.sh
```

После установки:

```bash
./scripts/verify-phase1-phase2.sh
```

Скрипты теперь пытаются установить `go` и `jdtls` автоматически:

- macOS: через Homebrew.
- Linux (Debian/Ubuntu): через `apt`.

## MCP-конфиг

Шаблон для фаз 1+2:

- `templates/qwen-settings.phase1-phase2.json`

Скрипт установки копирует его в:

- `.qwen/settings.json`

## Состав конфига

- `codebase-memory` — быстрый структурный поиск по коду.
- `lsp-java` — `mcp-language-server` с `jdtls`.
- `lsp-typescript` — `mcp-language-server` с `typescript-language-server`.
- `summaries` — `summary-mcp` (`get_summary`, `find_module`, `list_packages`).
- `gigacode-context` — доменный `.context` слой.

## Важные замечания по LSP

`mcp-language-server` оборачивает только один LSP-процесс на одну MCP-запись,
поэтому для Java и TypeScript заведены две отдельные записи.

Если `jdtls` недоступен в `PATH`, укажи абсолютный путь в `args` или добавь
каталог с `jdtls` в `PATH`.

`verify-phase1-phase2.sh` считает фазу 1 неготовой, если `jdtls` не найден.

## Проверка сценария

Тестовый запрос в CLI:

```text
Код пока не меняй.
1) Через codebase/LSP найди сервис, где создается Todo.
2) Через summaries опиши модуль и архитектуру.
3) Через context найди доменные точки изменения.
4) Покажи план, куда добавить поле deadline.
```

Ожидаемое поведение:

- агент отвечает по-русски;
- использует MCP tools до изменения кода;
- называет конкретные классы и методы;
- не начинает правку до плана.

## Что в эту фазу не входит

- Neo4j/jQAssistant/Joern (это Фаза 3).
- Автоматическая транскрибация интервью и extraction (это расширение Фазы 4).
