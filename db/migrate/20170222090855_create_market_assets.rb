class CreateMarketAssets < ActiveRecord::Migration[5.0]
  def change
    create_table :market_assets do |t|
      t.string :amount
      t.string :app_icon
      t.integer :appid
      t.string :background_color
      t.string :classid
      t.integer :commodity
      t.string :contextid
      t.integer :currency
      t.json :descriptions
      t.string :icon_url
      t.string :icon_url_large
      t.string :instance_id
      t.string :market_hash_name
      t.string :market_marketable_restriction
      t.string :market_name
      t.string :market_tradable_restriction
      t.integer :marketable
      t.string :name
      t.string :original_amount
      t.integer :owner
      t.json :owner_actions
      t.integer :status
      t.integer :tradable
      t.string :type
      t.integer :item_nameid
      t.timestamps
    end
    change_column :market_assets, :id, :bigint
    add_index :market_assets, :classid
    add_index :market_assets, :item_nameid
  end
end
