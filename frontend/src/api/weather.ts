import type { Weather } from '../types/weather';

const API_BASE = import.meta.env.VITE_API_BASE ?? 'http://localhost:3000';

export async function fetchWeather(lat: number, lon: number): Promise<Weather> {
  const url = new URL('/api/v1/weather', API_BASE);
  url.searchParams.set('latitude', String(lat));
  url.searchParams.set('longitude', String(lon));

  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`Weather request failed: ${res.status}`);
  }
  return (await res.json()) as Weather;
}
