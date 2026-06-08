# Фазы 1 и 2: ручное развертывание

Этот документ описывает запуск слоя навигации по коду (Фаза 1) и слоя
иерархических summary (Фаза 2) без автоматической загрузки стороннего софта.

Скрипты `setup-phase1-phase2-*` в этом репозитории работают только как
preflight-проверки. Они не вызывают `curl`, `go install`, `npm install`,
`pip install`, `winget`, `choco`, `brew`, `apt` и не скачивают артефакты из
интернета.

## Целевое состояние

После ручной установки агент получает:

1. Навигацию по коду через `codebase-memory-mcp`.
2. Семантическую навигацию через `mcp-language-server` + LSP-серверы.
3. Архитектурные summary через `summary-mcp`.
4. Доменный контекст и `find_change_points` через `gigacode-context`.

## Что нужно согласовать с безопасниками

Для рабочего контура все артефакты должны приходить из одобренного внутреннего
источника: корпоративный портал, внутренний package registry, артефактный
репозиторий или заранее проверенный golden image.

Минимальный список артефактов:

- Git.
- Python 3.11+ или 3.12+.
- Node.js LTS и npm.
- Go toolchain, если `mcp-language-server` собирается из исходников внутри
  компании.
- Java JDK 17+.
- Eclipse JDT Language Server (`jdtls`).
- `codebase-memory-mcp`.
- `mcp-language-server`.
- `typescript-language-server`.
- Python-пакеты `fastmcp` и `pyyaml` из внутреннего PyPI mirror.

Если внешний проект нужен как исходник, безопасный путь такой: проверка исходного
кода, сборка внутри корпоративного CI, публикация бинарника во внутренний
репозиторий, установка разработчиками только из внутреннего источника.

## Рекомендуемые пути установки

Команды ниже не скачивают зависимости. Они показывают, куда положить уже
одобренные артефакты и что должно оказаться в `PATH`.

### macOS

Рекомендуемый каталог:

```bash
mkdir -p "$HOME/.local/gigacode-tools/bin"
```

Положи или распакуй одобренные бинарники так, чтобы были доступны команды:

```bash
git --version
python3 --version
node --version
npm --version
go version
java -version
jdtls --version
codebase-memory-mcp --version
mcp-language-server --help
typescript-language-server --version
```

Добавь корпоративный каталог инструментов в shell profile:

```bash
export PATH="$HOME/.local/gigacode-tools/bin:$PATH"
```

### Linux

Рекомендуемый каталог:

```bash
mkdir -p "$HOME/.local/gigacode-tools/bin"
```

Положи или распакуй одобренные бинарники так, чтобы были доступны команды:

```bash
git --version
python3 --version
node --version
npm --version
go version
java -version
jdtls --version
codebase-memory-mcp --version
mcp-language-server --help
typescript-language-server --version
```

Добавь корпоративный каталог инструментов в shell profile:

```bash
export PATH="$HOME/.local/gigacode-tools/bin:$PATH"
```

### Windows

