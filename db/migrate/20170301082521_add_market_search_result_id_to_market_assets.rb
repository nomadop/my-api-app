class AddMarketSearchResultIdToMarketAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :market_assets, :market_search_result_id, :integer
    add_index :market_assets, :market_search_result_id
  end
end
