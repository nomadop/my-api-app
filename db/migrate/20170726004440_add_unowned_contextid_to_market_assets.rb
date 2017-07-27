class AddUnownedContextidToMarketAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :market_assets, :unowned_contextid, :string
  end
end
