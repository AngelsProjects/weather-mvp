# Be sure to restart your server when you modify this file.

# Allow the Vite dev server to call the API in development.
# Origins are read from env so nothing host-specific is hardcoded.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("CORS_ORIGINS", "http://localhost:5173").split(",")

    resource "*",
      headers: :any,
      methods: %i[get options head]
  end
end
