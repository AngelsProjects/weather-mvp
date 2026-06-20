# frozen_string_literal: true

# Records each successful weather lookup for observability / history.
class Search < ApplicationRecord
  validates :location, :latitude, :longitude, presence: true

  # Returns the N most-recent searches (default 10).
  # @param limit [Integer]
  # @return [ActiveRecord::Relation]
  scope :recent, ->(limit = 10) { order(created_at: :desc).limit(limit) }
end
