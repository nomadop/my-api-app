class OrderHistogram < ApplicationRecord
  belongs_to :market_asset, primary_key: :item_nameid, foreign_key: :item_nameid
end
