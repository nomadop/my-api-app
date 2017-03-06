class AddMarketFeeToMarketAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :market_assets, :market_fee, :string
  end
end
