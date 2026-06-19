require "rails_helper"

RSpec.describe WeatherFetcherService do
  let(:client) { instance_double(OpenMeteoClient) }
  subject(:service) { described_class.new(client: client) }

  around do |example|
    cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
    Rails.cache = cache
  end

  it "returns the raw forecast hash for coordinates" do
    expect(client).to receive(:forecast)
      .with(latitude: 40.41, longitude: -3.70)
      .and_return("current" => { "temperature_2m" => 18.4 })

    result = service.call(latitude: 40.41, longitude: -3.70)

    expect(result.dig("current", "temperature_2m")).to eq(18.4)
  end

  it "caches by coordinate so the client is hit only once" do
    allow(client).to receive(:forecast).once
      .and_return("current" => { "temperature_2m" => 18.4 })

    2.times { service.call(latitude: 40.41, longitude: -3.70) }

    expect(client).to have_received(:forecast).once
  end
end
