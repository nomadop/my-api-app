class AddContainedItemToMarketAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :market_assets, :contained_item, :string
  end
end
