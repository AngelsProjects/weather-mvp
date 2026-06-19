require "rails_helper"

RSpec.describe WeatherService do
  # Fake client injected in place of the real HTTP client (dependency injection).
  let(:client) do
    instance_double(
      OpenMeteoClient,
      current_weather: {
        "current" => {
          "temperature_2m" => 18.4,
          "precipitation" => 0.2,
          "weather_code" => 61
        }
      }
    )
  end

  subject(:service) { described_class.new(client: client) }

  it "maps the Open-Meteo response into the contract shape" do
    result = service.current(latitude: 40.4, longitude: -3.7)

    expect(result.latitude).to eq(40.4)
    expect(result.longitude).to eq(-3.7)
    expect(result.temperature_celsius).to eq(18.4)
    expect(result.precipitation_mm).to eq(0.2)
    expect(result.condition).to eq("Slight rain")
  end

  it "asks the client for the requested coordinates" do
    service.current(latitude: 1.0, longitude: 2.0)

    expect(client).to have_received(:current_weather).with(latitude: 1.0, longitude: 2.0)
  end
end
