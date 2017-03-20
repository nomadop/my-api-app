class ChangeColumnsOfMarketAssets < ActiveRecord::Migration[5.0]
  def up
    change_column :market_assets, :descriptions, :jsonb, using: 'CAST(descriptions AS jsonb)'
    change_column :market_assets, :owner_actions, :jsonb, using: 'CAST(owner_actions AS jsonb)'
    change_column :market_assets, :actions, :jsonb, using: 'CAST(actions AS jsonb)'
    change_column :market_assets, :market_actions, :jsonb, using: 'CAST(market_actions AS jsonb)'
    change_column :market_assets, :tags, :jsonb, using: 'CAST(tags AS jsonb)'
    change_column :market_assets, :item_expiration, :jsonb, using: 'CAST(item_expiration AS jsonb)'
  end

  def down
    change_column :market_assets, :descriptions, :json, using: 'CAST(descriptions AS json)'
    change_column :market_assets, :owner_actions, :json, using: 'CAST(owner_actions AS json)'
    change_column :market_assets, :actions, :json, using: 'CAST(actions AS json)'
    change_column :market_assets, :market_actions, :json, using: 'CAST(market_actions AS json)'
    change_column :market_assets, :tags, :json, using: 'CAST(tags AS json)'
    change_column :market_assets, :item_expiration, :json, using: 'CAST(item_expiration AS json)'
  end
end
