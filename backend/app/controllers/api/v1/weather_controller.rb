# frozen_string_literal: true

module Api
  module V1
    # Thin controller: validate params, delegate to services, render.
    # No business logic lives here. Accepts ?location= OR ?lat=&lon=.
    class WeatherController < ApplicationController
      LATITUDE_RANGE  = (-90.0..90.0)
      LONGITUDE_RANGE = (-180.0..180.0)
      MAX_LOCATION_LENGTH = 200

      # Client-facing message for upstream failures. The real cause is logged
      # server-side; we never leak the provider name or HTTP status to callers.
      UPSTREAM_ERROR_MESSAGE = "The weather service is temporarily unavailable. Please try again."

      def show
        place = resolve_place
        forecast = weather_fetcher_service.call(latitude: place.latitude, longitude: place.longitude)

        search_recorder.record(place)

        render json: WeatherSerializer.new(
          forecast: forecast,
          location: place.label,
          latitude: place.latitude,
          longitude: place.longitude
        )
      rescue ActionController::ParameterMissing, InvalidParamsError => e
        render json: { error: e.message }, status: :unprocessable_content
      rescue GeocodingService::LocationNotFoundError => e
        render json: { error: e.message }, status: :unprocessable_content
      rescue WeatherApiError => e
        Rails.logger.error("[WeatherController] upstream failure: #{e.message}")
        render json: { error: UPSTREAM_ERROR_MESSAGE }, status: :bad_gateway
      end

      private

      # Raised for malformed user input (out-of-range coords, over-long query).
      class InvalidParamsError < StandardError; end

      # Resolves a GeocodingService::Place from whichever params are present.
      # Validates input *before* any upstream call.
      def resolve_place
        if params[:location].present?
          resolve_by_location(params[:location])
        elsif params[:lat].present? && params[:lon].present?
          resolve_by_coords(params[:lat], params[:lon])
        else
          raise ActionController::ParameterMissing, "location or lat/lon required"
        end
      end

      def resolve_by_location(location)
        if location.length > MAX_LOCATION_LENGTH
          raise InvalidParamsError, "location is too long (max #{MAX_LOCATION_LENGTH} characters)"
        end

        geocoding_service.call(location)
      end

      def resolve_by_coords(raw_lat, raw_lon)
        lat = parse_coordinate(raw_lat, "latitude")
        lon = parse_coordinate(raw_lon, "longitude")

        raise InvalidParamsError, "latitude must be between -90 and 90" unless LATITUDE_RANGE.cover?(lat)
        raise InvalidParamsError, "longitude must be between -180 and 180" unless LONGITUDE_RANGE.cover?(lon)

        GeocodingService::Place.new(label: "#{lat}, #{lon}", latitude: lat, longitude: lon)
      end

      # Strict numeric parse — "foo".to_f silently returns 0.0, which would
      # become a valid-looking coordinate. Float() raises instead.
      def parse_coordinate(value, name)
        Float(value)
      rescue ArgumentError, TypeError
        raise InvalidParamsError, "#{name} must be a number"
      end

      def geocoding_service
        @geocoding_service ||= GeocodingService.new
      end

      def weather_fetcher_service
        @weather_fetcher_service ||= WeatherFetcherService.new
      end

      def search_recorder
        @search_recorder ||= SearchRecorder.new
      end
    end
  end
end
