# frozen_string_literal: true

# Fetches the raw current-weather payload for a coordinate pair, cached for
# 10 minutes so repeated lookups of the same spot don't re-hit Open-Meteo.
#
# The HTTP client is injected (DIP): defaults to a real {OpenMeteoClient},
# tests pass a stub. Returns raw JSON; mapping to the contract is the
# serializer's job (single responsibility).
class WeatherFetcherService
  CACHE_EXPIRY = 10.minutes

  # @param client [#forecast] collaborator that performs the forecast request.
  def initialize(client: OpenMeteoClient.new)
    @client = client
  end

  # Returns the raw forecast hash for the coordinates, reading through a
  # 10-minute cache keyed by rounded coordinate.
  #
  # @param latitude [Float] WGS84 latitude.
  # @param longitude [Float] WGS84 longitude.
  # @return [Hash] raw Open-Meteo forecast payload.
  # @raise [WeatherApiError] when the upstream request fails (uncached).
  # @complexity O(1) time, O(1) space — one cache read, at most one request.
  def call(latitude:, longitude:)
    key = cache_key(latitude, longitude)
    cached = Rails.cache.read(key)
    return cached unless cached.nil?

    result = @client.forecast(latitude: latitude, longitude: longitude)
    Rails.cache.write(key, result, expires_in: CACHE_EXPIRY)
    result
  end

  private

  # @complexity O(1) time, O(1) space.
  def cache_key(latitude, longitude)
    "weather/forecast/#{latitude.to_f.round(2)}/#{longitude.to_f.round(2)}"
  end
end
