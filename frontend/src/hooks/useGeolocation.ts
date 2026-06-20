// hooks layer — bridges browser/React state to the rest of the app.
// useGeolocation owns ONE concern: getting the user's coordinates from the
// browser Geolocation API and exposing it as React state. It knows nothing
// about weather or HTTP — it just yields Coordinates (or an error).

import { useCallback, useState } from 'react';
import type { Coordinates } from '../types/weather';

export interface GeolocationState {
  /** Last successfully resolved position, or null before any request. */
  coords: Coordinates | null;
  /** Human-readable failure reason, or null when there is none. */
  error: string | null;
  /** True while a permission prompt / position lookup is in flight. */
  loading: boolean;
  /** Triggers a geolocation request. Safe to call repeatedly. */
  request: () => void;
}

/** Maps a GeolocationPositionError code to a user-facing message. */
function describeError(err: GeolocationPositionError): string {
  switch (err.code) {
    case err.PERMISSION_DENIED:
      return 'Location permission denied. Enter a place name instead.';
    case err.POSITION_UNAVAILABLE:
      return 'Your location is currently unavailable.';
    case err.TIMEOUT:
      return 'Timed out while locating you. Try again.';
    default:
      return 'Could not determine your location.';
  }
}

export function useGeolocation(): GeolocationState {
  const [coords, setCoords] = useState<Coordinates | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState<boolean>(false);

  const request = useCallback((): void => {
    if (!navigator.geolocation) {
      setError('Geolocation is not supported by this browser.');
      return;
    }

    setLoading(true);
    setError(null);

    navigator.geolocation.getCurrentPosition(
      (position: GeolocationPosition): void => {
        setCoords({
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
        });
        setLoading(false);
      },
      (err: GeolocationPositionError): void => {
        setError(describeError(err));
        setLoading(false);
      },
      { enableHighAccuracy: false, timeout: 10_000, maximumAge: 60_000 },
    );
  }, []);

  return { coords, error, loading, request };
}
