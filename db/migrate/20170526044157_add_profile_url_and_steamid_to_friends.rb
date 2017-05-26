class AddProfileUrlAndSteamidToFriends < ActiveRecord::Migration[5.0]
  def change
    add_column :friends, :profile_url, :string
    add_column :friends, :steamid, :string
  end
end
