# weather_mvp

## Goal

MVP weather app. Shows current **temperature** + **precipitation** for a location on an interactive **map**.

## Strategic Context

Hiring firm is migrating its stack from **Node/TypeScript/React/AWS** toward **Rails/Postgres**. This app intentionally mirrors that migration: a Rails/Postgres backend serving a React/TypeScript frontend. Architecture choices should reflect production Rails idioms, not just "make it work."

## Stack

**Backend** — Rails 7.1, API-only, serves JSON under `/api/v1`. Postgres via **Docker** (not a local install).
**Frontend** — Vite + React 18 + TypeScript + Tailwind CSS, [react-leaflet](https://react-leaflet.js.org/) for the map. Package manager: **pnpm** (latest stable), not npm.
**Weather data** — [Open-Meteo](https://open-meteo.com/) free API (no API key required).
**Map tiles** — OpenStreetMap via react-leaflet.

## Monorepo Layout

```
/backend    Rails 7.1 API-only app
/frontend   Vite + React + TS app (pnpm)
```

## Dev Ports & CORS

- Frontend dev server: `:5173`
- Backend (Rails/Puma): `:3000`
- CORS configured in `backend/config/initializers/cors.rb` — allows `http://localhost:5173` by default (override via `CORS_ORIGINS` env var).

## Postgres via Docker

Run Postgres in Docker, not as a local service. Avoids the `icu4c` dylib version mismatch that breaks `postgresql@14` on macOS after a brew upgrade.

```bash
docker run -d --name weather_mvp_db \
  -e POSTGRES_USER=weather_mvp \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=weather_mvp_development \
  -p 5432:5432 postgres:16
```

`backend/config/database.yml` must match these credentials.

## Why React over Hotwire

Deliberate choice. Hiring firm's current stack is Node/TS/React/AWS. This app mirrors the *migration target* (Rails/Postgres backend) while keeping React on the frontend to match the firm's frontend fluency and the migration narrative.

## Environment Gotchas

- **Ruby**: system Ruby on macOS is 2.6 — too old for Rails 7.1. Use rbenv (`brew install rbenv ruby-build`), pin Ruby 3.3.x via `.ruby-version`.
- **Postgres on macOS**: `postgresql@14` via brew breaks after brew upgrades icu4c (v74→v78 dylib mismatch). Use Docker instead.
- **pnpm**: frontend uses pnpm, not npm. Install: `npm install -g pnpm` or `brew install pnpm`.

## Principles

- **SOLID** — single responsibility, depend on abstractions.
- **Thin controllers** — controllers parse params, call a service, render. No business logic.
- **Service objects** — domain logic lives in plain Ruby service classes.
- **Dependency injection** — pass collaborators (e.g. the weather client) in; don't hard-wire. Keeps things testable and swappable.
- **Typed API contract** — frontend consumes a single shared TypeScript type matching the JSON contract below. Backend and frontend agree on shape.
- **Meaningful tests** — test behavior and contracts, not getters/setters. Cover the service layer and the contract.
- **No secrets in code** — config via env vars (`.env`, Rails credentials). Nothing sensitive committed.

## JSON Contract

The API returns this shape. Frontend types and backend serializers must match it exactly.

```json
{
  "location": "string",
  "latitude": 0.0,
  "longitude": 0.0,
  "temperature_celsius": 0.0,
  "precipitation_mm": 0.0,
  "condition": "string"
}
```

| Field                 | Type   | Notes                          |
| --------------------- | ------ | ------------------------------ |
| `location`            | string | Human-readable place name      |
| `latitude`            | number | Decimal degrees                |
| `longitude`           | number | Decimal degrees                |
| `temperature_celsius` | number | Current temp, °C               |
| `precipitation_mm`    | number | Current precipitation, mm      |
| `condition`           | string | Weather condition label        |

## Dev Commands

- **Backend tests:** `export PATH="$HOME/.rbenv/shims:/opt/homebrew/bin:$PATH"` first (else system Ruby 2.6 hijacks `bundle`), then `bundle exec rspec`.
- **Frontend:** `pnpm vitest run` (unit), `pnpm lint`, `pnpm exec tsc -b` (typecheck), `pnpm test:e2e` (Playwright).
- **DB:** `docker compose up db`; container is `meltzer-db-1`. Migrate: `bin/rails db:migrate` + `RAILS_ENV=test bin/rails db:test:prepare`.

## PII Handling (searches table)

- `Search.location` is **encrypted at rest** (Active Record Encryption; keys in Rails credentials under `active_record_encryption`). Column is `text` (ciphertext > plaintext).
- Coordinates are **rounded to 2dp (~1km)** in a `before_validation` — never store pinpoint locations.
- Retention: `rake searches:purge` (default 30 days, `RETENTION_DAYS` env). Schedule it in prod.
- Request params `location/lat/lon/latitude/longitude` are filtered from logs (`filter_parameter_logging.rb`).

## API Conventions

- Controller validates input **before** any upstream call: `Float()` (not `.to_f`) for coords, range-check lat[-90,90]/lon[-180,180], cap location at 200 chars → `422`.
- Upstream/Open-Meteo failures (`WeatherApiError`, incl. malformed payloads via serializer) → generic `502`; real cause logged server-side, never leaked to client.
- Search persistence is **best-effort** via `SearchRecorder` — a logging failure never breaks a successful lookup.
- Prod requires `CORS_ORIGINS` (raises if unset, rejects `*`).
