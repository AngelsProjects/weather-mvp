module Api
  module V1
    # Thin controller: validate params, delegate to services, render.
    # No business logic lives here. Collaborators are memoized behind private
    # readers so tests can override them (DI).
    class WeatherController < ApplicationController
      def show
        place = geocoding_service.call(params.require(:location))
        forecast = weather_fetcher_service.call(latitude: place.latitude, longitude: place.longitude)

        render json: WeatherSerializer.new(
          forecast: forecast,
          location: place.label,
          latitude: place.latitude,
          longitude: place.longitude
        )
      rescue ActionController::ParameterMissing => e
        render json: { error: e.message }, status: :bad_request
      rescue GeocodingService::LocationNotFoundError => e
        render json: { error: e.message }, status: :not_found
      rescue WeatherApiError => e
        render json: { error: e.message }, status: :bad_gateway
      end

      private

      # Override points for tests / DI.
      def geocoding_service
        @geocoding_service ||= GeocodingService.new
      end

      def weather_fetcher_service
        @weather_fetcher_service ||= WeatherFetcherService.new
      end
    end
  end
end
