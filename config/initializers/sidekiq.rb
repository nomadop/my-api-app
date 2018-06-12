host = Rails.configuration.redis['host']
port = Rails.configuration.redis['port']
database = Rails.configuration.redis['database']['sidekiq']
url = "redis://#{host}:#{port}/#{database}"

Sidekiq.configure_server { |config| config.redis = { url: url } }
Sidekiq.configure_client { |config| config.redis = { url: url } }
