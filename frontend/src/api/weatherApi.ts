// api layer — the ONLY place that knows about HTTP, URLs, and the wire format.
// Hooks/components call these functions; they never touch fetch directly.
// Keeps networking swappable and the rest of the app transport-agnostic.

import type { Weather, ApiError } from '../types/weather';

const API_BASE: string = import.meta.env.VITE_API_BASE ?? 'http://localhost:3000';
const WEATHER_PATH = '/api/v1/weather';

/**
 * Thrown for any failed weather request. Carries the HTTP status and the
 * backend-supplied message so callers can branch on `status` and surface
 * `message` to the user without re-parsing responses.
 */
export class WeatherRequestError extends Error {
  readonly status: number;

  constructor(message: string, status: number) {
    super(message);
    this.name = 'WeatherRequestError';
    this.status = status;
  }
}

/** Narrows an unknown JSON body to the `{ error: string }` envelope. */
function isApiError(body: unknown): body is ApiError {
  return (
    typeof body === 'object' &&
    body !== null &&
    'error' in body &&
    typeof (body as Record<string, unknown>).error === 'string'
  );
}

/**
 * Performs the request, validates the response, and normalizes every
 * failure path into a single typed WeatherRequestError.
 * `status: 0` denotes a transport/network failure (no HTTP response).
 */
async function request(url: URL): Promise<Weather> {
  let res: Response;
  try {
    res = await fetch(url);
  } catch {
    throw new WeatherRequestError('Network error: could not reach the weather service.', 0);
  }

  let body: unknown;
  try {
    body = await res.json();
  } catch {
    body = null;
  }

  if (!res.ok) {
    const message = isApiError(body) ? body.error : `Weather request failed (${res.status}).`;
    throw new WeatherRequestError(message, res.status);
  }

  return body as Weather;
}

/** Builds a weather URL with the given query params. */
function buildUrl(params: Record<string, string>): URL {
  const url = new URL(WEATHER_PATH, API_BASE);
  for (const [key, value] of Object.entries(params)) {
    url.searchParams.set(key, value);
  }
  return url;
}

/** Look up current weather by human-readable place name (?location=). */
export function getWeatherByLocation(name: string): Promise<Weather> {
  return request(buildUrl({ location: name }));
}

/** Look up current weather by decimal-degree coordinates (?lat=&lon=). */
export function getWeatherByCoords(lat: number, lon: number): Promise<Weather> {
  return request(buildUrl({ lat: String(lat), lon: String(lon) }));
}
