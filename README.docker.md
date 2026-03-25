# Docker: единая точка входа

Из корня:

```bash
docker compose up --build
```

Или через интерактивный launcher:

```bash
./run.sh
```

Скрипт перед стартом спрашивает:

- режим запуска: `DEV` или `PROD`
- внешний порт gateway
- запуск миграций marketplace
- использовать ли demo-seed для marketplace
- нужен ли `--build`
- запускать ли в `detached`-режиме
- сохранять ли выбранные значения в `.env`

Снаружи публикуется только один контейнер `gateway` на `localhost:${GATEWAY_PORT}`. По умолчанию это `http://localhost:3120`. Все остальные сервисы доступны только внутри Docker-сети.

## Маршруты через gateway

- `/` -> Nuxt frontend
- `/auth/*` -> auth backend
- `/me`, `/roles/*`, `/permissions/*`, `/users/*` -> auth backend
- `/api/marketplace/*` -> marketplace backend

`/marketplace` оставлен за frontend-страницами, поэтому API marketplace вынесен под `/api/marketplace/*`, чтобы не конфликтовать с UI-роутами.

## Основные переменные

- `GATEWAY_PORT=3120` — единственный внешний порт на хосте
- `GATEWAY_INTERNAL_BASE=http://gateway` — внутренний адрес gateway для SSR из frontend-контейнера
- `FRONTEND_URL=http://localhost:3120` — публичный адрес frontend для redirect'ов auth
- `NUXT_PUBLIC_AUTH_API_BASE=` — auth работает в same-origin через gateway
- `NUXT_PUBLIC_MARKETPLACE_API_BASE=/api/marketplace`
- `MARKETPLACE_AUTO_SEED=true` — при старте создаёт demo-данные marketplace (`demo-clinic`)

Если меняете внешний порт gateway, синхронно обновите:

- `GATEWAY_PORT`
- `FRONTEND_URL`
- `PUBLIC_BASE_URL`
- `AUTH_ALLOWED_ORIGINS`
- `MARKETPLACE_ALLOWED_ORIGINS`
- `auth/.env` -> `GOOGLE_REDIRECT_URL` и URI в Google Cloud Console

## Полезные URL

- приложение: `http://localhost:3120`
- auth health: `http://localhost:3120/auth/healthz`
- marketplace health: `http://localhost:3120/api/marketplace/healthz`

## Очистка старых контейнеров

Если раньше сервисы запускались отдельно и мешают:

```bash
docker rm -f auth-postgres auth-backend auth-backup-serv marketplace-db marketplace-backend adm-frontend 2>/dev/null
```
