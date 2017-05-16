class CreateFriends < ActiveRecord::Migration[5.0]
  def change
    create_table :friends do |t|
      t.string :profile
      t.string :account_id
      t.string :account_name

      t.timestamps
    end
    add_index :friends, :profile, unique: true
  end
end
