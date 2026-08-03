# Запуск KuberCode через Docker

Один clone монорепозитория + один `docker-compose.yml` в корне поднимают весь стек: MongoDB, Redis, API, marketing (:3001), app (:3002), admin (:3003).

Корневой `Dockerfile` — подсказка-entrypoint (стек многосервисный). Реальная оркестрация — Compose.

## Требования

- Docker Engine + Docker Compose v2
- ~4 GB RAM свободно (с Judge0 — больше)
- На Linux для Judge0 нужен privileged mode

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

## Быстрый старт (localhost)

```bash
cd KuberCode-monorepo      # корень монорепо
cp .env.example .env
# при желании отредактируйте секреты JWT_* и SEED_ADMIN_PASSWORD

docker compose up -d --build
```

Откройте:

| Сервис    | URL                     |
|-----------|-------------------------|
| Marketing | http://localhost:3001   |
| App       | http://localhost:3002   |
| Admin     | http://localhost:3003   |
| API       | http://localhost:4000   |

Админ после seed: `admin@kubercode.local` / пароль из `SEED_ADMIN_PASSWORD`.

Логи:

```bash
docker compose logs -f
docker compose logs -f api
```

Остановка (контейнеры остаются, данные в volumes сохраняются):

```bash
docker compose down
```

## Переменные окружения (одинаковые имена везде)

Единый файл: **корневой `.env`** (шаблон — `.env.example`).  
Те же имена используются в `kubercode-*/.env.example` для локальной разработки без Docker.

### Публичные URL (браузер)

| Переменная | Кто использует | Назначение |
|------------|----------------|------------|
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

Браузер **не** ходит на `mongo` / `api` по внутренним именам — только на проброшенные порты хоста.

## Сценарии: какие URL указывать

### 1) Всё на одной машине, доступ с неё же

Оставьте значения из `.env.example` (`localhost`).

### 2) Сервер с публичным IP, доступ по IP

Подставьте IP сервера (пример `203.0.113.10`):

```env
NEXT_PUBLIC_API_URL=http://203.0.113.10:4000
NEXT_PUBLIC_MARKETING_URL=http://203.0.113.10:3001
NEXT_PUBLIC_APP_URL=http://203.0.113.10:3002
NEXT_PUBLIC_ADMIN_URL=http://203.0.113.10:3003
CORS_ORIGINS=http://203.0.113.10:3001,http://203.0.113.10:3002,http://203.0.113.10:3003

INTERNAL_API_URL=http://api:4000
MONGODB_URI=mongodb://mongo:27017
REDIS_URL=redis://redis:6379
```

Затем:

```bash
docker compose up -d --build
```

Порты можно сменить через `*_HOST_PORT` в `.env`, если 3001/4000 заняты.

### 3) Домены + HTTPS (reverse proxy: nginx/Caddy)

Снаружи — HTTPS-домены, внутри Compose порты как есть; proxy проксирует на `127.0.0.1:3001` и т.д.

```env
NEXT_PUBLIC_API_URL=https://api.example.com
NEXT_PUBLIC_MARKETING_URL=https://www.example.com
NEXT_PUBLIC_APP_URL=https://app.example.com
NEXT_PUBLIC_ADMIN_URL=https://admin.example.com
CORS_ORIGINS=https://www.example.com,https://app.example.com,https://admin.example.com
COOKIE_SECURE=true
```

Пересоберите фронты после смены URL.

### 4) Обновление кода на сервере

```bash
git pull
# обновите submodule SHA при необходимости, либо pull внутри каждой папки kubercode-*
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
**Удаляет** volumes `mongo_data`, `redis_data` (и judge0 volumes, если были).

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
# останов + volumes нашего проекта
docker compose down -v --rmi local

# висячие образы / сети / build cache (глобально)
docker system prune -af
docker builder prune -af

# ВНИМАНИЕ: удалит ВСЕ неиспользуемые volumes на хосте
# docker volume prune -f
```

Когда: диск забит, хотите вычистить весь Docker после тестов.  
`volume prune` без `-v` у compose может стереть чужие данные — используйте осознанно.

### Удалить только кэш сборки

```bash
docker builder prune -af
```

Когда: мало места, контейнеры/volumes трогать не нужно.

## Полезные команды

```bash
docker compose ps
docker compose pull          # обновить mongo/redis/judge0 images
docker compose restart api
docker compose exec api sh   # если нужен shell в api (образ bookworm)
```

Mongo с хоста (Compass): `mongodb://127.0.0.1:27018` (порт `MONGO_HOST_PORT`).

## Структура

```
KuberCode-v0.3/
  docker-compose.yml      # оркестратор всего стека
  Dockerfile              # meta / docs entrypoint
  .env.example            # единый шаблон env
  DOCKER.md               # этот файл
  kubercode-api/Dockerfile
  kubercode-app/Dockerfile
  kubercode-admin/Dockerfile
  kubercode-marketing/Dockerfile
```

Локальная разработка без полного стека по-прежнему: `kubercode-api/docker-compose.yml` (только mongo+redis) + `npm run dev` / `go run`.
