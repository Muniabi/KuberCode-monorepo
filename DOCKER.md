# Запуск KuberCode через Docker

Один clone монорепозитория + один `docker-compose.yml` в корне поднимают весь стек: MongoDB, Redis, API, marketing, app, admin и **Caddy** на порту **80** (поддомены без `:3001`).

Корневой `Dockerfile` — подсказка-entrypoint (стек многосервисный). Реальная оркестрация — Compose.

## Требования

- Docker Engine + Docker Compose v2
- ~4 GB RAM свободно (с Judge0 — больше)
- На Linux для Judge0 нужен privileged mode
- Для домена: DNS A-записи + открытый порт **80** на файрволе

## Clone монорепо (обязательно с submodule)

Вложенные `kubercode-*` — отдельные git-репозитории. Без `.gitmodules` / `--recurse-submodules` после clone папки будут пустыми.

```bash
git clone --recurse-submodules git@github.com:Muniabi/KuberCode-monorepo.git
cd KuberCode-monorepo

# если уже клонировали без submodule:
git submodule update --init --recursive
```

HTTPS (тот же протокол, что и у clone — URL submodule относительные `../…`):

```bash
git clone --recurse-submodules https://github.com/Muniabi/KuberCode-monorepo.git
cd KuberCode-monorepo
```

## Быстрый старт (localhost через proxy :80)

```bash
cd KuberCode-monorepo
cp .env.example .env
# при желании отредактируйте секреты JWT_* и SEED_ADMIN_PASSWORD

docker compose up -d --build
```

Откройте (современные браузеры резолвят `*.localhost` → 127.0.0.1):

| Сервис    | URL                         |
|-----------|-----------------------------|
| Marketing | http://localhost            |
| App       | http://app.localhost        |
| Admin     | http://admin.localhost      |
| API       | http://api.localhost/health |

Прямые порты `3001–4000` по умолчанию **не** публикуются. Если нужны:

```bash
docker compose --profile exposed up -d
# http://localhost:3001 … :4000
```

Админ после seed: `admin@kubercode.local` / пароль из `SEED_ADMIN_PASSWORD`.

Логи:

```bash
docker compose logs -f
docker compose logs -f proxy
docker compose logs -f api
```

Остановка (контейнеры остаются, данные в volumes сохраняются):

```bash
docker compose down
```

## Домен без портов (например kubercode.mikata.ru)

Браузер на `http://kubercode.mikata.ru` ходит на **порт 80**. Caddy (`proxy`) принимает Host и проксирует:

| Host | Сервис |
|------|--------|
| `kubercode.mikata.ru` | marketing |
| `app.kubercode.mikata.ru` | app |
| `admin.kubercode.mikata.ru` | admin |
| `api.kubercode.mikata.ru` | api |

### 1) DNS

A-записи на IP сервера (пример `201.24.116.55`):

- `kubercode.mikata.ru`
- `app.kubercode.mikata.ru`
- `admin.kubercode.mikata.ru`
- `api.kubercode.mikata.ru`

Или apex + wildcard: `kubercode.mikata.ru` и `*.kubercode.mikata.ru`.

Дождитесь распространения DNS (`dig +short app.kubercode.mikata.ru`).

### 2) `.env` на сервере

```env
DOMAIN=kubercode.mikata.ru

NEXT_PUBLIC_API_URL=http://api.kubercode.mikata.ru
NEXT_PUBLIC_MARKETING_URL=http://kubercode.mikata.ru
NEXT_PUBLIC_APP_URL=http://app.kubercode.mikata.ru
NEXT_PUBLIC_ADMIN_URL=http://admin.kubercode.mikata.ru
CORS_ORIGINS=http://kubercode.mikata.ru,http://app.kubercode.mikata.ru,http://admin.kubercode.mikata.ru

INTERNAL_API_URL=http://api:4000
MONGODB_URI=mongodb://mongo:27017
REDIS_URL=redis://redis:6379
COOKIE_SECURE=false
```

Смените `JWT_*` и `SEED_ADMIN_PASSWORD`. Порты в публичных URL **не указывайте**.

### 3) Запуск / обновление

```bash
cd ~/KuberCode-monorepo
git pull
git submodule update --init --recursive

# отредактируйте .env как выше
docker compose up -d --build
```

Обязателен `--build` после смены `NEXT_PUBLIC_*`.

Файрвол: откройте **80**. Прямые `3001–4000` можно закрыть (не используйте `--profile exposed` на проде).

### 4) Проверка

```bash
curl -sI http://kubercode.mikata.ru
curl -sI http://app.kubercode.mikata.ru
curl -sI http://admin.kubercode.mikata.ru
curl -s http://api.kubercode.mikata.ru/health

# если DNS ещё не готов — проверка Host на IP:
curl -sI -H "Host: kubercode.mikata.ru" http://127.0.0.1/
curl -s -H "Host: api.kubercode.mikata.ru" http://127.0.0.1/health
```

