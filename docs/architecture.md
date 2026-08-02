# Architecture — KuberCode

## Границы ответственности

### kubercode-marketing (`kubercode.ru`)
- Главная и маркетинговые страницы
- SEO / Open Graph
- Cookie consent
- Юридические static-страницы (terms/privacy) — по мере появления
- CTA на приложение (`NEXT_PUBLIC_APP_URL`)

**Не сюда:** авторизация, кабинет, прогресс, онлайн-редактор.

### kubercode-app (`app.kubercode.ru`)
- Login / register UI
- Личный кабинет и профиль
- Треки обучения, задачи, прогресс
- Онлайн-редактор
- Настройки

Общается только с `kubercode-api` через `NEXT_PUBLIC_API_URL`.

### kubercode-admin (`admin.kubercode.ru` / :3003)
- CMS: CRUD треков, модулей, упражнений, ресурсов, пользователей
- Soft-delete + restore, publish toggle
- Только `role=admin` (JWT)

### kubercode-api (`api.kubercode.ru`)
- Go + Gin
- Auth: JWT access + refresh (httpOnly cookies + Bearer), MongoDB users + roles
- Public tracks API; admin CMS API
- Seed: admin user + demo javascript track (`SEED_ON_BOOT`)
- CORS: marketing + app + admin origins

На сервере backend может жить в отдельной папке деплоя; локально — `kubercode-api/`.

## Env (локально)

| Проект | Переменная | Пример |
|--------|------------|--------|
| marketing | `NEXT_PUBLIC_APP_URL` | `http://localhost:3002` |
| marketing | `NEXT_PUBLIC_API_URL` | `http://localhost:4000` |
| app | `NEXT_PUBLIC_API_URL` | `http://localhost:4000` |
| app | `NEXT_PUBLIC_MARKETING_URL` | `http://localhost:3001` |
| admin | `NEXT_PUBLIC_API_URL` | `http://localhost:4000` |
| api (Go) | `PORT` | `4000` |
| api (Go) | `CORS_ORIGINS` | `http://localhost:3001,http://localhost:3002,http://localhost:3003` |
| api (Go) | `MONGODB_URI` | `mongodb://127.0.0.1:27018` |
| api (Go) | `MONGODB_DB` | `kubercode` |
| api (Go) | `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` | dev secrets |
| api (Go) | `SEED_ON_BOOT` / `SEED_ADMIN_PASSWORD` | `true` / admin password |

## Shared brand

Logo / CSS-токены пока **дублируются** в marketing и app.
Общий пакет (`@kubercode/brand`) — только при реальном split/monorepo, не сейчас.

## Порядок развития

1. Marketing готов (лендинг)
2. App shell + stub routes
3. API health + auth stubs
4. Реальный auth (JWT + Mongo) и кабинет ← сейчас
5. Контент треков / runner
