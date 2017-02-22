class CreateInventoryDescriptions < ActiveRecord::Migration[5.0]
  def change

    create_table :inventory_descriptions do |t|
      t.json :actions
      t.integer :appid
      t.string :background_color
      t.string :classid
      t.integer :commodity
      t.integer :currency
      t.json :descriptions
      t.string :icon_url
      t.string :icon_url_large
      t.string :instanceid
      t.string :market_hash_name
      t.integer :market_marketable_restriction
      t.string :market_name
      t.integer :market_tradable_restriction
      t.integer :marketable
      t.string :name
      t.json :owner_actions
      t.json :tags
      t.integer :tradable
      t.string :type
      t.timestamps
    end
    add_index :inventory_descriptions, :appid
    add_index :inventory_descriptions, [:classid, :instanceid]
  end
end
