import type { Page, Route } from '@playwright/test';

/**
 * The exact JSON contract the Rails `WeatherSerializer` emits and the frontend
 * `Weather` interface consumes:
 *   { location, latitude, longitude, temperature_celsius, precipitation_mm, condition }
 *
 * Keeping the fixtures shaped 1:1 with that contract means these E2E tests also
 * guard the contract: if a field is renamed on either side, the assertions on
 * the rendered values break.
 */
export interface WeatherContract {
  location: string;
  latitude: number;
  longitude: number;
  temperature_celsius: number;
  precipitation_mm: number;
  condition: string;
}

/** Result of a successful city-name lookup (`?location=Tokyo`). */
export const TOKYO: WeatherContract = {
  location: 'Tokyo, Tokyo, Japan',
  latitude: 35.6895,
  longitude: 139.69171,
  temperature_celsius: 21.9,
  precipitation_mm: 0.7,
  condition: 'Moderate rain',
};

/** Result of a coordinate lookup from a mocked geolocation position. */
export const GEO_BERLIN: WeatherContract = {
  location: '52.52, 13.405',
  latitude: 52.52,
  longitude: 13.405,
  temperature_celsius: 14.3,
  precipitation_mm: 0.0,
  condition: 'Clear sky',
};

/** Coordinates fed to the browser's mocked Geolocation API. */
export const BERLIN_COORDS = { latitude: 52.52, longitude: 13.405 };

/**
 * The error envelope the controller renders for an unresolvable place name.
 * `GeocodingService::LocationNotFoundError` → HTTP 422 (`unprocessable_content`).
 */
export const NOT_FOUND_ERROR = {
  status: 422,
  body: { error: 'No matching location found. Try a more specific name.' },
};

/**
 * Intercept every browser → backend weather request at `GET /api/v1/weather`
 * and answer from a routing table keyed on the query params.
 *
 * This is the single network boundary the browser sees — geocoding and the
 * Open-Meteo forecast are resolved server-side and never reach the browser, so
 * stubbing this one endpoint makes the whole flow deterministic.
 *
 * The handler branches on the same params the frontend api layer sends:
 *   - `?location=<name>`  → city search
 *   - `?lat=&lon=`        → coordinate / geolocation lookup
 */
export async function stubWeatherApi(page: Page): Promise<void> {
  await page.route('**/api/v1/weather*', async (route: Route) => {
    const url = new URL(route.request().url());
    const location = url.searchParams.get('location');
    const lat = url.searchParams.get('lat');
    const lon = url.searchParams.get('lon');

    // City-name searches.
    if (location) {
      const normalized = location.trim().toLowerCase();
      if (normalized === 'tokyo') {
        return route.fulfill({ json: TOKYO });
      }
      // Anything else is treated as an unresolvable place name.
      return route.fulfill({
        status: NOT_FOUND_ERROR.status,
        json: NOT_FOUND_ERROR.body,
      });
    }

    // Coordinate lookups (map click or geolocation).
    if (lat && lon) {
      return route.fulfill({ json: GEO_BERLIN });
    }

    // No usable params — mirror the controller's ParameterMissing branch.
    return route.fulfill({
      status: 422,
      json: { error: 'param is missing or the value is empty: location or lat/lon required' },
    });
  });
}
