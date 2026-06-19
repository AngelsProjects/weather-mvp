# Serializes a WeatherService::Result into the exact JSON contract.
# This is the single backend definition of the contract shape; it must
# match frontend/src/types/weather.ts.
class WeatherSerializer
  def initialize(result)
    @result = result
  end

  def as_json(*)
    {
      location: @result.location,
      latitude: @result.latitude,
      longitude: @result.longitude,
      temperature_celsius: @result.temperature_celsius,
      precipitation_mm: @result.precipitation_mm,
      condition: @result.condition
    }
  end
end
