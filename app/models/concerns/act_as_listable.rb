module ActAsListable
  extend ActiveSupport::Concern

  def listing_url
    Market.get_url(market_hash_name)
  end
end