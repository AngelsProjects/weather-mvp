# Domain logic: fetch current weather for coordinates and map it to our contract.
# The HTTP client is injected (dependency injection) so the service is
# testable without network access and the client is swappable.
class WeatherService
  Result = Struct.new(
    :location,
    :latitude,
    :longitude,
    :temperature_celsius,
    :precipitation_mm,
    :condition,
    keyword_init: true
  )

  def initialize(client: OpenMeteoClient.new)
    @client = client
  end

  # @return [Result] the contract payload for the given coordinates.
  def current(latitude:, longitude:)
    data = @client.current_weather(latitude: latitude, longitude: longitude)
    current = data.fetch("current")

    Result.new(
      location: "#{latitude}, #{longitude}",
      latitude: latitude.to_f,
      longitude: longitude.to_f,
      temperature_celsius: current.fetch("temperature_2m").to_f,
      precipitation_mm: current.fetch("precipitation").to_f,
      condition: WeatherCodes.describe(current.fetch("weather_code"))
    )
  end
end
