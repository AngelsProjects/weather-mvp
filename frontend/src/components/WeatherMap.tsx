// WeatherMap owns map presentation and programmatic re-centering.
// It receives weather data and a click handler from App; it does not
// fetch anything itself. MapRecenter is an internal child that calls
// useMap() to imperatively fly to new coordinates when data changes.

import { useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import type { LeafletMouseEvent } from 'leaflet';
import type { Weather } from '../types/weather';

interface WeatherMapProps {
  weather: Weather | null;
  onMapClick: (lat: number, lon: number) => void;
}

interface MapRecenterProps {
  lat: number;
  lng: number;
}

/** Inner child: only purpose is to call useMap() and re-center the view. */
function MapRecenter({ lat, lng }: MapRecenterProps) {
  const map = useMap();

  useEffect(() => {
    map.flyTo([lat, lng], Math.max(map.getZoom(), 8), {
      animate: true,
      duration: 1.2,
    });
  }, [lat, lng, map]);

  return null;
}

/** Transparent overlay that captures click coordinates and delegates upward. */
function ClickCatcher({ onMapClick }: { onMapClick: (lat: number, lon: number) => void }) {
  const map = useMap();

  useEffect(() => {
    function handleClick(e: LeafletMouseEvent): void {
      onMapClick(e.latlng.lat, e.latlng.lng);
    }
    map.on('click', handleClick);
    return () => { map.off('click', handleClick); };
  }, [map, onMapClick]);

  return null;
}

export default function WeatherMap({ weather, onMapClick }: WeatherMapProps) {
  return (
    <MapContainer
      center={[20, 0]}
      zoom={2}
      style={{ height: '100%', width: '100%' }}
      zoomControl={true}
    >
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />

      <ClickCatcher onMapClick={onMapClick} />

      {weather && (
        <>
          <MapRecenter lat={weather.latitude} lng={weather.longitude} />
          <Marker position={[weather.latitude, weather.longitude]}>
            <Popup>
              <div style={{ fontFamily: 'var(--mono)', lineHeight: '1.7', minWidth: '140px' }}>
                <div style={{ color: 'var(--amber)', fontSize: '11px', fontWeight: 500, marginBottom: '4px' }}>
                  {weather.location}
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: '12px' }}>
                  <span style={{ color: 'var(--muted)', fontSize: '10px' }}>TEMP</span>
                  <span>{weather.temperature_celsius.toFixed(1)}°C</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: '12px' }}>
                  <span style={{ color: 'var(--muted)', fontSize: '10px' }}>PRECIP</span>
                  <span>{weather.precipitation_mm.toFixed(1)} mm</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: '12px' }}>
                  <span style={{ color: 'var(--muted)', fontSize: '10px' }}>COND</span>
                  <span style={{ textAlign: 'right', maxWidth: '100px' }}>{weather.condition}</span>
                </div>
              </div>
            </Popup>
          </Marker>
        </>
      )}
    </MapContainer>
  );
}
