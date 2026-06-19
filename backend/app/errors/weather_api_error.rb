# frozen_string_literal: true

# Raised when an upstream weather/geocoding request fails (timeout or non-2xx).
# Lets controllers rescue a single domain error instead of Faraday internals.
class WeatherApiError < StandardError; end
