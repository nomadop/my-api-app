class ChangeItemNameidOfMarketAsset < ActiveRecord::Migration[5.0]
  def change
    change_column :market_assets, :item_nameid, :string, using: 'CAST(item_nameid AS text)'
  end
end
