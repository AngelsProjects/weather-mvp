# Weather MVP

A full-stack weather application: search any city (or use your current location) to see current temperature, precipitation, and a live map marker. Built as a hiring demo for Meltzer Hellrung, mirroring their stack migration from **Node/TypeScript/React/AWS → Rails/Postgres**.

---

## Why React on Rails?

The firm's *existing* stack is Node/TypeScript/React/AWS. Their *target* is Rails/Postgres on the backend. This app mirrors that migration deliberately:

- **Backend** — Rails 7.1 API-only with Postgres: the migration target. Demonstrates Rails idioms — thin controllers, service objects, dependency injection, typed serializers.
- **Frontend** — React 18 + TypeScript: kept to match the firm's current frontend fluency, so the demo isn't "explain React" but "show how Rails integrates with what you already have."

Every architecture decision maps to a choice the firm will face during their migration.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Browser (React)                     │
│                                                         │
│  SearchForm ──► useWeather hook ──► weatherApi.ts       │
│  WeatherPanel ◄── Weather type (shared contract)        │
│  WeatherMap (react-leaflet / OpenStreetMap tiles)       │
└───────────────────────────┬─────────────────────────────┘
                            │ GET /api/v1/weather
                            ▼
┌─────────────────────────────────────────────────────────┐
│                   Rails 7.1 API-only                    │
│                                                         │
│  WeatherController (parse params, delegate, render)     │
│       │                                                 │
│       ▼                                                 │
│  WeatherFetcherService                                  │
│    ├── GeocodingService  (Open-Meteo geocoding API)     │
│    └── OpenMeteoClient   (Open-Meteo weather API)       │
│       │                                                 │
│       ▼                                                 │
│  SearchRecorder (persist search to Postgres)            │
│  WeatherSerializer (shape → JSON contract)              │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│              Postgres (Docker / Supabase)               │
│  searches: id, location, latitude, longitude,           │
│            created_at, updated_at                       │
└─────────────────────────────────────────────────────────┘
```

**Key design principles:**
- Thin controllers — parse params, call service, render. No business logic.
- Service objects — domain logic in plain Ruby classes, injected as collaborators.
- Typed contract — `frontend/src/types/weather.ts` mirrors `WeatherSerializer` 1:1.
- No secrets in code — config via env vars / Rails credentials.

---

## Monorepo Layout

```
/
├── backend/                Rails 7.1 API-only
│   ├── app/
│   │   ├── controllers/api/v1/weather_controller.rb
│   │   ├── services/
│   │   │   ├── weather_fetcher_service.rb
│   │   │   ├── geocoding_service.rb
│   │   │   ├── search_recorder.rb
│   │   │   └── weather_codes.rb
│   │   └── serializers/
│   ├── config/
│   │   ├── database.yml
│   │   └── initializers/cors.rb
│   ├── db/migrate/
│   └── spec/               RSpec + FactoryBot
├── frontend/               Vite + React 18 + TypeScript
│   └── src/
│       ├── api/weatherApi.ts
│       ├── components/     SearchForm, WeatherPanel, WeatherMap
│       ├── hooks/          useWeather, useGeolocation
│       ├── types/weather.ts   ← shared contract
│       └── test/           Vitest unit + Playwright E2E
├── docker-compose.yml      Local Postgres (dev/test)
└── supabase/               Linked project (production)
```

---

## Setup

### Prerequisites

- Ruby 3.3.x via rbenv (`brew install rbenv ruby-build`)
- Node 20+ and pnpm (`npm install -g pnpm`)
- Docker Desktop (for local Postgres)

### Backend

```bash
# Start Postgres
docker compose up -d db

# Install dependencies
cd backend
bundle install

# Create and migrate dev database
rails db:create db:migrate

# Start API server
rails s -p 3000
```

**Environment variables** (copy `.env.example` to `.env`):

```
DATABASE_URL=postgresql://weather_mvp:password@localhost:5432/weather_mvp_development
CORS_ORIGINS=http://localhost:5173
```

### Frontend

```bash
cd frontend
pnpm install
pnpm dev          # starts on http://localhost:5173
```

### Production (Supabase)

Production points to a managed Supabase Postgres instance:

```
DATABASE_URL=postgresql://postgres:<password>@db.xbrmdansydqafucsvulq.supabase.co:5432/postgres
RAILS_ENV=production
SECRET_KEY_BASE=<from rails credentials>
```

`database.yml` production stanza uses `url: <%= ENV["DATABASE_URL"] %>`. Use the **direct** connection URL (not the pooler) for migrations — DDL requires session-mode semantics.

---

## Running Tests

### Backend — RSpec

```bash
cd backend
bundle exec rspec
```

Covers: request specs (API contract), service specs (WeatherFetcherService, GeocodingService), serializer specs, model specs.

### Frontend — Vitest (unit)

```bash
cd frontend
pnpm test          # run once
pnpm test:watch    # watch mode
pnpm test:coverage # with coverage report
```

Covers: `useWeather` hook, `useGeolocation` hook, `weatherApi` client, `SearchForm` component, `WeatherPanel` component.

### Frontend — Playwright (E2E)

```bash
cd frontend
pnpm exec playwright install   # first time only
pnpm exec playwright test
```

E2E specs: city search (renders temp + map marker), geolocation flow (mocked), invalid location (friendly error, no broken state).

---

## API Contract

### `GET /api/v1/weather`

**Query params:**

| Param | Type | Required | Notes |
|---|---|---|---|
| `location` | string | one of location/lat+lon | City name or address |
| `lat` | number | one of location/lat+lon | Decimal degrees |
| `lon` | number | one of location/lat+lon | Decimal degrees |

**Success — 200:**

```json
{
  "location": "New York, NY",
  "latitude": 40.7128,
  "longitude": -74.006,
  "temperature_celsius": 18.4,
  "precipitation_mm": 0.0,
  "condition": "Partly cloudy"
}
```

**Error responses:**

| Status | Meaning |
|---|---|
| 400 | Missing required params |
| 422 | Location not found |
| 500 | Upstream weather API failure |

```json
{ "error": "Location not found" }
```

The TypeScript type in `frontend/src/types/weather.ts` (`Weather`, `ApiError`, `Coordinates`) mirrors this contract exactly — any drift is a compile error.

---

## MVP Trade-offs

| Area | Decision | What's deferred |
|---|---|---|
| **Auth** | None — public API | Add Devise + JWT for multi-user |
| **Caching** | In-memory Rails cache (10 min TTL per location) | Redis for multi-process / multi-server |
| **Search history** | All searches persisted; no user association | Scope to user after auth ships |
| **Weather provider** | Open-Meteo (free, no key) | Swap client for paid provider via DI seam |
| **Map tiles** | OpenStreetMap (free) | Mapbox for custom styling |
| **Error monitoring** | None | Add Sentry (backend + frontend) |
| **CI/CD** | None | GitHub Actions → Render/Fly deploy |
| **Rate limiting** | None | Rack::Attack for production hardening |

---

## Data Provider

[Open-Meteo](https://open-meteo.com/) — free, no API key required. Provides geocoding (city name → lat/lon) and current weather in a single integration. The client (`OpenMeteoClient`) is injected into `WeatherFetcherService`, making it straightforward to swap for a paid provider without touching controller or serializer logic.
