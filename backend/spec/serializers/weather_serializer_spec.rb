require "rails_helper"

RSpec.describe WeatherSerializer do
  let(:forecast) do
    {
      "current" => { "temperature_2m" => 18.4, "precipitation" => 0.2, "weather_code" => 61 }
    }
  end

  subject(:serializer) do
    described_class.new(
      forecast: forecast, location: "Madrid, Madrid, Spain", latitude: 40.41, longitude: -3.70
    )
  end

  it "maps raw forecast JSON into the contract shape" do
    expect(serializer.as_json).to eq(
      location: "Madrid, Madrid, Spain",
      latitude: 40.41,
      longitude: -3.70,
      temperature_celsius: 18.4,
      precipitation_mm: 0.2,
      condition: "Slight rain"
    )
  end
end
