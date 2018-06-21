class GetGooValueJob < ApplicationJob
  queue_as :goo_value

  def perform(classid)
    market_asset = MarketAsset.find(classid)
    goo_value = market_asset.get_goo_value
    market_asset.update(goo_value: goo_value)
  end

  rescue_from(
    RestClient::TooManyRequests, RestClient::Forbidden,
    TOR::NoAvailableInstance, TOR::InstanceNotAvailable,
  ) do
    retry_job
  end
end
