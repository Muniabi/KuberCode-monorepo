# Implementation plan v2 — обучение, баллы, runner

Актуальный суперсет. Старые доки:

- [learning-flow.md](./learning-flow.md) — MVP поток (часть выполнена)
- [exercise-runner.md](./exercise-runner.md) — контракт `/run` и hints
- [phase-b-sandbox.md](./phase-b-sandbox.md) — **следующий этап**: Docker/Judge0, auth-матрица, БД

## Что реализовано в этом этапе (Phase A)

### UX упражнения
- Toolbar «К треку» / «Кабинет» (pill-кнопки, не прижаты)
- Точки прогресса модуля: completed = lime, current = ring, иначе muted
- Теория: статья Markdown слева; видео + материалы справа
- Практика: условие/тесты слева; Monaco справа
- **Запустить** = локальный stdout (`console.log`) только для JS/TS
- **Проверить** = `POST /v1/exercises/:id/run` (серверный judge)
- Human hint + спойлер «Подробнее»

### Подписка
- Enroll **без** редиректа; toast + баннер; CTA «Начать» / «Позже»

### Кабинет
- Полный круг ProgressGauge
- `N/M треков`, стрик дней, баллы по трекам
- `GET /v1/me/stats`

### Баллы
- `Exercise.points` (default 5 tutorial / 10 practice)
- Начисление при первом `completed` → `enrollment.points`

### Контент
- JS: теория + «Умная сумма» + «Счётчик» (рабочие тесты)
- Go: теория + Greet + Add

### Runner Phase A
- In-process worker pool (`internal/runner`)
- JS: `node` subprocess + timeout
- Go: `go test` в tempdir
- Public GET не отдаёт `tests[].code`

## Auth (напоминание)

| Endpoint | Auth |
| --- | --- |
| `GET /v1/tracks`, `GET /v1/tracks/:slug`, exercise detail | public |
| `/v1/me/*`, `/run`, progress, enrollments | Bearer token |

## Порядок проверки

1. Перезапустить API (seed on boot) — появится трек Go.
2. Добавить трек → остаёшься на странице + toast.
3. Теория → Markdown слева, отметить прочитанным → баллы.
4. Практика JS → Запустить (лог) → Проверить (тесты сервером).
5. Кабинет: % / треки / баллы.
