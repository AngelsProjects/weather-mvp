// App is the composition root: wires hooks to components, owns no state
// of its own beyond what the hooks provide. Three hooks, three components,
// one clear data flow: user input → hook → component renders.

import { useCallback, useEffect } from 'react';
import { useWeather } from './hooks/useWeather';
import { useGeolocation } from './hooks/useGeolocation';
import SearchForm from './components/SearchForm';
import WeatherPanel from './components/WeatherPanel';
import WeatherMap from './components/WeatherMap';

export default function App() {
  const weather = useWeather();
  const geo = useGeolocation();

  // When geolocation resolves new coords, fire a weather lookup.
  useEffect(() => {
    if (geo.coords) {
      weather.byCoords(geo.coords.latitude, geo.coords.longitude);
    }
    // weather object is stable (useCallback inside hook) so safe to omit
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [geo.coords]);

  const handleMapClick = useCallback(
    (lat: number, lon: number): void => {
      weather.byCoords(lat, lon);
    },
    [weather],
  );

  const hasPanel = weather.loading || !!weather.error || !!weather.data;

  return (
    <div className="flex flex-col h-dvh bg-[--ink] overflow-hidden">

      {/* ── Header ─────────────────────────────────────────────────────── */}
      <header
        className="flex-shrink-0 bg-[--ink-mid] border-b border-[--border]"
        role="banner"
      >
        {/* Top bar: wordmark + subtitle */}
        <div className="flex items-center gap-3 px-4 pt-3 pb-1">
          <h1
            className="text-xl leading-none select-none whitespace-nowrap"
            style={{ fontFamily: 'var(--display)', fontStyle: 'italic', fontWeight: 300, color: 'var(--text-hi)' }}
          >
            weather
            <span style={{ color: 'var(--amber)', fontWeight: 600 }}>_mvp</span>
          </h1>
          <span
            className="hidden sm:block text-[10px] tracking-widest uppercase"
            style={{ color: 'var(--muted)' }}
            aria-hidden="true"
          >
            Current conditions
          </span>
        </div>

        {/* Search row */}
        <div className="px-2 pb-2 sm:px-4">
          <SearchForm
            onSearch={weather.byLocation}
            onLocate={geo.request}
            loading={weather.loading}
            geoLoading={geo.loading}
          />
        </div>
      </header>

      {/* ── Live error announcements (geo + weather) ────────────────────
          role="status" + aria-live="polite" so SR reads on update
          without interrupting current speech.                          */}
      <div
        role="status"
        aria-live="polite"
        aria-atomic="true"
        className="flex-shrink-0"
      >
        {geo.error && (
          <p
            className="px-4 py-2 text-xs tracking-wide border-b"
            style={{
              background: 'var(--danger-dim)',
              borderColor: 'rgba(224 92 92 / 0.2)',
              color: 'var(--danger)',
            }}
          >
            <span className="font-medium">Location: </span>{geo.error}
          </p>
        )}
      </div>

      {/* ── Hint bar — hidden once a query is made ──────────────────── */}
      {!hasPanel && (
        <div
          className="flex-shrink-0 flex items-center justify-center gap-2 py-2 text-[11px] tracking-wider uppercase select-none"
          style={{ color: 'var(--muted)', borderBottom: '1px solid var(--border)' }}
          aria-label="Usage hint: tap the map or search a city"
        >
          <svg width="12" height="12" viewBox="0 0 12 12" fill="none" aria-hidden="true">
            <circle cx="6" cy="6" r="5" stroke="currentColor" strokeWidth="1.2" />
            <line x1="6" y1="3" x2="6" y2="6.5" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" />
            <circle cx="6" cy="8.5" r="0.7" fill="currentColor" />
          </svg>
          Tap the map or search a city
        </div>
      )}

      {/* ── Main content ────────────────────────────────────────────────
          Mobile:  map full-width, panel below (flex-col)
          Desktop: map + panel side by side (md:flex-row)             */}
      <main
        className="flex-1 min-h-0 flex flex-col md:flex-row"
        id="main-content"
        aria-label="Weather map and results"
      >
        {/* Map — always full-width on mobile, flex-1 on desktop */}
        <div className={`min-h-0 ${hasPanel ? 'h-[55vh] md:h-auto md:flex-1' : 'flex-1'}`}>
          <WeatherMap weather={weather.data} onMapClick={handleMapClick} />
        </div>

        {/* Panel — slides in below map on mobile, beside on desktop */}
        {hasPanel && (
          <WeatherPanel
            data={weather.data}
            loading={weather.loading}
            error={weather.error}
          />
        )}
      </main>

      {/* ── Footer ─────────────────────────────────────────────────────── */}
      <footer
        className="flex-shrink-0 flex flex-wrap gap-x-4 gap-y-0.5 px-4 py-1.5 text-[10px] tracking-wider uppercase select-none border-t border-[--border]"
        style={{ color: 'var(--muted)', background: 'var(--ink-mid)' }}
        aria-label="Data sources"
      >
        <span>Data: Open-Meteo</span>
        <span aria-hidden="true" style={{ color: 'var(--border-hi)' }}>|</span>
        <span>Tiles: OpenStreetMap</span>
      </footer>
    </div>
  );
}
