class AddAccountIdToInventoryAsset < ActiveRecord::Migration[5.0]
  def change
    add_column :inventory_assets, :account_id, :integer
  end
end
