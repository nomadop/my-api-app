class ChangeIndexOfInventoryDescriptions < ActiveRecord::Migration[5.0]
  def up
    remove_index :inventory_descriptions, [:classid, :instanceid]
    add_index :inventory_descriptions, [:classid, :instanceid], unique: true
  end

  def down
    remove_index :inventory_descriptions, [:classid, :instanceid]
    add_index :inventory_descriptions, [:classid, :instanceid]
  end
end
