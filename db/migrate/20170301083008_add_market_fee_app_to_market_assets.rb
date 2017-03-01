class AddMarketFeeAppToMarketAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :market_assets, :market_fee_app, :integer
  end
end
