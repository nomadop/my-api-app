class AddMarketActionsToMarketAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :market_assets, :market_actions, :json
  end
end
