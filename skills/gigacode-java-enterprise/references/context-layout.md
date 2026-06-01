# Структура контекста

Используй такую структуру в продуктовых репозиториях:

```text
repo-root/
  AGENTS.md или QWEN.md
  .lsp.json
  .gigacode.yaml
  .context/
    index.md
    architecture.md
    glossary.yaml
    processes/
      example-process.yaml
    rules/
      example-rules.yaml
  .gigacode/
    cache/
    index.sqlite
```

Коммить человеко-проверяемый контекст:

- `.context/index.md`
- `.context/architecture.md`
- `.context/glossary.yaml`
- `.context/processes/*.yaml`
- `.context/rules/*.yaml`

Не коммить машинный кэш:

- `.gigacode/cache/`
- `.gigacode/index.sqlite`
- `.gigacode/tmp/`

Сгенерированные summaries можно коммитить только если команда согласилась
ревьюить их как тесты или документацию.

