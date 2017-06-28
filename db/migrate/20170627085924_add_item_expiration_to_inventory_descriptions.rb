class AddItemExpirationToInventoryDescriptions < ActiveRecord::Migration[5.0]
  def change
    add_column :inventory_descriptions, :item_expiration, :string
  end
end
