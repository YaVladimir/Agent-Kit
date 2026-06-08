# Соответствие манифесту

Этот файл связывает манифест внедрения AI-кодингового агента с текущими
артефактами Agent Kit. Его цель — быстро показать, что уже реализовано как
шаблонный проект, что является ручным шагом внедрения, а что сознательно
оставлено для следующих фаз.

## Итоговый статус

Текущий kit закрывает переносимый пилот для фаз 1, 2, минимальной no-Docker
фазы 3 и базовой части фазы 4:

- агентский workflow и русскоязычные инструкции;
- шаблоны для продуктового репозитория;
- доменный `.context`;
- локальные stdio MCP-серверы `gigacode-context` и `summary-mcp`;
- локальный no-Docker MCP-сервер `architecture-mcp` для архитектурного графа;
- Qwen-compatible MCP config;
- контракт адаптера для Qwen Coder, DeepSeek v4 Flash, DeepSeek-like и других LLM;
- machine-readable passport kit в `agent-kit.manifest.json`;
- no-Docker сценарий;
- корпоративно безопасный manual setup без скрытых внешних загрузок.

Расширенная фаза 3 с Neo4j/jQAssistant/Joern и расширенная фаза 4 с интервью,
транскрибацией и extraction остаются roadmap-слоями. Для шаблонного проекта
готов минимальный файловый backend, который можно заменить корпоративным
графовым backend без смены агентского workflow.

## Матрица соответствия

| Требование манифеста | Статус | Доказательство в репозитории | Как проверить |
|---|---|---|---|
| Шаблонный проект можно развернуть в продуктовом репозитории | Реализовано | `agent-kit.manifest.json`, `scripts/copy-templates.ps1`, `scripts/copy-templates.sh`, `templates/*`, `scripts/check-kit.ps1`, `scripts/check-kit.sh` | `check-kit.ps1` и `check-kit.sh` запускают smoke-test развёртывания во временный каталог и проверяют `AGENTS.md`, `QWEN.md`, `.context`, `.gigacode.yaml`, `.gigacode-adapter.yaml`, `.gigacode-kit.json` |
| Общение агента и текстовые инструкции на русском языке | Реализовано | `README.md`, `prompts/system.md`, `templates/AGENTS.md`, `skills/gigacode-java-enterprise/SKILL.md` | `scripts/check-kit.ps1` проверяет русскоязычное правило в системном промпте |
| Модель-независимый workflow: задача -> контекст -> поиск -> план -> код -> проверки | Реализовано | `prompts/system.md`, `templates/AGENTS.md`, `skills/gigacode-java-enterprise/SKILL.md`, `docs/model-agnostic-agent-test.md` | Прогнать dry-run из `docs/model-agnostic-agent-test.md` |
| Интеграция с Qwen Coder / GigaCode CLI | Реализовано как совместимый шаблон | `templates/qwen-settings.json`, `templates/qwen-settings.phase1-phase2.json`, `docs/gigacode-cli-integration.md` | Скопировать settings в `.qwen/settings.json` и запустить совместимый CLI из корня проекта |
| Возможность встроить DeepSeek v4 Flash, DeepSeek-like или другую LLM | Реализовано как контракт адаптера | `docs/model-adapter-contract.md`, `templates/adapter-compatibility.yaml`, `templates/adapters/deepseek-v4-flash.yaml`, `templates/tool-manifest.json`, `docs/cli-integration-notes.md` | Выбрать starter profile, заполнить `.gigacode-adapter.yaml`, загрузить `.gigacode-tools.json` в wrapper и пройти acceptance checklist |
| Машиночитаемый контракт tools для MCP/function-calling/wrapper-loop | Реализовано | `templates/tool-manifest.json`, `docs/model-adapter-contract.md`, `scripts/check-kit.*` | `check-kit.ps1`/`check-kit.sh` валидируют JSON и обязательные logical tools |
| Машиночитаемый паспорт kit для ревью и wrapper'ов | Реализовано | `agent-kit.manifest.json`, `scripts/copy-templates.*`, `scripts/check-kit.*` | `check-kit.ps1`/`check-kit.sh` валидируют JSON, политики no-download/no-Docker и наличие Qwen/DeepSeek profiles |
| Фаза 1: навигация по коду через codebase/LSP/MCP | Реализовано как подключаемый слой | `templates/qwen-settings.phase1-phase2.json`, `docs/phase1-phase2-deployment.md`, `scripts/verify-phase1-phase2.*` | Установить approved tools из внутренних источников и запустить verify |
| Java LSP через Eclipse JDT LS | Реализовано как обязательная проверка окружения | `templates/.lsp.json`, `docs/phase1-phase2-deployment.md`, `scripts/verify-phase1-phase2.*` | `jdtls` должен быть в `PATH` или указан абсолютным путем в конфиге |
| TypeScript LSP | Реализовано как подключаемый слой | `templates/qwen-settings.phase1-phase2.json`, `docs/phase1-phase2-deployment.md` | Проверить `typescript-language-server --version` и verify |
| Фаза 2: иерархические summary | Реализован минимальный MCP | `mcp/summary-mcp/src/summary_mcp/server.py`, `templates/qwen-settings.phase1-phase2.json` | Запустить `summary-mcp` как stdio MCP и проверить tools `get_summary`, `find_module`, `list_packages` |
| Фаза 4: доменный контекст | Реализован базовый слой | `templates/context/*`, `schemas/*.yaml`, `mcp/gigacode-context/src/gigacode_context/server.py`, `templates/tool-manifest.json`, `examples/todoserver-context/*` | Заполнить `.context`, запустить `gigacode-context`, проверить `repo_overview`, `lookup_domain`, `translate_task`, `find_rule`, `list_processes`, `list_rules`, `find_change_points` |
| No-Docker пилот | Реализовано | `docs/no-docker-architecture.md`, `docs/phase1-phase2-deployment.md` | Использовать локальные файлы/SQLite/approved artifacts вместо Docker-сервисов |
| Корпоративная безопасность: без автоматической загрузки стороннего софта | Реализовано | `scripts/setup-phase1-phase2-*`, `docs/phase1-phase2-deployment.md`, `scripts/check-kit.ps1` | `check-kit.ps1` запрещает автоустановочные команды в setup-скриптах |
| Фаза 3: архитектурный граф без Docker | Реализован минимальный MCP | `mcp/architecture-mcp/src/architecture_mcp/server.py`, `templates/context/architecture-graph.yaml`, `schemas/architecture-graph.schema.yaml`, `templates/tool-manifest.json` | Заполнить `.context/architecture-graph.yaml`, запустить `architecture-mcp`, проверить `trace_endpoint_to_db`, `find_blast_radius`, `check_layer_violations`, `find_spring_wiring` |
| Фаза 3: Neo4j/jQAssistant/Joern backend | Отложено как расширение | `docs/phase1-phase2-deployment.md`, `docs/no-docker-architecture.md` | Для пилота используется файловый no-Docker backend; Neo4j/jQAssistant подключаются позже как другой backend того же tool contract |
| Расширенная фаза 4: интервью, транскрибация, extraction | Отложено | `docs/phase1-phase2-deployment.md`, манифест | Нужен отдельный workflow после согласования процесса с продуктом и безопасниками |
| Open-source лицензирование | Реализовано | `LICENSE`, `NOTICE`, `README.md` | Проверить Apache License 2.0 |

