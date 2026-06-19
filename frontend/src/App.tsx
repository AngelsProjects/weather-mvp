import { useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMapEvents } from 'react-leaflet';
import type { LeafletMouseEvent } from 'leaflet';
import { fetchWeather } from './api/weather';
import type { Weather } from './types/weather';

function ClickHandler({ onPick }: { onPick: (lat: number, lon: number) => void }) {
  useMapEvents({
    click(e: LeafletMouseEvent) {
      onPick(e.latlng.lat, e.latlng.lng);
    },
  });
  return null;
}

export default function App() {
  const [weather, setWeather] = useState<Weather | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function handlePick(lat: number, lon: number) {
    setError(null);
    try {
      setWeather(await fetchWeather(lat, lon));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    }
  }

  return (
    <div className="flex h-screen flex-col">
      <header className="bg-slate-900 px-6 py-4 text-white">
        <h1 className="text-xl font-semibold">weather_mvp</h1>
        <p className="text-sm text-slate-300">Click the map for temperature &amp; precipitation.</p>
      </header>

      {error && (
        <div className="bg-red-100 px-6 py-2 text-sm text-red-800">{error}</div>
      )}

      <div className="flex-1">
        <MapContainer center={[40, -3]} zoom={4} className="h-full w-full">
          <TileLayer
            attribution="&copy; OpenStreetMap contributors"
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          <ClickHandler onPick={handlePick} />
          {weather && (
            <Marker position={[weather.latitude, weather.longitude]}>
              <Popup>
                <strong>{weather.location}</strong>
                <br />
                {weather.temperature_celsius}&deg;C &middot; {weather.precipitation_mm} mm
                <br />
                {weather.condition}
              </Popup>
            </Marker>
          )}
        </MapContainer>
      </div>
    </div>
  );
}
