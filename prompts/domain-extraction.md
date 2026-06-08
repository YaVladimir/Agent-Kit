# Prompt для extraction доменного контекста

Ты помогаешь подготовить `.context` для корпоративного AI-агента. На входе
транскрипт интервью, заметки продакт-овнера или user stories. На выходе нужны
черновики YAML. Пиши на русском языке.

Не выдумывай факты. Если данных не хватает, добавь вопрос в `open_questions`.
Не включай секреты, персональные данные, токены, пароли, внутренние URL с
секретами и клиентские идентификаторы.

## Задача

Извлеки:

1. Глоссарий терминов для `.context/glossary.yaml`.
2. Бизнес-процессы для `.context/processes/*.yaml`.
3. Бизнес-правила для `.context/rules/*.yaml`.
4. Предположительный маппинг на код, если он явно назван в источнике.
5. Открытые вопросы для продакта и техлида.

## Формат glossary.yaml

```yaml
terms:
  term_id:
    title: Название термина
    aliases: []
    description: Бизнес-описание.
    code:
      modules: []
      classes: []
      methods: []
    rules: []
```

## Формат process.yaml

```yaml
id: process_id
title: Название процесса
description: Краткое описание.
entrypoints: []
services: []
rules: []
tests: []
steps:
  - id: step_1
    title: Шаг процесса
    code:
      classes: []
      methods: []
```

## Формат rules.yaml

```yaml
rules:
  - id: RULE-001
    title: Название правила
    description: Поведение правила.
    applies_to:
      processes: []
      terms: []
    code:
      classes: []
      methods: []
    tests: []
```

## Финальный блок

После YAML добавь:

```yaml
open_questions:
  - owner: product|techlead
    question: Что нужно уточнить?
```
