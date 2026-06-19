require "rails_helper"

RSpec.describe OpenMeteoClient do
  subject(:client) { described_class.new }

  describe "#geocode" do
    it "returns the first geocoding match" do
      stub_request(:get, %r{geocoding-api\.open-meteo\.com/v1/search})
        .with(query: hash_including("name" => "Madrid", "count" => "1"))
        .to_return(
          status: 200,
          body: {
            results: [
              { name: "Madrid", latitude: 40.41, longitude: -3.70, country: "Spain", admin1: "Madrid" }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.geocode("Madrid")

      expect(result["name"]).to eq("Madrid")
      expect(result["latitude"]).to eq(40.41)
      expect(result["longitude"]).to eq(-3.70)
    end

    it "returns nil when there are no matches" do
      stub_request(:get, %r{geocoding-api\.open-meteo\.com/v1/search})
        .to_return(
          status: 200,
          body: { generationtime_ms: 0.1 }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect(client.geocode("Nowhereville")).to be_nil
    end

    it "raises WeatherApiError on a non-2xx response" do
      stub_request(:get, %r{geocoding-api\.open-meteo\.com/v1/search})
        .to_return(status: 500, body: "boom")

      expect { client.geocode("Madrid") }.to raise_error(WeatherApiError)
    end

    it "raises WeatherApiError on a timeout" do
      stub_request(:get, %r{geocoding-api\.open-meteo\.com/v1/search}).to_timeout

      expect { client.geocode("Madrid") }.to raise_error(WeatherApiError)
    end
  end

  describe "#forecast" do
    it "returns the parsed current-weather payload" do
      stub_request(:get, %r{api\.open-meteo\.com/v1/forecast})
        .with(query: hash_including("latitude" => "40.41", "longitude" => "-3.7"))
        .to_return(
          status: 200,
          body: {
            current: { temperature_2m: 18.4, precipitation: 0.2, weather_code: 61 }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.forecast(latitude: 40.41, longitude: -3.7)

      expect(result.dig("current", "temperature_2m")).to eq(18.4)
    end

    it "raises WeatherApiError on a non-2xx response" do
      stub_request(:get, %r{api\.open-meteo\.com/v1/forecast})
        .to_return(status: 502, body: "bad gateway")

      expect { client.forecast(latitude: 1.0, longitude: 2.0) }.to raise_error(WeatherApiError)
    end

    it "raises WeatherApiError on a timeout" do
      stub_request(:get, %r{api\.open-meteo\.com/v1/forecast}).to_timeout

      expect { client.forecast(latitude: 1.0, longitude: 2.0) }.to raise_error(WeatherApiError)
    end
  end
end
