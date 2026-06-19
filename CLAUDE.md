# weather_mvp

## Goal

MVP weather app. Shows current **temperature** + **precipitation** for a location on an interactive **map**.

## Strategic Context

Hiring firm is migrating its stack from **Node/TypeScript/React/AWS** toward **Rails/Postgres**. This app intentionally mirrors that migration: a Rails/Postgres backend serving a React/TypeScript frontend. Architecture choices should reflect production Rails idioms, not just "make it work."

## Stack

**Backend** — Rails 7.1, API-only, PostgreSQL.
**Frontend** — Vite + React 18 + TypeScript + Tailwind CSS, [react-leaflet](https://react-leaflet.js.org/) for the map.
**Weather data** — [Open-Meteo](https://open-meteo.com/) free API (no key required).

## Monorepo Layout

```
/backend    Rails 7.1 API-only app
/frontend   Vite + React + TS app
```

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
