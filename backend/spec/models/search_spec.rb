require "rails_helper"

RSpec.describe Search, type: :model do
  # ── Factory helpers ────────────────────────────────────────────────────────
  let(:valid_attributes) do
    { location: "London, England, United Kingdom", latitude: 51.5085, longitude: -0.1257 }
  end

  subject(:search) { described_class.new(valid_attributes) }

  # ── Validations ────────────────────────────────────────────────────────────
  describe "validations" do
    it "is valid with location, latitude, and longitude" do
      expect(search).to be_valid
    end

    it "is invalid without a location" do
      search.location = nil
      expect(search).not_to be_valid
      expect(search.errors[:location]).to include("can't be blank")
    end

    it "is invalid without a latitude" do
      search.latitude = nil
      expect(search).not_to be_valid
      expect(search.errors[:latitude]).to include("can't be blank")
    end

    it "is invalid without a longitude" do
      search.longitude = nil
      expect(search).not_to be_valid
      expect(search.errors[:longitude]).to include("can't be blank")
    end
  end

  # ── Persistence ────────────────────────────────────────────────────────────
  describe "persistence" do
    it "stores decimal latitude with precision" do
      search.save!
      expect(search.reload.latitude).to eq(BigDecimal("51.5085"))
    end

    it "stores decimal longitude with precision" do
      search.save!
      expect(search.reload.longitude).to eq(BigDecimal("-0.1257"))
    end

    it "records a created_at timestamp on save" do
      search.save!
      expect(search.created_at).not_to be_nil
    end
  end

  # ── Scopes ─────────────────────────────────────────────────────────────────
  describe ".recent" do
    before do
      # Insert four records with distinct timestamps.
      4.times do |i|
        described_class.create!(
          valid_attributes.merge(location: "Place #{i}",
                                 created_at: i.hours.ago)
        )
      end
    end

    it "returns the N most-recent records" do
      expect(described_class.recent(2).count).to eq(2)
    end

    it "orders newest first" do
      results = described_class.recent(4)
      expect(results.map(&:location)).to eq(["Place 0", "Place 1", "Place 2", "Place 3"])
    end

    it "defaults to 10 results" do
      # Only 4 rows exist; all should come back.
      expect(described_class.recent.count).to eq(4)
    end

    it "returns an ActiveRecord::Relation (chainable)" do
      expect(described_class.recent).to be_a(ActiveRecord::Relation)
    end
  end
end