Рекомендуемый каталог:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.local\gigacode-tools\bin"
```

Положи или распакуй одобренные бинарники так, чтобы были доступны команды:

```powershell
git --version
python --version
node --version
npm --version
go version
java -version
jdtls --version
codebase-memory-mcp --version
mcp-language-server --help
typescript-language-server --version
```

Добавь корпоративный каталог инструментов в пользовательский `PATH`:

```powershell
$tools = "$env:USERPROFILE\.local\gigacode-tools\bin"
[Environment]::SetEnvironmentVariable(
  "Path",
  $tools + ";" + [Environment]::GetEnvironmentVariable("Path", "User"),
  "User"
)
```

После изменения `PATH` открой новый терминал.

## Установка `mcp-language-server`

Предпочтительный корпоративный вариант:

1. Безопасники утверждают upstream-проект и конкретную версию.
2. CI внутри компании собирает бинарник.
3. Бинарник публикуется во внутренний артефактный репозиторий.
4. Разработчик получает готовый `mcp-language-server` из внутреннего источника.
5. Каталог с бинарником добавляется в `PATH`.

Если компания разрешает сборку на машине разработчика, исходники и Go modules
должны подтягиваться только из внутреннего mirror. В публичный интернет скрипты
этого репозитория не ходят.

## Установка `codebase-memory-mcp`

Предпочтительный корпоративный вариант:

1. Безопасники утверждают upstream-проект и конкретную версию.
2. Бинарник собирается или проверяется внутри компании.
3. Артефакт публикуется во внутреннем репозитории.
4. Разработчик кладет `codebase-memory-mcp` в корпоративный каталог инструментов.
5. Команда `codebase-memory-mcp` должна быть доступна из `PATH`.

## Установка Eclipse JDT Language Server

Для Java-навигации нужен `jdtls` и JDK 17+.

Порядок:

1. Получить одобренный архив Eclipse JDT Language Server из внутреннего
   источника.
2. Распаковать его в корпоративный каталог инструментов.
3. Добавить launcher `jdtls` или `jdtls.bat` в `PATH`.
4. Проверить `java -version`.
5. Проверить `jdtls --version` или запуск `jdtls` без ошибки загрузчика.

Если `jdtls` не лежит в `PATH`, в `templates/qwen-settings.phase1-phase2.json`
можно заменить `jdtls` на абсолютный путь к launcher.

## Установка TypeScript LSP

Нужен `typescript-language-server`.

Предпочтительный вариант: использовать внутренний npm registry или заранее
собранный корпоративный Node.js пакет. После установки команда
`typescript-language-server` должна быть доступна из `PATH`.

## Python-зависимости для Фазы 2

Для локальных MCP-серверов нужны:

- `fastmcp`
- `pyyaml`

Они должны устанавливаться из внутреннего PyPI mirror или входить в
корпоративный Python-образ. Проверка:

```bash
python3 -c "import fastmcp, yaml; print('ok')"
```

На Windows:

```powershell
python -c "import fastmcp, yaml; print('ok')"
```

## MCP-конфиг

Шаблон для фаз 1+2:

- `templates/qwen-settings.phase1-phase2.json`

Ручной шаг:

### macOS/Linux

```bash
mkdir -p .qwen
cp templates/qwen-settings.phase1-phase2.json .qwen/settings.json
```

### Windows

```powershell
New-Item -ItemType Directory -Force .qwen
Copy-Item templates\qwen-settings.phase1-phase2.json .qwen\settings.json -Force
```

После этого Gigacode/Qwen-compatible CLI должен запускаться из корня проекта,
где лежит `.qwen/settings.json`.

## Проверка

### macOS

```bash
chmod +x scripts/setup-phase1-phase2-macos.sh
chmod +x scripts/verify-phase1-phase2.sh
./scripts/setup-phase1-phase2-macos.sh
./scripts/verify-phase1-phase2.sh
```

### Linux

```bash
chmod +x scripts/setup-phase1-phase2-linux.sh
chmod +x scripts/verify-phase1-phase2.sh
./scripts/setup-phase1-phase2-linux.sh
./scripts/verify-phase1-phase2.sh
```

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-phase1-phase2-windows.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify-phase1-phase2-windows.ps1
```

`setup` показывает, какие команды отсутствуют. `verify` проверяет, что окружение
готово для запуска фаз 1+2.

## Состав MCP-конфига

- `codebase-memory` — структурная навигация по коду.
- `lsp-java` — `mcp-language-server` с `jdtls`.
- `lsp-typescript` — `mcp-language-server` с `typescript-language-server`.
- `summaries` — `summary-mcp` (`get_summary`, `find_module`, `list_packages`).
- `gigacode-context` — доменный `.context` слой.

## Проверка сценария в CLI

Тестовый запрос:

```text
Код пока не меняй.
1. Через codebase/LSP найди сервис, где создается Todo.
2. Через summaries опиши модуль и архитектуру.
3. Через context найди доменные точки изменения.
4. Покажи план, куда добавить поле deadline.
```

Ожидаемое поведение:

- агент отвечает по-русски;
- использует MCP tools до изменения кода;
- называет конкретные классы и методы;
- не начинает правку до плана.

## Что не входит в эту фазу

- Neo4j/jQAssistant/Joern — это Фаза 3.
- Автоматическая транскрибация интервью и extraction — это расширение Фазы 4.
