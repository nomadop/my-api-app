class ChangeColumnInstanceIdOfMarketAssets < ActiveRecord::Migration[5.0]
  def change
    remove_column :market_assets, :instance_id
    add_column :market_assets, :instanceid, :string
  end
end
