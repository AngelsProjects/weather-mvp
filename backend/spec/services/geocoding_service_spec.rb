require "rails_helper"

RSpec.describe GeocodingService do
  let(:client) { instance_double(OpenMeteoClient) }

  subject(:service) { described_class.new(client: client) }

  describe "#call" do
    context "when the client returns a full result" do
      before do
        allow(client).to receive(:geocode).with("Madrid").and_return(
          "name" => "Madrid",
          "latitude" => 40.41,
          "longitude" => -3.70,
          "country" => "Spain",
          "admin1" => "Community of Madrid"
        )
      end

      it "returns a Place struct" do
        expect(service.call("Madrid")).to be_a(GeocodingService::Place)
      end

      it "sets latitude from the match" do
        expect(service.call("Madrid").latitude).to eq(40.41)
      end

      it "sets longitude from the match" do
        expect(service.call("Madrid").longitude).to eq(-3.70)
      end

      it "builds a full label: name, admin1, country" do
        expect(service.call("Madrid").label).to eq("Madrid, Community of Madrid, Spain")
      end
    end

    context "when admin1 and country are missing" do
      before do
        allow(client).to receive(:geocode).and_return(
          "name" => "Atlantis", "latitude" => 0.0, "longitude" => 0.0
        )
      end

      it "omits blank segments from the label" do
        expect(service.call("Atlantis").label).to eq("Atlantis")
      end
    end

    context "when only country is present (no admin1)" do
      before do
        allow(client).to receive(:geocode).and_return(
          "name" => "Vatican City", "latitude" => 41.90, "longitude" => 12.45,
          "country" => "Vatican City"
        )
      end

      it "includes name and country but skips the blank admin1 segment" do
        expect(service.call("Vatican City").label).to eq("Vatican City, Vatican City")
      end
    end

    context "when admin1 is an empty string" do
      before do
        allow(client).to receive(:geocode).and_return(
          "name" => "Somewhere", "latitude" => 1.0, "longitude" => 2.0,
          "admin1" => "   ", "country" => "Testland"
        )
      end

      it "strips and omits whitespace-only admin1" do
        expect(service.call("Somewhere").label).to eq("Somewhere, Testland")
      end
    end

    context "when the client returns nil (no results)" do
      before do
        allow(client).to receive(:geocode).and_return(nil)
      end

      it "raises LocationNotFoundError" do
        expect { service.call("Nowhereville") }
          .to raise_error(GeocodingService::LocationNotFoundError)
      end

      it "includes the query in the error message" do
        expect { service.call("Nowhereville") }
          .to raise_error(GeocodingService::LocationNotFoundError, /Nowhereville/)
      end
    end

    context "when the client raises WeatherApiError" do
      before do
        allow(client).to receive(:geocode).and_raise(WeatherApiError, "timeout")
      end

      it "propagates WeatherApiError without wrapping" do
        expect { service.call("Madrid") }.to raise_error(WeatherApiError, "timeout")
      end
    end
  end
end
