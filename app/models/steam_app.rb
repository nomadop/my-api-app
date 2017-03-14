class SteamApp < ApplicationRecord
  self.inheritance_column = nil

  has_many :market_assets, primary_key: :steam_appid, foreign_key: :market_fee_app

  scope :with_market_assets, -> { find(joins(:market_assets).distinct.pluck(:id)) }
  scope :without_market_assets, -> { left_outer_joins(:market_assets).where(market_assets: {market_fee_app: nil}) }
end
