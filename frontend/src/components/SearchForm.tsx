// Presentational + controlled. Owns only the input string and delegates
// all fetch decisions upward via onSearch / onLocate props.

import { type FormEvent, type ChangeEvent, useState, useId } from 'react';

interface SearchFormProps {
  onSearch: (location: string) => void;
  onLocate: () => void;
  loading: boolean;
  geoLoading: boolean;
}

export default function SearchForm({ onSearch, onLocate, loading, geoLoading }: SearchFormProps) {
  const [query, setQuery] = useState<string>('');
  const inputId = useId();
  const busy = loading || geoLoading;
  const canSubmit = query.trim().length > 0 && !busy;

  function handleSubmit(e: FormEvent<HTMLFormElement>): void {
    e.preventDefault();
    const trimmed = query.trim();
    if (trimmed) onSearch(trimmed);
  }

  function handleChange(e: ChangeEvent<HTMLInputElement>): void {
    setQuery(e.target.value);
  }

  return (
    /* role="search" makes the landmark discoverable in SR navigation */
    <div role="search" aria-label="Weather location search">
      <form
        onSubmit={handleSubmit}
        className="flex items-stretch gap-1.5"
        noValidate
      >
        {/* Visible label — sr-only keeps layout clean but satisfies SR */}
        <label htmlFor={inputId} className="sr-only">
          Search by city or place name
        </label>

        <input
          id={inputId}
          type="search"
          value={query}
          onChange={handleChange}
          placeholder="City, country…"
          disabled={busy}
          autoComplete="off"
          autoCorrect="off"
          spellCheck={false}
          /* min-h-11 = 44px touch target */
          className="flex-1 min-w-0 min-h-11 px-3 text-sm rounded-sm transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          style={{
            background: 'var(--ink)',
            border: '1px solid var(--border-hi)',
            borderRadius: '3px',
            color: 'var(--text)',
            fontFamily: 'var(--mono)',
            /* Placeholder color */
          }}
          aria-label="Search by city or place name"
        />

        {/* Submit */}
        <button
          type="submit"
          disabled={!canSubmit}
          aria-label={loading ? 'Searching…' : 'Search this location'}
          aria-busy={loading}
          className="min-h-11 px-4 text-xs tracking-widest uppercase rounded-sm transition-all disabled:opacity-40 disabled:cursor-not-allowed"
          style={{
            background: canSubmit ? 'var(--amber-dim)' : 'transparent',
            border: `1px solid ${canSubmit ? 'var(--amber)' : 'var(--border-hi)'}`,
            borderRadius: '3px',
            color: canSubmit ? 'var(--amber)' : 'var(--muted)',
            fontFamily: 'var(--mono)',
            whiteSpace: 'nowrap',
          }}
        >
          {loading ? (
            /* Spinner for SR + visual */
            <span aria-hidden="true">…</span>
          ) : (
            'Search'
          )}
        </button>

        {/* Divider */}
        <div className="w-px self-stretch mx-0.5" style={{ background: 'var(--border-hi)' }} aria-hidden="true" />

        {/* Geolocation */}
        <button
          type="button"
          onClick={onLocate}
          disabled={busy}
          aria-label={geoLoading ? 'Detecting your location…' : 'Use my current location'}
          aria-busy={geoLoading}
          className="min-h-11 px-3 text-xs tracking-widest uppercase rounded-sm transition-all flex items-center gap-1.5 disabled:opacity-40 disabled:cursor-not-allowed"
          style={{
            background: geoLoading ? 'var(--teal-dim)' : 'transparent',
            border: `1px solid ${geoLoading ? 'var(--teal)' : 'var(--border-hi)'}`,
            borderRadius: '3px',
            color: geoLoading ? 'var(--teal)' : 'var(--muted)',
            fontFamily: 'var(--mono)',
            whiteSpace: 'nowrap',
          }}
        >
          {/* Crosshair icon */}
          <svg width="13" height="13" viewBox="0 0 12 12" fill="none" aria-hidden="true" focusable="false">
            <circle cx="6" cy="6" r="4.5" stroke="currentColor" strokeWidth="1.1" />
            <circle cx="6" cy="6" r="1.4" fill="currentColor" />
            <line x1="6" y1="0.5" x2="6" y2="2.8" stroke="currentColor" strokeWidth="1.1" strokeLinecap="round" />
            <line x1="6" y1="9.2" x2="6" y2="11.5" stroke="currentColor" strokeWidth="1.1" strokeLinecap="round" />
            <line x1="0.5" y1="6" x2="2.8" y2="6" stroke="currentColor" strokeWidth="1.1" strokeLinecap="round" />
            <line x1="9.2" y1="6" x2="11.5" y2="6" stroke="currentColor" strokeWidth="1.1" strokeLinecap="round" />
          </svg>
          <span className="hidden sm:inline">
            {geoLoading ? 'Locating…' : 'My location'}
          </span>
        </button>
      </form>
    </div>
  );
}
