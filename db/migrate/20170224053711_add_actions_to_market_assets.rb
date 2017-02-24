class AddActionsToMarketAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :market_assets, :actions, :json
  end
end
