class CreateBoosterCreators < ActiveRecord::Migration[5.0]
  def change
    create_table :booster_creators do |t|
      t.integer :appid
      t.string :name
      t.integer :series
      t.integer :price

      t.timestamps
    end
    add_index :booster_creators, :appid, unique: true
  end
end
