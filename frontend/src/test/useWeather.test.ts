import { act, renderHook, waitFor } from '@testing-library/react';
import { useWeather } from '../hooks/useWeather';
import * as api from '../api/weatherApi';
import { WeatherRequestError } from '../api/weatherApi';
import type { Weather } from '../types/weather';

const MOCK_WEATHER: Weather = {
  location: 'Madrid, Spain',
  latitude: 40.41,
  longitude: -3.7,
  temperature_celsius: 22.0,
  precipitation_mm: 0.0,
  condition: 'Clear sky',
};

afterEach(() => { vi.restoreAllMocks(); });

describe('useWeather', () => {
  it('exposes data on a successful lookup', async () => {
    vi.spyOn(api, 'getWeatherByLocation').mockResolvedValue(MOCK_WEATHER);

    const { result } = renderHook(() => useWeather());
    act(() => { result.current.byLocation('Madrid'); });

    await waitFor(() => expect(result.current.data).toEqual(MOCK_WEATHER));
    expect(result.current.error).toBeNull();
  });

  it('clears stale data when a later lookup fails', async () => {
    const getByLocation = vi.spyOn(api, 'getWeatherByLocation');

    // First lookup succeeds.
    getByLocation.mockResolvedValueOnce(MOCK_WEATHER);
    const { result } = renderHook(() => useWeather());
    act(() => { result.current.byLocation('Madrid'); });
    await waitFor(() => expect(result.current.data).toEqual(MOCK_WEATHER));

    // Second lookup fails — stale data must not linger alongside the error.
    getByLocation.mockRejectedValueOnce(new WeatherRequestError('not found', 422));
    act(() => { result.current.byLocation('asdf'); });

    await waitFor(() => expect(result.current.error).toBe('not found'));
    expect(result.current.data).toBeNull();
  });
});
