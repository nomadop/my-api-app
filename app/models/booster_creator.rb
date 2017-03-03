class BoosterCreator < ApplicationRecord
  def scan_market
    Market.scan(name)
  end
end
