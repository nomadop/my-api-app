class CreateBoosterCreations < ActiveRecord::Migration[5.0]
  def change
    create_table :booster_creations do |t|
      t.integer :account_id, null: false
      t.integer :booster_creator_id, null: false
      t.string :communityitemid
      t.integer :appid
      t.integer :item_type
      t.string :purchaseid
      t.integer :success
      t.integer :rwgrsn

      t.timestamps
    end
    add_index :booster_creations, :booster_creator_id
  end
end
