# Интеграция с GigaCode CLI

Эта инструкция описывает, как подключить kit к внутреннему `gigacode cli`.
Поскольку корпоративный CLI недоступен локально, ориентиром служит совместимая
модель Qwen Code: настройки MCP через `mcpServers` в `settings.json`, проектные
инструкции через `AGENTS.md`/`QWEN.md`, LSP через `.lsp.json` и отдельный флаг
запуска.

## Цель

После настройки разработчик запускает CLI из корня репозитория и получает
агента, который:

1. Общается на русском языке.
2. Читает `AGENTS.md`, `QWEN.md` и `.context`.
3. Видит MCP-инструменты `basecode-mcp-server` и `gigacode-context`.
4. Перед правками ищет контекст через MCP, а не только через `grep`.
5. Использует LSP, если он доступен, но не блокируется без LSP.

## Файлы в продуктовом репозитории

Минимальный набор:

```text
repo-root/
  AGENTS.md
  QWEN.md
  .lsp.json
  .gigacode.yaml
  .gigacode-adapter.yaml
  .gigacode-tools.json
  .gigacode-kit.json
  .gigacode-adapters/
    qwen-coder.yaml
    deepseek-v4-flash.yaml
  .context/
    index.md
    architecture.md
    glossary.yaml
    processes/
    rules/
```

`AGENTS.md` задаёт поведение агента.  
`QWEN.md` подключает верхнеуровневый контекст.  
`.context` содержит знания о продукте.  
`.lsp.json` нужен только для LSP-навигации.  
`.gigacode.yaml` хранит настройки проекта, понятные wrapper'у.
`.gigacode-adapter.yaml` фиксирует совместимость конкретного CLI/wrapper с
контрактом kit.
`.gigacode-tools.json` содержит машиночитаемый список logical tools, input
schemas и backend mapping для MCP/function-calling/wrapper-loop.
`.gigacode-kit.json` описывает развернутый kit как пакет: поддерживаемые модели,
output-файлы, проверки и security invariants.
`.gigacode-adapters/` содержит starter profiles для Qwen Coder и
DeepSeek v4 Flash wrapper'ов.

## Слои промптов

Рекомендуемый порядок:

```text
prompts/system.md
  -> prompts/corporate.md
  -> repo/AGENTS.md или repo/QWEN.md
  -> пользовательская задача
```

Если GigaCode CLI поддерживает только один системный промпт, wrapper может
собирать его из этих частей при старте.

## MCP через settings.json

В Qwen Code MCP-серверы подключаются через объект `mcpServers` в `settings.json`.
GigaCode CLI желательно сделать совместимым с этим форматом или написать
адаптер.

Пример проектного конфига для macOS/Linux:

```json
{
  "mcpServers": {
    "basecode": {
      "command": "/opt/gigacode/bin/basecode-mcp-server",
      "args": [],
      "cwd": ".",
      "timeout": 60000,
      "trust": false
    },
    "gigacode-context": {
      "command": "python3",
      "args": ["tools/gigacode-context/server.py"],
      "cwd": ".",
      "includeTools": [
        "repo_overview",
        "lookup_domain",
        "get_module_summary",
        "find_change_points"
      ],
      "timeout": 30000,
      "trust": false
    }
  }
}
```

Путь `/opt/gigacode/bin/basecode-mcp-server` замени на реальный путь на рабочем
компьютере. На macOS M4 это может быть путь внутри `/opt/homebrew/bin`,
`/Applications/...` или корпоративной директории установки. На Linux это часто
`/usr/local/bin/...`, `/opt/...` или путь внутри домашней директории.

Если сервер запускается через `node`, `java`, `uv`, `npx` или другой runner,
укажи его в `command`, а параметры запуска в `args`.

Пример для Windows, если у кого-то из коллег всё же будет такая машина:

```json
{
  "command": "C:\\path\\to\\basecode-mcp-server.exe",
  "args": [],
  "cwd": "."
}
```

