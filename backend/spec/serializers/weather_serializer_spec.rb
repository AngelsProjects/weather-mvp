require "rails_helper"

RSpec.describe WeatherSerializer do
  let(:base_forecast) do
    {
      "current" => {
        "temperature_2m" => 18.4,
        "precipitation"  => 0.2,
        "weather_code"   => 61
      }
    }
  end

  let(:location)  { "Madrid, Community of Madrid, Spain" }
  let(:latitude)  { 40.41 }
  let(:longitude) { -3.70 }

  subject(:serializer) do
    described_class.new(
      forecast:  base_forecast,
      location:  location,
      latitude:  latitude,
      longitude: longitude
    )
  end

  describe "#as_json" do
    it "returns all six contract keys" do
      expect(serializer.as_json.keys).to match_array(
        %i[location latitude longitude temperature_celsius precipitation_mm condition]
      )
    end

    it "maps temperature_2m to temperature_celsius" do
      expect(serializer.as_json[:temperature_celsius]).to eq(18.4)
    end

    it "maps precipitation to precipitation_mm" do
      expect(serializer.as_json[:precipitation_mm]).to eq(0.2)
    end

    it "resolves weather_code 61 to 'Slight rain'" do
      expect(serializer.as_json[:condition]).to eq("Slight rain")
    end

    it "passes through the location label unchanged" do
      expect(serializer.as_json[:location]).to eq(location)
    end

    it "coerces latitude to Float" do
      serializer = described_class.new(
        forecast: base_forecast, location: location,
        latitude: "40.41", longitude: longitude
      )
      expect(serializer.as_json[:latitude]).to eq(40.41)
    end

    it "coerces longitude to Float" do
      serializer = described_class.new(
        forecast: base_forecast, location: location,
        latitude: latitude, longitude: "-3.70"
      )
      expect(serializer.as_json[:longitude]).to eq(-3.70)
    end

    context "with known weather codes" do
      {
        0 => "Clear sky",
        3 => "Overcast",
        45 => "Fog",
        63 => "Moderate rain",
        80 => "Rain showers",
        95 => "Thunderstorm"
      }.each do |code, expected_condition|
        it "maps weather_code #{code} to '#{expected_condition}'" do
          forecast = { "current" => base_forecast["current"].merge("weather_code" => code) }
          result = described_class.new(
            forecast: forecast, location: location, latitude: latitude, longitude: longitude
          ).as_json

          expect(result[:condition]).to eq(expected_condition)
        end
      end
    end

    context "with an unknown weather code" do
      it "returns 'Unknown' for an unrecognised code" do
        forecast = { "current" => base_forecast["current"].merge("weather_code" => 999) }
        result = described_class.new(
          forecast: forecast, location: location, latitude: latitude, longitude: longitude
        ).as_json

        expect(result[:condition]).to eq("Unknown")
      end
    end

    context "when precipitation is zero" do
      it "returns 0.0, not nil" do
        forecast = { "current" => base_forecast["current"].merge("precipitation" => 0) }
        result = described_class.new(
          forecast: forecast, location: location, latitude: latitude, longitude: longitude
        ).as_json

        expect(result[:precipitation_mm]).to eq(0.0)
      end
    end
  end
end
