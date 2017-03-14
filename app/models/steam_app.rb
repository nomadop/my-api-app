class SteamApp < ApplicationRecord
  self.inheritance_column = nil

  has_many :market_assets, primary_key: :steam_appid, foreign_key: :market_fee_app

  scope :with_trading_cards, -> { where('categories @> ?', [{id: 29}].to_json) }
  scope :with_market_assets, -> { joins(:market_assets).distinct }
  scope :without_market_assets, -> { left_outer_joins(:market_assets).where(market_assets: {market_fee_app: nil}) }

  def scan_market
    Market.scan(steam_appid)
  end
end
