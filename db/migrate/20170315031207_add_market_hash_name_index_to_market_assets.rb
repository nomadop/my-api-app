class AddMarketHashNameIndexToMarketAssets < ActiveRecord::Migration[5.0]
  def change
    add_index :market_assets, :market_hash_name
  end
end
