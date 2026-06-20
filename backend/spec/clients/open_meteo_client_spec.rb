require "rails_helper"

RSpec.describe OpenMeteoClient do
  subject(:client) { described_class.new }

  describe "#geocode" do
    context "when the location is found" do
      before do
        stub_request(:get, %r{geocoding-api\.open-meteo\.com/v1/search})
          .with(query: hash_including("name" => "Madrid", "count" => "1", "language" => "en"))
          .to_return(
            status: 200,
            body: {
              results: [
                {
                  name: "Madrid",
                  latitude: 40.41,
                  longitude: -3.70,
                  country: "Spain",
                  admin1: "Community of Madrid"
                }
              ]
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns the first result hash" do
        result = client.geocode("Madrid")

        expect(result["name"]).to eq("Madrid")
        expect(result["latitude"]).to eq(40.41)
        expect(result["longitude"]).to eq(-3.70)
        expect(result["country"]).to eq("Spain")
        expect(result["admin1"]).to eq("Community of Madrid")
      end

      it "requests exactly one result" do
        client.geocode("Madrid")

        expect(WebMock).to have_requested(:get, %r{geocoding-api\.open-meteo\.com/v1/search})
          .with(query: hash_including("count" => "1"))
      end
    end

    context "when the location is not found" do
      before do
        stub_request(:get, %r{geocoding-api\.open-meteo\.com/v1/search})
          .to_return(
            status: 200,
            body: { generationtime_ms: 0.05 }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns nil (results key absent)" do
        expect(client.geocode("Xyzzy")).to be_nil
      end
    end

    context "when the results array is empty" do
      before do
        stub_request(:get, %r{geocoding-api\.open-meteo\.com/v1/search})
          .to_return(
            status: 200,
            body: { results: [] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns nil" do
        expect(client.geocode("Empty")).to be_nil
      end
    end

    context "when the upstream is unavailable" do
      it "raises WeatherApiError on a 5xx response" do
        stub_request(:get, %r{geocoding-api\.open-meteo\.com/v1/search})
          .to_return(status: 500, body: "internal server error")

        expect { client.geocode("Madrid") }.to raise_error(WeatherApiError, /500/)
      end

      it "raises WeatherApiError on a 4xx response" do
        stub_request(:get, %r{geocoding-api\.open-meteo\.com/v1/search})
          .to_return(status: 400, body: "bad request")

        expect { client.geocode("Madrid") }.to raise_error(WeatherApiError, /400/)
      end

      it "raises WeatherApiError on a network timeout" do
        stub_request(:get, %r{geocoding-api\.open-meteo\.com/v1/search}).to_timeout

        expect { client.geocode("Madrid") }.to raise_error(WeatherApiError, /failed/)
      end
    end
  end

  describe "#forecast" do
    context "when the request succeeds" do
      before do
        stub_request(:get, %r{api\.open-meteo\.com/v1/forecast})
          .with(query: hash_including(
            "latitude" => "40.41",
            "longitude" => "-3.7",
            "current" => "temperature_2m,precipitation,weather_code"
          ))
          .to_return(
            status: 200,
            body: {
              current: { temperature_2m: 18.4, precipitation: 0.2, weather_code: 61 }
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns the parsed forecast hash" do
        result = client.forecast(latitude: 40.41, longitude: -3.7)

        expect(result.dig("current", "temperature_2m")).to eq(18.4)
        expect(result.dig("current", "precipitation")).to eq(0.2)
        expect(result.dig("current", "weather_code")).to eq(61)
      end

      it "requests the expected weather variables" do
        client.forecast(latitude: 40.41, longitude: -3.7)

        expect(WebMock).to have_requested(:get, %r{api\.open-meteo\.com/v1/forecast})
          .with(query: hash_including("current" => "temperature_2m,precipitation,weather_code"))
      end
    end

    context "when the upstream is unavailable" do
      it "raises WeatherApiError on a 5xx response" do
        stub_request(:get, %r{api\.open-meteo\.com/v1/forecast})
          .to_return(status: 502, body: "bad gateway")

        expect { client.forecast(latitude: 1.0, longitude: 2.0) }.to raise_error(WeatherApiError, /502/)
      end

      it "raises WeatherApiError on a network timeout" do
        stub_request(:get, %r{api\.open-meteo\.com/v1/forecast}).to_timeout

        expect { client.forecast(latitude: 1.0, longitude: 2.0) }.to raise_error(WeatherApiError, /failed/)
      end
    end
  end
end
