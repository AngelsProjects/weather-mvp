# frozen_string_literal: true

module Api
  module V1
    # Thin controller: validate params, delegate to services, render.
    # No business logic lives here. Accepts ?location= OR ?lat=&lon=.
    class WeatherController < ApplicationController
      def show
        place = resolve_place
        forecast = weather_fetcher_service.call(latitude: place.latitude, longitude: place.longitude)

        Search.create!(
          location: place.label,
          latitude: place.latitude,
          longitude: place.longitude
        )

        render json: WeatherSerializer.new(
          forecast: forecast,
          location: place.label,
          latitude: place.latitude,
          longitude: place.longitude
        )
      rescue ActionController::ParameterMissing => e
        render json: { error: e.message }, status: :unprocessable_content
      rescue GeocodingService::LocationNotFoundError => e
        render json: { error: e.message }, status: :unprocessable_content
      rescue WeatherApiError => e
        render json: { error: e.message }, status: :bad_gateway
      end

      private

      # Resolves a GeocodingService::Place from whichever params are present.
      # Raises ActionController::ParameterMissing when neither set is provided.
      def resolve_place
        if params[:location].present?
          geocoding_service.call(params[:location])
        elsif params[:lat].present? && params[:lon].present?
          GeocodingService::Place.new(
            label: "#{params[:lat]}, #{params[:lon]}",
            latitude: params[:lat].to_f,
            longitude: params[:lon].to_f
          )
        else
          raise ActionController::ParameterMissing, "location or lat/lon required"
        end
      end

      def geocoding_service
        @geocoding_service ||= GeocodingService.new
      end

      def weather_fetcher_service
        @weather_fetcher_service ||= WeatherFetcherService.new
      end
    end
  end
end
