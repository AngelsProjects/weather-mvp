# Weather MVP — Panel Demo Pack

A 15–20 min demo for a cross-functional immigration-firm panel (UX, PM, Senior Engineer) migrating from **Node/TS/React/AWS → Rails/Postgres**. Code references are real and verified against the repo. MVP trade-offs are called out honestly.

---

## Pre-flight (before they join)

- Postgres Docker container up
- Rails on `:3000`, Vite on `:5173`
- Browser open to the app, editor open with these files pre-loaded
- Have one bad search ready (`asdfgh`) to show error handling

---

## (1) 12-Minute Timestamped Demo Script

### [0:00–1:30] Intro — frame the migration narrative

> "Quick weather app: type a city, see current temp + precipitation on a map. Looks simple. Built it to mirror *your* migration — Rails/Postgres backend, React/TypeScript frontend. Every architecture choice maps to a decision you'll face moving off Node/AWS. That's what I want to walk through, not the weather."

Set expectation: ~4 min live, ~5 min code, ~2 min Q&A buffer.

### [1:30–5:30] Live demo

- **[1:30]** Type "Madrid" → temp, precipitation, condition, map marker drops. Note speed.
- **[2:15]** Search same city again → "instant, because the backend caches the forecast 10 min — repeat lookups don't re-hit the weather provider." ([weather_fetcher_service.rb:28](backend/app/services/weather_fetcher_service.rb#L28))
- **[3:00]** Click "Use my location" → browser geolocation → coords path (`?lat=&lon=`), not the city-name path. Same endpoint, two input modes.
- **[3:45]** Type "asdfgh" → friendly error, map doesn't break, no stale marker. "Failure is a designed state, not a stack trace."
- **[4:30]** Open DevTools Network → show the single `GET /api/v1/weather?location=Madrid` request and the JSON response. "That JSON shape is the contract. Hold that thought."
- **[5:00]** Resize window → responsive, accessible (keyboard-navigable search, ARIA).

### [5:30–10:30] Code walkthrough — 3 beats

**Beat 1 — Typed API contract [5:30–7:00]**

The one shape both sides agree on. CLAUDE.md defines it; show it enforced in code on both ends:

- Backend: [weather_serializer.rb:30-37](backend/app/serializers/weather_serializer.rb#L30-L37) — single place that emits the contract.
- Frontend: [weather.ts:9-16](frontend/src/types/weather.ts#L9-L16) — `interface Weather`, 1:1 mirror.

> "Backend changes a field → TypeScript compile breaks on the frontend. The contract is checked, not hoped for. This is the discipline that's hard to keep in a loose Node/JSON world."

**Beat 2 — Service objects + DI [7:00–9:00]**

- [weather_controller.rb:16-35](backend/app/controllers/api/v1/weather_controller.rb#L16-L35) — controller is *thin*: validate params, call services, render, map errors to status codes. Zero business logic.
- [geocoding_service.rb:16](backend/app/services/geocoding_service.rb#L16) and [weather_fetcher_service.rb:13](backend/app/services/weather_fetcher_service.rb#L13) — both take `client:` injected, default to real `OpenMeteoClient`, tests pass a stub.

> "Domain logic lives in plain Ruby service objects, each one job. The HTTP client is injected — depend on `#geocode`/`#forecast`, the abstraction, not a concrete network class. Swap the weather provider, never touch the service. That's the SOLID story your senior engineer will care about."

- [open_meteo_client.rb:57-64](backend/app/clients/open_meteo_client.rb#L57-L64) — all network failures normalized to one `WeatherApiError`. Callers never rescue Faraday internals.

**Beat 3 — React frontend layering [9:00–10:30]**

Strict layers, each ignorant of the next:

- [weatherApi.ts](frontend/src/api/weatherApi.ts) — the *only* file that knows fetch/URLs/wire format. Every failure normalized to one typed `WeatherRequestError`.
- [useWeather.ts:34-57](frontend/src/hooks/useWeather.ts#L34-L57) — owns async lifecycle: `{ data, loading, error }`. Note the **request-ID guard** ([useWeather.ts:32](frontend/src/hooks/useWeather.ts#L32)): slow earlier request can't overwrite a newer one. Real race-condition handling, not a `useEffect` afterthought.
- Components stay declarative — render off state, never touch `fetch`.

### [10:30–12:00] Close + trade-offs

> "MVP, so honest limits: no auth, no rate-limiting, in-memory cache (not Redis), single weather provider, searches persisted but not yet surfaced as history. None are dead-ends — each has a clear next step. What I'm showing is that the *bones* are production-Rails idioms, so scaling this is addition, not rewrite."

Hand to Q&A.

---

## (2) Audience-Specific Talking Points

### For UX

- Failure is a first-class designed state — friendly copy, no stack traces, stale data cleared on error ([useWeather.ts:52-53](frontend/src/hooks/useWeather.ts#L52-L53)) so the map never shows the wrong city beside an error.
- Two input modes, one mental model: type a city *or* "use my location."
- Loading / empty / error / success all handled — no dead screens.
- Accessible + responsive: keyboard nav, ARIA, works at any width.
- Latency hidden by caching — repeat searches feel instant.

### For PM

- Strategic fit: the app *is* the migration story — Rails/Postgres backend, React frontend, low risk to your team's existing fluency.
- Free data source (Open-Meteo, no API key) → zero per-call cost, no vendor contract to ship MVP.
- Scope honesty: shipped the core loop; auth/history/rate-limiting are scoped-but-deferred, not forgotten.
- Test coverage exists (rspec backend, vitest frontend, Playwright E2E) → safe to iterate.
- Provider-swap is cheap (DI) → not locked to one weather vendor.

### For the Senior Engineer

- Thin controllers, service objects, DI throughout — production Rails, not "make it work."
- One domain error type (`WeatherApiError`) at the boundary; upstream details logged server-side, never leaked to the client ([weather_controller.rb:12-14](backend/app/controllers/api/v1/weather_controller.rb#L12-L14)).
- Strict coordinate parsing — `Float()` not `.to_f`, because `"foo".to_f == 0.0` is a silent valid-looking bug ([weather_controller.rb:72-78](backend/app/controllers/api/v1/weather_controller.rb#L72-L78)).
- Read-through cache only writes on success → errors never cached.
- Frontend layered (api → hooks → components), race-guarded, single typed error.
- Contract enforced by the type system across the boundary.

---

## (3) 15 Q&A Answers

**1. Why React-on-Rails vs Hotwire? When would you pick Hotwire?**
Your team's frontend fluency is React/TS — keeping React matches that while the *backend* migrates to Rails. Lower people-risk. **I'd pick Hotwire if** the team were going full-Rails and wanted to drop the SPA toolchain entirely: server-rendered HTML over the wire, far less JS, faster to ship CRUD-heavy internal tools. For a map-driven, client-state-heavy UI like this, and a React-fluent team, React wins. Hotwire shines when interactivity is modest and the team is all-in on Rails.

**2. Why Postgres vs DynamoDB?**
Relational, known query patterns, you want joins / ad-hoc queries / migrations as the app grows. DynamoDB forces you to model access patterns upfront and punishes anything you didn't predict. Coming *from* AWS, Dynamo is the familiar reflex — but the migration target is Rails/Postgres, and Postgres is the lower-surprise default. **Dynamo if** you had massive predictable key-value scale and single-digit-ms latency needs. Not this app.

**3. How is PII / secrets handled?**
No API key needed (Open-Meteo is open). No user accounts → minimal PII; only searched locations persisted, and those aren't tied to a person. Config via env vars (`CORS_ORIGINS`, `VITE_API_BASE`), nothing sensitive committed — Rails credentials / `.env` for anything that is. **MVP gap, honest:** geolocation coords *are* personal; right now they hit the API and get cached by rounded coordinate but aren't stored against a user. Before real users: privacy notice on the geolocation prompt, retention policy on the searches table.

**4. CORS / security between the two apps?**
CORS locked to `http://localhost:5173` by default, overridable via `CORS_ORIGINS` env var ([config/initializers/cors.rb](backend/config/initializers/cors.rb)). Not `*`. Input validated server-side before any upstream call — coordinate ranges, max location length, strict numeric parse. Upstream errors never leak provider name/status to the client. **MVP gaps:** no rate-limiting (add Rack::Attack), no auth (API is currently open). Both are additive.

**5. What happens when Open-Meteo is down?**
Client normalizes timeout / non-2xx to `WeatherApiError` → controller renders `502 Bad Gateway` with a generic user message, logs the real cause server-side. 5-second timeout so we fail fast, don't hang the request ([open_meteo_client.rb:16](backend/app/clients/open_meteo_client.rb#L16)). Errors are *not* cached. **Next:** retry-with-backoff and a fallback provider (cheap because of DI).

**6. How does this scale?**
Stateless Rails API → scale horizontally behind a load balancer. The bottleneck is the upstream weather API, not us — that's why the cache exists. **Real scaling step:** move the cache from in-memory to Redis (so it's shared across instances), add Rack::Attack rate-limiting, connection-pool Postgres. The 10-min cache already cuts upstream calls hard for popular cities.

**7. Why a service object instead of fat models or controller logic?**
Single responsibility + testability. The geocoding logic and the fetch logic each get one class, each independently unit-tested with a stubbed client. Fat models tangle persistence with domain logic; fat controllers can't be tested without HTTP. Services are plain Ruby — fast, isolated tests.

**8. Why inject the HTTP client?**
Dependency Inversion. Services depend on "responds to `#forecast`," not on `OpenMeteoClient` concretely. Tests pass a stub — no network in unit tests. Swapping weather providers means writing one new client, zero service changes. ([weather_fetcher_service.rb:13](backend/app/services/weather_fetcher_service.rb#L13))

**9. How do you keep frontend and backend types in sync?**
The serializer is the single backend definition of the contract; `interface Weather` mirrors it 1:1. They're manually kept in lockstep today, and the TS compiler catches frontend-side drift. **Honest MVP limit:** it's a *convention*, not auto-generated. **Next:** generate TS types from the Rails serializer (or an OpenAPI spec) in CI so drift is impossible, not just caught.

**10. What's your test strategy?**
Backend rspec on the service layer and contract (behavior, not getters). Frontend vitest on hooks / api / components. Playwright E2E for the full flow: city search, mocked-geolocation, invalid-location error. I test contracts and behavior, not implementation detail — so refactors don't break the suite.

**11. Why cache by rounded coordinate?**
Two searches a few meters apart are the same weather. Rounding to 2 decimals (~1km) collapses them to one cache key → higher hit rate, fewer upstream calls ([weather_fetcher_service.rb:36-37](backend/app/services/weather_fetcher_service.rb#L36-L37)). Trade-off: ~1km precision loss, irrelevant for current weather.

**12. What about that race condition in the UI?**
Handled. `useWeather` uses a monotonic request-ID ref — only the most recent request commits state. Type fast, switch cities, a slow earlier response can't clobber the newer one ([useWeather.ts:32](frontend/src/hooks/useWeather.ts#L32), [useWeather.ts:41](frontend/src/hooks/useWeather.ts#L41)). Common SPA bug; designed out here.

**13. Why persist searches if you don't show them?**
Laid the rail for search history / popular-locations / analytics without a later migration. **Honest:** it's currently write-only — a deliberate seam, not a finished feature. Recording is isolated in `SearchRecorder` so it's swappable.

**14. Biggest MVP trade-off you'd flag?**
In-memory cache. Works for a single-instance demo, but it's per-process — won't share across scaled instances and resets on deploy. First production change: Redis. I chose it knowingly to keep the MVP dependency-light.

**15. What would you build next?**
Priority order: (1) Redis cache + Rack::Attack rate-limiting (production hardening), (2) auto-generated TS types from the serializer in CI (kill contract drift), (3) surface search history + a forecast (not just current), (4) auth if it becomes multi-user, (5) retry / fallback weather provider. Each is additive — the architecture already has the seams.
