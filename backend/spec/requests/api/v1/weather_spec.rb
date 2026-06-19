require "rails_helper"

RSpec.describe "GET /api/v1/weather", type: :request do
  let(:open_meteo_body) do
    {
      current: {
        temperature_2m: 12.0,
        precipitation: 1.5,
        weather_code: 3
      }
    }.to_json
  end

  before do
    stub_request(:get, %r{api\.open-meteo\.com/v1/forecast})
      .to_return(status: 200, body: open_meteo_body, headers: { "Content-Type" => "application/json" })
  end

  it "returns the weather contract" do
    get "/api/v1/weather", params: { latitude: 51.5, longitude: -0.12 }

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)

    expect(body.keys).to match_array(%w[
      location latitude longitude temperature_celsius precipitation_mm condition
    ])
    expect(body["temperature_celsius"]).to eq(12.0)
    expect(body["precipitation_mm"]).to eq(1.5)
    expect(body["condition"]).to eq("Overcast")
  end

  it "rejects missing coordinates" do
    get "/api/v1/weather", params: { latitude: 51.5 }

    expect(response).to have_http_status(:bad_request)
  end
end
