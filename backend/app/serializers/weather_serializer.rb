# frozen_string_literal: true

# Maps a raw Open-Meteo forecast payload (plus resolved location context) into
# the exact JSON contract. This is the single backend definition of the contract
# shape; it must match frontend/src/types/weather.ts.
#
#   { location, latitude, longitude, temperature_celsius, precipitation_mm, condition }
#
# location/latitude/longitude come from geocoding (the forecast endpoint has no
# place name), so they are passed in alongside the raw forecast hash.
class WeatherSerializer
  # @param forecast [Hash] raw Open-Meteo forecast payload (with "current").
  # @param location [String] human-readable place label.
  # @param latitude [Float] resolved WGS84 latitude.
  # @param longitude [Float] resolved WGS84 longitude.
  def initialize(forecast:, location:, latitude:, longitude:)
    @forecast = forecast
    @location = location
    @latitude = latitude
    @longitude = longitude
  end

  # Builds the contract hash.
  #
  # @return [Hash] the contract payload (symbol keys).
  # @complexity O(1) time, O(1) space — fixed set of fields.
  def as_json(*)
    current = @forecast.fetch("current")

    {
      location: @location,
      latitude: @latitude.to_f,
      longitude: @longitude.to_f,
      temperature_celsius: current.fetch("temperature_2m").to_f,
      precipitation_mm: current.fetch("precipitation").to_f,
      condition: WeatherCodes.describe(current.fetch("weather_code"))
    }
  rescue KeyError => e
    # The upstream payload was missing a field we depend on. Normalize to the
    # single domain error so the controller renders a 502 instead of a 500.
    raise WeatherApiError, "malformed forecast payload (#{e.key})"
  end
end
