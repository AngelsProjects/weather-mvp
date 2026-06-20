require "rails_helper"

RSpec.describe "GET /api/v1/weather", type: :request do
  let(:geocoding_body) do
    {
      results: [
        {
          name: "London",
          latitude: 51.5,
          longitude: -0.12,
          country: "United Kingdom",
          admin1: "England"
        }
      ]
    }.to_json
  end

  let(:forecast_body) do
    {
      current: {
        temperature_2m: 12.0,
        precipitation: 1.5,
        weather_code: 3
      }
    }.to_json
  end

  before do
    stub_request(:get, %r{geocoding-api\.open-meteo\.com/v1/search})
      .to_return(status: 200, body: geocoding_body, headers: { "Content-Type" => "application/json" })
    stub_request(:get, %r{api\.open-meteo\.com/v1/forecast})
      .to_return(status: 200, body: forecast_body, headers: { "Content-Type" => "application/json" })
  end

  # ── Happy path: ?location= ────────────────────────────────────────────────
  describe "happy path with ?location=" do
    before { get "/api/v1/weather", params: { location: "London" } }

    it "returns 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "returns all six contract keys" do
      body = JSON.parse(response.body)
      expect(body.keys).to match_array(%w[
        location latitude longitude temperature_celsius precipitation_mm condition
      ])
    end

    it "returns the geocoded location label" do
      expect(JSON.parse(response.body)["location"]).to eq("London, England, United Kingdom")
    end

    it "returns the correct latitude" do
      expect(JSON.parse(response.body)["latitude"]).to eq(51.5)
    end

    it "returns the correct temperature" do
      expect(JSON.parse(response.body)["temperature_celsius"]).to eq(12.0)
    end

    it "returns the correct precipitation" do
      expect(JSON.parse(response.body)["precipitation_mm"]).to eq(1.5)
    end

    it "returns the human-readable condition" do
      expect(JSON.parse(response.body)["condition"]).to eq("Overcast")
    end

    it "persists a Search record" do
      expect(Search.count).to eq(1)
      expect(Search.last.location).to eq("London, England, United Kingdom")
    end
  end

  # ── Happy path: direct lat/lon ────────────────────────────────────────────
  describe "happy path with ?lat=&lon=" do
    before { get "/api/v1/weather", params: { lat: 51.5, lon: -0.12 } }

    it "returns 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "does not call the geocoding API" do
      expect(WebMock).not_to have_requested(:get, %r{geocoding-api\.open-meteo\.com})
    end

    it "returns the numeric coordinates as the location label" do
      body = JSON.parse(response.body)
      expect(body["location"]).to eq("51.5, -0.12")
    end

    it "returns the correct latitude" do
      expect(JSON.parse(response.body)["latitude"]).to eq(51.5)
    end

    it "returns the correct temperature" do
      expect(JSON.parse(response.body)["temperature_celsius"]).to eq(12.0)
    end
  end

  # ── Error: missing params ─────────────────────────────────────────────────
  describe "missing location params" do
    before { get "/api/v1/weather" }

    it "returns 422 Unprocessable Content" do
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns a JSON error body" do
      body = JSON.parse(response.body)
      expect(body).to have_key("error")
      expect(body["error"]).to be_a(String)
      expect(body["error"]).not_to be_empty
    end
  end

  # ── Error: location not found ─────────────────────────────────────────────
  describe "location not found" do
    before do
      stub_request(:get, %r{geocoding-api\.open-meteo\.com/v1/search})
        .to_return(
          status: 200,
          body: { generationtime_ms: 0.05 }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      get "/api/v1/weather", params: { location: "Nowhereville" }
    end

    it "returns 422 Unprocessable Content" do
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns a JSON error body mentioning the query" do
      body = JSON.parse(response.body)
      expect(body["error"]).to include("Nowhereville")
    end

    it "does not persist a Search record" do
      expect(Search.count).to eq(0)
    end
  end

  # ── Error: upstream forecast API failure ──────────────────────────────────
  describe "upstream forecast API failure" do
    before do
      stub_request(:get, %r{api\.open-meteo\.com/v1/forecast})
        .to_return(status: 500, body: "internal server error")
      get "/api/v1/weather", params: { location: "London" }
    end

    it "returns 502 Bad Gateway" do
      expect(response).to have_http_status(:bad_gateway)
    end

    it "returns a JSON error body" do
      body = JSON.parse(response.body)
      expect(body).to have_key("error")
      expect(body["error"]).to be_a(String)
    end

    it "does not persist a Search record" do
      expect(Search.count).to eq(0)
    end
  end

  # ── Error: upstream geocoding API failure ─────────────────────────────────
  describe "upstream geocoding API failure" do
    before do
      stub_request(:get, %r{geocoding-api\.open-meteo\.com/v1/search})
        .to_return(status: 502, body: "bad gateway")
      get "/api/v1/weather", params: { location: "London" }
    end

    it "returns 502 Bad Gateway" do
      expect(response).to have_http_status(:bad_gateway)
    end

    it "returns a JSON error body" do
      body = JSON.parse(response.body)
      expect(body).to have_key("error")
    end
  end
end
