require "rails_helper"

RSpec.describe "GET /api/v1/weather", type: :request do
  let(:geocoding_body) do
    {
      results: [
        { name: "London", latitude: 51.5, longitude: -0.12, country: "United Kingdom", admin1: "England" }
      ]
    }.to_json
  end

  let(:forecast_body) do
    { current: { temperature_2m: 12.0, precipitation: 1.5, weather_code: 3 } }.to_json
  end

  before do
    stub_request(:get, %r{geocoding-api\.open-meteo\.com/v1/search})
      .to_return(status: 200, body: geocoding_body, headers: { "Content-Type" => "application/json" })
    stub_request(:get, %r{api\.open-meteo\.com/v1/forecast})
      .to_return(status: 200, body: forecast_body, headers: { "Content-Type" => "application/json" })
  end

  it "returns the weather contract for a place name" do
    get "/api/v1/weather", params: { location: "London" }

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)

    expect(body.keys).to match_array(%w[
      location latitude longitude temperature_celsius precipitation_mm condition
    ])
    expect(body["location"]).to eq("London, England, United Kingdom")
    expect(body["latitude"]).to eq(51.5)
    expect(body["temperature_celsius"]).to eq(12.0)
    expect(body["precipitation_mm"]).to eq(1.5)
    expect(body["condition"]).to eq("Overcast")
  end

  it "returns 422 when no location params are provided" do
    get "/api/v1/weather"

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "returns 422 when the location cannot be found" do
    stub_request(:get, %r{geocoding-api\.open-meteo\.com/v1/search})
      .to_return(status: 200, body: { generationtime_ms: 0.1 }.to_json,
                 headers: { "Content-Type" => "application/json" })

    get "/api/v1/weather", params: { location: "Nowhereville" }

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "returns 200 for direct lat/lon coords without geocoding" do
    stub_request(:get, %r{api\.open-meteo\.com/v1/forecast})
      .to_return(status: 200, body: forecast_body, headers: { "Content-Type" => "application/json" })

    get "/api/v1/weather", params: { lat: 51.5, lon: -0.12 }

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["latitude"]).to eq(51.5)
    expect(body["temperature_celsius"]).to eq(12.0)
  end

  it "returns 502 when the upstream weather API fails" do
    stub_request(:get, %r{api\.open-meteo\.com/v1/forecast}).to_return(status: 500)

    get "/api/v1/weather", params: { location: "London" }

    expect(response).to have_http_status(:bad_gateway)
  end
end
