# План реализации marketplace — backend

## Цель

Реализовать `marketplace` как отдельный сервис для `adm_superApp`, который отвечает за:

- каталог специалистов
- каталог услуг
- расписание
- свободные слоты
- запись, отмену и перенос приема

Дополнительное требование бизнеса: это B2B white-label сервис для сторонних клиник.

Это означает:

- каждая клиника работает в своем data scope
- у каждой клиники своя публичная витрина, домен, тексты и тема (конфиг хранится в БД, отдаётся API)
- клиника управляет только своей админкой
- часть ролей работает в рамках одной клиники, часть — в рамках всей платформы

За reference берем pet project `medCalendar`, но проектируем новую реализацию уже под production-like сценарии и дальнейший рост в CRM и MIS.

План по UI и Nuxt — отдельно: [`../frontend/implementation-plan.md`](../frontend/implementation-plan.md).

## Почему идем в порядке: БД -> сущности -> API

Как backend-разработчик на `Go`, сначала фиксируем PostgreSQL-схему и бизнес-ограничения, затем сущности и сервисы, затем HTTP API.

## 1. Этап базы данных

### 1.1. Поднять PostgreSQL в контейнере

Для `marketplace` нужен свой контейнер БД в сервисной директории.

Базовый состав:

- `marketplace/docker-compose.yml`
- `marketplace/backend/`
- `marketplace/db/migrations/`
- `marketplace/db/seeds/`
- `marketplace/db/backup/`

Рекомендуемая версия: `PostgreSQL 16`.

### 1.2. Сначала проектируем таблицы

Для MVP рекомендуемый стартовый набор:

- `clinic_branches`
- `clinic_frontend_configs`
- `clinic_domains`
- `clinic_members`
- `clinic_member_roles`
- `specialties`
- `specialists`
- `specialist_specialties`
- `services`
- `specialist_services`
- `schedule_templates`
- `schedule_exceptions`
- `schedule_slots`
- `patient_refs`
- `appointments`
- `appointment_events`

### 1.2.1. Дополнительные таблицы под white-label и роли

#### Публичная витрина клиники

- `clinic_frontend_configs`
- `clinic_domains`
- опционально позже: `clinic_pages`, `clinic_assets`

Минимум настроек: `clinic_slug`, `domain`, `theme_config`, `landing_config`, `seo_config`, статус публикации.

#### Доступ сотрудников

- `clinic_members`
- `clinic_member_roles`

### 1.3. Почему не хранить все расписание в JSONB

Реляционная модель: `schedule_templates`, `schedule_exceptions`, `schedule_slots` — для блокировок, индексов и отчётов.

### 1.4. Ключевые ограничения БД

- foreign keys
- уникальность слота по времени и специалисту
- индексы на `specialist_id`, `clinic_branch_id`, `starts_at`, `status`
- индексы на `appointments`
- `CHECK ends_at > starts_at`
- уникальность `clinic_slug` и `domain`

### 1.5. Порядок миграций

1. справочники и филиалы
2. white-label и домены
3. члены клиник и роли
4. специалисты и услуги
5. расписание
6. записи
7. журнал событий

## 2. Этап доменных сущностей

Структура `marketplace/backend/internal`:

- `clinicconfig`
- `clinicmember`
- `branch`
- `specialty`
- `specialist`
- `servicecatalog`
- `schedule`
- `appointment`
- `patientref`
- `config`
- `http`
- `shared`

### 2.1. Сущности первого этапа

`ClinicBranch`, `ClinicFrontendConfig`, `ClinicDomain`, `ClinicMember`, `ClinicMemberRole`, `Specialty`, `Specialist`, `Service`, `SpecialistService`, `ScheduleTemplate`, `ScheduleException`, `ScheduleSlot`, `PatientRef`, `Appointment`, `AppointmentEvent`.

### 2.2. Пакеты

Минимум: `model.go`, `dto.go`, `repository.go`, `service.go`, `handler.go`.

### 2.3. Бизнес-правила (service layer)

- транзакционная запись в слот
- scope клиники для админа
- врач — только свои записи
- анонимная запись — обязательные поля пациента
- авторизованный — ИИН и дозаполнение недостающих полей (контракт с `auth`)

### 2.4. Модель прав

`role_code` + `scope_type` + `scope_id`; alias `admin.<clinic_code>` для UI/аудита, не как единственный источник истины.

## 3. Этап API

### 3.1. Публичное API

- `GET /public/clinic`
- `GET /public/clinic/theme`
- `GET /branches`, `GET /specialties`, `GET /specialists`, `GET /specialists/:id`, `GET /services`
- `GET /availability`
- `POST /appointments`

### 3.2. Внутреннее API клиники

`GET|POST|PATCH /admin/...` для branches, specialists, services, schedules, appointments, `frontend-config`.

### 3.3. API врача

`GET /doctor/me/schedule`, `GET /doctor/me/appointments`, календарь.

### 3.4. API call-центра

`GET|POST /call-center/...`, поиск пациентов.

### 3.5. API sales

`GET|POST /sales/...`, список клиник в scope.

### 3.6. API пациента

`GET /me/appointments`, отмена и т.д.

## 4. Интеграция с auth

- JWT, middleware, scope организации/клиники
- договорённость: недостающие `phone` / `IIN` дозаполняются через `auth` до вызова `POST /appointments` (см. sequence в [`diagrams/02-booking-sequence.puml`](diagrams/02-booking-sequence.puml))
- `marketplace` хранит snapshot данных в записи

## 5. Очередь реализации (backend)

1. каркас `marketplace/backend` + `db`, docker-compose, PostgreSQL
2. миграции и seed
3. доменные пакеты
4. публичный API (витрина + availability + запись)
5. внутренние API (admin, doctor, call-center, sales)

Параллельно UI — по [`../frontend/implementation-plan.md`](../frontend/implementation-plan.md).

## 6. Критерии готовности backend

- миграции применяются на чистую БД
- публичные ручки отдают конфиг клиники и слоты
- `POST /appointments` с транзакцией и блокировкой слота
- scoped доступ для admin/doctor/call-center/sales
- healthcheck и `.env.example`

## 7. Первые шаги в коде

1. каркас сервиса
2. docker-compose + PostgreSQL
3. миграции расписания и записей
4. репозитории `schedule` + `appointment`
5. `GET /availability` и `POST /appointments`

UML: [`diagrams/01-domain-uml.puml`](diagrams/01-domain-uml.puml).
