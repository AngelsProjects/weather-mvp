module Api
  module V1
    # Thin controller: validate params, delegate to the service, render.
    # No business logic lives here.
    class WeatherController < ApplicationController
      def show
        result = weather_service.current(
          latitude: params.require(:latitude),
          longitude: params.require(:longitude)
        )
        render json: WeatherSerializer.new(result)
      rescue ActionController::ParameterMissing => e
        render json: { error: e.message }, status: :bad_request
      rescue OpenMeteoClient::Error => e
        render json: { error: e.message }, status: :bad_gateway
      end

      private

      # Override point for tests / DI.
      def weather_service
        @weather_service ||= WeatherService.new
      end
    end
  end
end
