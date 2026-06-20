// hooks layer — useWeather owns the async lifecycle of a weather lookup:
// the data, the loading flag, and the error. It delegates the actual
// networking to the api layer (weatherApi) and translates typed errors
// into a flat string for the UI. Components stay declarative: they call
// byLocation/byCoords and render off { data, loading, error }.

import { useCallback, useRef, useState } from 'react';
import type { Weather } from '../types/weather';
import {
  getWeatherByLocation,
  getWeatherByCoords,
  WeatherRequestError,
} from '../api/weatherApi';

export interface WeatherState {
  data: Weather | null;
  loading: boolean;
  error: string | null;
  /** Fetch by place name. */
  byLocation: (name: string) => void;
  /** Fetch by decimal-degree coordinates. */
  byCoords: (lat: number, lon: number) => void;
}

export function useWeather(): WeatherState {
  const [data, setData] = useState<Weather | null>(null);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Monotonic token: only the most recent request is allowed to commit
  // state, so a slow earlier lookup can't overwrite a newer one.
  const requestId = useRef<number>(0);

  const run = useCallback((fetcher: () => Promise<Weather>): void => {
    const id = ++requestId.current;
    setLoading(true);
    setError(null);

    fetcher()
      .then((weather: Weather): void => {
        if (id !== requestId.current) return;
        setData(weather);
        setLoading(false);
      })
      .catch((err: unknown): void => {
        if (id !== requestId.current) return;
        const message =
          err instanceof WeatherRequestError
            ? err.message
            : 'Something went wrong fetching the weather.';
        // Drop stale data so the UI never shows an old result beside an error
        // (e.g. a previous city's marker lingering on the map after a failure).
        setData(null);
        setError(message);
        setLoading(false);
      });
  }, []);

  const byLocation = useCallback(
    (name: string): void => run(() => getWeatherByLocation(name)),
    [run],
  );

  const byCoords = useCallback(
    (lat: number, lon: number): void => run(() => getWeatherByCoords(lat, lon)),
    [run],
  );

  return { data, loading, error, byLocation, byCoords };
}
