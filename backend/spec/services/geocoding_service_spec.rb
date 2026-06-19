require "rails_helper"

RSpec.describe GeocodingService do
  let(:client) { instance_double(OpenMeteoClient) }
  subject(:service) { described_class.new(client: client) }

  it "returns a Place with the name, coordinates and human label" do
    allow(client).to receive(:geocode).with("Madrid").and_return(
      "name" => "Madrid", "latitude" => 40.41, "longitude" => -3.70,
      "country" => "Spain", "admin1" => "Madrid"
    )

    place = service.call("Madrid")

    expect(place.latitude).to eq(40.41)
    expect(place.longitude).to eq(-3.70)
    expect(place.label).to eq("Madrid, Madrid, Spain")
  end

  it "omits blank admin/country segments from the label" do
    allow(client).to receive(:geocode).and_return(
      "name" => "Atlantis", "latitude" => 0.0, "longitude" => 0.0
    )

    expect(service.call("Atlantis").label).to eq("Atlantis")
  end

  it "raises LocationNotFoundError when the client finds nothing" do
    allow(client).to receive(:geocode).and_return(nil)

    expect { service.call("Nowhereville") }
      .to raise_error(GeocodingService::LocationNotFoundError)
  end
end
