# Thin wrapper over the Open-Meteo HTTP API.
# Knows how to talk HTTP; knows nothing about our domain shape.
# Injected into WeatherService so it can be swapped/stubbed.
class OpenMeteoClient
  BASE_URL = "https://api.open-meteo.com".freeze

  def initialize(connection: default_connection)
    @connection = connection
  end

  # Returns the raw parsed Open-Meteo response Hash for the given coordinates.
  def current_weather(latitude:, longitude:)
    response = @connection.get("/v1/forecast") do |req|
      req.params["latitude"] = latitude
      req.params["longitude"] = longitude
      req.params["current"] = "temperature_2m,precipitation,weather_code"
    end

    raise Error, "Open-Meteo responded #{response.status}" unless response.success?

    response.body
  end

  class Error < StandardError; end

  private

  def default_connection
    Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end
end
