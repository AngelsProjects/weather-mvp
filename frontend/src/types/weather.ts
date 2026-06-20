// types layer — pure data contracts, no logic, no I/O.
// Single source of truth for the shapes the frontend and backend agree on.
// Must match the backend WeatherSerializer exactly (see CLAUDE.md JSON Contract).

/**
 * Current weather payload returned by GET /api/v1/weather.
 * Field names and types mirror the Rails serializer 1:1.
 */
export interface Weather {
  location: string;
  latitude: number;
  longitude: number;
  temperature_celsius: number;
  precipitation_mm: number;
  condition: string;
}

/**
 * Error envelope returned by the backend on a non-2xx response.
 * The controller renders `{ error: "..." }` for every failure case
 * (param missing, location not found, upstream weather API failure).
 */
export interface ApiError {
  error: string;
}

/** Decimal-degree coordinate pair. Used by geolocation + coord lookups. */
export interface Coordinates {
  latitude: number;
  longitude: number;
}
