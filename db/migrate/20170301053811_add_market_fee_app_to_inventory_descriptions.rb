class AddMarketFeeAppToInventoryDescriptions < ActiveRecord::Migration[5.0]
  def change
    add_column :inventory_descriptions, :market_fee_app, :integer
  end
end