HTTPS (Let's Encrypt) — следующий шаг; сейчас HTTP на `:80` (`auto_https off` в `deploy/Caddyfile`).

## Переменные окружения (одинаковые имена везде)

Единый файл: **корневой `.env`** (шаблон — `.env.example`).  
Те же имена используются в `kubercode-*/.env.example` для локальной разработки без Docker.

### Публичные URL (браузер)

| Переменная | Кто использует | Назначение |
|------------|----------------|------------|
| `DOMAIN` | Caddy | Apex-домен для Host-routing |
| `NEXT_PUBLIC_API_URL` | app, admin, marketing | URL API, который видит браузер |
| `NEXT_PUBLIC_MARKETING_URL` | app | Ссылки на лендинг |
| `NEXT_PUBLIC_APP_URL` | marketing | Ссылки «в кабинет» |
| `NEXT_PUBLIC_ADMIN_URL` | compose / CORS | URL админки |
| `CORS_ORIGINS` | api | Разрешённые origin через запятую |

`NEXT_PUBLIC_*` **вшиваются на этапе `docker build`**. Сменили IP/домен → пересоберите:

```bash
docker compose up -d --build
```

### Внутренние (docker-сеть)

| Переменная | Типичное значение в Compose |
|------------|-----------------------------|
| `MONGODB_URI` | `mongodb://mongo:27017` |
| `REDIS_URL` | `redis://redis:6379` |
| `INTERNAL_API_URL` | `http://api:4000` (SSR marketing → API) |

Браузер ходит на **proxy :80** (или на прямые порты с `--profile exposed`), не на имена `mongo` / `api` внутри Docker.

## Сценарии: какие URL указывать

### 1) Локально через proxy

Оставьте блок localhost из `.env.example` (`DOMAIN=localhost`, `*.localhost`).

### 2) Сервер только по IP (без домена)

Нужны прямые порты + URL с портами:

```env
DOMAIN=localhost
NEXT_PUBLIC_API_URL=http://203.0.113.10:4000
NEXT_PUBLIC_MARKETING_URL=http://203.0.113.10:3001
NEXT_PUBLIC_APP_URL=http://203.0.113.10:3002
NEXT_PUBLIC_ADMIN_URL=http://203.0.113.10:3003
CORS_ORIGINS=http://203.0.113.10:3001,http://203.0.113.10:3002,http://203.0.113.10:3003
```

```bash
docker compose --profile exposed up -d --build
```

### 3) Домен на :80 (рекомендуется)

См. секцию [Домен без портов](#домен-без-портов-например-kubercodemicataru) выше.

### 4) Домены + HTTPS (позже)

Когда включите TLS в Caddy и порт 443:

```env
NEXT_PUBLIC_API_URL=https://api.example.com
NEXT_PUBLIC_MARKETING_URL=https://example.com
NEXT_PUBLIC_APP_URL=https://app.example.com
NEXT_PUBLIC_ADMIN_URL=https://admin.example.com
CORS_ORIGINS=https://example.com,https://app.example.com,https://admin.example.com
COOKIE_SECURE=true
```

### 5) Обновление кода на сервере

```bash
git pull
git submodule update --init --recursive
docker compose up -d --build
```

Данные Mongo/Redis в named volumes не трогаются.

## Judge0 (опционально)

По умолчанию API гоняет код локальным runner (Go/Node внутри контейнера `api`).

Изолированный Judge0:

```bash
# в .env:
# JUDGE0_URL=http://judge0-server:2358

docker compose --profile judge0 up -d
docker compose up -d --build api
```

Нужен Linux/WSL и privileged контейнеры. Конфиг: `kubercode-api/judge0.conf`.

## Очистка и сброс

### Только остановить стек (данные сохранить)

```bash
docker compose down
```

Когда: обычная остановка сервера / деплой без сброса БД.

### Удалить контейнеры + volumes (полная очистка данных Mongo/Redis)

```bash
docker compose down -v
```

Когда: хотите «с нуля» (seed заново, без старых пользователей/прогресса).  
**Удаляет** volumes `mongo_data`, `redis_data`, `caddy_*` (и judge0 volumes, если были).

### Удалить также образы, собранные этим compose-проектом

```bash
docker compose down -v --rmi local
```

Когда: освободить место после крупных обновлений Dockerfile / зависимостей.

### Пересобрать без кэша слоёв Docker

```bash
docker compose build --no-cache
docker compose up -d
```

Когда: подозрение на битый build-cache или смена base-image не подхватывается.

### Ядерная очистка Docker на машине (все неиспользуемое)

Осторожно: затронет **другие** проекты на том же Docker daemon.

```bash
docker compose down -v --rmi local
docker system prune -af
docker builder prune -af
# docker volume prune -f   # ОСТОРОЖНО: все неиспользуемые volumes на хосте
```

### Удалить только кэш сборки

```bash
docker builder prune -af
```

## Полезные команды

```bash
docker compose ps
docker compose pull
docker compose restart proxy
docker compose logs -f proxy
docker compose exec api sh
```

Mongo с хоста (Compass): `mongodb://127.0.0.1:27018` (порт `MONGO_HOST_PORT`).

## Структура

```
KuberCode-monorepo/
  docker-compose.yml      # оркестратор + Caddy proxy
  deploy/Caddyfile        # Host → marketing/app/admin/api
  Dockerfile              # meta / docs entrypoint
  .env.example            # единый шаблон env
  DOCKER.md               # этот файл
  kubercode-api/Dockerfile
  kubercode-app/Dockerfile
  kubercode-admin/Dockerfile
  kubercode-marketing/Dockerfile
```

Локальная разработка без полного стека по-прежнему: `kubercode-api/docker-compose.yml` (только mongo+redis) + `npm run dev` / `go run`.
