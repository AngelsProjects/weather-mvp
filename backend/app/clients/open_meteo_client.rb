# frozen_string_literal: true

# Thin HTTP wrapper over the Open-Meteo API.
#
# Single responsibility: speak HTTP to Open-Meteo and hand back parsed JSON.
# It knows nothing about our domain contract — mapping lives in the serializer.
# Two distinct hosts are involved:
#   * geocoding: https://geocoding-api.open-meteo.com/v1/search
#   * forecast:  https://api.open-meteo.com/v1/forecast
#
# Network/HTTP failures are normalized to {WeatherApiError} so callers never
# have to rescue Faraday internals.
class OpenMeteoClient
  GEOCODING_URL = "https://geocoding-api.open-meteo.com"
  FORECAST_URL  = "https://api.open-meteo.com"
  TIMEOUT_SECONDS = 5

  # @param geocoding_connection [Faraday::Connection] injected for tests/DI.
  # @param forecast_connection [Faraday::Connection] injected for tests/DI.
  def initialize(geocoding_connection: build_connection(GEOCODING_URL),
                 forecast_connection: build_connection(FORECAST_URL))
    @geocoding_connection = geocoding_connection
    @forecast_connection = forecast_connection
  end

  # Looks up coordinates for a free-text place name.
  #
  # @param name [String] place name or postal code to search for.
  # @return [Hash, nil] the first match (name/latitude/longitude/country/admin1),
  #   or nil when Open-Meteo returns no results.
  # @raise [WeatherApiError] on timeout or a non-2xx response.
  # @complexity O(1) time, O(1) space — one request, first result only.
  def geocode(name)
    body = get(@geocoding_connection, "/v1/search", name: name, count: 1, language: "en", format: "json")
    Array(body["results"]).first
  end

  # Fetches current weather for a coordinate pair.
  #
  # @param latitude [Float, String] WGS84 latitude.
  # @param longitude [Float, String] WGS84 longitude.
  # @return [Hash] raw Open-Meteo forecast payload (includes the "current" object).
  # @raise [WeatherApiError] on timeout or a non-2xx response.
  # @complexity O(1) time, O(1) space — one request, fixed-size payload.
  def forecast(latitude:, longitude:)
    get(
      @forecast_connection, "/v1/forecast",
      latitude: latitude, longitude: longitude,
      current: "temperature_2m,precipitation,weather_code"
    )
  end

  private

  # Performs the GET and normalizes failures to {WeatherApiError}.
  # @complexity O(1) time, O(1) space.
  def get(connection, path, params)
    response = connection.get(path, params)
    return response.body if response.success?

    raise WeatherApiError, "Open-Meteo responded #{response.status}"
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
    raise WeatherApiError, "Open-Meteo request failed: #{e.message}"
  end

  # @complexity O(1) time, O(1) space.
  def build_connection(url)
    Faraday.new(url: url, request: { timeout: TIMEOUT_SECONDS, open_timeout: TIMEOUT_SECONDS }) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end
end
