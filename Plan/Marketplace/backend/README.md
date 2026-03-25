# Marketplace — backend (план)

Документация по микросервису `marketplace`: PostgreSQL, доменная модель на Go, HTTP API, интеграция с `auth`.

## Файлы

- [`implementation-plan.md`](implementation-plan.md) — пошаговый план: БД → сущности → API → интеграция с auth
- [`diagrams/01-domain-uml.puml`](diagrams/01-domain-uml.puml) — UML классов домена
- [`diagrams/02-booking-sequence.puml`](diagrams/02-booking-sequence.puml) — sequence: запись, конфликт, перенос, дозаполнение профиля

## Связь с фронтом

Контракты для корневого [`frontend/`](../../../frontend/) и UI-потоки — в соседней папке: [`../frontend/README.md`](../frontend/README.md).

Общая бизнес-логика (роли, white-label, запись) — [`../bussnesLogic/README.md`](../bussnesLogic/README.md).
