import { defineConfig, devices } from '@playwright/test';

/**
 * E2E config for the weather_mvp frontend.
 *
 * The specs are hermetic: every browser-visible call to the backend
 * (`GET /api/v1/weather`) is intercepted with Playwright `route` and answered
 * from fixtures (see e2e/fixtures.ts). Geocoding + the Open-Meteo forecast both
 * happen *backend-side* (Rails → Open-Meteo), so the browser never sees them —
 * intercepting the single `/api/v1/weather` boundary is what makes the run
 * deterministic without standing up Rails or reaching the real upstream.
 *
 * The dev server is auto-started (and reused if already running on :5173).
 */
const PORT = 5173;
const BASE_URL = `http://localhost:${PORT}`;

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: process.env.CI ? 'github' : 'list',

  use: {
    baseURL: BASE_URL,
    trace: 'on-first-retry',
    // Deterministic viewport so the desktop layout (panel beside map) renders.
    viewport: { width: 1280, height: 800 },
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  webServer: {
    command: 'pnpm dev',
    url: BASE_URL,
    reuseExistingServer: true,
    timeout: 60_000,
  },
});
