# План реализации marketplace — frontend

Корневой каталог приложения: [`frontend/`](../../../frontend/) (Nuxt + Nuxt UI + Tailwind). Код модуля marketplace **не** живёт в `marketplace/frontend` репозитория сервиса — только в общем клиенте.

## 1. Конфигурация и env

В `frontend/.env.example` и `nuxt.config.ts` → `runtimeConfig.public`:

- `authApiBase` — URL сервиса `auth`
- `marketplaceApiBase` — URL микросервиса `marketplace`

Опционально позже: единый gateway — тогда один base URL и префиксы путей.

CORS на `marketplace` backend должен разрешать origin dev-сервера фронта.

## 2. White-label: резолв клиники

Перед показом витрины нужно определить контекст клиники:

- по поддомену или полному домену (`Host`)
- или по сегменту пути `/:clinicSlug`

Дальше:

1. запрос `GET /public/clinic` и/или `GET /public/clinic/theme` на `marketplaceApiBase`
2. применение темы (цвета, логотип, типографика) через `ClinicThemeProvider` / `useClinicTheme`
3. кэширование конфига в памяти или Pinia на время сессии

## 3. Маршруты (рекомендация)

Публичная витрина (white-label):

- `/:clinicSlug` — лендинг клиники
- `/:clinicSlug/specialists`
- `/:clinicSlug/specialists/[id]` — карточка специалиста, график, слоты
- `/:clinicSlug/booking` — при необходимости отдельный шаг

Платформа (опционально):

- `/marketplace/...` — общий каталог, если нужен агрегатор

Кабинеты (после логина через `auth`):

- `/marketplace/admin/...` — админ клиники
- `/marketplace/admin/branding` — тема и контент витрины
- `/marketplace/doctor/schedule` — врач
- `/marketplace/call-center` — кол-центр
- `/marketplace/sales` — продажники
- `/account/appointments` — записи пациента

Точный префикс можно согласовать с UX; важно разделить **публичный white-label** и **закрытые кабинеты**.

## 4. Composables

Рекомендуемые:

- `useMarketplaceApi()` — `fetch` с base URL, опционально Bearer из `useAuthSession`
- `useClinicContext()` — текущий `clinicSlug` / id из route или middleware
- `useClinicTheme()` — загрузка и применение темы
- `useBookingFlow()` — шаги как в `medCalendar`: специалист → дата → слот → форма
- `useScheduleAdmin`, `useAppointmentsAdmin` — админка

## 5. Поток записи

### Гость

Перед `POST /appointments` — форма: имя, фамилия, возраст, телефон.

### Авторизованный пользователь

- если в профиле (`GET /me` в `auth`) есть все обязательные поля — сразу подтверждение
- если не хватает полей (в т.ч. **ИИН**) — шаг `ProfileCompletionStep`, затем PATCH в `auth`, затем запись

См. диаграмму состояний: [`diagrams/03-frontend-schedule.puml`](diagrams/03-frontend-schedule.puml) и sequence в [`../backend/diagrams/02-booking-sequence.puml`](../backend/diagrams/02-booking-sequence.puml).

## 6. Что перенять из medCalendar

- список специалистов, фильтры, карточка
- календарь и слоты
- пошаговый booking UI

Адаптировать под:

- `clinicSlug` / домен
- два API base (`auth` + `marketplace`)
- кабинеты ролей и branding

## 7. Очередь реализации (frontend)

1. `runtimeConfig`, `useMarketplaceApi`, базовый layout
2. middleware резолва клиники + страница лендинга
3. каталог и карточка специалиста + availability + запись (гость)
4. интеграция с `auth` + запись авторизованного + дозаполнение ИИН
5. админ клиники (специалисты, услуги, расписание, записи, branding)
6. кабинеты врача, call-центра, sales

## 8. Критерии готовности UI

- витрина клиники открывается по slug/домену с корректной темой
- сценарий записи как в `medCalendar` работает end-to-end
- гость и авторизованный пользователь проходят свои ветки формы
- админ видит только свою клинику (данные с backend уже отфильтрованы — UI не полагается на «честность» клиента)

Диаграмма компонентов: [`diagrams/03-frontend-schedule.puml`](diagrams/03-frontend-schedule.puml).
