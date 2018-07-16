class LoadMarketAssetJob < ApplicationJob
  queue_as :market_asset
  rescue_from RestClient::TooManyRequests, with: :retry_now
  rescue_from RestClient::Forbidden, with: :retry_now
  rescue_from TOR::NoAvailableInstance, with: :retry_now
  rescue_from TOR::InstanceNotAvailable, with: :retry_now

  def perform(url, market_hash_name = nil)
    market_hash_name.nil? ?
      Market.load_asset_by_url(url) :
      Market.load_asset_by_hash_name(market_hash_name)
  end

  def retry_now
    retry_job
  end
end
