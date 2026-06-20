import { test, expect } from '@playwright/test';
import {
  stubWeatherApi,
  TOKYO,
  GEO_BERLIN,
  BERLIN_COORDS,
  NOT_FOUND_ERROR,
} from './fixtures';

/**
 * Full-flow E2E coverage for the weather_mvp frontend, with the single
 * browser→backend boundary (`GET /api/v1/weather`) stubbed from fixtures.
 *
 * Selectors are taken from the components' accessibility attributes, not from
 * styling classes, so they survive visual refactors:
 *   - search input  → aria-label "Search by city or place name"
 *   - search submit → aria-label "Search this location"
 *   - geo button    → aria-label "Use my current location"
 *   - error panel   → role="alert"
 *   - map marker    → leaflet's .leaflet-marker-icon
 */

test.beforeEach(async ({ page }) => {
  await stubWeatherApi(page);
});

test('city search shows temperature + precipitation and drops a map marker', async ({ page }) => {
  await page.goto('/');

  // No marker before any query.
  await expect(page.locator('.leaflet-marker-icon')).toHaveCount(0);

  await page.getByRole('searchbox', { name: 'Search by city or place name' }).fill('Tokyo');
  await page.getByRole('button', { name: 'Search this location' }).click();

  const panel = page.getByRole('complementary', { name: 'Weather results' });

  // Location label resolved by the (stubbed) backend.
  await expect(panel.getByText(TOKYO.location)).toBeVisible();

  // Temperature hero readout — rendered as toFixed(1) with a °C suffix.
  await expect(
    panel.getByLabel(`${TOKYO.temperature_celsius.toFixed(1)} degrees Celsius`),
  ).toBeVisible();

  // Precipitation row — value formatted as "<n> mm".
  await expect(
    panel.getByText(`${TOKYO.precipitation_mm.toFixed(1)} mm`),
  ).toBeVisible();

  // Marker appears at the resolved coordinates.
  await expect(page.locator('.leaflet-marker-icon')).toHaveCount(1);

  // Popup content confirms the marker carries this location's data.
  await page.locator('.leaflet-marker-icon').click();
  await expect(page.locator('.leaflet-popup-content')).toContainText(TOKYO.location);
});

test('"Use my location" with a mocked position updates the panel', async ({ page, context }) => {
  // Grant geolocation permission and pin the browser's position to Berlin so the
  // app's navigator.geolocation.getCurrentPosition resolves deterministically.
  await context.grantPermissions(['geolocation']);
  await context.setGeolocation(BERLIN_COORDS);

  await page.goto('/');

  await page.getByRole('button', { name: 'Use my current location' }).click();

  const panel = page.getByRole('complementary', { name: 'Weather results' });

  await expect(panel.getByText(GEO_BERLIN.location)).toBeVisible();
  await expect(
    panel.getByLabel(`${GEO_BERLIN.temperature_celsius.toFixed(1)} degrees Celsius`),
  ).toBeVisible();
  await expect(
    panel.getByText(`${GEO_BERLIN.precipitation_mm.toFixed(1)} mm`),
  ).toBeVisible();

  // Marker recentred on the geolocated point.
  await expect(page.locator('.leaflet-marker-icon')).toHaveCount(1);
});

test('an invalid location shows a friendly error and no marker', async ({ page }) => {
  await page.goto('/');

  await page
    .getByRole('searchbox', { name: 'Search by city or place name' })
    .fill('asdfghjkl-nowhere');
  await page.getByRole('button', { name: 'Search this location' }).click();

  // Error renders in the panel's alert region with the backend-supplied message.
  const alert = page.getByRole('alert');
  await expect(alert).toBeVisible();
  await expect(alert).toContainText(NOT_FOUND_ERROR.body.error);

  // Friendly recovery hint is present.
  await expect(alert).toContainText('Try a different city name or click the map.');

  // A failed lookup must not leave a stale marker on the map.
  await expect(page.locator('.leaflet-marker-icon')).toHaveCount(0);
});
