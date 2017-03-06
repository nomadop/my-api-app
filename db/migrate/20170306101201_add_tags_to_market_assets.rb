class AddTagsToMarketAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :market_assets, :tags, :json
  end
end
