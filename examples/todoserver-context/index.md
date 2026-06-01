# Обзор репозитория TodoServer

TodoServer — небольшой Spring Boot 2.6 проект на Java 11. Он отдаёт REST
маршруты для CRUD и поиска todo-задач, которые сохраняются через Spring Data
JPA.

## Основные слои

- `controllers`: HTTP-точки входа. `TodoController` мапит todo-маршруты и
  делегирует работу в `TodoService`.
- `services`: прикладная логика. `TodoService` выполняет CRUD, фильтрацию,
  логирование, поиск entity и операции persistence.
- `repositories`: доступ к persistence. `TodoRepository` расширяет
  `JpaRepository`.
- `model`: JPA-сущности. `Todo` содержит `id`, `text`, `completed` и `color`.
- `dto` и `filters`: объекты тела запроса.
- `mappers`: MapStruct mapper для частичных обновлений из `TodoDto` в `Todo`.
- `exceptions`: доменные исключения, связанные с HTTP-ответами, например
  `EntityNotFoundException`.

## Сборка

- Maven-проект.
- Java 11.
- Spring Boot parent `2.6.0`.
- Используются Lombok и MapStruct annotation processors.

## Тесты

Во время read-only осмотра файлов `src/test` не было видно. Для функциональных
изменений лучше добавлять тесты до ручных проверок HTTP-маршрутов.
