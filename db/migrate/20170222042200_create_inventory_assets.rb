class CreateInventoryAssets < ActiveRecord::Migration[5.0]
  def change
    create_table :inventory_assets do |t|
      t.string :appid
      t.string :amount
      t.string :assetid
      t.string :classid
      t.string :contextid
      t.string :instanceid
      t.timestamps
    end
    add_index :inventory_assets, :assetid, unique: true
  end
end
