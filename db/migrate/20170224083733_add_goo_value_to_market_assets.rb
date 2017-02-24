class AddGooValueToMarketAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :market_assets, :goo_value, :integer
  end
end
