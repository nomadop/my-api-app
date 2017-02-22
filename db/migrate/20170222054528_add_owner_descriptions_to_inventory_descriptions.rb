class AddOwnerDescriptionsToInventoryDescriptions < ActiveRecord::Migration[5.0]
  def change
    add_column :inventory_descriptions, :owner_descriptions, :json
  end
end
