class CreateMarketSearchResults < ActiveRecord::Migration[5.0]
  def change
    create_table :market_search_results do |t|
      t.string :listing_url
      t.string :item_name
      t.string :game_name

      t.timestamps
    end
    add_index :market_search_results, :listing_url, unique: true
    add_index :market_search_results, :game_name
  end
end