## Как заставить агента использовать basecode-mcp-server

Полностью “заставить” LLM невозможно, но можно сделать использование MCP
обязательной частью процесса.

### 1. Зарегистрировать сервер с понятным alias

Используй короткий alias:

```json
"basecode": {
  "command": "/opt/gigacode/bin/basecode-mcp-server",
  "args": [],
  "cwd": "."
}
```

Если CLI префиксует имена tools alias'ом, инструменты могут выглядеть как
`basecode__search_symbols`, `basecode__read_file`, `basecode__find_references`
или похожим образом.

### 2. Явно описать правило в AGENTS.md

Добавь в проектные инструкции:

```md
Перед любым изменением Java-кода сначала используй basecode MCP:

1. Найди релевантные классы и методы.
2. Прочитай определения найденных символов.
3. Найди использования и похожие реализации.
4. Только после этого составляй план изменения.

Если basecode MCP недоступен, явно напиши об этом и используй резервный поиск
через LSP или `rg`.
```

### 3. Дать агенту обязательный маршрут

В системном промпте или `AGENTS.md`:

```md
Для задач по коду не начинай реализацию, пока не выполнишь хотя бы один поиск
через basecode MCP или не объяснишь, почему MCP недоступен.
```

### 4. Проверять в первом ответе агента

Команда для проверки:

```text
Сначала покажи, какие MCP-инструменты доступны, затем через basecode найди
TodoService и все места его использования. Код пока не меняй.
```

Если агент не вызывает MCP, проблема обычно в одном из трёх мест:

- сервер не зарегистрирован или не стартует;
- CLI не отдаёт tools модели;
- описания tools слишком непонятные, и модель не понимает, зачем они нужны.

### 5. Ограничить хаотичные инструменты

Если CLI поддерживает `includeTools`/`excludeTools`, на пилоте лучше оставить
только нужный минимум. Чем меньше похожих tools, тем выше шанс, что агент будет
использовать правильные.

## Что делать, если LSP не работает

LSP полезен, но для первого пилота не обязателен. Если `basecode-mcp-server`
уже установлен, можно временно жить так:

```text
basecode MCP -> поиск символов, чтение определений, связи, примеры
gigacode-context MCP -> бизнес-контекст и точки изменения
rg/read-file -> резервный поиск
LSP -> включить позже
```

Проверки LSP:

1. Запускать CLI из корня Maven/Gradle-проекта.
2. Убедиться, что `.lsp.json` лежит в корне репозитория.
3. Убедиться, что `jdtls` доступен в `PATH` или указан абсолютным путём.
4. Для Qwen-compatible CLI запускать с флагом вроде `--experimental-lsp`.
5. Проверить, что Java version проекта совпадает с окружением LSP.
6. Для Lombok/MapStruct учитывать annotation processing: JDT LS часто требует
   корректный Maven import и доступ к dependency cache.

Установка `jdtls` выполняется только из одобренного внутреннего источника:

```text
1. Получить approved-архив Eclipse JDT LS из внутреннего источника.
2. Распаковать его во внутренний каталог инструментов.
3. Добавить launcher jdtls/jdtls.bat в PATH или указать абсолютный путь в .lsp.json.
4. Проверить java -version и запуск jdtls.
```

Если LSP падает, не блокируй пилот. Зафиксируй проблему и используй
`basecode-mcp-server` как основной навигационный слой.

## Минимальная проверка интеграции

Из корня проекта:

```text
Проверь интеграцию. Код не меняй.
1. Подтверди, что видишь инструкции репозитория.
2. Покажи доступные MCP-инструменты.
3. Через basecode найди основной service.
4. Через .context объясни архитектуру проекта.
5. Составь план, куда добавлять новое поле Todo.
```

Ожидаемый результат: агент отвечает на русском, вызывает MCP, не пишет код до
плана и явно называет найденные классы.
