# frozen_string_literal: true

# Persists a resolved lookup to the searches table for history/observability.
#
# Recording is *best-effort*: a weather lookup that succeeded must still return
# 200 even if writing the audit row fails. So persistence errors are caught and
# logged, never propagated. Keeping this out of the controller keeps the
# controller thin (it parses params, calls services, renders) and keeps the
# searches-table schema knowledge in one place.
class SearchRecorder
  # @param place [GeocodingService::Place] the resolved place to record.
  # @return [Search, nil] the created record, or nil when persistence failed.
  def record(place)
    Search.create!(
      location: place.label,
      latitude: place.latitude,
      longitude: place.longitude
    )
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.warn("[SearchRecorder] failed to record search: #{e.class}")
    nil
  end
end
