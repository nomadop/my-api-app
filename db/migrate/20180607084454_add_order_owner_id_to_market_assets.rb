class AddOrderOwnerIdToMarketAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :market_assets, :order_owner_id, :integer
    add_index :market_assets, :order_owner_id
  end
end
