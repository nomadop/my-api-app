class CreateMyHistories < ActiveRecord::Migration[5.0]
  def change
    create_table :my_histories do |t|
      t.string :history_id
      t.string :who_acted_with
      t.integer :price
      t.string :classid
      t.string :market_hash_name

      t.timestamps
    end
    add_index :my_histories, :history_id, unique: true
    add_index :my_histories, :market_hash_name
  end
end
