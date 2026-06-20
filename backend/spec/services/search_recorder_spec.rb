require "rails_helper"

RSpec.describe SearchRecorder do
  subject(:recorder) { described_class.new }

  let(:place) do
    GeocodingService::Place.new(label: "London, England, United Kingdom", latitude: 51.5, longitude: -0.12)
  end

  describe "#record" do
    it "persists a Search row from the place" do
      expect { recorder.record(place) }.to change(Search, :count).by(1)
      expect(Search.last.location).to eq("London, England, United Kingdom")
    end

    it "swallows persistence errors so a logging failure can't break the request" do
      allow(Search).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Search.new))
      expect { recorder.record(place) }.not_to raise_error
    end

    it "logs when persistence fails" do
      allow(Search).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Search.new))
      expect(Rails.logger).to receive(:warn).with(/SearchRecorder/)
      recorder.record(place)
    end
  end
end
