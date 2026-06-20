import {
  getWeatherByLocation,
  getWeatherByCoords,
  WeatherRequestError,
} from '../api/weatherApi';
import type { Weather } from '../types/weather';

// ── Fixtures ───────────────────────────────────────────────────────────────

const MOCK_WEATHER: Weather = {
  location: 'London, UK',
  latitude: 51.5074,
  longitude: -0.1278,
  temperature_celsius: 14.5,
  precipitation_mm: 0.2,
  condition: 'Partly cloudy',
};

// ── Helpers ────────────────────────────────────────────────────────────────

/** Build a minimal fetch Response stub. */
function mockResponse(body: unknown, status = 200): Response {
  return {
    ok: status >= 200 && status < 300,
    status,
    json: () => Promise.resolve(body),
  } as unknown as Response;
}

/** Stub global fetch to return a given response. */
function stubFetch(res: Response): void {
  vi.stubGlobal('fetch', vi.fn().mockResolvedValue(res));
}

/** Stub global fetch to reject (simulates a network error). */
function stubFetchNetworkError(): void {
  vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new TypeError('Failed to fetch')));
}

// ── Tests ──────────────────────────────────────────────────────────────────

describe('getWeatherByLocation', () => {
  afterEach(() => { vi.unstubAllGlobals(); });

  it('returns parsed Weather on 200', async () => {
    stubFetch(mockResponse(MOCK_WEATHER));
    const result = await getWeatherByLocation('London');
    expect(result).toEqual(MOCK_WEATHER);
  });

  it('sends ?location= param in the URL', async () => {
    const fetchSpy = vi.fn().mockResolvedValue(mockResponse(MOCK_WEATHER));
    vi.stubGlobal('fetch', fetchSpy);

    await getWeatherByLocation('Tokyo');

    const calledUrl = fetchSpy.mock.calls[0][0] as URL;
    expect(calledUrl.searchParams.get('location')).toBe('Tokyo');
  });

  it('throws WeatherRequestError with backend message on 422', async () => {
    stubFetch(mockResponse({ error: 'location or lat/lon required' }, 422));

    await expect(getWeatherByLocation('')).rejects.toSatisfy(
      (e: unknown) =>
        e instanceof WeatherRequestError &&
        e.status === 422 &&
        e.message === 'location or lat/lon required',
    );
  });

  it('throws WeatherRequestError with fallback message when no error envelope', async () => {
    stubFetch(mockResponse('Internal Server Error', 500));

    await expect(getWeatherByLocation('x')).rejects.toSatisfy(
      (e: unknown) =>
        e instanceof WeatherRequestError &&
        e.status === 500 &&
        e.message.includes('500'),
    );
  });

  it('throws WeatherRequestError with status 0 on network failure', async () => {
    stubFetchNetworkError();

    await expect(getWeatherByLocation('London')).rejects.toSatisfy(
      (e: unknown) =>
        e instanceof WeatherRequestError &&
        e.status === 0 &&
        e.message.toLowerCase().includes('network'),
    );
  });
});

describe('getWeatherByCoords', () => {
  afterEach(() => { vi.unstubAllGlobals(); });

  it('returns parsed Weather on 200', async () => {
    stubFetch(mockResponse(MOCK_WEATHER));
    const result = await getWeatherByCoords(51.5074, -0.1278);
    expect(result).toEqual(MOCK_WEATHER);
  });

  it('sends ?lat= and ?lon= params in the URL', async () => {
    const fetchSpy = vi.fn().mockResolvedValue(mockResponse(MOCK_WEATHER));
    vi.stubGlobal('fetch', fetchSpy);

    await getWeatherByCoords(40.7128, -74.006);

    const calledUrl = fetchSpy.mock.calls[0][0] as URL;
    expect(calledUrl.searchParams.get('lat')).toBe('40.7128');
    expect(calledUrl.searchParams.get('lon')).toBe('-74.006');
  });

  it('throws WeatherRequestError with backend message on 422', async () => {
    stubFetch(mockResponse({ error: 'location not found' }, 422));

    await expect(getWeatherByCoords(0, 0)).rejects.toSatisfy(
      (e: unknown) =>
        e instanceof WeatherRequestError &&
        e.status === 422 &&
        e.message === 'location not found',
    );
  });

  it('throws WeatherRequestError with status 0 on network failure', async () => {
    stubFetchNetworkError();

    await expect(getWeatherByCoords(0, 0)).rejects.toSatisfy(
      (e: unknown) =>
        e instanceof WeatherRequestError && e.status === 0,
    );
  });
});

describe('WeatherRequestError', () => {
  it('is instanceof Error', () => {
    const err = new WeatherRequestError('oops', 404);
    expect(err).toBeInstanceOf(Error);
    expect(err.name).toBe('WeatherRequestError');
    expect(err.status).toBe(404);
    expect(err.message).toBe('oops');
  });
});
