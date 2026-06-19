// Shared API contract. Must match the backend serializer exactly.
// Single source of truth for the weather payload shape.
export interface Weather {
  location: string;
  latitude: number;
  longitude: number;
  temperature_celsius: number;
  precipitation_mm: number;
  condition: string;
}
