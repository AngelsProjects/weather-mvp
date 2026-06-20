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

    it "is invalid when latitude is out of the WGS84 range" do
      search.latitude = 91
      expect(search).not_to be_valid
      expect(search.errors[:latitude]).to be_present
    end

    it "is invalid when longitude is out of the WGS84 range" do
      search.longitude = -181
      expect(search).not_to be_valid
      expect(search.errors[:longitude]).to be_present
    end

    it "accepts the boundary coordinates" do
      search.latitude = -90
      search.longitude = 180
      expect(search).to be_valid
    end
  end

  # ── PII handling ───────────────────────────────────────────────────────────
  describe "PII handling" do
    it "encrypts the location at rest" do
      search.save!
      raw = Search.connection.select_value(
        "SELECT location FROM searches WHERE id = #{search.id}"
      )
      expect(raw).not_to include("London")
    end

    it "exposes the decrypted location through the attribute" do
      search.save!
      expect(search.reload.location).to eq("London, England, United Kingdom")
    end

    it "rounds stored coordinates to two decimals before saving" do
      search.latitude = 51.508530
      search.longitude = -0.125700
      search.save!
      expect(search.reload.latitude).to eq(BigDecimal("51.51"))
      expect(search.reload.longitude).to eq(BigDecimal("-0.13"))
    end
  end

  # ── Persistence ────────────────────────────────────────────────────────────
  describe "persistence" do
    it "stores latitude rounded to two decimals" do
      search.save!
      expect(search.reload.latitude).to eq(BigDecimal("51.51"))
    end

    it "stores longitude rounded to two decimals" do
      search.save!
      expect(search.reload.longitude).to eq(BigDecimal("-0.13"))
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

  # ── Retention ──────────────────────────────────────────────────────────────
  describe ".purge_older_than" do
    it "deletes rows older than the cutoff and keeps newer ones" do
      old = described_class.create!(valid_attributes.merge(created_at: 40.days.ago))
      fresh = described_class.create!(valid_attributes.merge(created_at: 1.day.ago))

      described_class.purge_older_than(30.days.ago)

      expect(described_class.exists?(old.id)).to be(false)
      expect(described_class.exists?(fresh.id)).to be(true)
    end
  end
end
