# Be sure to restart your server when you modify this file.

# Origins are read from env so nothing host-specific is hardcoded.
# Development defaults to the Vite dev server; production MUST set CORS_ORIGINS
# explicitly and may never use a wildcard (this API is fronted by a browser app
# handling sensitive PII — a wildcard would let any site read responses).
origins_env = ENV.fetch("CORS_ORIGINS") do
  if Rails.env.production?
    raise "CORS_ORIGINS must be set in production (no default, no wildcard)."
  else
    "http://localhost:5173"
  end
end

allowed_origins = origins_env.split(",").map(&:strip).reject(&:empty?)

if Rails.env.production? && allowed_origins.include?("*")
  raise "CORS_ORIGINS may not contain '*' in production."
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "*",
      headers: :any,
      methods: %i[get options head]
  end
end
