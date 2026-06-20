# frozen_string_literal: true

# Records each successful weather lookup for observability / history.
#
# This table holds sensitive PII: a record of which places a user looked up.
# Three protections apply:
#   * +location+ is encrypted at rest (Active Record Encryption).
#   * coordinates are rounded to ~1km before persistence (no pinpoint homes).
#   * old rows are purged on a retention schedule (see +purge_older_than+).
class Search < ApplicationRecord
  COORDINATE_PRECISION = 2

  encrypts :location

  validates :location, :latitude, :longitude, presence: true
  validates :latitude,
            numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 },
            allow_nil: true
  validates :longitude,
            numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 },
            allow_nil: true

  before_validation :round_coordinates

  # Returns the N most-recent searches (default 10).
  # @param limit [Integer]
  # @return [ActiveRecord::Relation]
  scope :recent, ->(limit = 10) { order(created_at: :desc).limit(limit) }

  # Deletes every row created before +cutoff+. Used by the retention task.
  # @param cutoff [ActiveSupport::TimeWithZone, Time]
  # @return [Integer] number of rows deleted.
  def self.purge_older_than(cutoff)
    where(created_at: ...cutoff).delete_all
  end

  private

  # Rounds coordinates to COORDINATE_PRECISION decimals so we never store a
  # pinpoint location. ~2dp ≈ 1.1km.
  def round_coordinates
    self.latitude = latitude.to_d.round(COORDINATE_PRECISION) if latitude.present?
    self.longitude = longitude.to_d.round(COORDINATE_PRECISION) if longitude.present?
  end
end
