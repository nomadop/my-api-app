class AddItemExpirationToMarketAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :market_assets, :item_expiration, :json
  end
end
