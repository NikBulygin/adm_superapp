# План проекта adm_superApp

В этой директории собрана дорожная карта проекта `adm_superApp` для медучреждений.

Текущая реализованная база проекта находится в `auth/`:

- backend на `Go + Gin`
- внутри `auth/` есть отдельный playground-фронт `auth/frontend` на `Nuxt + Nuxt UI + Tailwind` — **целевой вариант**: один общий клиент в корне репозитория — [`frontend/`](../frontend/) (см. [`01-target-architecture.md`](01-target-architecture.md))
- PostgreSQL, миграции, seed-данные и backup service
- JWT, refresh sessions и RBAC

**Целевая архитектура монорепозитория:**

- **`frontend/`** в корне — единое Nuxt-приложение для всего `adm_superApp`; оно обращается по HTTP к нескольким backend-микросервисам (разные base URL из `runtimeConfig`).
- **`auth/`**, **`marketplace/`**, **`crm/`**, **`mis/`** (и при необходимости другие) — **только backend + `db/`** в своей папке: API, миграции, Docker для сервиса и своей БД, без собственного `frontend/` внутри сервиса.

Документы в этой директории описывают именно эту схему; детали — в [`01-target-architecture.md`](01-target-architecture.md).

## Документы

### Архитектура

Файл: [`01-target-architecture.md`](01-target-architecture.md)

Что описано:

- целевая структура монорепозитория
- единый корневой `frontend/` и шаблон микросервиса `backend/` + `db/` для каждого домена
- роль `auth` как центра identity и RBAC
- правила для Docker, миграций, env и backup-процессов

### Общий доменный foundation

Файл: [`02-shared-domain-foundation.md`](02-shared-domain-foundation.md)

Что описано:

- общие сущности для marketplace, CRM и MIS
- multi-organization модель
- филиалы, сотрудники, специалисты, пациенты, услуги, записи
- границы ответственности между сервисами

### Marketplace MVP

Файл: [`03-marketplace-mvp.md`](03-marketplace-mvp.md)

Что описано:

- первый продуктовый модуль после `auth`
- каталог специалистов и услуг
- расписание и слоты
- онлайн-запись, перенос и отмена
- роли, API и frontend-сценарии

### Бизнес-логика marketplace

Файл: [`Marketplace/bussnesLogic/README.md`](Marketplace/bussnesLogic/README.md)

Что описано:

- B2B-модель для сторонних клиник
- white-label витрина клиники
- роли и scoped access
- сценарии записи для анонимного и авторизованного пользователя
- обязательность ИИН и недостающих полей профиля

Папка [`Plan/bussnesLogic/`](bussnesLogic/README.md) оставлена как редирект на новое расположение.

### CRM roadmap

Файл: [`04-crm-roadmap.md`](04-crm-roadmap.md)

Что описано:

- лиды и заявки
- воронка продаж
- задачи и напоминания
- коммуникации с пациентами
- синхронизация с marketplace

### MIS roadmap

Файл: [`05-mis-roadmap.md`](05-mis-roadmap.md)

Что описано:

- карточка пациента
- история приемов
- медицинские документы
- шаблоны осмотра и заключений
- требования к доступу к чувствительным данным

### Сквозные платформенные требования

Файл: [`06-cross-cutting.md`](06-cross-cutting.md)

Что описано:

- audit log
- уведомления
- файловое хранилище
- очереди и фоновые задачи
- observability
- backup/restore
- CI/CD и delivery process

## Порядок чтения

Если нужно быстро понять направление развития проекта:

1. открыть [`01-target-architecture.md`](01-target-architecture.md)
2. затем прочитать [`02-shared-domain-foundation.md`](02-shared-domain-foundation.md)
3. после этого перейти к [`03-marketplace-mvp.md`](03-marketplace-mvp.md)
4. затем прочитать [`04-crm-roadmap.md`](04-crm-roadmap.md) и [`05-mis-roadmap.md`](05-mis-roadmap.md)
5. завершить чтение документом [`06-cross-cutting.md`](06-cross-cutting.md)

## Приоритет реализации

Текущий рекомендованный порядок внедрения:

1. выровнять шаблон микросервисов (`backend/` + `db/`), завести единый `frontend/` и согласовать `runtimeConfig` под все API
2. реализовать общий foundation: организация, филиалы, сотрудники, специалисты, пациенты, услуги, базовые справочники
3. запустить `marketplace` как первый MVP с записью к специалистам
4. построить CRM-контур поверх потока заявок и записей
5. добавить MIS-контур для медицинских данных и документов
6. усилить платформенные возможности: аудит, уведомления, очереди, backup, observability
