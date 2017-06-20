class AddAvatarNameToSteamUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :steam_users, :avatar_name, :string
  end
end
