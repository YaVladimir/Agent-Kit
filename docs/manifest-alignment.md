# Соответствие манифесту

Этот файл связывает манифест внедрения AI-кодингового агента с текущими
артефактами Agent Kit. Его цель — быстро показать, что уже реализовано как
шаблонный проект, что является ручным шагом внедрения, а что сознательно
оставлено для следующих фаз.

## Итоговый статус

Текущий kit закрывает переносимый пилот для фаз 1, 2 и базовой части фазы 4:

- агентский workflow и русскоязычные инструкции;
- шаблоны для продуктового репозитория;
- доменный `.context`;
- локальные stdio MCP-серверы `gigacode-context` и `summary-mcp`;
- Qwen-compatible MCP config;
- контракт адаптера для Qwen Coder, DeepSeek-like и других LLM;
- no-Docker сценарий;
- корпоративно безопасный manual setup без скрытых внешних загрузок.

Фаза 3 и расширенная фаза 4 описаны как целевая архитектура и не считаются
готовыми runtime-компонентами этого шаблонного проекта.

## Матрица соответствия

| Требование манифеста | Статус | Доказательство в репозитории | Как проверить |
|---|---|---|---|
| Шаблонный проект можно развернуть в продуктовом репозитории | Реализовано | `scripts/copy-templates.ps1`, `scripts/copy-templates.sh`, `templates/*` | Запустить copy-templates во временный каталог и проверить `AGENTS.md`, `QWEN.md`, `.context`, `.gigacode.yaml`, `.gigacode-adapter.yaml` |
| Общение агента и текстовые инструкции на русском языке | Реализовано | `README.md`, `prompts/system.md`, `templates/AGENTS.md`, `skills/gigacode-java-enterprise/SKILL.md` | `scripts/check-kit.ps1` проверяет русскоязычное правило в системном промпте |
| Модель-независимый workflow: задача -> контекст -> поиск -> план -> код -> проверки | Реализовано | `prompts/system.md`, `templates/AGENTS.md`, `skills/gigacode-java-enterprise/SKILL.md`, `docs/model-agnostic-agent-test.md` | Прогнать dry-run из `docs/model-agnostic-agent-test.md` |
| Интеграция с Qwen Coder / GigaCode CLI | Реализовано как совместимый шаблон | `templates/qwen-settings.json`, `templates/qwen-settings.phase1-phase2.json`, `docs/gigacode-cli-integration.md` | Скопировать settings в `.qwen/settings.json` и запустить совместимый CLI из корня проекта |
| Возможность встроить DeepSeek-like или другую LLM | Реализовано как контракт адаптера | `docs/model-adapter-contract.md`, `templates/adapter-compatibility.yaml`, `docs/cli-integration-notes.md` | Заполнить `.gigacode-adapter.yaml` для конкретного CLI/wrapper и пройти acceptance checklist |
| Фаза 1: навигация по коду через codebase/LSP/MCP | Реализовано как подключаемый слой | `templates/qwen-settings.phase1-phase2.json`, `docs/phase1-phase2-deployment.md`, `scripts/verify-phase1-phase2.*` | Установить approved tools из внутренних источников и запустить verify |
| Java LSP через Eclipse JDT LS | Реализовано как обязательная проверка окружения | `templates/.lsp.json`, `docs/phase1-phase2-deployment.md`, `scripts/verify-phase1-phase2.*` | `jdtls` должен быть в `PATH` или указан абсолютным путем в конфиге |
| TypeScript LSP | Реализовано как подключаемый слой | `templates/qwen-settings.phase1-phase2.json`, `docs/phase1-phase2-deployment.md` | Проверить `typescript-language-server --version` и verify |
| Фаза 2: иерархические summary | Реализован минимальный MCP | `mcp/summary-mcp/src/summary_mcp/server.py`, `templates/qwen-settings.phase1-phase2.json` | Запустить `summary-mcp` как stdio MCP и проверить tools `get_summary`, `find_module`, `list_packages` |
| Фаза 4: доменный контекст | Реализован базовый слой | `templates/context/*`, `schemas/*.yaml`, `mcp/gigacode-context/src/gigacode_context/server.py`, `examples/todoserver-context/*` | Заполнить `.context`, запустить `gigacode-context`, проверить `repo_overview`, `lookup_domain`, `find_change_points` |
| No-Docker пилот | Реализовано | `docs/no-docker-architecture.md`, `docs/phase1-phase2-deployment.md` | Использовать локальные файлы/SQLite/approved artifacts вместо Docker-сервисов |
| Корпоративная безопасность: без автоматической загрузки стороннего софта | Реализовано | `scripts/setup-phase1-phase2-*`, `docs/phase1-phase2-deployment.md`, `scripts/check-kit.ps1` | `check-kit.ps1` запрещает автоустановочные команды в setup-скриптах |
| Фаза 3: Neo4j/jQAssistant/Joern | Отложено | `docs/phase1-phase2-deployment.md`, `docs/no-docker-architecture.md` | Для пилота не требуется; отдельная реализация нужна после согласования инфраструктуры |
| Расширенная фаза 4: интервью, транскрибация, extraction | Отложено | `docs/phase1-phase2-deployment.md`, манифест | Нужен отдельный workflow после согласования процесса с продуктом и безопасниками |
| Open-source лицензирование | Реализовано | `LICENSE`, `NOTICE`, `README.md` | Проверить Apache License 2.0 |

## Что считается готовым для пилота

Пилот можно считать готовым на уровне шаблонного проекта, если:

1. `scripts/check-kit.ps1` проходит.
2. `scripts/copy-templates.ps1` или `scripts/copy-templates.sh` разворачивает
   шаблоны в пустой продуктовый репозиторий.
3. В продуктовом репозитории есть `AGENTS.md`, `QWEN.md`, `.context`,
   `.gigacode.yaml`, `.gigacode-adapter.yaml`.
4. Для выбранного CLI заполнен профиль адаптера.
5. Все runtime-инструменты установлены только из approved внутренних источников.
6. `setup-phase1-phase2-*` показывает, каких команд не хватает, но ничего не
   скачивает и не устанавливает.
7. `verify-phase1-phase2-*` проходит в окружении разработчика или честно
   показывает недостающие approved tools.

## Что не нужно делать в пилоте

- Поднимать Docker.
- Поднимать Neo4j локально.
- Встраивать Joern/jQAssistant в первый запуск.
- Автоматически скачивать бинарники из GitHub, Homebrew, npm, PyPI или других
  публичных источников.
- Делать отдельную копию workflow под каждую модель.

## Следующие шаги после пилота

1. Согласовать внутренний артефактный источник для approved tools.
2. Собрать корпоративные бинарники `codebase-memory-mcp`, `mcp-language-server`
   и `jdtls`.
3. Проверить реальный GigaCode/Qwen-compatible CLI на tool calling.
4. Заполнить `.gigacode-adapter.yaml` для DeepSeek-like wrapper, если он будет
   использоваться.
5. Решить, нужна ли фаза 3 для архитектурных графов в первом промышленном
   контуре.
