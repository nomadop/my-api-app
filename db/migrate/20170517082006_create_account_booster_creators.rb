class CreateAccountBoosterCreators < ActiveRecord::Migration[5.0]
  def change
    create_table :account_booster_creators do |t|
      t.integer :account_id
      t.integer :appid

      t.timestamps
    end
    add_index :account_booster_creators, [:account_id, :appid], unique: true
  end
end
