// Pure presentational. Receives weather data, loading, and error state.
// Renders nothing visible until one of those states is present.
// Layout: full-width below map on mobile, fixed-width sidebar on md+.

import type { Weather } from '../types/weather';

interface WeatherPanelProps {
  data: Weather | null;
  loading: boolean;
  error: string | null;
}

/** Labelled data row */
function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between items-baseline gap-4">
      <dt className="text-[10px] tracking-widest uppercase" style={{ color: 'var(--muted)' }}>
        {label}
      </dt>
      <dd className="text-[13px] tabular-nums" style={{ color: 'var(--text)', fontFamily: 'var(--mono)' }}>
        {value}
      </dd>
    </div>
  );
}

export default function WeatherPanel({ data, loading, error }: WeatherPanelProps) {
  if (!loading && !error && !data) return null;

  return (
    <aside
      /* Mobile: full-width strip below map. md+: fixed sidebar */
      className={[
        'shrink-0 flex flex-col overflow-y-auto',
        'w-full md:w-56 md:border-l',
        'border-t md:border-t-0',
        data ? 'panel-animate' : '',
      ].join(' ')}
      style={{
        background: 'var(--ink-mid)',
        borderColor: 'var(--border)',
      }}
      aria-label="Weather results"
      aria-live="polite"
      aria-atomic="false"
    >

      {/* ── Loading ─────────────────────────────────────────────────── */}
      {loading && (
        <div
          className="flex flex-row md:flex-col items-center justify-center gap-3 p-6 shrink-0"
          role="status"
          aria-label="Loading weather data"
        >
          <div className="relative w-6 h-6 shrink-0" aria-hidden="true">
            <div
              className="pulse-ring absolute inset-0 rounded-full"
              style={{ border: '2px solid var(--amber)' }}
            />
            <div
              className="pulse-core absolute rounded-full"
              style={{ inset: '6px', background: 'var(--amber)' }}
            />
          </div>
          <span className="text-[11px] tracking-widest uppercase" style={{ color: 'var(--muted)' }}>
            Fetching…
          </span>
        </div>
      )}

      {/* ── Error ───────────────────────────────────────────────────── */}
      {!loading && error && (
        <div
          className="m-4 p-3 text-xs leading-relaxed rounded-sm"
          style={{
            background: 'var(--danger-dim)',
            border: '1px solid rgba(224 92 92 / 0.25)',
            borderLeft: '3px solid var(--danger)',
            color: 'var(--danger)',
          }}
          role="alert"
        >
          <p className="font-medium mb-1 text-[10px] tracking-widest uppercase opacity-75">Error</p>
          <p className="mb-2">{error}</p>
          <p className="text-[11px]" style={{ color: 'var(--muted)' }}>
            Try a different city name or click the map.
          </p>
        </div>
      )}

      {/* ── Data ────────────────────────────────────────────────────── */}
      {!loading && !error && data && (
        <div className="flex flex-col">

          {/* Location */}
          <div className="px-4 py-3" style={{ borderBottom: '1px solid var(--border)' }}>
            <p className="text-[9px] tracking-[0.14em] uppercase mb-1" style={{ color: 'var(--muted)' }}>
              Location
            </p>
            <p
              className="text-sm font-medium leading-snug wrap-break-word"
              style={{ color: 'var(--text-hi)' }}
            >
              {data.location}
            </p>
          </div>

          {/* Temperature — hero readout */}
          <div className="px-4 py-4" style={{ borderBottom: '1px solid var(--border)' }}>
            <p className="text-[9px] tracking-[0.14em] uppercase mb-1" style={{ color: 'var(--muted)' }}>
              Temperature
            </p>
            {/* tabular-nums keeps digits stable if value updates */}
            <p
              className="leading-none tabular-nums"
              style={{
                color: 'var(--amber)',
                fontFamily: 'var(--mono)',
                fontSize: '40px',
                fontWeight: 300,
                letterSpacing: '-0.02em',
              }}
              aria-label={`${data.temperature_celsius.toFixed(1)} degrees Celsius`}
            >
              {data.temperature_celsius.toFixed(1)}
              <span className="text-lg ml-1" style={{ color: 'var(--muted)', fontWeight: 400 }}>
                °C
              </span>
            </p>
          </div>

          {/* Precip + Condition */}
          <dl className="flex flex-col gap-2 px-4 py-3" style={{ borderBottom: '1px solid var(--border)' }}>
            <Row label="Precipitation" value={`${data.precipitation_mm.toFixed(1)} mm`} />
            <Row label="Condition" value={data.condition} />
          </dl>

          {/* Coordinates */}
          <dl className="flex flex-col gap-1.5 px-4 py-3">
            <p className="text-[9px] tracking-[0.14em] uppercase mb-0.5" style={{ color: 'var(--muted)' }}>
              Coordinates
            </p>
            <Row label="Lat" value={`${data.latitude.toFixed(4)}°`} />
            <Row label="Lon" value={`${data.longitude.toFixed(4)}°`} />
          </dl>

        </div>
      )}
    </aside>
  );
}
