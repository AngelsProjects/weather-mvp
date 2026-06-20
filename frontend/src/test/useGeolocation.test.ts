import { renderHook, act } from '@testing-library/react';
import { useGeolocation } from '../hooks/useGeolocation';

// ── Helpers ────────────────────────────────────────────────────────────────

/** Build a mock GeolocationPositionError with the given code. */
function makeGeoError(code: number): GeolocationPositionError {
  return {
    code,
    message: '',
    PERMISSION_DENIED: 1,
    POSITION_UNAVAILABLE: 2,
    TIMEOUT: 3,
  } satisfies GeolocationPositionError;
}

/** Build a minimal GeolocationPosition stub. */
function makePosition(lat: number, lng: number): GeolocationPosition {
  return {
    coords: {
      latitude: lat,
      longitude: lng,
      accuracy: 10,
      altitude: null,
      altitudeAccuracy: null,
      heading: null,
      speed: null,
      toJSON() { return this; },
    },
    timestamp: Date.now(),
    toJSON() { return this; },
  };
}

// ── Tests ──────────────────────────────────────────────────────────────────

describe('useGeolocation', () => {
  let getCurrentPositionMock: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    getCurrentPositionMock = vi.fn();
    // Replace the browser API with a controllable mock
    Object.defineProperty(navigator, 'geolocation', {
      writable: true,
      value: { getCurrentPosition: getCurrentPositionMock },
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('starts idle: no coords, no error, not loading', () => {
    const { result } = renderHook(() => useGeolocation());

    expect(result.current.coords).toBeNull();
    expect(result.current.error).toBeNull();
    expect(result.current.loading).toBe(false);
  });

  it('sets loading=true immediately after request() is called', () => {
    // Never call success or error — position stays pending
    getCurrentPositionMock.mockImplementation(() => { /* noop */ });

    const { result } = renderHook(() => useGeolocation());

    act(() => { result.current.request(); });

    expect(result.current.loading).toBe(true);
    expect(result.current.coords).toBeNull();
    expect(result.current.error).toBeNull();
  });

  it('resolves coords on success and clears loading', () => {
    const position = makePosition(37.7749, -122.4194);
    getCurrentPositionMock.mockImplementation(
      (success: PositionCallback) => success(position),
    );

    const { result } = renderHook(() => useGeolocation());

    act(() => { result.current.request(); });

    expect(result.current.loading).toBe(false);
    expect(result.current.error).toBeNull();
    expect(result.current.coords).toEqual({ latitude: 37.7749, longitude: -122.4194 });
  });

  it('sets a descriptive error on PERMISSION_DENIED and clears loading', () => {
    const geoErr = makeGeoError(1 /* PERMISSION_DENIED */);
    getCurrentPositionMock.mockImplementation(
      (_: PositionCallback, error: PositionErrorCallback) => error(geoErr),
    );

    const { result } = renderHook(() => useGeolocation());

    act(() => { result.current.request(); });

    expect(result.current.loading).toBe(false);
    expect(result.current.coords).toBeNull();
    expect(result.current.error).toBe(
      'Location permission denied. Enter a place name instead.',
    );
  });

  it('sets a descriptive error on POSITION_UNAVAILABLE', () => {
    const geoErr = makeGeoError(2 /* POSITION_UNAVAILABLE */);
    getCurrentPositionMock.mockImplementation(
      (_: PositionCallback, error: PositionErrorCallback) => error(geoErr),
    );

    const { result } = renderHook(() => useGeolocation());

    act(() => { result.current.request(); });

    expect(result.current.error).toBe('Your location is currently unavailable.');
  });

  it('sets a descriptive error on TIMEOUT', () => {
    const geoErr = makeGeoError(3 /* TIMEOUT */);
    getCurrentPositionMock.mockImplementation(
      (_: PositionCallback, error: PositionErrorCallback) => error(geoErr),
    );

    const { result } = renderHook(() => useGeolocation());

    act(() => { result.current.request(); });

    expect(result.current.error).toBe('Timed out while locating you. Try again.');
  });

  it('reports unsupported when navigator.geolocation is falsy', () => {
    // jsdom's navigator.geolocation is non-configurable so it cannot be deleted,
    // but setting it to undefined via the mock lets us exercise the truthiness
    // check in the hook (`!navigator.geolocation`).
    Object.defineProperty(navigator, 'geolocation', {
      writable: true,
      value: undefined,
    });

    const { result } = renderHook(() => useGeolocation());

    act(() => { result.current.request(); });

    expect(result.current.error).toBe('Geolocation is not supported by this browser.');
    expect(result.current.loading).toBe(false);
  });

  it('clears a previous error when a new request succeeds', () => {
    // First call → permission denied
    const denied = makeGeoError(1);
    getCurrentPositionMock.mockImplementationOnce(
      (_: PositionCallback, error: PositionErrorCallback) => error(denied),
    );
    // Second call → success
    const position = makePosition(51.5074, -0.1278);
    getCurrentPositionMock.mockImplementationOnce(
      (success: PositionCallback) => success(position),
    );

    const { result } = renderHook(() => useGeolocation());

    act(() => { result.current.request(); });
    expect(result.current.error).not.toBeNull();

    act(() => { result.current.request(); });
    expect(result.current.error).toBeNull();
    expect(result.current.coords).toEqual({ latitude: 51.5074, longitude: -0.1278 });
  });
});
