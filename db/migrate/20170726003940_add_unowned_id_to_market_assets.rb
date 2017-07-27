class AddUnownedIdToMarketAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :market_assets, :unowned_id, :string
  end
end
