# Marketplace: планы по модулю

Прикладные материалы по `marketplace` для `adm_superApp`. Документация **разделена по слоям**:

| Папка | Содержимое |
|-------|------------|
| [`backend/`](backend/README.md) | PostgreSQL, Go/Gin, домен, HTTP API, диаграммы домена и sequence записи |
| [`frontend/`](frontend/README.md) | корневой Nuxt [`frontend/`](../../frontend/), white-label, маршруты, composables, диаграмма UI |
| [`bussnesLogic/`](bussnesLogic/README.md) | бизнес-логика модуля marketplace: роли, запись, white-label, правила для backend |

## Контекст продукта

За основу UX берём pet project `medCalendar` (каталог, карточка врача, график, слоты, запись).

Целевая модель:

- отдельный **backend**-микросервис `marketplace` (`marketplace/backend` + `marketplace/db` в репозитории кода)
- единый **frontend** в корне репозитория — [`frontend/`](../../frontend/)
- B2B white-label для сторонних клиник (см. [`bussnesLogic/README.md`](bussnesLogic/README.md))

## Быстрые ссылки

- Backend-план: [`backend/implementation-plan.md`](backend/implementation-plan.md)
- Frontend-план: [`frontend/implementation-plan.md`](frontend/implementation-plan.md)
- Бизнес-логика marketplace: [`bussnesLogic/README.md`](bussnesLogic/README.md)

## Диаграммы PlantUML

- Домен и запись (backend): [`backend/diagrams/`](backend/diagrams/)
- Компоненты и состояния UI: [`frontend/diagrams/03-frontend-schedule.puml`](frontend/diagrams/03-frontend-schedule.puml)

Рендер: расширение PlantUML в IDE или [plantuml.com](https://www.plantuml.com/plantuml).

## Порядок работ (кратко)

1. backend: схема БД и API ([`backend/implementation-plan.md`](backend/implementation-plan.md))
2. frontend: витрина и запись ([`frontend/implementation-plan.md`](frontend/implementation-plan.md))

Так UI опирается на стабильные контракты API, а не наоборот.
