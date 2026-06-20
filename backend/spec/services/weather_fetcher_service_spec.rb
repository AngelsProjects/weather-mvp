require "rails_helper"

RSpec.describe WeatherFetcherService do
  let(:client) { instance_double(OpenMeteoClient) }

  subject(:service) { described_class.new(client: client) }

  # Swap Rails.cache for an isolated in-memory store per example.
  around do |example|
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
    Rails.cache = original
  end

  describe "#call" do
    let(:raw_forecast) do
      {
        "current" => {
          "temperature_2m" => 18.4,
          "precipitation"  => 0.2,
          "weather_code"   => 61
        }
      }
    end

    context "when the client returns a forecast" do
      before do
        allow(client).to receive(:forecast)
          .with(latitude: 40.41, longitude: -3.70)
          .and_return(raw_forecast)
      end

      it "returns the raw forecast hash" do
        result = service.call(latitude: 40.41, longitude: -3.70)

        expect(result.dig("current", "temperature_2m")).to eq(18.4)
        expect(result.dig("current", "precipitation")).to eq(0.2)
        expect(result.dig("current", "weather_code")).to eq(61)
      end
    end

    context "caching behaviour" do
      before do
        allow(client).to receive(:forecast).and_return(raw_forecast)
      end

      it "only calls the client once for repeated identical coordinates" do
        2.times { service.call(latitude: 40.41, longitude: -3.70) }

        expect(client).to have_received(:forecast).once
      end

      it "calls the client again for different coordinates" do
        service.call(latitude: 40.41, longitude: -3.70)
        service.call(latitude: 51.50, longitude: -0.12)

        expect(client).to have_received(:forecast).twice
      end

      it "treats coordinates that round to the same value as the same cache key" do
        # 40.414 and 40.413 both round to 40.41 at 2 decimal places.
        service.call(latitude: 40.414, longitude: -3.704)
        service.call(latitude: 40.413, longitude: -3.703)

        expect(client).to have_received(:forecast).once
      end
    end

    context "when the client raises WeatherApiError" do
      before do
        allow(client).to receive(:forecast)
          .and_raise(WeatherApiError, "Open-Meteo request failed: timeout")
      end

      it "propagates WeatherApiError without wrapping" do
        expect { service.call(latitude: 40.41, longitude: -3.70) }
          .to raise_error(WeatherApiError, /timeout/)
      end

      it "does not cache the failed result" do
        # First call raises; second call should still hit the client (not a cached error).
        call_count = 0
        allow(client).to receive(:forecast) do
          call_count += 1
          raise WeatherApiError, "timeout" if call_count == 1
          raw_forecast
        end

        expect { service.call(latitude: 40.41, longitude: -3.70) }.to raise_error(WeatherApiError)
        result = service.call(latitude: 40.41, longitude: -3.70)
        expect(result).to eq(raw_forecast)
      end
    end
  end
end
