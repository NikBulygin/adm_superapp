# Сквозные платформенные требования

## Назначение

`auth`, `marketplace`, `crm` и `mis` должны развиваться как отдельные сервисы, но использовать единые правила для безопасности, наблюдаемости, доставки изменений и восстановления данных.

Этот документ фиксирует общие требования, которые нельзя откладывать до поздних стадий проекта.

## Audit log

Каждый сервис должен писать аудит для важных действий.

Минимальный набор полей аудита:

- `event_id`
- `service_name`
- `entity_type`
- `entity_id`
- `action`
- `performed_by_user_id`
- `organization_id`
- `clinic_branch_id`
- `request_id`
- `created_at`

Обязательные audit-сценарии:

- логин и logout
- изменение ролей и permissions
- создание, перенос и отмена записи
- изменение лида и задач
- чтение и изменение чувствительных медицинских данных

## Уведомления

Уведомления лучше планировать как отдельный контур, даже если сначала отправка будет выполняться внутри сервисов.

Каналы первой очереди:

- `email`
- `sms`
- `telegram`
- `whatsapp`

Типы событий первой очереди:

- подтверждение записи
- перенос записи
- отмена записи
- напоминание о визите
- новая задача сотруднику

Рекомендуемый путь развития:

1. простая отправка из backend сервиса
2. затем выделение notification layer с очередями и retry

## Файловое хранилище

Для `mis` и частично для `crm` потребуется отдельный подход к файлам.

На старте нужно зафиксировать:

- использование object storage или совместимого S3-слоя
- хранение только `storage_key` в БД
- разделение публичных и приватных файлов
- ограниченный срок жизни signed URLs

## Очереди и фоновые задачи

Даже если первая версия запускается без брокера сообщений, архитектура должна предусматривать фоновые задачи.

Типовые use cases:

- отправка уведомлений
- построение отчетов
- очистка и архивирование данных
- периодические backup-задачи
- синхронизация статусов между сервисами

Минимальный путь:

1. cron или internal worker внутри сервиса
2. затем переход на очередь сообщений или job runner

## Observability

Каждый сервис должен поддерживать:

- structured logging
- correlation id или request id
- healthcheck endpoint
- readiness/liveness подход для контейнеров
- базовые метрики по HTTP, ошибкам и времени ответа

Логи должны быть пригодны для ответа на вопросы:

- кто выполнил действие
- в каком сервисе произошла ошибка
- какой запрос вызвал проблему
- какой tenant или филиал был затронут

## Безопасность

Базовые требования:

- secrets только через env или secret manager
- access token с коротким TTL
- refresh sessions с отзывом и ротацией
- rate limiting
- CORS по явному allowlist
- аудит административных действий
- разграничение доступа по organization и clinic_branch scope

Для `mis` дополнительно:

- аудит чтения чувствительных данных
- запрет широкого доступа по ролям без scope
- контроль скачивания документов

## Backup и restore

Каждый сервис обязан иметь собственный backup-контур в `db/backup/`.

Минимальные требования:

- отдельная утилита backup
- запуск по расписанию
- ручной запуск одного backup
- retention policy
- инструкция по restore
- проверка восстановления на staging

Рекомендуемая структура:

```text
db/
  migrations/
  seeds/
  backup/
    cmd/
      main.go
    Dockerfile
    README.md
```

## Конфигурация и env strategy

**Микросервисы** — только backend-окружение:

- `service-name/backend/.env.example`
- список обязательных переменных в README сервиса
- **CORS**: `AllowedOrigins` должен включать origin единого фронта (например `http://localhost:3000` в dev)

**Единый клиент** в корне репозитория:

- [`frontend/.env.example`](../frontend/.env.example) — все публичные base URL к API, например:
  - `NUXT_PUBLIC_AUTH_API_BASE`
  - `NUXT_PUBLIC_MARKETPLACE_API_BASE`
  - `NUXT_PUBLIC_CRM_API_BASE`
  - `NUXT_PUBLIC_MIS_API_BASE`

Разделение переменных по окружениям: `local` / `staging` / `production`.

Рекомендуемые группы переменных на бэкендах:

- app
- database
- jwt / auth validation
- cors
- storage
- notifications
- observability

## API contracts

Чтобы сервисы легче интегрировались друг с другом, нужно унифицировать:

- формат ошибок
- формат пагинации
- структуру metadata и filters
- naming для permission codes
- версионирование API при необходимости

## CI/CD и delivery process

**На каждый микросервис** — pipeline backend:

1. lint
2. test
3. build backend image
4. migration validation (применимость на чистую БД)
5. deploy

**На корневой `frontend/`** — отдельный pipeline:

1. install
2. lint / typecheck
3. build (и при необходимости build Docker image фронта)
4. deploy

Минимальный набор quality gates:

- сборка каждого затронутого backend проходит
- `frontend` typecheck и lint проходят
- миграции сервисов применимы на чистую БД
- smoke healthcheck бэкендов после деплоя

## Документация

Каждый **микросервис** должен иметь:

- `README.md`
- `docs/architecture.md` или `docs/README.md`
- описание env backend
- описание API
- описание backup и restore

Корневой **`frontend/`** — свой `README.md` и описание env (`NUXT_PUBLIC_*`), интеграция с `auth` и остальными API.

`Plan/` хранит продуктовый roadmap, а сервисные `docs/` хранят технические детали реализации.

## Приоритет внедрения сквозных требований

### Сразу в первой итерации

- structured logs
- healthcheck
- `.env.example`
- backup utility
- базовый audit
- единый формат ошибок

### Во второй итерации

- уведомления с retry
- worker-процессы
- object storage
- расширенные метрики и dashboards

### В третьей итерации

- централизованный tracing
- event-driven интеграции
- расширенные security controls и compliance-процессы
