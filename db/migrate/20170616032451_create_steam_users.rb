class CreateSteamUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :steam_users do |t|
      t.string :account_id
      t.string :account_name
      t.string :profile_url
      t.string :steamid
      t.string :nickname

      t.timestamps
    end
    add_index :steam_users, :steamid, unique: true
  end
end
