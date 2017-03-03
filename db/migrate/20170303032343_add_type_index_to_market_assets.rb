class AddTypeIndexToMarketAssets < ActiveRecord::Migration[5.0]
  def change
    add_index :market_assets, :type
  end
end
