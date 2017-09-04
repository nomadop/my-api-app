class AddRollbackNewContextidToMarketAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :market_assets, :rollback_new_contextid, :string
  end
end
