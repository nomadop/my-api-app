class LoadMarketAssetJob < ApplicationJob
  queue_as :market_asset

  def perform(url, market_hash_name = nil)
    market_hash_name ||= url.split('/').last
    Market.load_asset_by_hash_name(market_hash_name) if market_hash_name
  end

  rescue_from(
    RestClient::TooManyRequests, RestClient::Forbidden,
    TOR::NoAvailableInstance, TOR::InstanceNotAvailable,
  ) do
    retry_job
  end
end
