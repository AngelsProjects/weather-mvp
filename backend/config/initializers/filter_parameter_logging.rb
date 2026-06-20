# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,
  # Location lookups are sensitive PII for our user base (immigration services):
  # the request params reveal where someone is or is asking about. Keep them out
  # of the logs.
  :location, :lat, :lon, :latitude, :longitude
]
