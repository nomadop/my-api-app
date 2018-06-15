class LoadMarketAssetJob < ApplicationJob
  queue_as :market_asset

  def perform(url, market_hash_name = nil)
    Market.load_asset_by_url(url) if url
    Market.load_asset_by_hash_name(market_hash_name) if market_hash_name
  end

  rescue_from(
    RestClient::TooManyRequests, RestClient::Forbidden,
    TOR::NoAvailableInstance, TOR::InstanceNotAvailable,
  ) do
    retry_job
  end
end
