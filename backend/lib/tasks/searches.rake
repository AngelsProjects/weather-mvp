# frozen_string_literal: true

namespace :searches do
  desc "Purge search-history rows older than RETENTION_DAYS (default 30) — PII retention"
  task purge: :environment do
    days = Integer(ENV.fetch("RETENTION_DAYS", "30"))
    deleted = Search.purge_older_than(days.days.ago)
    Rails.logger.info("[searches:purge] deleted #{deleted} rows older than #{days} days")
    puts "Purged #{deleted} search rows older than #{days} days."
  end
end