## Что считается готовым для пилота

Пилот можно считать готовым на уровне шаблонного проекта, если:

1. `scripts/check-kit.ps1` или `scripts/check-kit.sh` проходит, включая
   smoke-test развёртывания шаблонов.
2. `scripts/copy-templates.ps1` или `scripts/copy-templates.sh` разворачивает
   шаблоны в пустой продуктовый репозиторий.
3. В продуктовом репозитории есть `AGENTS.md`, `QWEN.md`, `.context`,
   `.gigacode.yaml`, `.gigacode-adapter.yaml`, `.gigacode-tools.json`,
   `.gigacode-kit.json`,
   `.gigacode-adapters/qwen-coder.yaml`,
   `.gigacode-adapters/deepseek-v4-flash.yaml`.
4. Для выбранного CLI заполнен профиль адаптера на основе starter profile.
5. Wrapper выбранной модели читает `.gigacode-tools.json` или внутренний
   эквивалент.
6. Все runtime-инструменты установлены только из approved внутренних источников.
7. `setup-phase1-phase2-*` показывает, каких команд не хватает, но ничего не
   скачивает и не устанавливает.
8. `verify-phase1-phase2-*` проходит в окружении разработчика или честно
   показывает недостающие approved tools.

## Что не нужно делать в пилоте

- Поднимать Docker.
- Поднимать Neo4j локально.
- Встраивать Joern/jQAssistant в первый запуск.
- Менять агентский workflow при замене файлового phase 3 backend на Neo4j.
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
