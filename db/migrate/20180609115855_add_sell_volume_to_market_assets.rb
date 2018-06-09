class AddSellVolumeToMarketAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :market_assets, :sell_volume, :integer, default: 0
  end
end
