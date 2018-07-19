redis_config = Rails.configuration.redis

if redis_config
  host = redis_config['host']
  port = redis_config['port']
  database = redis_config['database']['sidekiq']
  url = "redis://#{host}:#{port}/#{database}"

  Sidekiq.configure_server { |config| config.redis = { url: url } }
  Sidekiq.configure_client { |config| config.redis = { url: url } }
end
