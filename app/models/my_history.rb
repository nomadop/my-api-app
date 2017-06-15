class MyHistory < ApplicationRecord
  belongs_to :market_asset, primary_key: :market_hash_name, foreign_key: :market_hash_name
end
