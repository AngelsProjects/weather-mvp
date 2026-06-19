# frozen_string_literal: true

# Resolves a free-text place name to coordinates plus a human-readable label.
#
# The HTTP client is injected (DIP): defaults to a real {OpenMeteoClient},
# but tests pass a stub. Depends on the abstraction "responds to #geocode",
# not on a concrete network class.
class GeocodingService
  # Raised when no location matches the query.
  class LocationNotFoundError < StandardError; end

  # Value object: the resolved place.
  Place = Struct.new(:label, :latitude, :longitude, keyword_init: true)

  # @param client [#geocode] collaborator that performs the lookup.
  def initialize(client: OpenMeteoClient.new)
    @client = client
  end

  # Resolves +name+ to a {Place}.
  #
  # @param name [String] free-text place name (e.g. "Madrid").
  # @return [Place] label + coordinates of the best match.
  # @raise [LocationNotFoundError] when nothing matches.
  # @raise [WeatherApiError] when the upstream request fails.
  # @complexity O(1) time, O(1) space — single lookup, first match.
  def call(name)
    match = @client.geocode(name)
    raise LocationNotFoundError, "No location found for #{name.inspect}" if match.nil?

    Place.new(
      label: build_label(match),
      latitude: match["latitude"],
      longitude: match["longitude"]
    )
  end

  private

  # Joins name + admin1 + country, dropping blanks. e.g. "Madrid, Madrid, Spain".
  # @complexity O(1) time, O(1) space — fixed number of segments.
  def build_label(match)
    [match["name"], match["admin1"], match["country"]]
      .map { |segment| segment.to_s.strip }
      .reject(&:empty?)
      .join(", ")
  end
end
